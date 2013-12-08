package kcs;

//import haxe.io.BytesData;
import kcs.tools.Sample;

using kcs.tools.BytesDataTools;
using kcs.tools.ArrayTools;

import flash.Vector;

private typedef BytesData = flash.utils.ByteArray;

class Decoder {

	public var str : String;

	public var sampleWidth : Int = 4;
	public var baseFreq : Int = 2400;
	public var frameRate : Int = 44100;

	static var bitmasks : Array<Int> = [0x1,0x2,0x4,0x8,0x10,0x20,0x40,0x80];

	//public var dump : String;
	var changeBits : Array<Int>;
	var t = 0;
	var previous = 0;

	var bytes : BytesData;
	var sample : Sample;

	var output : BytesData;
	
	public function new(){
		init();
	}

	public function init(){
		changeBits = new Array();
		bytes = new BytesData();
		//dump = "";
		output = new BytesData();
	}

	function generateChangeBits( /*bytes : BytesData*/ ){
		var signBit;
		var b;
		var f;

		var pos = bytes.position;
		while( Std.int(bytes.bytesAvailable) >= sampleWidth ){
			b = bytes.readByte();
			signBit = b & 0x80;
			changeBits.push( ( signBit ^ previous > 0 ) ? 1 : 0 );
			previous = signBit;
			bytes.position += sampleWidth - 1;
		}
		bytes.position = pos;

	}

	function generateBytes(){
		
		t++;
		var bitStream = changeBits;//bitStream.concat( s );
		//trace("bitstream "+bitStream.length);
		//var outp = new BytesData();
		var framesPerBit : Int = Std.int( Math.floor( frameRate * 8 / baseFreq ) );
		if( sample == null )
			sample = new Sample(framesPerBit);
		
		for( _ in 0...(framesPerBit-sample.count()) ){
			sample.push( bitStream.shift() );
		}
		
		var byteval : Int = 0;
		var val = 0;
		var bit = 0;

		while( Std.int(bitStream.length) > framesPerBit * 12 ){
			
			sample.push( bitStream.shift() );

			if( sample.sum() <= 9 ){
				byteval = 0;
				//var bin = "";
				for( mask in bitmasks ){
					for( _ in 0...framesPerBit ){
						sample.push( bitStream.shift() );
					}
					//sums += " "+sample.sum();
					if( sample.sum() >= 12 ){
						byteval |= mask;
						//bin += "1";
					}else{
						//bin += "0";
					}
				}

				if( byteval > 0 ){
					output.writeByte( byteval );
				}
				
				for( _ in 0...framesPerBit ){
					sample.push( bitStream.shift() );
				}
				
			}

		}

		//return output;

	}

	function readChar() : BytesData {
		//trace("read");
		//trace( output.bytesAvailable );
		var firstByte : Int = output.readUnsignedByte();
		var n : Int = 0;
		var nbytes : Int = 0;
		var ch : Int = firstByte;
		
		var outp = new BytesData();
		//trace("ch "+ch);
		if (ch <= 0x7F) /* 0XXX XXXX one byte */
	    {
	   		//trace("single byte");
	         n = ch;
	         nbytes = 1;
	     }
	     else if ((ch & 0xE0) == 0xC0)  /* 110X XXXX  two bytes */
	     {
	    	//trace("two bytes");
	         n = ch & 31;
	         nbytes = 2;
	     }
	     else if ((ch & 0xF0) == 0xE0)  /* 1110 XXXX  three bytes */
	     {
	     	//trace("three bytes");
	         n = ch & 15;
	         nbytes = 3;
	     }
	     else if ((ch & 0xF8) == 0xF0)  /* 1111 0XXX  four bytes */
	     {
	     	//trace("four bytes");
	         n = ch & 7;
	         nbytes = 4;
	     }
	     else if ((ch & 0xFC) == 0xF8)  /* 1111 10XX  five bytes */
	     {
	         n = ch & 3;
	         nbytes = 5;
	         throw "Error: 5 bytes";
	     }
	     else if ((ch & 0xFE) == 0xFC)  /* 1111 110X  six bytes */
	     {
	         n = ch & 1;
	         nbytes = 6;
	         throw "Error: 6 bytes";
	     }
	     else
	     {
	         /* not a valid first byte of a UTF-8 sequence, skipping */
	         return outp;
	     }
	     
	     outp.writeByte( ch );

	     if( output.bytesAvailable < nbytes-1 ){
	     	var ex = "Too short at "+output.position+" (" +output.bytesAvailable+"/" + (nbytes-1)+")";
	     	output.position -= 1;
	     	throw ex;
	     }

	 	for( i in 0...nbytes-1 ){
			var b = output.readByte();
			
			if ( (b & 0xC0) != 0x80 ){
				output.position -= (1 + i);
				throw "Illegal";
			}

			outp.writeByte( b );

			n = (n << 6) | (b & 0x3F);
		}

		outp.position = 0;
		return outp;
	}

	public function decode( b : BytesData ) {
		var pos = bytes.position;

		bytes.writeBytes( b );
		bytes.position = pos;
		
		generateChangeBits();
		generateBytes();
		
		output.position = 0;
		
		var str = new BytesData();
		
		while( output.bytesAvailable > 0 ){
			try{
				var ch = readChar();
				if( ch == null ) break;
				str.writeBytes(ch);
			}catch(e: Dynamic){
				trace(e);
				break;
			}
		}

		//trace("str length",str.length);

		var remaining = new BytesData();
		if( output.bytesAvailable > 0 ){
			remaining.writeBytes( output , output.position , output.bytesAvailable );
		}
		output = remaining;
		
		return str;
		
	}

}
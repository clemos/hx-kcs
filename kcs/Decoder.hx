package kcs;

import haxe.io.BytesData;
import kcs.tools.Sample;

using kcs.tools.BytesDataTools;
using kcs.tools.ArrayTools;

import flash.Vector;

class Decoder {

	public var str : String;

	public var sampleWidth : Int = 4;
	public var baseFreq : Int = 2400;
	public var frameRate : Int = 44100;

	static var bitmasks = [0x1,0x2,0x4,0x8,0x10,0x20,0x40,0x80];

	public var dump : String;
	var changeBits : Vector<Int>;
	var t = 0;
	var previous = 0;

	var bytes : BytesData;
	var sample : Sample;

	var output : BytesData;
	
	public function new(){
		changeBits = new Vector();
		bytes = new BytesData();
		dump = "";
		output = new BytesData();
	}

	function generateChangeBits( /*bytes : BytesData*/ ){
		var signBit;
		var b;
		var f;

		while( Std.int(bytes.bytesAvailable) >= sampleWidth ){
			b = bytes.readByte();
			signBit = b & 0x80;
			changeBits.push( ( signBit ^ previous > 0 ) ? 1 : 0 );
			previous = signBit;
			bytes.position += sampleWidth - 1;
		}

	}

	function generateBytes(){
		
		t++;
		var bitStream = changeBits;//bitStream.concat( s );
		
		//var outp = new BytesData();
		var framesPerBit : Int = Std.int( Math.floor( frameRate * 8 / baseFreq ) );
		if( sample == null )
			sample = new Sample(framesPerBit);
		
		for( _ in 0...(framesPerBit-sample.count()) ){
			sample.push( bitStream.shift() );
		}
		
		var byteval = 0;
		var val = 0;
		var bit = 0;

		while( Std.int(bitStream.length) > framesPerBit * 12 ){
			
			sample.push( bitStream.shift() );
			
			if( sample.sum() <= 9 ){
				byteval = 0;
				for( mask in bitmasks ){
					for( _ in 0...framesPerBit ){
						sample.push( bitStream.shift() );
					}
					//sums += " "+sample.sum();
					if( sample.sum() >= 12 ){
						byteval |= mask;
					}
				}

				if( byteval > 0 ){
					dump += String.fromCharCode( byteval );
					output.writeByte( byteval );
				}
				
				for( _ in 0...framesPerBit ){
					sample.push( bitStream.shift() );
				}
				
			}

		}

		//return output;

	}

	function readChar(){
		//trace("read");
		//trace( output.bytesAvailable );
		var firstByte = output.readByte();
		var n : UInt = 0;
		var nbytes : UInt = 0;
		var ch : UInt = firstByte;

		var outp = new BytesData();
		
		if (ch <= 0x7F) /* 0XXX XXXX one byte */
	    {
	         n = ch;
	         nbytes = 1;
	     }
	     else if ((ch & 0xE0) == 0xC0)  /* 110X XXXX  two bytes */
	     {
	         n = ch & 31;
	         nbytes = 2;
	     }
	     else if ((ch & 0xF0) == 0xE0)  /* 1110 XXXX  three bytes */
	     {
	         n = ch & 15;
	         nbytes = 3;
	     }
	     else if ((ch & 0xF8) == 0xF0)  /* 1111 0XXX  four bytes */
	     {
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
	         /* not a valid first byte of a UTF-8 sequence */
	         n = ch;
	         nbytes = 1;
	         //throw "Error: Invalid sequence";
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
		while( b.bytesAvailable > 0 ){
			bytes.writeByte( b.readByte() );
		}
		bytes.position = pos;
		generateChangeBits();
		generateBytes();
		
		output.position = 0;
		var str = new BytesData();
		while( output.bytesAvailable > 0 ){
			try{
				var ch = readChar();
				if( ch == null ) break;
				/*if( ch.length > 1 ){
					trace("UTF8");
					//ch.readByte(); // drop one
					try{
					trace(ch.readUTFBytes(ch.length));
					}catch(e:Dynamic){
						trace("Invalid UTF");
						trace(e);
					}
				}
				ch.position = 0;*/
				while( ch.bytesAvailable > 0 ){
					str.writeByte( ch.readByte() );
				}
			}catch(e: Dynamic){
				//trace(e);
				//trace(output.position + "/" + output.length);
				break;
			}
		}

		var remaining = new BytesData();
		while( output.bytesAvailable > 0 ){
			remaining.writeByte( output.readByte() );
		}
		output = remaining;
		output.position = output.length;
		/*if( output.length > 0 ){
			trace("left : "+output.length);
		}*/
		return str;
		
	}

}
package kcs.tools;

import haxe.io.BytesData;

class BytesDataTools {
	public static function sum( bytes : BytesData ){
		var s = 0;

		for( i in 0...bytes.length ){
			s += bytes[i];
		}
		return s;
	}

	public static function slice( bytes : BytesData , start : UInt , ?stop : UInt = null ){
		if( stop == null ){
			stop = start;
			start = 0;
		}
		var outp = new BytesData();
		for( i in start...stop ){
			outp[i] = bytes[i];
		}
		return outp;
	}
}
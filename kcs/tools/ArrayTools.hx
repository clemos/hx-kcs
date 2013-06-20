package kcs.tools;

import flash.Vector;

class ArrayTools {
	public static function sum( bytes : Array<Int> ){
		var s = 0;

		for( v in bytes ){
			s += v;
		}
		return s;
	}

	public static function vSum( bytes : Vector<Int> ){
		var s = 0;
		for( i in 0...bytes.length ){
			s += bytes[i];
		}
		return s;
	}
}
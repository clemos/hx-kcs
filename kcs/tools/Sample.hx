package kcs.tools;

import flash.Vector;

class Sample {
	var a : Array<Int>;
	public var length (default, null) : Int;
	var _sum : Int = 0;

	public function new( length : Int ){
		this.length = length;
		_sum = 0;
		a = [];
	}

	public function push( val : Int ){
		_sum += val;
		a.push( val );

		while( a.length > length ){
			_sum -= a.shift();
		}
	}

	public function offset(){
		var i = 0;
		for( v in a ){
			if( v == 1 ) return i; 
			i++;
		}
		return 0;
	}

	public function unshift( val : Int ){
		_sum += val;
		a.unshift( val );

		while( a.length > length ){
			_sum -= a.pop();
		}
	}

	public inline function count(){
		return a.length;
	}

	public inline function sum() : Int{
		return _sum;
	}

	public function toArray(){
		return a.slice(0); 
	}

	public function toString(){
		return a.join('');
	}

	public function pop(){
		var val = a.pop();
		_sum -= val;
		return val;
	}

	public function popleft(){
		var val = a.shift();
		_sum -= val;
		return val;
	}
}
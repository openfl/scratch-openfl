package com.adobe.utils.macro;


import com.adobe.utils.macro.VM;

class Expression {
	public function print(depth : Int) : Void{trace("top");
	}
	public function exec(vm : VM) : Void{
		trace("WTF");
	}
	
	private function spaces(depth : Int) : String
	{
		// Must be a clever way to do this...
		var str : String = "";
		for (i in 0...depth){
			str += "  ";
		}
		return str;
	}

	public function new()
	{
	}
}






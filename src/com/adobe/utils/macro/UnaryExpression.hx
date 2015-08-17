package com.adobe.utils.macro;

import nme.errors.Error;

class UnaryExpression extends Expression {
	@:allow(com.adobe.utils.macro)
	private function new()
	{
		super();
	}
	
	public var right : Expression;
	override public function print(depth : Int) : Void{
		if (AGALPreAssembler.TRACE_VM) {
			trace(spaces(depth) + "not");
		}
		right.print(depth + 1);
	}
	override public function exec(vm : VM) : Void{
		right.exec(vm);
		
		var varRight : Float = vm.stack.pop();
		var value : Float = ((varRight == 0)) ? 1 : 0;
		
		if (AGALPreAssembler.TRACE_VM) {
			trace("::NotExpression push " + value);
		}
		if (Math.isNaN(varRight)) 			throw new Error("UnaryExpression NaN");
		vm.stack.push(value);
	}
}


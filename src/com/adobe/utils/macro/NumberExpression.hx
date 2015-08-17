package com.adobe.utils.macro;

import nme.errors.Error;

class NumberExpression extends Expression {
	@:allow(com.adobe.utils.macro)
	private function new(v : Float)
	{
		super();
		value = v;
	}
	private var value : Float;
	override public function print(depth : Int) : Void{trace(spaces(depth) + "number=" + value);
	}
	override public function exec(vm : VM) : Void{
		if (AGALPreAssembler.TRACE_VM) {
			trace("::NumberExpression push " + value);
		}
		if (Math.isNaN(value)) 			throw new Error("Pushing NaN to stack");
		vm.stack.push(value);
	}
}

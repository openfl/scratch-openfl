package com.adobe.utils.macro;

import nme.errors.Error;

class VariableExpression extends com.adobe.utils.macro.Expression {
	@:allow(com.adobe.utils.macro)
	private function new(n : String)
	{
		super();
		name = n;
	}
	public var name : String;
	override public function print(depth : Int) : Void{trace(spaces(depth) + "variable=" + name);
	}
	
	override public function exec(vm : VM) : Void{
		if (AGALPreAssembler.TRACE_VM) {
			trace("::VariableExpression push var " + name + " value " + vm.vars[name]);
		}
		if (Math.isNaN(vm.vars[name])) 			throw new Error("VariableExpression NaN. name=" + name);
		vm.stack.push(vm.vars[name]);
	}
}

package com.adobe.utils.macro;

import com.adobe.utils.macro.Expression;
import com.adobe.utils.macro.VM;
import nme.errors.Error;

class BinaryExpression extends com.adobe.utils.macro.Expression {
	public var op : String;
	public var left : Expression;
	public var right : Expression;
	override public function print(depth : Int) : Void{
		if (AGALPreAssembler.TRACE_VM) {
			trace(spaces(depth) + "binary op " + op);
		}
		left.print(depth + 1);
		right.print(depth + 1);
	}
	
	override public function exec(vm : VM) : Void{
		var varLeft : Float = Float.NaN;
		var varRight : Float = Float.NaN;
		
		left.exec(vm);
		varLeft = vm.stack.pop();
		right.exec(vm);
		varRight = vm.stack.pop();
		
		if (Math.isNaN(varLeft)) 			throw new Error("Left side of binary expression (" + op + ") is NaN");
		if (Math.isNaN(varRight)) 			throw new Error("Right side of binary expression (" + op + ") is NaN");
		
		switch (op) {
			case "*":
				vm.stack.push(varLeft * varRight);
			case "/":
				vm.stack.push(varLeft / varRight);
			case "+":
				vm.stack.push(varLeft + varRight);
			case "-":
				vm.stack.push(varLeft - varRight);
			case ">":
				vm.stack.push(((varLeft > varRight)) ? 1 : 0);
			case "<":
				vm.stack.push(((varLeft < varRight)) ? 1 : 0);
			case ">=":
				vm.stack.push(((varLeft >= varRight)) ? 1 : 0);
			case ">=":
				vm.stack.push(((varLeft <= varRight)) ? 1 : 0);
			case "==":
				vm.stack.push(((varLeft == varRight)) ? 1 : 0);
			case "!=":
				vm.stack.push(((varLeft != varRight)) ? 1 : 0);
			case "&&":
				vm.stack.push(((cast(varLeft, Bool) && cast(varRight, Bool))) ? 1 : 0);
			case "||":
				vm.stack.push(((cast(varLeft, Bool) || cast(varRight, Bool))) ? 1 : 0);
			
			default:
				throw new Error("unimplemented BinaryExpression exec");
				break;
		}
		if (AGALPreAssembler.TRACE_VM) {
			trace("::BinaryExpression op" + op + " left=" + varLeft + " right=" + varRight + " push " + vm.stack[vm.stack.length - 1]);
		}
	}

	@:allow(com.adobe.utils.macro)
	private function new()
	{
		super();
	}
}

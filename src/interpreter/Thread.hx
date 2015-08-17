/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// Thread.as
// John Maloney, March 2010
//
// Thread is an internal data structure used by the interpreter. It holds the
// state of a thread so it can continue from where it left off, and it has
// a stack to support nested control structures and procedure calls.

package interpreter;


import blocks.Block;


import blocks.*;
import interpreter.*;

class Thread {
	
	public var target : Dynamic;  // object that owns the stack  
	public var topBlock : Block;  // top block of the stack  
	public var tmpObj : Dynamic;  // temporary object (not saved on stack)  
	public var startDelayCount : Int;  // number of frames to delay before starting  
	
	// the following state is pushed and popped when running substacks
	public var block : Block;
	public var isLoop : Bool;
	public var firstTime : Bool;  // used by certain control structures  
	public var tmp : Int;  // used by repeat and wait  
	public var args : Array<Dynamic>;  // arguments to a user-defined procedure  
	
	// the stack
	private var stack : Array<StackFrame>;
	private var sp : Int;
	
	public function new(b : Block, targetObj : Dynamic, startupDelay : Int = 0)
	{
		target = targetObj;
		stop();
		topBlock = b;
		startDelayCount = startupDelay;
		// initForBlock
		block = b;
		isLoop = false;
		firstTime = true;
		tmp = 0;
	}
	
	public function pushStateForBlock(b : Block) : Void{
		if (sp >= (stack.length - 1)) 			growStack();
		var old : StackFrame = stack[sp++];
		old.block = block;
		old.isLoop = isLoop;
		old.firstTime = firstTime;
		old.tmp = tmp;
		old.args = args;
		// initForBlock
		block = b;
		isLoop = false;
		firstTime = true;
		tmp = 0;
	}
	
	public function popState() : Bool{
		if (sp == 0) 			return false;
		var old : StackFrame = stack[--sp];
		block = old.block;
		isLoop = old.isLoop;
		firstTime = old.firstTime;
		tmp = old.tmp;
		args = old.args;
		return true;
	}
	
	public function stackEmpty() : Bool{return sp == 0;
	}
	
	public function stop() : Void{
		block = null;
		stack = new Array<StackFrame>();
		stack[0] = new StackFrame();
		stack[1] = new StackFrame();
		stack[2] = new StackFrame();
		stack[3] = new StackFrame();
		sp = 0;
	}
	
	public function isRecursiveCall(procCall : Block, procHat : Block) : Bool{
		var callCount : Int = 5;  // maximum number of enclosing procedure calls to examine  
		var i : Int = sp - 1;
		while (i >= 0){
			var b : Block = stack[i].block;
			if (b.op == Specs.CALL) {
				if (procCall == b) 					return true;
				if (procHat == target.procCache[b.spec]) 					return true;
			}
			if (--callCount < 0) 				return false;
			i--;
		}
		return false;
	}
	
	public function returnFromProcedure() : Bool{
		var i : Int = sp - 1;
		while (i >= 0){
			if (stack[i].block.op == Specs.CALL) {
				sp = i + 1;
				popState();
				return true;
			}
			i--;
		}
		return false;
	}
	
	private function initForBlock(b : Block) : Void{
		block = b;
		isLoop = false;
		firstTime = true;
		tmp = 0;
	}
	
	private function growStack() : Void{
		// The stack is an array of Thread instances, pre-allocated for efficiency.
		// When growing, the current size is doubled.
		var s : Int = stack.length;
		var n : Int = s + s;
		stack.length = n;
		for (i in s...n){stack[i] = new StackFrame();
		}
	}
}


class StackFrame {
	@:allow(interpreter)
	private var block : Block;
	@:allow(interpreter)
	private var isLoop : Bool;
	@:allow(interpreter)
	private var firstTime : Bool;
	@:allow(interpreter)
	private var tmp : Int;
	@:allow(interpreter)
	private var args : Array<Dynamic>;

	public function new()
	{
	}
}

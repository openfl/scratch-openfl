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

// Primitives.as
// John Maloney, April 2010
//
// Miscellaneous primitives. Registers other primitive modules.
// Note: A few control structure primitives are implemented directly in Interpreter.as.

package primitives;

import flash.utils.Dictionary;
import blocks.*;
import interpreter.*;
import scratch.ScratchSprite;
import translation.Translator;

class Primitives
{

	private static inline var MaxCloneCount : Int = 300;

	private var app : Scratch;
	private var interp : Interpreter;
	private var counter : Int;

	public function new(app : Scratch, interpreter : Interpreter)
	{
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable : Map<String,Block->Dynamic>) : Void{
		// operators
		primTable[ "+"] = function(b : Dynamic) : Dynamic{return interp.numarg(b, 0) + interp.numarg(b, 1);
		};
		primTable[ "-"] = function(b : Dynamic) : Dynamic{return interp.numarg(b, 0) - interp.numarg(b, 1);
		};
		primTable[ "*"] = function(b : Dynamic) : Dynamic{return interp.numarg(b, 0) * interp.numarg(b, 1);
		};
		primTable[ "/"] = function(b : Dynamic) : Dynamic{return interp.numarg(b, 0) / interp.numarg(b, 1);
		};
		primTable[ "randomFrom:to:"] = primRandom;
		primTable[ "<"] = function(b : Dynamic) : Dynamic{return compare(interp.arg(b, 0), interp.arg(b, 1)) < 0;
		};
		primTable[ "="] = function(b : Dynamic) : Dynamic{return compare(interp.arg(b, 0), interp.arg(b, 1)) == 0;
		};
		primTable[ ">"] = function(b : Dynamic) : Dynamic{return compare(interp.arg(b, 0), interp.arg(b, 1)) > 0;
		};
		primTable[ "&"] = function(b : Dynamic) : Dynamic{return interp.arg(b, 0) && interp.arg(b, 1);
		};
		primTable[ "|"] = function(b : Dynamic) : Dynamic{return interp.arg(b, 0) || interp.arg(b, 1);
		};
		primTable[ "not"] = function(b : Dynamic) : Dynamic{return !interp.arg(b, 0);
		};
		primTable[ "abs"] = function(b : Dynamic) : Dynamic{return Math.abs(interp.numarg(b, 0));
		};
		primTable[ "sqrt"] = function(b : Dynamic) : Dynamic{return Math.sqrt(interp.numarg(b, 0));
		};

		primTable[ "concatenate:with:"] = function(b : Dynamic) : Dynamic{return ("" + interp.arg(b, 0) + interp.arg(b, 1)).substr(0, 10240);
		};
		primTable[ "letter:of:"] = primLetterOf;
		primTable[ "stringLength:"] = function(b : Dynamic) : Dynamic{return Std.string(interp.arg(b, 0)).length;
		};

		primTable[ "%"] = primModulo;
		primTable[ "rounded"] = function(b : Dynamic) : Dynamic{return Math.round(interp.numarg(b, 0));
		};
		primTable[ "computeFunction:of:"] = primMathFunction;

		// clone
		primTable[ "createCloneOf"] = primCreateCloneOf;
		primTable[ "deleteClone"] = primDeleteClone;
		primTable[ "whenCloned"] = interp.primNoop;

		// testing (for development)
		primTable[ "NOOP"] = interp.primNoop;
		primTable[ "COUNT"] = function(b : Dynamic) : Dynamic {
			return counter;
		};
		primTable[ "INCR_COUNT"] = function(b : Dynamic) : Dynamic {
			counter++;
			return null;
		};
		primTable[ "CLR_COUNT"] = function(b : Dynamic) : Dynamic {
			counter = 0;
			return null;
		};

		new LooksPrims(app, interp).addPrimsTo(primTable);
		new MotionAndPenPrims(app, interp).addPrimsTo(primTable);
		new SoundPrims(app, interp).addPrimsTo(primTable);
		//new VideoMotionPrims(app, interp).addPrimsTo(primTable);
		addOtherPrims(primTable);
	}

	private function addOtherPrims(primTable : Map<String,Block->Dynamic>) : Void{
		new SensingPrims(app, interp).addPrimsTo(primTable);
		new ListPrims(app, interp).addPrimsTo(primTable);
	}

	private function primRandom(b : Block) : Float{
		var n1 : Float = interp.numarg(b, 0);
		var n2 : Float = interp.numarg(b, 1);
		var low : Float = ((n1 <= n2)) ? n1 : n2;
		var hi : Float = ((n1 <= n2)) ? n2 : n1;
		if (low == hi)             return low;  // if both low and hi are ints, truncate the result to an int  ;



		var ba1 : BlockArg = try cast(b.args[0], BlockArg) catch(e:Dynamic) null;
		var ba2 : BlockArg = try cast(b.args[1], BlockArg) catch(e:Dynamic) null;
		var int1 : Bool = (ba1 != null) ? ba1.numberType == BlockArg.NT_INT : Std.int(n1) == n1;
		var int2 : Bool = (ba2 != null) ? ba2.numberType == BlockArg.NT_INT : Std.int(n2) == n2;
		if (int1 && int2) 
			return low + Std.int(Math.random() * ((hi + 1) - low));

		return (Math.random() * (hi - low)) + low;
	}

	private function primLetterOf(b : Block) : String{
		var s : String = interp.arg(b, 1);
		var i : Int = Std.int(interp.numarg(b, 0) - 1);
		if ((i < 0) || (i >= s.length))             return "";
		return s.charAt(i);
	}

	private function primModulo(b : Block) : Float{
		var n : Float = interp.numarg(b, 0);
		var modulus : Float = interp.numarg(b, 1);
		var result : Float = n % modulus;
		if (result / modulus < 0)             result += modulus;
		return result;
	}

	private function primMathFunction(b : Block) : Float{
		var op : Dynamic = interp.arg(b, 0);
		var n : Float = interp.numarg(b, 1);
		switch (op)
		{
			case "abs":return Math.abs(n);
			case "floor":return Math.floor(n);
			case "ceiling":return Math.ceil(n);
			case "int":return n - (n % 1);  // used during alpha, but removed from menu  
			case "sqrt":return Math.sqrt(n);
			case "sin":return Math.sin((Math.PI * n) / 180);
			case "cos":return Math.cos((Math.PI * n) / 180);
			case "tan":return Math.tan((Math.PI * n) / 180);
			case "asin":return (Math.asin(n) * 180) / Math.PI;
			case "acos":return (Math.acos(n) * 180) / Math.PI;
			case "atan":return (Math.atan(n) * 180) / Math.PI;
			case "ln":return Math.log(n);
			case "log":return Math.log(n) / Math.LN10;
			case "e ^":return Math.exp(n);
			case "10 ^":return Math.pow(10, n);
		}
		return 0;
	}

	private static var emptyDict : Map<Dynamic, Dynamic> = new Map<Dynamic, Dynamic>();
	private static var lcDict : Map<Dynamic, String> = new Map<Dynamic, String>();
	public static function compare(a1 : Dynamic, a2 : Dynamic) : Int{
		// This is static so it can be used by the list "contains" primitive.
		var n1 : Float = Interpreter.asNumber(a1);
		var n2 : Float = Interpreter.asNumber(a2);
		// X != X is faster than isNaN()
		if (n1 != n1 || n2 != n2) {
			// Suffix the strings to avoid properties and methods of the Dictionary class (constructor, hasOwnProperty, etc)
			if (Std.is(a1, String) && emptyDict.exists(a1))                 a1 += "_";
			if (Std.is(a2, String) && emptyDict.exists(a2))                 a2 += "_";  // at least one argument can't be converted to a number: compare as strings  ;



			var s1 : String = lcDict[a1];
			if (s1 == null)                 s1 = lcDict[a1] = Std.string(a1).toLowerCase();
			var s2 : String = lcDict[a2];
			if (s2 == null)                 s2 = lcDict[a2] = Std.string(a2).toLowerCase();
			//return s1.localeCompare(s2);
			if (s1 < s2) return -1;
			if (s1 > s2) return 1;
			return 0;
		}
		else {
			// compare as numbers
			if (n1 < n2)                 return -1;
			if (n1 == n2)                 return 0;
			if (n1 > n2)                 return 1;
		}
		return 1;
	}

	private function primCreateCloneOf(b : Block) : Dynamic{
		var objName : String = interp.arg(b, 0);
		var proto : ScratchSprite = app.stagePane.spriteNamed(objName);
		if ("_myself_" == objName)             proto = cast(interp.activeThread.target, ScratchSprite);
		if (proto == null)             return null;
		if (app.runtime.cloneCount > MaxCloneCount)             return null;
		var clone : ScratchSprite = new ScratchSprite();
		if (proto.parent == app.stagePane) 
			app.stagePane.addChildAt(clone, app.stagePane.getChildIndex(proto))
		else 
		app.stagePane.addChild(clone);

		clone.initFrom(proto, true);
		clone.objName = proto.objName;
		clone.isClone = true;
		for (stack/* AS3HX WARNING could not determine type for var: stack exp: EField(EIdent(clone),scripts) type: null */ in clone.scripts){
			if (stack.op == "whenCloned") {
				interp.startThreadForClone(stack, clone);
			}
		}
		app.runtime.cloneCount++;
		return null;
	}

	private function primDeleteClone(b : Block) : Dynamic{
		var clone : ScratchSprite = interp.targetSprite();
		if ((clone == null) || (!clone.isClone) || (clone.parent == null))             return null;
		if (clone.bubble != null && clone.bubble.parent != null)             clone.bubble.parent.removeChild(clone.bubble);
		clone.parent.removeChild(clone);
		app.interp.stopThreadsFor(clone);
		app.runtime.cloneCount--;
		return null;
	}
}

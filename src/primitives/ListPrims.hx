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

// ListPrimitives.as
// John Maloney, September 2010
//
// List primitives.

package primitives;


import blocks.Block;
import interpreter.Interpreter;
import watchers.ListWatcher;
import scratch.ScratchObj;

class ListPrims
{

	private var app : Scratch;
	private var interp : Interpreter;

	public function new(app : Scratch, interpreter : Interpreter)
	{
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable : Map<String, Block->Dynamic>) : Void{
		primTable[Specs.GET_LIST] = primContents;
		primTable[ "append:toList:"] = primAppend;
		primTable[ "deleteLine:ofList:"] = primDelete;
		primTable[ "insert:at:ofList:"] = primInsert;
		primTable[ "setLine:ofList:to:"] = primReplace;
		primTable[ "getLine:ofList:"] = primGetItem;
		primTable[ "lineCountOfList:"] = primLength;
		primTable[ "list:contains:"] = primContains;
	}

	private function primContents(b : Block) : String{
		var list : ListWatcher = interp.targetObj().lookupOrCreateList(b.spec);
		if (list == null)             return "";
		var allSingleLetters : Bool = true;
		for (el/* AS3HX WARNING could not determine type for var: el exp: EField(EIdent(list),contents) type: null */ in list.contents){
			if (!((Std.is(el, String)) && (el.length == 1))) {
				allSingleLetters = false;
				break;
			}
		}
		return (list.contents.join((allSingleLetters) ? "" : " "));
	}

	private function primAppend(b : Block) : Dynamic{
		var list : ListWatcher = listarg(b, 1);
		if (list == null)             return null;
		listAppend(list, interp.arg(b, 0));
		if (list.visible)             list.updateWatcher(list.contents.length, false, interp);
		return null;
	}

	private function listAppend(list : ListWatcher, item : Dynamic) : Void{
		list.contents.push(item);
	}

	private function primDelete(b : Block) : Dynamic{
		var which : Dynamic = interp.arg(b, 0);
		var list : ListWatcher = listarg(b, 1);
		if (list == null)             return null;
		var len : Int = list.contents.length;
		if (which == "all") {
			listSet(list, []);
			if (list.visible)                 list.updateWatcher(-1, false, interp);
		}
		var n : Float = ((which == "last")) ? len : Std.parseFloat(which);
		if (Math.isNaN(n))             return null;
		var i : Int = Math.round(n);
		if ((i < 1) || (i > len))             return null;
		listDelete(list, i);
		if (list.visible)             list.updateWatcher((((i == len)) ? i - 1 : i), false, interp);
		return null;
	}

	private function listSet(list : ListWatcher, newValue : Array<Dynamic>) : Void{
		list.contents = newValue;
	}

	private function listDelete(list : ListWatcher, i : Int) : Void{
		list.contents.splice(i - 1, 1);
	}

	private function primInsert(b : Block) : Dynamic{
		var val : Dynamic = interp.arg(b, 0);
		var where : Dynamic = interp.arg(b, 1);
		var list : ListWatcher = listarg(b, 2);
		if (list == null)             return null;
		if (where == "last") {
			listAppend(list, val);
			if (list.visible)                 list.updateWatcher(list.contents.length, false, interp);
		}
		else {
			var i : Int = computeIndex(where, list.contents.length + 1);
			if (i < 0)                 return null;
			listInsert(list, i, val);
			if (list.visible)                 list.updateWatcher(i, false, interp);
		}
		return null;
	}

	private function listInsert(list : ListWatcher, i : Int, item : Dynamic) : Void{
		list.contents.insert(i - 1, item);
	}

	private function primReplace(b : Block) : Dynamic{
		var list : ListWatcher = listarg(b, 1);
		if (list == null)             return null;
		var i : Int = computeIndex(interp.arg(b, 0), list.contents.length);
		if (i < 0)             return null;
		listReplace(list, i, interp.arg(b, 2));
		if (list.visible)             list.updateWatcher(i, false, interp);
		return null;
	}

	private function listReplace(list : ListWatcher, i : Int, item : Dynamic) : Void{
		list.contents[i - 1] = item;
	}

	private function primGetItem(b : Block) : Dynamic{
		var list : ListWatcher = listarg(b, 1);
		if (list == null)             return "";
		var i : Int = computeIndex(interp.arg(b, 0), list.contents.length);
		if (i < 0)             return "";
		if (list.visible)             list.updateWatcher(i, true, interp);
		return list.contents[i - 1];
	}

	private function primLength(b : Block) : Float{
		var list : ListWatcher = listarg(b, 0);
		if (list == null)             return 0;
		return list.contents.length;
	}

	private function primContains(b : Block) : Bool{
		var list : ListWatcher = listarg(b, 0);
		if (list == null)             return false;
		var item : Dynamic = interp.arg(b, 1);
		if (list.contents.indexOf(item) >= 0)             return true;
		for (el/* AS3HX WARNING could not determine type for var: el exp: EField(EIdent(list),contents) type: null */ in list.contents){
			// use Scratch comparison operator (Scratch considers the string '123' equal to the number 123)
			if (Primitives.compare(el, item) == 0)                 return true;
		}
		return false;
	}

	private function listarg(b : Block, i : Int) : ListWatcher{
		var listName : String = interp.arg(b, i);
		if (listName.length == 0)             return null;
		var obj : ScratchObj = interp.targetObj();
		var result : ListWatcher = obj.listCache[listName];
		if (result == null) {
			result = obj.listCache[listName] = obj.lookupOrCreateList(listName);
		}
		return result;
	}

	private function computeIndex(n : Dynamic, len : Int) : Int{
		var i : Int;
		if (!(Std.is(n, Float))) {
			if (n == "last")                 return ((len == 0)) ? -1 : len;
			if ((n == "any") || (n == "random"))                 return ((len == 0)) ? -1 : 1 + Math.floor(Math.random() * len);
			n = Std.parseFloat(n);
			if (Math.isNaN(n))                 return -1;
		}
		i = ((Std.is(n, Int))) ? n : Math.floor(n);
		if ((i < 1) || (i > len))             return -1;
		return i;
	}
}

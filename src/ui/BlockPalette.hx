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

// BlockPalette.as
// John Maloney, August 2009
//
// A BlockPalette holds the blocks for the selected category.
// The mouse handling code detects when a Block's parent is a BlocksPalette and
// creates a copy of that block when it is dragged out of the palette.

package ui;

import ui.ScrollFrameContents;

import flash.geom.*;
import blocks.Block;
import interpreter.Interpreter;
import uiwidgets.*;
import scratch.ScratchObj;
import scratch.ScratchComment;

class BlockPalette extends ScrollFrameContents {
	
	public var isBlockPalette : Bool = true;
	
	public function new()
	{
		super();
		this.color = 0xE0E0E0;
	}
	
	override public function clear(scrollToOrigin : Bool = true) : Void{
		var interp : Interpreter = Scratch.app.interp;
		var targetObj : ScratchObj = Scratch.app.viewedObj();
		while (numChildren > 0){
			var b : Block = try cast(getChildAt(0), Block) catch(e:Dynamic) null;
			if (interp.isRunning(b, targetObj)) 				interp.toggleThread(b, targetObj);
			removeChildAt(0);
		}
		if (scrollToOrigin) 			x = y = 0;
	}
	
	public function handleDrop(obj : Dynamic) : Bool{
		// Delete blocks and stacks dropped onto the palette.
		var c : ScratchComment = try cast(obj, ScratchComment) catch(e:Dynamic) null;
		if (c != null) {
			c.x = c.y = 20;  // position for undelete  
			c.deleteComment();
			return true;
		}
		var b : Block = try cast(obj, Block) catch(e:Dynamic) null;
		if (b != null) {
			return b.deleteStack();
		}
		return false;
	}
	
	public static function strings() : Array<Dynamic>{
		return ["Cannot Delete", "To delete a block definition, first remove all uses of the block."];
	}
}

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

package util;

import flash.display.DisplayObject;
import blocks.*;
import interpreter.Variable;
import scratch.*;
import watchers.*;

class OldProjectReader
{

	public function extractProject(objTable : Array<Dynamic>) : ScratchStage{
		var newStage : ScratchStage = new ScratchStage();
		var stageContents : Array<Dynamic> = [];
		recordSpriteNames(objTable);
		for (i in 0...objTable.length){
			var entry : Array<Dynamic> = objTable[i];
			var classID : Int = entry[1];
			if (classID == 125) {
				/* stage:
				objName 9
				vars 10
				blocksBin 11
				isClone 12 (not used)
				media 13
				current costume 14
				---
				zoom 15 (not used)
				hPan 16 (not used)
				vPan 17 (not used)
				obsoleteSavedState 18 (not used)
				spriteOrderInLibrary 19
				volume 20 (always 100 in saved projects)
				tempoBPM 21
				sceneStates 22 (not used)
				lists 23
			*/
				stageContents = entry[5];
				newStage = entry[0];
				newStage.objName = entry[9];
				newStage.variables = buildVars(entry[10]);
				newStage.scripts = buildScripts(entry[11]);
				newStage.scriptComments = buildComments(entry[11]);
				fixCommentRefs(newStage.scriptComments, newStage.scripts);
				newStage.setMedia(entry[13], entry[14]);
				if (entry.length > 19)                     recordSpriteLibraryOrder(entry[19]);
				if (entry.length > 21)                     newStage.tempoBPM = entry[21];
				if (entry.length > 23)                     newStage.lists = buildLists(entry[23], newStage);
			}
			if (classID == 124) {
				/* sprite:
				objName 9
				vars 10
				blocksBin 11
				isClone 12 (not used)
				media 13
				current costume 14
				---
				visibility 15 (always 100 in saved projects)
				scalePoint 16
				rotationDegrees 17
				rotationStyle 18
				volume 19 (always 100 in saved projects)
				tempoBPM 20 (sprites now use stage tempo)
				draggable 21
				sceneStates 22 (not used)
				lists 23
			*/
				var s : ScratchSprite = entry[0];
				s.objName = entry[9];
				s.variables = buildVars(entry[10]);
				s.scripts = buildScripts(entry[11]);
				s.scriptComments = buildComments(entry[11]);
				fixCommentRefs(s.scriptComments, s.scripts);
				s.setMedia(entry[13], entry[14]);
				s.visible = (entry[7] & 1) == 0;
				s.scaleX = s.scaleY = entry[16][0];
				s.rotationStyle = entry[18];
				var dir : Float = Math.round(entry[17] * 1000000) / 1000000;  // round to nearest millionth  
				s.setDirection(dir - 270);
				if (entry.length > 21)                     s.isDraggable = entry[21];
				if (entry.length > 23)                     s.lists = buildLists(entry[23], s);
				var c : ScratchCostume = s.currentCostume();
				s.setScratchXY(
						entry[3][0] + c.rotationCenterX - 240,
						180 - (entry[3][1] + c.rotationCenterY));
			}
		}
		var i:Int = stageContents.length - 1;
		while (i >= 0){
			// filter out any SensorBoardMorphs on the stage
			if (Std.is(stageContents[i], DisplayObject))                 newStage.addChild(stageContents[i]);
			i--;
		}
		fixWatchers(newStage);
		return newStage;
	}

	private function recordSpriteNames(objTable : Array<Dynamic>) : Void{
		// Set the objName for every sprite in the object table.
		// This must be done before processing scripts so that
		// inter-sprite references (e.g. in 'distanceTo:' can
		// be converted from a direct object reference to a name.
		for (i in 0...objTable.length){
			var entry : Array<Dynamic> = objTable[i];
			if (entry[1] == 124) {
				cast((entry[0]), ScratchSprite).objName = entry[9];
			}
		}
	}

	private function fixWatchers(newStage : ScratchStage) : Void{
		// Connect each variable watcher on the stage to its underlying variable.
		// Update the contents of visible list watchers.
		for (i in 0...newStage.numChildren){
			var c : Dynamic = newStage.getChildAt(i);
			if (Std.is(c, Watcher)) {
				var w : Watcher = try cast(c, Watcher) catch(e:Dynamic) null;
				var t : ScratchObj = w.target;
				for (v/* AS3HX WARNING could not determine type for var: v exp: EField(EIdent(t),variables) type: null */ in t.variables){
					if (w.isVarWatcherFor(t, v.name))                         v.watcher = w;
				}
			}
			if (Std.is(c, ListWatcher))                 c.updateTitleAndContents();
		}
	}

	private function recordSpriteLibraryOrder(spriteList : Array<Dynamic>) : Void{
		for (i in 0...spriteList.length){
			var s : ScratchSprite = spriteList[i];
			s.indexInLibrary = i;
		}
	}

	private function buildVars(pairs : Array<Dynamic>) : Array<Dynamic>{
		if (pairs == null)             return [];
		var result : Array<Dynamic> = [];
		var i : Int = 0;
		while (i < (pairs.length - 1)){
			result.push(new Variable(pairs[i], pairs[i + 1]));
			i += 2;
		}
		return result;
	}

	private function buildLists(pairs : Array<Dynamic>, targetObj : ScratchObj) : Array<ListWatcher>{
		if (pairs == null)             return [];
		var result : Array<ListWatcher> = [];
		var i : Int = 0;
		while (i < (pairs.length - 1)){
			var listW : ListWatcher = cast((pairs[i + 1]), ListWatcher);
			listW.target = targetObj;
			result.push(listW);
			i += 2;
		}
		return result;
	}

	private function buildScripts(scripts : Array<Dynamic>) : Array<Dynamic>{
		if (!(Std.is(scripts[0], Array)))             return [];
		var result : Array<Dynamic> = [];
		for (stack in scripts){
			// stack is of form: [[x y] [blocks]]
			var a : Array<Dynamic> = stack[1][0];
			if (a != null && (a[0] == "scratchComment"))                 continue;  // skip comments  ;
			var topBlock : Block = BlockIO.arrayToStack(stack[1]);
			topBlock.x = stack[0][0];
			topBlock.y = stack[0][1];
			result.push(topBlock);
		}
		return result;
	}

	private function buildComments(scripts : Array<Dynamic>) : Array<Dynamic>{
		if (!(Std.is(scripts[0], Array)))             return [];
		var result : Array<Dynamic> = [];
		for (stack in scripts){
			// stack is of form: [[x y] [blocks]]
			var a : Array<Dynamic> = stack[1][0];
			if (a != null && (a[0] != "scratchComment"))                 continue;  // skip non-comments  ;
			var blockID : Int = (a[4]) ? a[4] : -1;
			var comment : ScratchComment = new ScratchComment(a[1], a[2], a[3], blockID);
			comment.x = stack[0][0];
			comment.y = stack[0][1];
			result.push(comment);
		}
		return result;
	}

	private function fixCommentRefs(comments : Array<Dynamic>, stacks : Array<Dynamic>) : Void{
		// Bind comments block references, using the Squeak enumeration order.
		var blockListOld : Array<Dynamic> = [null];  // Scratch 1.4 blockRefs are 1-based  
		var blockListNew : Array<Dynamic> = [];  // Scratch 2.0 blockRefs are 0-based  
		for (b in stacks){
			b.fixStackLayout();
			oldAddAllBlocksTo(b, blockListOld);
			newAddAllBlocksTo(b, blockListNew);
		}
		for (c in comments){
			if ((c.blockID > 0) && (c.blockID < blockListOld.length)) {
				var target : Block = try cast(blockListOld[c.blockID], Block) catch(e:Dynamic) null;
				var newID : Int = Lambda.indexOf(blockListNew, target);
				c.blockID = newID;
			}
		}
	}

	private function oldAddAllBlocksTo(b : Block, blockList : Array<Dynamic>) : Void{
		// Recursively enumerate all blocks of the given stack in Squeak order
		// and add them to blockList. Block arguments are not included.
		if (b.subStack2 != null)             oldAddAllBlocksTo(b.subStack2, blockList);
		if (b.subStack1 != null)             oldAddAllBlocksTo(b.subStack1, blockList);
		if (b.nextBlock != null)             oldAddAllBlocksTo(b.nextBlock, blockList);
		blockList.push(b);
	}

	private function newAddAllBlocksTo(b : Block, blockList : Array<Dynamic>) : Void{
		// Recursively enumerate all blocks of the given stack in Squeak order
		// and add them to blockList. Block arguments are not included.
		blockList.push(b);
		if (b.subStack1 != null)             newAddAllBlocksTo(b.subStack1, blockList);
		if (b.subStack2 != null)             newAddAllBlocksTo(b.subStack2, blockList);
		if (b.nextBlock != null)             newAddAllBlocksTo(b.nextBlock, blockList);
	}

	private function arrayToString(a : Array<Dynamic>) : String{
		var result : String = "[";
		var i : Int;
		for (i in 0...a.length){
			result += ((Std.is(a[i], Array))) ? arrayToString(a[i]) : a[i];
			if (i < (a.length - 1))                 result += " ";
		}
		return result + "]";
	}

	public function new()
	{
	}
}

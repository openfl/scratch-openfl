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

// ScriptsPane.as
// John Maloney, August 2009
//
// A ScriptsPane is a working area that holds blocks and stacks. It supports the
// logic that highlights possible drop targets as a block is being dragged and
// decides what to do when the block is dropped.

package uiwidgets;


import flash.display.*;
import flash.events.MouseEvent;
import flash.geom.Point;
import blocks.*;
import scratch.*;
import flash.geom.Rectangle;
import ui.media.MediaInfo;

class ScriptsPane extends ScrollFrameContents
{

	private static inline var INSERT_NORMAL : Int = 0;
	private static inline var INSERT_ABOVE : Int = 1;
	private static inline var INSERT_SUB1 : Int = 2;
	private static inline var INSERT_SUB2 : Int = 3;
	private static inline var INSERT_WRAP : Int = 4;

	public var app : Scratch;
	public var padding : Int = 10;

	private var viewedObj : ScratchObj;
	private var commentLines : Shape;

	private var possibleTargets : Array<Dynamic> = [];
	private var nearestTarget : Array<Dynamic> = [];
	private var feedbackShape : BlockShape;

	public function new(app : Scratch)
	{
		super();
		this.app = app;
		addChild(commentLines = new Shape());
		hExtra = vExtra = 40;
		createTexture();
		addFeedbackShape();
	}

	public static function strings() : Array<String>{
		return [
		"add comment", 
		"clean up"];
	}

	private function createTexture() : Void{
		var alpha : Int = 0x90 << 24;
		var bgColor : Int = alpha | 0xD7D7D7;
		var c1 : Int = alpha | 0xCBCBCB;
		var c2 : Int = alpha | 0xC8C8C8;
		texture = new BitmapData(23, 23, true, bgColor);
		texture.setPixel(11, 0, c1);
		texture.setPixel(10, 1, c1);
		texture.setPixel(11, 1, c2);
		texture.setPixel(12, 1, c1);
		texture.setPixel(11, 2, c1);
		texture.setPixel(0, 11, c1);
		texture.setPixel(1, 10, c1);
		texture.setPixel(1, 11, c2);
		texture.setPixel(1, 12, c1);
		texture.setPixel(2, 11, c1);
	}

	public function viewScriptsFor(obj : ScratchObj) : Void{
		// View the blocks for the given object.
		saveScripts(false);
		while (numChildren > 0){
			var child : DisplayObject = removeChildAt(0);
			child.cacheAsBitmap = false;
		}
		addChild(commentLines);
		viewedObj = obj;
		if (viewedObj != null) {
			var blockList : Array<Block> = viewedObj.allBlocks();
			for (b in viewedObj.scripts){
				b.cacheAsBitmap = true;
				addChild(b);
			}
			for (c in viewedObj.scriptComments){
				c.updateBlockRef(blockList);
				addChild(c);
			}
		}
		fixCommentLayout();
		updateSize();
		x = y = 0;  // reset scroll offset  
		cast(parent, ScrollFrame).updateScrollbars();
	}

	public function saveScripts(saveNeeded : Bool = true) : Void{
		// Save the blocks in this pane in the viewed objects scripts list.
		if (viewedObj == null)             return;
		viewedObj.scripts.splice(0,viewedObj.scripts.length);  // remove all  
		viewedObj.scriptComments.splice(0,viewedObj.scriptComments.length);  // remove all  
		for (i in 0...numChildren){
			var o : Dynamic = getChildAt(i);
			if (Std.is(o, Block))                 viewedObj.scripts.push(o);
			if (Std.is(o, ScratchComment))                 viewedObj.scriptComments.push(o);
		}
		var blockList : Array<Dynamic> = viewedObj.allBlocks();
		for (c in viewedObj.scriptComments){
			c.updateBlockID(blockList);
		}
		if (saveNeeded)             app.setSaveNeeded();
		fixCommentLayout();
	}

	public function prepareToDrag(b : Block) : Void{
		findTargetsFor(b);
		nearestTarget = null;
		b.scaleX = b.scaleY = scaleX;
		addFeedbackShape();
	}

	public function prepareToDragComment(c : ScratchComment) : Void{
		c.scaleX = c.scaleY = scaleX;
	}

	public function draggingDone() : Void{
		hideFeedbackShape();
		possibleTargets = [];
		nearestTarget = null;
	}

	public function updateFeedbackFor(b : Block) : Void{

		function updateHeight() : Void{
			var h : Int = BlockShape.EmptySubstackH;
			if (nearestTarget != null) {
				var t : Dynamic = nearestTarget[1];
				var o : Block = null;
				var _sw0_ = (nearestTarget[2]);                

				switch (_sw0_)
				{
					case INSERT_NORMAL:
						o = t.nextBlock;
					case INSERT_WRAP:
						o = t;
					case INSERT_SUB1:
						o = t.subStack1;
					case INSERT_SUB2:
						o = t.subStack2;
				}
				if (o != null) {
					h = Std.int(o.height);
					if (!o.bottomBlock().isTerminal)                         h -= BlockShape.NotchDepth;
				}
			}
			b.previewSubstack1Height(h);
		};

		function updateFeedbackShape() : Void{
			var t : Dynamic = nearestTarget[1];
			var localP : Point = globalToLocal(nearestTarget[0]);
			feedbackShape.x = localP.x;
			feedbackShape.y = localP.y;
			feedbackShape.visible = true;
			if (b.isReporter) {
				if (Std.is(t, Block))                     feedbackShape.copyFeedbackShapeFrom(t, true);
				if (Std.is(t, BlockArg))                     feedbackShape.copyFeedbackShapeFrom(t, true);
			}
			else {
				var insertionType : Int = nearestTarget[2];
				var wrapH : Int = ((insertionType == INSERT_WRAP)) ? t.getRect(t).height : 0;
				var isInsertion : Bool = (insertionType != INSERT_ABOVE) && (insertionType != INSERT_WRAP);
				feedbackShape.copyFeedbackShapeFrom(b, false, isInsertion, wrapH);
			}
		};

		if (mouseX + x >= 0) {
			nearestTarget = nearestTargetForBlockIn(b, possibleTargets);
			if (nearestTarget != null) {
				updateFeedbackShape();
			}
			else {
				hideFeedbackShape();
			}
			if (b.base.canHaveSubstack1() && b.subStack1 == null) {
				updateHeight();
			}
		}
		else {
			nearestTarget = null;
			hideFeedbackShape();
		}

		fixCommentLayout();
	}

	public function allStacks() : Array<Dynamic>{
		var result : Array<Dynamic> = [];
		for (i in 0...numChildren){
			var child : DisplayObject = getChildAt(i);
			if (Std.is(child, Block))                 result.push(child);
		}
		return result;
	}

	private function blockDropped(b : Block) : Void{
		if (nearestTarget == null) {
			b.cacheAsBitmap = true;
		}
		else {
			if (app.editMode)                 b.hideRunFeedback();
			b.cacheAsBitmap = false;
			if (b.isReporter) {
				cast((nearestTarget[1].parent), Block).replaceArgWithBlock(nearestTarget[1], b, this);
			}
			else {
				var targetCmd : Block = nearestTarget[1];
				var _sw1_ = (nearestTarget[2]);                

				switch (_sw1_)
				{
					case INSERT_NORMAL:
						targetCmd.insertBlock(b);
					case INSERT_ABOVE:
						targetCmd.insertBlockAbove(b);
					case INSERT_SUB1:
						targetCmd.insertBlockSub1(b);
					case INSERT_SUB2:
						targetCmd.insertBlockSub2(b);
					case INSERT_WRAP:
						targetCmd.insertBlockAround(b);
				}
			}
		}
		if (b.op == Specs.PROCEDURE_DEF)             app.updatePalette();
		app.runtime.blockDropped(b);
	}

	public function findTargetsFor(b : Block) : Void{
		possibleTargets = [];
		var bEndWithTerminal : Bool = b.bottomBlock().isTerminal;
		var bCanWrap : Bool = b.base.canHaveSubstack1() && b.subStack1 == null;  // empty C or E block  
		var p : Point;
		for (i in 0...numChildren){
			var child : DisplayObject = getChildAt(i);
			if (Std.is(child, Block)) {
				var target : Block = cast((child), Block);
				if (b.isReporter) {
					if (reporterAllowedInStack(b, target))                         findReporterTargetsIn(target);
				}
				else {
					if (!target.isReporter) {
						if (!bEndWithTerminal && !target.isHat) {
							// b is a stack ending with a non-terminal command block and target
							// is not a hat so the bottom block of b can connect to top of target
							p = target.localToGlobal(new Point(0, -(b.height - BlockShape.NotchDepth)));
							possibleTargets.push([p, target, INSERT_ABOVE]);
						}
						if (bCanWrap && !target.isHat) {
							p = target.localToGlobal(new Point(-BlockShape.SubstackInset, -(b.base.substack1y() - BlockShape.NotchDepth)));
							possibleTargets.push([p, target, INSERT_WRAP]);
						}
						if (!b.isHat)                             findCommandTargetsIn(target, bEndWithTerminal && !bCanWrap);
					}
				}
			}
		}
	}

	private function reporterAllowedInStack(r : Block, stack : Block) : Bool{
		// True if the given reporter block can be inserted in the given stack.
		// Procedure parameter reporters can only be added to a block definition
		// that defines parameter.
		return true;  // xxx disable this check for now; it was causing confusion at Scratch@MIT conference  
		if (r.op != Specs.GET_PARAM)             return true;
		var top : Block = stack.topBlock();
		return (top.op == Specs.PROCEDURE_DEF) && (top.parameterNames.indexOf(r.spec) > -1);
	}

	private function findCommandTargetsIn(stack : Block, endsWithTerminal : Bool) : Void{
		var target : Block = stack;
		while (target != null){
			var p : Point = target.localToGlobal(new Point(0, 0));
			if (!target.isTerminal && (!endsWithTerminal || target.nextBlock == null)) {
				// insert stack after target block:
				// target block must not be a terminal
				// if stack does not end with a terminal, it can be inserted between blocks
				// otherwise, it can only inserted after the final block of the substack
				p = target.localToGlobal(new Point(0, target.base.nextBlockY() - 3));
				possibleTargets.push([p, target, INSERT_NORMAL]);
			}
			if (target.base.canHaveSubstack1() && (!endsWithTerminal || target.subStack1 == null)) {
				p = target.localToGlobal(new Point(15, target.base.substack1y()));
				possibleTargets.push([p, target, INSERT_SUB1]);
			}
			if (target.base.canHaveSubstack2() && (!endsWithTerminal || target.subStack2 == null)) {
				p = target.localToGlobal(new Point(15, target.base.substack2y()));
				possibleTargets.push([p, target, INSERT_SUB2]);
			}
			if (target.subStack1 != null)                 findCommandTargetsIn(target.subStack1, endsWithTerminal);
			if (target.subStack2 != null)                 findCommandTargetsIn(target.subStack2, endsWithTerminal);
			target = target.nextBlock;
		}
	}

	private function findReporterTargetsIn(stack : Block) : Void{
		var b : Block = stack;
		var i : Int;
		while (b != null){
			for (i in 0...b.args.length){
				var o : DisplayObject = b.args[i];
				if ((Std.is(o, Block)) || (Std.is(o, BlockArg))) {
					var p : Point = o.localToGlobal(new Point(0, 0));
					possibleTargets.push([p, o, INSERT_NORMAL]);
					if (Std.is(o, Block))                         findReporterTargetsIn(cast((o), Block));
				}
			}
			if (b.subStack1 != null)                 findReporterTargetsIn(b.subStack1);
			if (b.subStack2 != null)                 findReporterTargetsIn(b.subStack2);
			b = b.nextBlock;
		}
	}

	private function addFeedbackShape() : Void{
		if (feedbackShape == null)             feedbackShape = new BlockShape();
		feedbackShape.setWidthAndTopHeight(10, 10);
		hideFeedbackShape();
		addChild(feedbackShape);
	}

	private function hideFeedbackShape() : Void{
		feedbackShape.visible = false;
	}

	private function nearestTargetForBlockIn(b : Block, targets : Array<Dynamic>) : Array<Dynamic>{
		var threshold : Int = (b.isReporter) ? 15 : 30;
		var i : Int;
		var minDist : Int = 100000;
		var nearest : Array<Dynamic> = null;
		var bTopLeft : Point = new Point(b.x, b.y);
		var bBottomLeft : Point = new Point(b.x, b.y + b.height - 3);

		for (i in 0...targets.length){
			var item : Array<Dynamic> = targets[i];
			var diff : Point = bTopLeft.subtract(item[0]);
			var dist : Float = Math.abs(diff.x / 2) + Math.abs(diff.y);
			if ((dist < minDist) && (dist < threshold) && dropCompatible(b, item[1])) {
				minDist = Std.int(dist);
				nearest = item;
			}
		}
		return ((minDist < threshold)) ? nearest : null;
	}

	private function dropCompatible(droppedBlock : Block, target : DisplayObject) : Bool{
		var menusThatAcceptReporters : Array<Dynamic> = [
		"broadcast", "costume", "backdrop", "scene", "sound", 
		"spriteOnly", "spriteOrMouse", "spriteOrStage", "touching"];
		if (!droppedBlock.isReporter)             return true;  // dropping a command block  ;
		if (Std.is(target, Block)) {
			if (cast((target), Block).isEmbeddedInProcHat())                 return false;
			if (cast((target), Block).isEmbeddedParameter())                 return false;
		}
		var dropType : String = droppedBlock.type;
		var targetType : String = Std.is(target, Block) ? cast((target.parent), Block).argType(target).substring(1) : cast((target), BlockArg).type;
		if (targetType == "m") {
			if (cast((target.parent), Block).type == "h")                 return false;
			return Lambda.indexOf(menusThatAcceptReporters, cast((target), BlockArg).menuName) > -1;
		}
		if (targetType == "b")             return dropType == "b";
		return true;
	}

	/* Dropping */

	public function handleDrop(obj : Dynamic) : Bool{
		var localP : Point = globalToLocal(new Point(obj.x, obj.y));

		if (Std.is(obj, MediaInfo)) {
			var info : MediaInfo = cast(obj, MediaInfo);
			if (info.scripts == null)                 return false;
			localP.x += info.thumbnailX();
			localP.y += info.thumbnailY();
			addStacksFromBackpack(info, localP);
			return true;
		}

		var b : Block = null;
		if (Std.is(obj, Block)) b = cast(obj, Block);
		var c : ScratchComment = null;
		if (Std.is(obj, ScratchComment)) c = cast(obj, ScratchComment);
		if (b == null && c == null)             return false;

		obj.x = Math.max(5, localP.x);
		obj.y = Math.max(5, localP.y);
		obj.scaleX = obj.scaleY = 1;
		addChild(obj);
		if (b != null)             blockDropped(b);
		if (c != null) {
			c.blockRef = blockAtPoint(localP);
		}
		saveScripts();
		updateSize();
		if (c != null)             fixCommentLayout();
		return true;
	}

	private function addStacksFromBackpack(info : MediaInfo, dropP : Point) : Void{
		if (info.scripts == null)             return;
		var forStage : Bool = app.viewedObj() != null && app.viewedObj().isStage;
		for (a/* AS3HX WARNING could not determine type for var: a exp: EField(EIdent(info),scripts) type: null */ in info.scripts){
			if (a.length < 1)                 continue;
			var blockOrComment : Dynamic = 
			((Std.is(a[0], Array))) ? 
			BlockIO.arrayToStack(a, forStage) : 
			ScratchComment.fromArray(a);
			blockOrComment.x = dropP.x;
			blockOrComment.y = dropP.y;
			addChild(blockOrComment);
			if (Std.is(blockOrComment, Block))                 blockDropped(blockOrComment);
		}
		saveScripts();
		updateSize();
		fixCommentLayout();
	}

	private function blockAtPoint(p : Point) : Block{
		// Return the block at the given point (local) or null.
		var result : Block = null;
		for (stack/* AS3HX WARNING could not determine type for var: stack exp: ECall(EIdent(allStacks),[]) type: null */ in allStacks()){
			stack.allBlocksDo(function(b : Block) : Void{
						if (!b.isReporter) {
							var r : Rectangle = b.getBounds(parent);
							if (r.containsPoint(p) && ((p.y - r.y) < b.base.substack1y()))                                 result = b;
						}
					});
		}
		return result;
	}

	/* Menu */

	public function menu(evt : MouseEvent) : Menu{
		var x : Float = mouseX;
		var y : Float = mouseY;
		function newComment() : Void{addComment(null, x, y);
		};
		var m : Menu = new Menu();
		m.addItem("clean up", cleanUp);
		m.addItem("add comment", newComment);
		return m;
	}

	public function setScale(newScale : Float) : Void{
		x *= newScale / scaleX;
		y *= newScale / scaleY;
		newScale = Math.max(1 / 6, Math.min(newScale, 6.0));
		scaleX = scaleY = newScale;
		updateSize();
	}

	/* Comment Support */

	public function addComment(b : Block = null, x : Float = 50, y : Float = 50) : Void{
		var c : ScratchComment = new ScratchComment();
		c.blockRef = b;
		c.x = x;
		c.y = y;
		addChild(c);
		saveScripts();
		updateSize();
		c.startEditText();
	}

	public function fixCommentLayout() : Void{
		var commentLineColor : Int = 0xFFFF80;
		var g : Graphics = commentLines.graphics;
		g.clear();
		g.lineStyle(2, commentLineColor);
		for (i in 0...numChildren) {
			var child : DisplayObject = getChildAt(i);
			if (Std.is(child, ScratchComment))
			{
				var c : ScratchComment = cast(child, ScratchComment);
				if (c.blockRef != null) updateCommentConnection(c, g);
			}
		}
	}

	private function updateCommentConnection(c : ScratchComment, g : Graphics) : Void{
		// Update the position of the given comment based on the position of the
		// block it references and update the line connecting it to that block.
		if (c.blockRef == null)             return;  // update comment position  ;



		var blockP : Point = globalToLocal(c.blockRef.localToGlobal(new Point(0, 0)));
		var top : Block = c.blockRef.topBlock();
		var topP : Point = globalToLocal(top.localToGlobal(new Point(0, 0)));
		c.x = (c.isExpanded()) ? 
				topP.x + top.width + 15 : 
				blockP.x + c.blockRef.base.width + 10;
		c.y = blockP.y + (c.blockRef.base.substack1y() - 20) / 2;
		if (c.blockRef.isHat)             c.y = blockP.y + c.blockRef.base.substack1y() - 25;  // draw connecting line  ;



		var lineY : Int = Std.int(c.y + 10);
		g.moveTo(blockP.x + c.blockRef.base.width, lineY);
		g.lineTo(c.x, lineY);
	}

	/* Stack cleanup */

	private function cleanUp() : Void{
		// Clean up the layout of stacks and blocks in the scripts pane.
		// Steps:
		//	1. Collect stacks and sort by x
		//	2. Assign stacks to columns such that the y-ranges of all stacks in a column do not overlap
		//	3. Compute the column widths
		//	4. Move stacks into place

		var stacks : Array<Block> = stacksSortedByX();
		var columns : Array<Array<Block>> = assignStacksToColumns(stacks);
		var columnWidths : Array<Int> = computeColumnWidths(columns);

		var nextX : Int = padding;
		for (i in 0...columns.length){
			var col : Array<Dynamic> = columns[i];
			var nextY : Int = padding;
			for (b in col){
				b.x = nextX;
				b.y = nextY;
				nextY += b.height + padding;
			}
			nextX += columnWidths[i] + padding;
		}
		saveScripts();
	}

	private function stacksSortedByX() : Array<Block>{
		// Get all stacks and sorted by x.
		var stacks : Array<Block> = [];
		for (i in 0...numChildren){
			var o : Dynamic = getChildAt(i);
			if (Std.is(o, Block))                 stacks.push(o);
		}
		stacks.sort(function(b1 : Block, b2 : Block) : Int{return Std.int(b1.x - b2.x);
				});  // sort by increasing x  
		return stacks;
	}

	private function assignStacksToColumns(stacks : Array<Block>) : Array<Array<Block>>{
		// Assign stacks to columns. Assume stacks is sorted by increasing x.
		// A stack is placed in the first column where it does not overlap vertically with
		// another stack in that column. New columns are created as needed.
		var columns : Array<Array<Block>> = [];
		for (b in stacks){
			var assigned : Bool = false;
			for (c in columns){
				if (fitsInColumn(b, c)) {
					assigned = true;
					c.push(b);
					break;
				}
			}
			if (!assigned)                 columns.push([b]);  // create a new column for this stack  ;
		}
		return columns;
	}

	private function fitsInColumn(b : Block, c : Array<Dynamic>) : Bool{
		var bTop : Int = Std.int(b.y);
		var bBottom : Int = Std.int(bTop + b.height);
		for (other in c){
			if (!((other.y > bBottom) || ((other.y + other.height) < bTop)))                 return false;
		}
		return true;
	}

	private function computeColumnWidths(columns : Array<Array<Block>>) : Array<Int>{
		var widths : Array<Int> = [];
		for (c in columns){
			c.sort(function(b1 : Block, b2 : Block) : Int{return Std.int(b1.y - b2.y);
					});  // sort by increasing y  
			var w : Int = 0;
			for (b/* AS3HX WARNING could not determine type for var: b exp: EIdent(c) type: Dynamic */ in c)w = Std.int(Math.max(w, b.width));
			widths.push(w);
		}
		return widths;
	}
}

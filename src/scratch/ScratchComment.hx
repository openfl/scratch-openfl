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

package scratch;


import openfl.display.*;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.text.*;
import blocks.Block;
import translation.*;
import uiwidgets.*;

class ScratchComment extends Sprite
{

	public var blockID : Int;
	public var blockRef : Block;

	private var contentsFormat : TextFormat = new TextFormat(CSS.font, 12, CSS.textColor, false);
	private var titleFormat : TextFormat = new TextFormat(CSS.font, 12, CSS.textColor, true);
	private static inline var arrowColor : Int = 0x808080;
	private static inline var bodyColor : Int = 0xFFFFD2;
	private static inline var titleBarColor : Int = 0xFFFFA5;

	private var frame : ResizeableFrame;
	private var titleBar : Shape;
	private var expandButton : IconButton;
	private var title : TextField;
	private var contents : TextField;
	private var clipMask : Shape;
	private var isOpen : Bool;
	private var expandedSize : Point;

	public function new(s : String = null, isOpen : Bool = true, width : Int = 150, blockID : Int = -1)
	{
		super();
		this.isOpen = isOpen;
		this.blockID = blockID;
		addFrame();
		addChild(titleBar = new Shape());
		addChild(clipMask = new Shape());
		addExpandButton();
		addTitle();
		addContents();
		contents.text = s != null ? s : Translator.map("add comment here...");
		contents.mask = clipMask;
		frame.setWidthHeight(width, 200);
		expandedSize = new Point(width, 200);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		fixLayout();
		setExpanded(isOpen);
	}

	public function objToGrab(evt : MouseEvent) : Dynamic{return this;
	}

	public function fixLayout() : Void{
		contents.x = 5;
		contents.y = 20;
		var w : Int = Std.int(frame.w - contents.x - 6);
		var h : Int = Std.int(frame.h - contents.y - 2);
		contents.width = w;
		contents.height = h;

		var g : Graphics = clipMask.graphics;
		g.clear();
		g.beginFill(0xFFFF00);
		g.drawRect(contents.x, contents.y, w, h);

		drawTitleBar();
	}

	public function startEditText() : Void{
		contents.setSelection(0, contents.text.length);
		stage.focus = contents;
	}

	private function drawTitleBar() : Void{
		// Draw darker yellow title area used when comment expanded.
		var g : Graphics = titleBar.graphics;
		g.clear();
		g.lineStyle();
		g.beginFill(titleBarColor);
		g.drawRoundRect(1, 1, frame.w - 1, 21, 11, 11);
		g.beginFill(bodyColor);
		g.drawRect(1, 18, frame.w - 1, 4);
	}

	public function toArray() : Array<Dynamic>{
		return [x, y, (isOpen) ? frame.width : expandedSize.x, (isOpen) ? frame.height : expandedSize.y, isOpen, blockID, contents.text];
	}

	public static function fromArray(a : Array<Dynamic>) : ScratchComment{
		var c : ScratchComment = new ScratchComment();
		c.x = a[0];
		c.y = a[1];
		c.blockID = a[5];
		c.contents.text = a[6];
		if (a[4]) {
			c.expandedSize = new Point(a[2], a[3]);
		}
		else {
			c.frame.setWidthHeight(a[2], a[3] == (19) ? 200 : a[3]);
		}
		c.setExpanded(a[4]);
		return c;
	}

	public function updateBlockID(blockList : Array<Dynamic>) : Void{
		if (blockRef != null) {
			blockID = Lambda.indexOf(blockList, blockRef);
		}
	}

	public function updateBlockRef(blockList : Array<Dynamic>) : Void{
		if ((blockID >= 0) && (blockID < blockList.length)) {
			blockRef = blockList[blockID];
		}
	}

	/* Expand/Contract */

	public function isExpanded() : Bool{return isOpen;
	}

	public function setExpanded(flag : Bool) : Void{
		isOpen = flag;
		contents.visible = isOpen;
		titleBar.visible = isOpen;
		title.visible = !isOpen;
		expandButton.setOn(isOpen);
		if (flag) {
			frame.showResizer();
			frame.setColor(bodyColor);
			frame.setWidthHeight(Std.int(expandedSize.x), Std.int(expandedSize.y));
			if (parent != null)                 parent.addChild(this);  // go to front  ;
			fixLayout();
		}
		else {
			if (stage != null && stage.focus == contents)                 stage.focus = null;  // give up focus  ;
			expandedSize = new Point(frame.w, frame.h);
			updateTitleText();
			frame.hideResizer();
			frame.setWidthHeight(frame.w, 19);
			frame.setColor(titleBarColor);
		}
		var scriptsPane : ScriptsPane = try cast(parent, ScriptsPane) catch(e:Dynamic) null;
		if (scriptsPane != null)             scriptsPane.fixCommentLayout();
	}

	private function updateTitleText() : Void{
		var ellipses : String = "...";
		var maxW : Int = Std.int(frame.w - title.x - 5);
		var s : String = contents.text;
		var i : Int = s.indexOf("\r");
		if (i > -1)             s = s.substring(0, i);
		i = s.indexOf("\n");
		if (i > -1)             s = s.substring(0, i);  // the entire first line fits or out of space    // Keep adding letters to the title until either  ;





		i = 1;
		while (i < s.length){
			title.text = s.substring(0, i) + ellipses;
			if (title.textWidth > maxW) {
				title.text = s.substring(0, i - 1) + ellipses;
				return;
			}
			i++;
		}
		title.text = s;
	}

	/* Menu/Tool Operations */

	public function menu(evt : MouseEvent) : Menu{
		var m : Menu = new Menu();
		var startX : Float = stage.mouseX;
		var startY : Float = stage.mouseY;
		m.addItem("duplicate", function() : Void{
					duplicateComment(stage.mouseX - startX, stage.mouseY - startY);
				});
		m.addItem("delete", deleteComment);
		return m;
	}

	public function handleTool(tool : String, evt : MouseEvent) : Void{
		if (tool == "copy")             duplicateComment(10, 5);
		if (tool == "cut")             deleteComment();
	}

	public function deleteComment() : Void{
		if (parent != null)             parent.removeChild(this);
		Scratch.app.runtime.recordForUndelete(this, Std.int(x), Std.int(y), 0, Scratch.app.viewedObj());
		Scratch.app.scriptsPane.saveScripts();
	}

	public function duplicateComment(deltaX : Float, deltaY : Float) : Void{
		if (parent == null)             return;
		var dup : ScratchComment = new ScratchComment(contents.text, isOpen);
		dup.x = x + deltaX;
		dup.y = y + deltaY;
		parent.addChild(dup);
		Scratch.app.gh.grabOnMouseUp(dup);
	}

	private function mouseDown(evt : MouseEvent) : Void{
		// When open, clicks below the title bar set keyboard focus.
		if (isOpen && (evt.localY > 20)) {
			var end : Int = contents.text.length;
			contents.setSelection(end, end);
			stage.focus = contents;
		}
	}

	/* Construction */

	private function addFrame() : Void{
		frame = new ResizeableFrame(CSS.borderColor, bodyColor, 11, false, 1);
		frame.minWidth = 100;
		frame.minHeight = 34;
		frame.showResizer();
		addChild(frame);
	}

	private function addTitle() : Void{
		title = new TextField();
		title.autoSize = TextFieldAutoSize.LEFT;
		title.selectable = false;
		title.defaultTextFormat = titleFormat;
		title.visible = false;
		title.x = 14;
		title.y = 1;
		addChild(title);
	}

	private function addContents() : Void{
		contents = new TextField();
		contents.type = TextFieldType.INPUT;
		contents.wordWrap = true;
		contents.multiline = true;
		contents.autoSize = TextFieldAutoSize.LEFT;
		contents.defaultTextFormat = contentsFormat;
		addChild(contents);
	}

	private function addExpandButton() : Void{
		function toggleExpand(b : IconButton) : Void{setExpanded(!isOpen);
		};
		expandButton = new IconButton(toggleExpand, expandIcon(true), expandIcon(false));
		expandButton.setOn(true);
		expandButton.disableMouseover();
		expandButton.x = 4;
		expandButton.y = 4;
		addChild(expandButton);
	}

	private function expandIcon(pointDown : Bool) : Shape{
		var icon : Shape = new Shape();
		var g : Graphics = icon.graphics;

		g.lineStyle();
		g.beginFill(arrowColor);
		if (pointDown) {
			g.moveTo(0, 2);
			g.lineTo(5.5, 8);
			g.lineTo(11, 2);
		}
		else {
			g.moveTo(2, 0);
			g.lineTo(8, 5.5);
			g.lineTo(2, 11);
		}
		g.endFill();
		return icon;
	}
}

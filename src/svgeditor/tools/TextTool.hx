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

package svgeditor.tools;


import flash.display.Bitmap;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filters.DropShadowFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFieldType;
import flash.utils.Timer;

import svgeditor.*;
import svgeditor.objs.ISVGEditable;
import svgeditor.objs.SVGTextField;

import svgutils.SVGElement;

// TODO: Make it non-sticky when the editor is a BitmapEdit instance
@:final class TextTool extends SVGEditTool {
	private var created : Bool;
	public function new(ed : ImageEdit)
	{
		super(ed, "text");
		//cursorBMName = 'textOff';
		//cursorHotSpot = new Point(12,18);
		cursorName = "ibeam";
	}
	
	override private function init() : Void{
		super.init();
		if (object != null) 			STAGE.focus = try cast(object, SVGTextField) catch(e:Dynamic) null;
		editor.getContentLayer().removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		editor.getWorkArea().addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
		created = false;
	}
	
	override private function shutdown() : Void{
		endEdit();
		editor.getWorkArea().removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		super.shutdown();
	}
	
	private function handleEvents(e : Event) : Void{
		if (Std.is(e, KeyboardEvent)) {
			var kbe : KeyboardEvent = (try cast(e, KeyboardEvent) catch(e:Dynamic) null);
			if (kbe.keyCode == 27) {  //  || kbe.keyCode == 13  
				STAGE.focus = null;
				editor.endCurrentTool(object);
				e.stopImmediatePropagation();
			}
		}
		else if (Std.is(e, Event)) {
			saveState();
			drawDashedBorder();
		}
	}
	
	override private function edit(obj : ISVGEditable, e : MouseEvent) : Void{
		super.edit(obj, e);
		graphics.clear();
		if (object == null) 			return;
		
		var tf : SVGTextField = try cast(object, SVGTextField) catch(e:Dynamic) null;
		if (tf.type != TextFieldType.INPUT) {
			tf.type = TextFieldType.INPUT;
			tf.selectable = true;
			tf.autoSize = TextFieldAutoSize.LEFT;
		}
		else {
			// This was the only way I could find to put the text-cursor where the mouse clicked
			var focusTimer : Timer = new Timer(1);
			focusTimer.addEventListener(TimerEvent.TIMER, function(e : Event) : Void{
						focusTimer.removeEventListener(TimerEvent.TIMER, arguments.callee);
						focusTimer.stop();
						tf.autoSize = TextFieldAutoSize.LEFT;
						tf.selectable = true;
					}, false, 0, true);
			focusTimer.start();
		}
		tf.addEventListener(KeyboardEvent.KEY_DOWN, handleEvents, false, 0, true);
		tf.addEventListener(Event.CHANGE, handleEvents, false, 0, true);
		if (STAGE.focus != tf) 			STAGE.focus = tf;
		if (tf.text == " ") 			tf.text = "";
		if (Std.is(editor, SVGEdit)) 			tf.filters = [new DropShadowFilter(4, 45, 0, 0.3)];
		
		var s : Sprite = new Sprite();
		s.transform.matrix = (try cast(object, DisplayObject) catch(e:Dynamic) null).transform.concatenatedMatrix.clone();
		rotation = s.rotation;
		drawDashedBorder();
	}
	
	override public function refresh() : Void{
		if (object != null) {
			drawDashedBorder();
		}
	}
	
	private function drawDashedBorder() : Void{
		graphics.clear();
		DashDrawer.drawBox(graphics, (try cast(object, SVGTextField) catch(e:Dynamic) null).getBounds(this), dashLength, dashColor);
	}
	
	private function endEdit() : Void{
		graphics.clear();
		if (object == null) 			return;
		
		var tf : SVGTextField = try cast(object, SVGTextField) catch(e:Dynamic) null;
		tf.type = TextFieldType.DYNAMIC;
		tf.autoSize = TextFieldAutoSize.NONE;
		tf.selectable = false;
		tf.background = false;
		tf.removeEventListener(KeyboardEvent.KEY_DOWN, handleEvents);
		tf.removeEventListener(Event.CHANGE, handleEvents);
		saveState();
		// TODO: Fix redraw, it's currently moving the text field (due to the matrix?)
		//tf.redraw();
		if (Std.is(editor, SVGEdit)) 			tf.filters = [];
		
		if (tf.text == "" || tf.text == " ") {  // || tf.text.match(new RegExp('/^\s+$/'))) {  
			tf.parent.removeChild(tf);
		}
		
		setObject(null);
	}
	
	private static inline var dashLength : UInt = 3;
	private static inline var dashColor : UInt = 0xCCCCCC;
	private function saveState() : Void{
		if (object == null) 			return;
		
		var tf : SVGTextField = try cast(object, SVGTextField) catch(e:Dynamic) null;
		object.getElement().text = (try cast(object, SVGTextField) catch(e:Dynamic) null).text;
		dispatchEvent(new Event(Event.CHANGE));
	}
	
	override public function mouseDown(e : MouseEvent) : Void{
		var wasEditing : Bool = !!object;
		var obj : ISVGEditable = getEditableUnderMouse(false);
		var origObj : ISVGEditable = object;
		if (obj != object) {
			// If no object was found but the mouse clicked within the current textfield
			// then don't do anything
			if (obj == null && object != null) {
				var dObj : DisplayObject = try cast(object, DisplayObject) catch(e:Dynamic) null;
				if (dObj.getBounds(dObj).contains(dObj.mouseX, dObj.mouseY)) 
					return;
			}
			endEdit();
			
			if (Std.is(obj, SVGTextField)) {
				edit(obj, null);
			}
			else 
			setObject(null);
		}
		
		if (object == null) {
			if (wasEditing && (try cast(origObj, SVGTextField) catch(e:Dynamic) null).text.length && (try cast(origObj, SVGTextField) catch(e:Dynamic) null).text != " ") {
				editor.endCurrentTool((created) ? origObj : null);
				e.stopPropagation();
			}
			else {
				var contentLayer : Sprite = editor.getContentLayer();
				
				var el : SVGElement = new SVGElement("text", "");
				el.setAttribute("text-anchor", "start");
				el.text = "";
				el.setShapeFill(editor.getShapeProps());
				el.setFont(editor.getShapeProps().fontName, 22);
				
				var tf : SVGTextField = new SVGTextField(el);
				contentLayer.addChild(tf);
				tf.redraw();
				
				var p : Point = new Point(contentLayer.mouseX, contentLayer.mouseY);
				var ascent : Float = tf.getLineMetrics(0).ascent;
				tf.x = p.x;
				tf.y = p.y - tf.textHeight;
				el.setAttribute("x", tf.x + 2);
				el.setAttribute("y", tf.y + ascent + 2);
				el.transform = tf.transform.matrix.clone();
				saveState();
				
				// Switch to TextEditTool
				edit(tf, null);
				created = true;
			}
		}
	}
}


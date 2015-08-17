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

import svgeditor.tools.SVGTool;

import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Bitmap;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.geom.Point;

import svgeditor.BitmapEdit;
import svgeditor.ImageEdit;
import svgeditor.objs.ISVGEditable;
import svgeditor.objs.SVGBitmap;

import svgutils.SVGElement;

@:final class EyeDropperTool extends SVGTool {
	public function new(svgEditor : ImageEdit)
	{
		super(svgEditor);
		touchesContent = true;
		cursorBMName = "eyedropperOff";
		cursorHotSpot = new Point(14, 20);
	}
	
	override private function init() : Void{
		super.init();
		editor.getWorkArea().addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
	}
	
	override private function shutdown() : Void{
		editor.getWorkArea().removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		mouseUp();
		super.shutdown();
	}
	
	private function mouseDown(event : MouseEvent) : Void{
		currentEvent = event;
		grabColor();
		
		STAGE.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove, false, 0, true);
		STAGE.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
		event.stopPropagation();
	}
	
	private function mouseMove(event : MouseEvent) : Void{
		currentEvent = event;
		grabColor();
	}
	
	private function mouseUp(event : MouseEvent = null) : Void{
		STAGE.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		STAGE.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
	}
	
	private function grabColor() : Void{
		var c : UInt;
		var obj : ISVGEditable;
		if (Std.is(editor, BitmapEdit)) {
			var bmap : Bitmap = editor.getWorkArea().getBitmap();
			var p : Point = editor.getWorkArea().bitmapMousePoint();
			c = bmap.bitmapData.getPixel32(p.x, p.y);
		}
		// only grab the color if it's not transparent
		// TODO: Should we ever handle colors with partial alpha?
		else if ((obj = getEditableUnderMouse(false)) != null) {
			var dObj : DisplayObject = try cast(obj, DisplayObject) catch(e:Dynamic) null;
			var b : BitmapData = new BitmapData(1, 1, true, 0);
			var m : Matrix = new Matrix();
			m.translate(-dObj.mouseX, -dObj.mouseY);
			b.draw(dObj, m);
			c = b.getPixel32(0, 0);
		}
		
		
		
		
		
		if (c & 0xFF000000) {
			editor.setCurrentColor(c & 0xFFFFFF, 1);
		}
	}
}


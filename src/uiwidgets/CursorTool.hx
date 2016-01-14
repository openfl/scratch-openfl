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

package uiwidgets;


import flash.display.*;
import flash.events.*;
import flash.geom.Point;
import flash.system.Capabilities;
import flash.ui.*;
import assets.Resources;
import flash.Vector;

class CursorTool
{

	public static var tool : String;  // null or one of: copy, cut, grow, shrink, help  

	private static var app : Scratch;
	private static var currentCursor : Bitmap;
	private static var offsetX : Int;
	private static var offsetY : Int;
	private static var registeredCursors : Dynamic = { };

	public static function setTool(toolName : String) : Void{
		hideSoftwareCursor();
		tool = toolName;
		app.enableEditorTools(tool == null);
		if (tool == null)             return;
		switch (tool)
		{
			case "copy":
				showSoftwareCursor(Resources.createBmp("copyCursor"));
			case "cut":
				showSoftwareCursor(Resources.createBmp("cutCursor"));
			case "grow":
				showSoftwareCursor(Resources.createBmp("growCursor"));
			case "shrink":
				showSoftwareCursor(Resources.createBmp("shrinkCursor"));
			case "help":
				showSoftwareCursor(Resources.createBmp("helpCursor"));
			case "draw":
				showSoftwareCursor(Resources.createBmp("pencilCursor"));
			default:
				tool = null;
		}
		mouseMove(null);
	}

	private static function hideSoftwareCursor() : Void{
		// Hide the current cursor and revert to using the hardware cursor.
		if (currentCursor != null && currentCursor.parent!= null)             currentCursor.parent.removeChild(currentCursor);
		currentCursor = null;
		//Mouse.cursor = MouseCursor.AUTO;
		Mouse.show();
	}

	private static function showSoftwareCursor(bm : Bitmap, offsetX : Int = 999, offsetY : Int = 999) : Void{
		if (bm != null) {
			if (currentCursor != null && currentCursor.parent!= null)                 currentCursor.parent.removeChild(currentCursor);
			currentCursor = new Bitmap(bm.bitmapData);
			CursorTool.offsetX = ((offsetX <= bm.width)) ? offsetX : Std.int(bm.width / 2);
			CursorTool.offsetY = ((offsetY <= bm.height)) ? offsetY : Std.int(bm.height / 2);
			app.stage.addChild(currentCursor);
			Mouse.hide();
			mouseMove(null);
		}
	}

	public static function init(app : Scratch) : Void{
		CursorTool.app = app;
		app.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		app.stage.addEventListener(Event.MOUSE_LEAVE, mouseLeave);
	}

	private static function mouseMove(ignore : Dynamic) : Void{
		if (currentCursor != null) {
			Mouse.hide();
			currentCursor.x = app.mouseX - offsetX;
			currentCursor.y = app.mouseY - offsetY;
		}
	}

	private static function mouseLeave(ignore : Dynamic) : Void {
		//Mouse.cursor = MouseCursor.AUTO;
		Mouse.show();
	}

	public static function setCustomCursor(name : String, bmp : BitmapData = null, hotSpot : Point = null, reuse : Bool = true) : Void{
		var standardCursors : Array<Dynamic> = ["arrow", "auto", "button", "hand", "ibeam"];

		if (tool != null)             return;  // don't let point editor cursors override top bar tools  ;

		hideSoftwareCursor();
		if (Lambda.indexOf(standardCursors, name) != -1) {
			//Mouse.cursor = name;
			return;
		}

		if (("" == name) && !reuse) {
			// disposable cursors for bitmap pen and eraser (sometimes they are too large for hardware cursor)
			showSoftwareCursor(new Bitmap(bmp), Std.int(hotSpot.x), Std.int(hotSpot.y));
			return;
		}

		var saved : Array<Dynamic> = Reflect.field(registeredCursors, name);
		if (saved != null && reuse) {
			if (useSoftwareCursor())
				showSoftwareCursor(new Bitmap(saved[0]), cast(saved[1].x, Int), cast(saved[1].y, Int));
			//else 
				//Mouse.cursor = name;  // use previously registered hardware cursor  
			return;
		}

		if (bmp != null && hotSpot != null) {
			Reflect.setField(registeredCursors, name, [bmp, hotSpot]);
			if (useSoftwareCursor())
				showSoftwareCursor(new Bitmap(bmp), Std.int(hotSpot.x), Std.int(hotSpot.y));
			//else 
				//registerHardwareCursor(name, bmp, hotSpot);
		}
	}

	private static function useSoftwareCursor() : Bool {
		return true;
	}
	private static function isLinux() : Bool{
		var os : String = Capabilities.os;
		if (os.indexOf("Mac OS") > -1)             return false;
		if (os.indexOf("Win") > -1)             return false;
		return true;
	}

	//private static function registerHardwareCursor(name : String, bmp : BitmapData, hotSpot : Point) : Void{
		//var images : Array<BitmapData> = new Array<BitmapData>();
		//images[0] = bmp;
//
		//var cursorData : MouseCursorData = new MouseCursorData();
		//cursorData.data = Vector.ofArray(images);
		//cursorData.hotSpot = hotSpot;
		//Mouse.registerCursor(name, cursorData);
	//}

	public function new()
	{
	}
}

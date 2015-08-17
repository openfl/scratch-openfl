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


import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Point;

import svgeditor.ImageEdit;
import svgeditor.objs.*;
import svgutils.SVGPath;

class SVGTool extends Sprite {
	private static var STAGE : Stage;
	public static function setStage(s : Stage) : Void{STAGE = s;
	}
	
	private var editor : ImageEdit;
	private var isShuttingDown : Bool;
	private var currentEvent : MouseEvent;
	private var cursorBMName : String;
	private var cursorName : String;
	private var cursorHotSpot : Point;
	private var touchesContent : Bool;
	
	public function new(ed : ImageEdit)
	{
		super();
		editor = ed;
		isShuttingDown = false;
		touchesContent = false;
		
		addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		addEventListener(Event.REMOVED, removedFromStage);
	}
	
	public function refresh() : Void{
	}
	
	private function init() : Void{
		if (cursorBMName != null && cursorHotSpot != null) 
			editor.setCurrentCursor(cursorBMName, cursorBMName, cursorHotSpot)
		else if (cursorName != null) 
			editor.setCurrentCursor(cursorName);
	}
	
	private function shutdown() : Void{
		editor.setCurrentCursor(null);
		editor = null;
	}
	
	@:final public function interactsWithContent() : Bool{
		return touchesContent;
	}
	
	public function cancel() : Void{
		if (parent) 			parent.removeChild(this);
	}
	
	private function addedToStage(e : Event) : Void{
		removeEventListener(Event.ADDED_TO_STAGE, addedToStage);
		init();
	}
	
	private function removedFromStage(e : Event) : Void{
		if (e.target != this) 			return;
		
		removeEventListener(Event.REMOVED, removedFromStage);
		isShuttingDown = true;
		shutdown();
	}
	
	private function getEditableUnderMouse(includeGroups : Bool = true) : ISVGEditable{
		return staticGetEditableUnderMouse(editor, includeGroups, this);
	}
	
	public static function staticGetEditableUnderMouse(editor : ImageEdit, includeGroups : Bool = true, currentTool : SVGTool = null) : ISVGEditable{
		var objs : Array<Dynamic> = STAGE.getObjectsUnderPoint(new Point(STAGE.mouseX, STAGE.mouseY));
		
		// Select the top object that is ISVGEditable
		if (objs.length) {
			// Try to find the topmost element whose parent is the selection context
			var i : Int = objs.length - 1;
			while (i >= 0){
				var rawObj : DisplayObject = objs[i];
				var obj : DisplayObject = getChildOfSelectionContext(rawObj, editor);
				
				// If we're not including groups and a group was selected, try to select the object under
				// the mouse if it's parent is the group found.
				if (!includeGroups && Std.is(obj, SVGGroup) && Std.is(rawObj.parent, SVGGroup) && Std.is(rawObj, ISVGEditable)) 
					obj = rawObj;
				
				var isPaintBucket : Bool = (Std.is(currentTool, PaintBucketTool) || Std.is(currentTool, PaintBrushTool));
				var isOT : Bool = (Std.is(currentTool, ObjectTransformer));
				if (Std.is(obj, ISVGEditable) && (includeGroups || !(Std.is(obj, SVGGroup))) && (isPaintBucket || !(try cast(obj, ISVGEditable) catch(e:Dynamic) null).getElement().isBackDropBG())) {
					return (try cast(obj, ISVGEditable) catch(e:Dynamic) null);
				}
				--i;
			}
		}
		
		return null;
	}
	
	private static function getChildOfSelectionContext(obj : DisplayObject, editor : ImageEdit) : DisplayObject{
		var contentLayer : Sprite = editor.getContentLayer();
		while (obj && obj.parent != contentLayer)obj = obj.parent;
		return obj;
	}
	
	// Used by the PathEditTool and PathTool
	private function getContinuableShapeUnderMouse(strokeWidth : Float) : Dynamic{
		// Hide the current path so we don't get that
		var obj : ISVGEditable = getEditableUnderMouse(false);
		
		if (Std.is(obj, SVGShape)) {
			var s : SVGShape = try cast(obj, SVGShape) catch(e:Dynamic) null;
			var path : SVGPath = s.getElement().path;
			var segment : Array<Dynamic> = path.getSegmentEndPoints(0);
			var isClosed : Bool = segment[2];
			var otherWidth : Float = s.getElement().getAttribute("stroke-width", 1);
			var w : Float = (strokeWidth + otherWidth) / 2;
			if (!isClosed) {
				var m : Point = new Point(s.mouseX, s.mouseY);
				var p : Point = null;
				if (path.getPos(segment[0]).subtract(m).length < w) {
					return {
						index : segment[0],
						bEnd : false,
						shape : (try cast(obj, SVGShape) catch(e:Dynamic) null),

					};
				}
				else if (path.getPos(segment[1]).subtract(m).length < w) {
					return {
						index : segment[1],
						bEnd : true,
						shape : (try cast(obj, SVGShape) catch(e:Dynamic) null),

					};
				}
			}
		}
		
		return null;
	}
}

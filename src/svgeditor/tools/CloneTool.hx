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

import svgeditor.tools.ImageEdit;
import svgeditor.tools.SVGCreateTool;
import svgeditor.tools.Selection;

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.filters.GlowFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import svgeditor.*;
import svgeditor.objs.ISVGEditable;
import svgeditor.objs.SVGShape;

import svgutils.SVGElement;

@:final class CloneTool extends SVGCreateTool {
	private var copiedObjects : Array<Dynamic>;
	private var previewObjects : Array<Dynamic>;
	private var centerPt : Point;
	private var holder : Sprite;
	
	public function new(svgEditor : ImageEdit, s : Selection = null)
	{
		super(svgEditor, false);
		holder = new Sprite();
		addChild(holder);
		cursorBMName = "cloneOff";
		cursorHotSpot = new Point(12, 21);
		copiedObjects = null;
		previewObjects = null;
	}
	
	public function pasteFromClipboard(objs : Array<Dynamic>) : Void{
		for (dObj in objs){
			contentLayer.addChild(dObj);
		}
		var s : Selection = new Selection(objs);
		previewObjects = s.cloneObjs(contentLayer);
		copiedObjects = s.cloneObjs(contentLayer);
		s.shutdown();
		for (dObj in objs){
			contentLayer.removeChild(dObj);
		}
		createPreview();
	}
	
	private function makeCopies(s : Selection) : Void{
		copiedObjects = s.cloneObjs(contentLayer);
		previewObjects = s.cloneObjs(contentLayer);
	}
	
	override private function init() : Void{
		super.init();
		editor.getToolsLayer().mouseEnabled = false;
		editor.getToolsLayer().mouseChildren = false;
	}
	
	override private function shutdown() : Void{
		editor.getToolsLayer().mouseEnabled = true;
		editor.getToolsLayer().mouseChildren = true;
		super.shutdown();
		clearCurrentClone();
	}
	
	private function clearCurrentClone() : Void{
		while (holder.numChildren)holder.removeChildAt(0);
		copiedObjects = null;
		previewObjects = null;
	}
	
	override private function mouseMove(p : Point) : Void{
		if (copiedObjects != null) 			centerPreview()
		else checkUnderMouse();
	}
	
	override private function mouseDown(p : Point) : Void{
		if (copiedObjects == null) {
			var obj : ISVGEditable = getEditableUnderMouse();
			if (obj != null) {
				makeCopies(new Selection([obj]));
				createPreview();
				checkUnderMouse(true);
			}
			return;
		}
	}
	
	override private function mouseUp(p : Point) : Void{
		if (copiedObjects == null) 			return;
		
		for (i in 0...copiedObjects.length){
			var pObj : DisplayObject = try cast(previewObjects[i], DisplayObject) catch(e:Dynamic) null;
			var pt : Point = new Point(pObj.x, pObj.y);
			pt = holder.localToGlobal(pt);
			pt = contentLayer.globalToLocal(pt);
			
			var dObj : DisplayObject = try cast(copiedObjects[i], DisplayObject) catch(e:Dynamic) null;
			contentLayer.addChild(dObj);
			dObj.x = pt.x;
			dObj.y = pt.y;
		}
		
		var s : Selection = new Selection(copiedObjects);
		if (currentEvent.shiftKey) {
			// Get another copy
			copiedObjects = s.cloneObjs(contentLayer);
			s.shutdown();
		}
		else {
			// Select the copied objects
			editor.endCurrentTool(s);
		}
		
		dispatchEvent(new Event(Event.CHANGE));
	}
	
	private function createPreview() : Void{
		x = y = 0;
		
		// Match the current content scale factor
		var m : Matrix = editor.getContentLayer().transform.concatenatedMatrix;
		holder.scaleX = m.deltaTransformPoint(new Point(0, 1)).length;
		holder.scaleY = m.deltaTransformPoint(new Point(1, 0)).length;
		
		//
		for (i in 0...copiedObjects.length){
			var dObj : DisplayObject = try cast(previewObjects[i], DisplayObject) catch(e:Dynamic) null;
			holder.addChild(dObj);
		}
		
		var rect : Rectangle = getBounds(this);
		centerPt = new Point((rect.right + rect.left) / 2, (rect.bottom + rect.top) / 2);
		centerPreview();
		alpha = 0.5;
	}
	
	private function centerPreview() : Void{
		x += mouseX - centerPt.x;
		y += mouseY - centerPt.y;
	}
	
	private var highlightedObj : DisplayObject;
	private function checkUnderMouse(clear : Bool = false) : Void{
		var obj : ISVGEditable = (clear) ? null : getEditableUnderMouse();
		
		if (obj != highlightedObj) {
			if (highlightedObj != null) 				highlightedObj.filters = [];
			highlightedObj = try cast(obj, DisplayObject) catch(e:Dynamic) null;
			if (highlightedObj != null) 				highlightedObj.filters = [new GlowFilter(0x28A5DA)];
		}
	}
}


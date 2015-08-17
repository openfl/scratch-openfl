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

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.GlowFilter;
import flash.geom.Point;

import svgeditor.ImageEdit;
import svgeditor.Selection;
import svgeditor.objs.ISVGEditable;

class SVGEditTool extends SVGTool {
	private var object : ISVGEditable;
	private var editTag : Array<Dynamic>;
	
	public function new(ed : ImageEdit, tag : Dynamic = null)
	{
		super(ed);
		touchesContent = true;
		object = null;
		editTag = ((Std.is(tag, String))) ? [tag] : tag;
	}
	
	public function editSelection(s : Selection) : Void{
		if (s != null && s.getObjs().length == 1) 
			setObject(try cast(s.getObjs()[0], ISVGEditable) catch(e:Dynamic) null);
	}
	
	public function setObject(obj : ISVGEditable) : Void{
		edit(obj, null);
	}
	
	public function getObject() : ISVGEditable{
		return object;
	}
	
	// When overriding this method, usually an event handler will be added with a higher priority
	// so that the mouseDown method below is overridden
	private function edit(obj : ISVGEditable, event : MouseEvent) : Void{
		if (obj == object) 			return;
		
		if (object != null) {
			//(object as DisplayObject).filters = [];
			
		}
		
		if (obj != null && (editTag == null || Lambda.indexOf(editTag, obj.getElement().tag) > -1)) {
			object = obj;
			
			if (object != null) {
				//(object as DisplayObject).filters = [new GlowFilter(0x28A5DA)];
				
			}
		}
		else {
			object = null;
		}
		dispatchEvent(new Event("select"));
	}
	
	override private function init() : Void{
		super.init();
		editor.getContentLayer().addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
	}
	
	override private function shutdown() : Void{
		editor.getContentLayer().removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		super.shutdown();
		
		if (object != null) {
			setObject(null);
		}
	}
	
	public function mouseDown(event : MouseEvent) : Void{
		var obj : ISVGEditable = getEditableUnderMouse(!(Std.is(this, PathEditTool)));
		currentEvent = event;
		edit(obj, event);
		currentEvent = null;
		
		event.stopPropagation();
	}
}


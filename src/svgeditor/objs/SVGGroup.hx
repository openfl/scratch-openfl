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

package svgeditor.objs;


import flash.display.DisplayObject;
import flash.display.Sprite;

import svgeditor.objs.ISVGEditable;

import svgutils.SVGElement;

class SVGGroup extends Sprite implements ISVGEditable {
	private var element : SVGElement;
	
	public function new(elem : SVGElement)
	{
		super();
		element = elem;
	}
	
	public function getElement() : SVGElement{
		element.subElements = getSubElements();
		element.transform = transform.matrix;
		return element;
	}
	
	public function redraw(forHitTest : Bool = false) : Void{
		if (element.transform) 			transform.matrix = element.transform  // Redraw the sub elements  ;
		
		
		
		for (i in 0...numChildren){
			var child : DisplayObject = getChildAt(i);
			if (Std.is(child, ISVGEditable)) {
				(try cast(child, ISVGEditable) catch(e:Dynamic) null).redraw();
			}
		}
	}
	
	private function getSubElements() : Array<Dynamic>{
		var elements : Array<Dynamic> = [];
		for (i in 0...numChildren){
			var child : DisplayObject = getChildAt(i);
			if (Std.is(child, ISVGEditable)) {
				elements.push((try cast(child, ISVGEditable) catch(e:Dynamic) null).getElement());
			}
		}
		return elements;
	}
	
	public function clone() : ISVGEditable{
		var copy : SVGGroup = new SVGGroup(element.clone());
		(try cast(copy, DisplayObject) catch(e:Dynamic) null).transform.matrix = transform.matrix.clone();
		
		var elements : Array<Dynamic> = [];
		for (i in 0...numChildren){
			var child : DisplayObject = getChildAt(i);
			if (Std.is(child, ISVGEditable)) {
				copy.addChild(try cast((try cast(child, ISVGEditable) catch(e:Dynamic) null).clone(), DisplayObject) catch(e:Dynamic) null);
			}
		}
		
		copy.redraw();
		return copy;
	}
}


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

// ScrollFrameContents.as
// John Maloney, November 2010
//
// A ScrollFrameContents is a resizable container used as the contents of a ScrollFrame.
// It updates its size to include all of its children, ensures that children do not have
// negative positions (which are outside the scroll range), and can have a color or an
// optional background texture. Set hExtra or vExtra to provide some additional empty
// space to the right or bottom of the content.
//
// Note: The client should call updateSize() after adding or removing contents.

package uiwidgets;

import uiwidgets.BitmapData;
import uiwidgets.DisplayObject;

import flash.display.*;

class ScrollFrameContents extends Sprite {
	
	public var color : Int = 0xE0E0E0;
	public var texture : BitmapData;
	
	// extra padding using in updateSize
	public var hExtra : Int = 10;
	public var vExtra : Int = 10;
	
	public function clear(scrollToOrigin : Bool = true) : Void{
		while (numChildren > 0)removeChildAt(0);
		if (scrollToOrigin) 			x = y = 0;
	}
	
	public function setWidthHeight(w : Int, h : Int) : Void{
		// Draw myself using the texture bitmap, if available, or a solid gray color if not.
		graphics.clear();
		if (texture != null) 			graphics.beginBitmapFill(texture)
		else graphics.beginFill(color);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
	}
	
	public function updateSize() : Void{
		// Make my size a little bigger necessary to subsume all my children.
		// Also ensure that the x and y positions of all children are positive.
		var minX : Int = 5;
		var maxX : Int;
		var minY : Int = 5;
		var maxY : Int;
		var child : DisplayObject;
		var i : Int;
		for (i in 0...numChildren){
			child = getChildAt(i);
			minX = Math.min(minX, child.x);
			minY = Math.min(minY, child.y);
			maxX = Math.max(maxX, child.x + child.width);
			maxY = Math.max(maxY, child.y + child.height);
		}  // Move children, if necessary, to ensure that all positions are positive.  
		
		if ((minX < 0) || (minY < 0)) {
			var deltaX : Int = Math.max(0, -minX + 5);
			var deltaY : Int = Math.max(0, -minY + 5);
			for (i in 0...numChildren){
				child = getChildAt(i);
				child.x += deltaX;
				child.y += deltaY;
			}
			maxX += deltaX;
			maxY += deltaY;
		}
		maxX += hExtra;
		maxY += vExtra;
		if (Std.is(parent, ScrollFrame)) {
			maxX = Math.max(maxX, ((cast((parent), ScrollFrame).visibleW() - x) / scaleX));
			maxY = Math.max(maxY, ((cast((parent), ScrollFrame).visibleH() - y) / scaleY));
		}
		setWidthHeight(maxX, maxY);
		if (Std.is(parent, ScrollFrame)) 			(try cast(parent, ScrollFrame) catch(e:Dynamic) null).updateScrollbarVisibility();
	}

	public function new()
	{
		super();
	}
}

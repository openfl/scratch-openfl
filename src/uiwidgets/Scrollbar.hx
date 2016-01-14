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


import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.events.Event;
//import flash.filters.BevelFilter;
import flash.geom.Point;
import util.DragClient;

class Scrollbar extends Sprite implements DragClient
{

	public static var color : Int = 0xCBCDCF;
	public static var sliderColor : Int = 0x424447;
	public static var cornerRadius : Int = 9;
	public static var look3D : Bool = false;

	public var w : Int;public var h : Int;

	private var base : Shape;
	private var slider : Shape;
	private var positionFraction : Float = 0;  // scroll amount (range: 0-1)  
	private var sliderSizeFraction : Float = 0.1;  // slider size, used to show fraction of docutment vislbe (range: 0-1)  
	private var isVertical : Bool;
	private var dragOffset : Int;
	private var scrollFunction : Dynamic->Void;

	public function new(w : Int, h : Int, scrollFunction : Dynamic -> Void = null)
	{
		super();
		this.scrollFunction = scrollFunction;
		base = new Shape();
		slider = new Shape();
		addChild(base);
		addChild(slider);
		if (look3D)             addFilters();
		alpha = 0.7;
		setWidthHeight(w, h);
		allowDragging(true);
	}

	public function scrollValue() : Float{return positionFraction;
	}
	public function sliderSize() : Float{return sliderSizeFraction;
	}

	public function update(position : Float, sliderSize : Float = 0) : Bool{
		// Update the scrollbar scroll position (0-1) and slider size (0-1)
		var newPosition : Float = Math.max(0, Math.min(position, 1));
		var newSliderSize : Float = Math.max(0, Math.min(sliderSize, 1));
		if ((newPosition != positionFraction) || (newSliderSize != sliderSizeFraction)) {
			positionFraction = newPosition;
			sliderSizeFraction = newSliderSize;
			drawSlider();
			slider.visible = newSliderSize < 0.99;
		}
		return slider.visible;
	}

	public function setWidthHeight(w : Int, h : Int) : Void{
		this.w = w;
		this.h = h;
		base.graphics.clear();
		base.graphics.beginFill(color);
		base.graphics.drawRoundRect(0, 0, w, h, cornerRadius, cornerRadius);
		base.graphics.endFill();
		drawSlider();
	}

	private function drawSlider() : Void{
		var w : Int;
		var h : Int;
		var maxSize : Int;
		isVertical = base.height > base.width;
		if (isVertical) {
			maxSize = Std.int(base.height);
			w = Std.int(base.width);
			h = Std.int(Math.max(10, Math.min(sliderSizeFraction * maxSize, maxSize)));
			slider.x = 0;
			slider.y = positionFraction * (this.height - h);
		}
		else {
			maxSize = Std.int(base.width);
			w = Std.int(Math.max(10, Math.min(sliderSizeFraction * maxSize, maxSize)));
			h = Std.int(base.height);
			slider.x = positionFraction * (this.width - w);
			slider.y = 0;
		}
		slider.graphics.clear();
		slider.graphics.beginFill(sliderColor);
		slider.graphics.drawRoundRect(0, 0, w, h, cornerRadius, cornerRadius);
		slider.graphics.endFill();
	}

	private function addFilters() : Void {
		return [];
		/*
		var f : BevelFilter = new BevelFilter();
		f.distance = 1;
		f.blurX = f.blurY = 2;
		f.highlightAlpha = 0.5;
		f.shadowAlpha = 0.5;
		f.angle = 225;
		base.filters = [f];
		f = new BevelFilter();
		f.distance = 2;
		f.blurX = f.blurY = 4;
		f.highlightAlpha = 1.0;
		f.shadowAlpha = 0.5;
		slider.filters = [f];
		*/
	}

	public function allowDragging(flag : Bool) : Void{
		if (flag)             addEventListener(MouseEvent.MOUSE_DOWN, mouseDown)
		else removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
	}

	private function mouseDown(evt : MouseEvent) : Void{
		Scratch.app.gh.setDragClient(this, evt);
	}

	public function dragBegin(evt : MouseEvent) : Void{
		var sliderOrigin : Point = slider.localToGlobal(new Point(0, 0));
		if (isVertical) {
			dragOffset = Std.int(evt.stageY - sliderOrigin.y);
			dragOffset = Std.int(Math.max(5, Math.min(dragOffset, slider.height - 5)));
		}
		else {
			dragOffset = Std.int(evt.stageX - sliderOrigin.x);
			dragOffset = Std.int(Math.max(5, Math.min(dragOffset, slider.width - 5)));
		}
		dispatchEvent(new Event(Event.SCROLL));
		dragMove(evt);
	}

	public function dragMove(evt : MouseEvent) : Void{
		var range : Int;
		var frac : Float;
		var localP : Point = globalToLocal(new Point(evt.stageX, evt.stageY));
		if (isVertical) {
			range = Std.int(base.height - slider.height);
			positionFraction = (localP.y - dragOffset) / range;
		}
		else {
			range = Std.int(base.width - slider.width);
			positionFraction = (localP.x - dragOffset) / range;
		}
		positionFraction = Math.max(0, Math.min(positionFraction, 1));
		drawSlider();
		if (scrollFunction != null)             scrollFunction(positionFraction);
	}

	public function dragEnd(evt : MouseEvent) : Void{
		dispatchEvent(new Event(Event.COMPLETE));
	}
}

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

// Slider.as
// John Maloney, February 2013
//
// A simple slider for a fractional value from 0-1. Either vertical or horizontal, depending on its aspect ratio.
// The client can supply an optional function to be called when the value is changed.

package uiwidgets;

import uiwidgets.Graphics;

import flash.display.*;
import flash.events.*;
import flash.geom.*;
import util.DragClient;

class Slider extends Sprite implements DragClient {
	public var min(get, set) : Float;
	public var max(get, set) : Float;
	public var value(get, set) : Float;

	
	public var slotColor : Int = 0xBBBDBF;
	public var slotColor2 : Int = -1;  // if >= 0, fill with linear gradient from slotColor to slotColor2  
	
	private var slot : Shape;
	private var knob : Shape;
	private var positionFraction : Float = 0;  // range: 0-1  
	
	private var isVertical : Bool;
	private var dragOffset : Int;
	private var scrollFunction : Function;
	private var minValue : Float;
	private var maxValue : Float;
	
	public function new(w : Int, h : Int, scrollFunction : Function = null)
	{
		super();
		this.scrollFunction = scrollFunction;
		minValue = 0;
		maxValue = 1;
		addChild(slot = new Shape());
		addChild(knob = new Shape());
		setWidthHeight(w, h);
		moveKnob();
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
	}
	
	private function get_Min() : Float{return minValue;
	}
	private function set_Min(n : Float) : Float{minValue = n;
		return n;
	}
	
	private function get_Max() : Float{return maxValue;
	}
	private function set_Max(n : Float) : Float{maxValue = n;
		return n;
	}
	
	private function get_Value() : Float{return positionFraction * (maxValue - minValue) + minValue;
	}
	private function set_Value(n : Float) : Float{
		// Update the slider value (0-1).
		var newFraction : Float = Math.max(0, Math.min((n - minValue) / (maxValue - minValue), 1));
		if (newFraction != positionFraction) {
			positionFraction = newFraction;
			moveKnob();
		}
		return n;
	}
	
	public function setWidthHeight(w : Int, h : Int) : Void{
		isVertical = h > w;
		drawSlot(w, h);
		drawKnob(w, h);
	}
	
	private function drawSlot(w : Int, h : Int) : Void{
		var slotRadius : Int = 9;
		var g : Graphics = slot.graphics;
		g.clear();
		if (slotColor2 >= 0) {
			var m : Matrix = new Matrix();
			m.createGradientBox(w, h, ((isVertical) ? -Math.PI / 2 : Math.PI), 0, 0);
			g.beginGradientFill(GradientType.LINEAR, [slotColor, slotColor2], [1, 1], [0, 255], m);
		}
		else {
			g.beginFill(slotColor);
		}
		g.drawRoundRect(0, 0, w, h, slotRadius, slotRadius);
		g.endFill();
	}
	
	private function drawKnob(w : Int, h : Int) : Void{
		var knobOutline : Int = 0x707070;
		var knobFill : Int = 0xEBEBEB;
		var knobRadius : Int = 6;  // 3;  
		var knobW : Int = (isVertical) ? w + 7 : 7;
		var knobH : Int = (isVertical) ? 7 : h + 7;
		var g : Graphics = knob.graphics;
		g.clear();
		g.lineStyle(1, knobOutline);
		g.beginFill(knobFill);
		g.drawRoundRect(0.5, 0.5, knobW, knobH, knobRadius, knobRadius);
		g.endFill();
	}
	
	private function moveKnob() : Void{
		if (isVertical) {
			knob.x = -4;
			knob.y = Math.round((1 - positionFraction) * (slot.height - knob.height));
		}
		else {
			knob.x = Math.round(positionFraction * (slot.width - knob.width));
			knob.y = -4;
		}
	}
	
	private function mouseDown(evt : MouseEvent) : Void{
		Scratch.app.gh.setDragClient(this, evt);
	}
	
	public function dragBegin(evt : MouseEvent) : Void{
		var sliderOrigin : Point = knob.localToGlobal(new Point(0, 0));
		if (isVertical) {
			dragOffset = evt.stageY - sliderOrigin.y;
			dragOffset = Math.max(5, Math.min(dragOffset, knob.height - 5));
		}
		else {
			dragOffset = evt.stageX - sliderOrigin.x;
			dragOffset = Math.max(5, Math.min(dragOffset, knob.width - 5));
		}
		dragMove(evt);
	}
	
	public function dragMove(evt : MouseEvent) : Void{
		var range : Int;
		var frac : Float;
		var localP : Point = globalToLocal(new Point(evt.stageX, evt.stageY));
		if (isVertical) {
			range = slot.height - knob.height;
			positionFraction = 1 - (localP.y - dragOffset) / range;
		}
		else {
			range = slot.width - knob.width;
			positionFraction = (localP.x - dragOffset) / range;
		}
		positionFraction = Math.max(0, Math.min(positionFraction, 1));
		moveKnob();
		if (scrollFunction != null) 			scrollFunction(this.value);
	}
	
	public function dragEnd(evt : MouseEvent) : Void{
		dispatchEvent(new Event(Event.COMPLETE));
	}
}

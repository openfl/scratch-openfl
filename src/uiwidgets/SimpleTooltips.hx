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

import uiwidgets.Graphics;
import uiwidgets.Stage;
import uiwidgets.TextField;

import flash.display.DisplayObject;
import flash.display.*;
import flash.events.*;
import flash.filters.DropShadowFilter;
import flash.geom.*;
import flash.text.*;
import flash.utils.Dictionary;
import flash.utils.Timer;

import translation.Translator;











class SimpleTooltips {
	private static var instance : SimpleTooltip = null;
	/**
	 * Add a tooltip to a DisplayObject
	 * @param dObj Attach the tooltip to this
	 * @param opts Options (just 'text' and 'direction' right now)
	 *
	 */
	public static function add(dObj : DisplayObject, opts : Dynamic) : Void{
		if (instance == null) 			instance = new SimpleTooltip();
		if (dObj == null) 			return;
		instance.addTooltip(dObj, opts);
	}
	
	public static function hideAll() : Void{
		if (instance != null) 			instance.forceHide();
	}
	
	public static function showOnce(dObj : DisplayObject, opts : Dynamic) : Void{
		if (instance == null) 			instance = new SimpleTooltip();
		instance.showOnce(dObj, opts);
	}

	public function new()
	{
	}
}




class SimpleTooltip {
	// Map of DisplayObject => Strings
	private var tipObjs : Dictionary = new Dictionary();
	private var currentTipObj : DisplayObject;
	private var nextTipObj : DisplayObject;
	
	// Timing values (in milliseconds)
	private inline var delay : UInt = 500;
	private inline var linger : UInt = 1000;
	private inline var fadeIn : UInt = 200;
	private inline var fadeOut : UInt = 500;
	
	private inline var bgColor : UInt = 0xfcfed4;
	
	// Timers
	private var showTimer : Timer;
	private var hideTimer : Timer;
	private var animTimer : Timer;
	
	private var sprite : Sprite;
	private var textField : TextField;
	private var stage : Stage;
	private function new()
	{
		// Setup timers
		showTimer = new Timer(delay);
		showTimer.addEventListener(TimerEvent.TIMER, eventHandler);
		hideTimer = new Timer(linger);
		hideTimer.addEventListener(TimerEvent.TIMER, eventHandler);
		
		// Setup display objects
		sprite = new Sprite();
		sprite.mouseEnabled = false;
		sprite.mouseChildren = false;
		sprite.filters = [new DropShadowFilter(4, 90, 0, 0.6, 12, 12, 0.8)];
		textField = new TextField();
		textField.autoSize = TextFieldAutoSize.LEFT;
		textField.selectable = false;
		textField.background = false;
		textField.defaultTextFormat = CSS.normalTextFormat;
		textField.textColor = CSS.buttonLabelColor;
		sprite.addChild(textField);
	}
	
	private static var instance : Dynamic;
	public function addTooltip(dObj : DisplayObject, opts : Dynamic) : Void{
		if (!opts.exists("text") || !opts.exists("direction") ||
			["top", "bottom", "left", "right"].indexOf(opts.direction) == -1) {
			trace("Invalid parameters!");
			return;
		}
		
		if (Reflect.field(tipObjs, Std.string(dObj)) == null) {
			dObj.addEventListener(MouseEvent.MOUSE_OVER, eventHandler);
		}
		Reflect.setField(tipObjs, Std.string(dObj), opts);
	}
	
	private function eventHandler(evt : Event) : Void{
		var _sw2_ = (evt.type);		

		switch (_sw2_) {
			case MouseEvent.MOUSE_OVER:
				startShowTimer(try cast(evt.currentTarget, DisplayObject) catch(e:Dynamic) null);
			case MouseEvent.MOUSE_OUT:
				(try cast(evt.currentTarget, DisplayObject) catch(e:Dynamic) null).removeEventListener(MouseEvent.MOUSE_OUT, eventHandler);
				
				if (showTimer.running) {
					showTimer.reset();
					nextTipObj = null;
				}
				
				startHideTimer(try cast(evt.currentTarget, DisplayObject) catch(e:Dynamic) null);
			case TimerEvent.TIMER:
				if (evt.target == showTimer) {
					startShow();
				}
				else {
					startHide(try cast(evt.target, Timer) catch(e:Dynamic) null);
					if (evt.target != hideTimer) {
						(try cast(evt.target, Timer) catch(e:Dynamic) null).removeEventListener(TimerEvent.TIMER, eventHandler);
					}
				}
		}
	}
	
	private function startShow() : Void{
		//trace('startShow()');
		showTimer.reset();
		hideTimer.reset();
		sprite.alpha = 0;
		var ttOpts : Dynamic = Reflect.field(tipObjs, Std.string(nextTipObj));
		renderTooltip(ttOpts.text);
		currentTipObj = nextTipObj;
		
		// TODO: Make it fade in
		sprite.alpha = 1;
		stage.addChild(sprite);
		
		var pos : Point = getPos(ttOpts.direction);
		sprite.x = pos.x;
		sprite.y = pos.y;
	}
	
	public function showOnce(dObj : DisplayObject, ttOpts : Dynamic) : Void{
		if (stage == null && dObj.stage) 			stage = dObj.stage  //trace('showOnce()');  ;
		
		forceHide();
		showTimer.reset();
		hideTimer.reset();
		sprite.alpha = 0;
		renderTooltip(ttOpts.text);
		currentTipObj = dObj;
		
		// TODO: Make it fade in
		sprite.alpha = 1;
		stage.addChild(sprite);
		
		var pos : Point = getPos(ttOpts.direction);
		sprite.x = pos.x;
		sprite.y = pos.y;
		
		// Show the tooltip for twice as long
		var myTimer : Timer = new Timer(5000);
		myTimer.addEventListener(TimerEvent.TIMER, eventHandler);
		myTimer.reset();
		myTimer.start();
	}
	
	private function getPos(direction : String) : Point{
		var rect : Rectangle = currentTipObj.getBounds(stage);
		var pos : Point;
		switch (direction) {
			case "right":
				pos = new Point(rect.right + 5, Math.round((rect.top + rect.bottom - sprite.height) / 2));
			case "left":
				pos = new Point(rect.left - 5 - sprite.width, Math.round((rect.top + rect.bottom - sprite.height) / 2));
			case "top":
				pos = new Point(Math.round((rect.left + rect.right - sprite.width) / 2), rect.top - 4 - sprite.height);
			case "bottom":
				pos = new Point(Math.round((rect.left + rect.right - sprite.width) / 2), rect.bottom + 4);
		}
		if (pos.x < 0) 			pos.x = 0;
		if (pos.y < 0) 			pos.y = 0;
		return pos;
	}
	
	public function forceHide() : Void{
		startHide(hideTimer);
	}
	
	private function startHide(timer : Timer) : Void{
		//trace('startHide()');
		hideTimer.reset();
		currentTipObj = null;
		sprite.alpha = 0;
		if (sprite.parent) 			stage.removeChild(sprite);
	}
	
	private function renderTooltip(text : String) : Void{
		//trace('renderTooltip(\''+text+'\')');
		var g : Graphics = sprite.graphics;
		textField.text = Translator.map(text);
		g.clear();
		g.lineStyle(1, 0xCCCCCC);
		g.beginFill(bgColor);
		g.drawRect(0, 0, textField.textWidth + 5, textField.textHeight + 3);
		g.endFill();
	}
	
	private function startShowTimer(dObj : DisplayObject) : Void{
		//trace('startShowTimer()');
		if (stage == null && dObj.stage) 			stage = dObj.stage;
		
		dObj.addEventListener(MouseEvent.MOUSE_OUT, eventHandler);
		
		if (dObj == currentTipObj) {
			hideTimer.reset();
			return;
		}
		
		if (Std.is(Reflect.field(tipObjs, Std.string(dObj)), Dynamic)) {
			nextTipObj = dObj;
			
			showTimer.reset();
			showTimer.start();
		}
	}
	
	private function startHideTimer(dObj : DisplayObject) : Void{
		//trace('startHideTimer()');
		if (dObj != currentTipObj) 			return;
		
		hideTimer.reset();
		hideTimer.start();
	}
}

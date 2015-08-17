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

package util;




class Transition {
	
	private static var activeTransitions : Array<Dynamic> = [];
	
	private var interpolate : Function;
	private var setValue : Function;
	private var startValue : Dynamic;
	private var endValue : Dynamic;
	private var delta : Dynamic;
	private var whenDone : Function;
	private var startMSecs : UInt;
	private var duration : UInt;
	
	public function new(interpolate : Function, setValue : Function, startValue : Dynamic, endValue : Dynamic, secs : Float, whenDone : Function)
	{
		// Create a transition animation between two values (either scalars or Arrays).
		this.interpolate = interpolate;
		this.setValue = setValue;
		this.startValue = startValue;
		this.endValue = endValue;
		this.whenDone = whenDone;
		if (Std.is(startValue, Array)) {
			delta = [];
			for (i in 0...startValue.length){
				this.delta.push(endValue[i] - startValue[i]);
			}
		}
		else {
			delta = endValue - startValue;
		}
		startMSecs = Math.round(haxe.Timer.stamp() * 1000);
		duration = 1000 * secs;
	}
	
	public static function linear(setValue : Function, startValue : Dynamic, endValue : Dynamic, secs : Float, whenDone : Function = null) : Void{
		activeTransitions.push(new Transition(linearFunc, setValue, startValue, endValue, secs, whenDone));
	}
	
	public static function quadratic(setValue : Function, startValue : Dynamic, endValue : Dynamic, secs : Float, whenDone : Function = null) : Void{
		activeTransitions.push(new Transition(quadraticFunc, setValue, startValue, endValue, secs, whenDone));
	}
	
	public static function cubic(setValue : Function, startValue : Dynamic, endValue : Dynamic, secs : Float, whenDone : Function = null) : Void{
		activeTransitions.push(new Transition(cubicFunc, setValue, startValue, endValue, secs, whenDone));
	}
	
	public static function step(evt : Dynamic) : Void{
		if (activeTransitions.length == 0) 			return;
		var now : UInt = Math.round(haxe.Timer.stamp() * 1000);
		var newActive : Array<Dynamic> = [];
		for (t in activeTransitions){
			if (t.apply(now)) 				newActive.push(t);
		}
		activeTransitions = newActive;
	}
	
	private function apply(now : UInt) : Bool{
		var msecs : Int = now - startMSecs;
		if (msecs < 50) {  // ensure that start value is processed for at least one frame  
			setValue(startValue);
			return true;
		}
		var t : Float = (now - startMSecs) / duration;
		if (t > 1.0) {
			setValue(endValue);
			if (whenDone != null) 				whenDone();
			return false;
		}
		if (Std.is(startValue, Array)) {
			var a : Array<Dynamic> = [];
			for (i in 0...startValue.length){
				a.push(startValue[i] + (delta[i] * (1.0 - interpolate(1.0 - t))));
			}
			setValue(a);
		}
		else {
			setValue(startValue + (delta * (1.0 - interpolate(1.0 - t))));
		}
		return true;
	}
	
	// Transition functions:
	private static function linearFunc(t : Float) : Float{return t;
	}
	private static function quadraticFunc(t : Float) : Float{return t * t;
	}
	private static function cubicFunc(t : Float) : Float{return t * t * t;
	}
}

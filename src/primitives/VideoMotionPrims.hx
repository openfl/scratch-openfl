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

// VideoMotionPrims.as
// Tony Hwang and John Maloney, January 2011
//
// Video motion sensing primitives.

package primitives;

import primitives.BitmapData;
import primitives.Matrix;
import primitives.Rectangle;
import primitives.Scratch;

import flash.display.*;
import flash.geom.*;
import flash.utils.*;
import blocks.Block;
import interpreter.*;
import scratch.*;

class VideoMotionPrims {
	
	public static var readMotionSensor : Function;
	
	private var toDegree : Float = 180 / Math.PI;
	private inline var WIDTH : Int = 480;
	private inline var HEIGHT : Int = 360;
	private inline var AMOUNT_SCALE : Int = 100;  // chosen empirically to give a range of roughly 0-100  
	private inline var THRESHOLD : Int = 10;
	private inline var WINSIZE : Int = 8;
	
	private var app : Scratch;
	private var interp : Interpreter;
	
	private var gradA2Array : Array<Float> = new Array<Float>();
	private var gradA1B2Array : Array<Float> = new Array<Float>();
	private var gradB1Array : Array<Float> = new Array<Float>();
	private var gradC2Array : Array<Float> = new Array<Float>();
	private var gradC1Array : Array<Float> = new Array<Float>();
	
	private var motionAmount : Int;
	private var motionDirection : Int;
	private var analysisDone : Bool;
	
	private var frameNum : Int;
	private var frameBuffer : BitmapData;
	private var curr : Array<UInt>;
	private var prev : Array<UInt>;
	
	public function new(app : Scratch, interpreter : Interpreter)
	{
		this.app = app;
		this.interp = interpreter;
		frameBuffer = new BitmapData(WIDTH, HEIGHT);
	}
	
	public function addPrimsTo(primTable : Dictionary) : Void{
		Reflect.setField(primTable, "senseVideoMotion", primVideoMotion);
		readMotionSensor = getMotionOn;
	}
	
	private function primVideoMotion(b : Block) : Float{
		var motionType : String = interp.arg(b, 0);
		var obj : ScratchObj = app.stagePane.objNamed(Std.string(interp.arg(b, 1)));
		if ("this sprite" == interp.arg(b, 1)) 			obj = interp.targetObj();
		return getMotionOn(motionType, obj);
	}
	
	private function getMotionOn(motionType : String, obj : ScratchObj) : Float{
		if (obj == null) 			return 0;
		startMotionDetector();
		if (!analysisDone) 			analyzeFrame();
		if (obj.isStage) {
			if (motionType == "direction") 				return motionDirection;
			if (motionType == "motion") 				return Math.min(100, motionAmount);
		}
		else {
			var s : ScratchSprite = try cast(obj, ScratchSprite) catch(e:Dynamic) null;
			if (analysisDone) 				getLocalMotion(s);
			if (motionType == "direction") 				return s.localMotionDirection;
			if (motionType == "motion") 				return Math.min(100, s.localMotionAmount);
		}
		return 0;
	}
	
	// start/stop getting step() calls from runtime:
	private function startMotionDetector() : Void{app.runtime.motionDetector = this;
	}
	private function stopMotionDetector() : Void{app.runtime.motionDetector = null;
	}
	
	public function step() : Void{
		frameNum++;
		var sprites : Array<Dynamic> = app.stagePane.sprites();
		if (!(app.stagePane && app.stagePane.videoImage)) {
			prev = curr = null;
			motionAmount = motionDirection = 0;
			for (i in 0...sprites.length){
				sprites[i].localMotionAmount = 0;
				sprites[i].localMotionDirection = 0;
			}
			analysisDone = true;
			stopMotionDetector();
			return;
		}
		var img : BitmapData = app.stagePane.videoImage.bitmapData;
		var scale : Float = Math.min(WIDTH / img.width, HEIGHT / img.height);
		var m : Matrix = new Matrix();
		m.scale(scale, scale);
		frameBuffer.draw(img, m);
		prev = curr;
		curr = frameBuffer.getVector(frameBuffer.rect);
		analysisDone = false;
	}
	
	private function getLocalMotion(s : ScratchSprite) : Void{
		if (curr == null || prev == null) {
			s.localMotionAmount = s.localMotionDirection = -1;
			return;
		}
		if (s.localFrameNum != frameNum) {
			var i : Int;
			var j : Int;
			var address : Int;
			var activePixelNum : Int;
			
			var A2 : Float;
			var A1B2 : Float;
			var B1 : Float;
			var C1 : Float;
			var C2 : Float;
			var u : Float;
			var v : Float;
			var uu : Float;
			var vv : Float;
			
			var boundingRect : Rectangle = s.bounds();  //bounding rectangle for sprite  
			var xmin : Float = boundingRect.left;
			var xmax : Float = boundingRect.right;
			var ymin : Float = boundingRect.top;
			var ymax : Float = boundingRect.bottom;
			var scaleFactor : Float = 0;
			
			A2 = 0;
			A1B2 = 0;
			B1 = 0;
			C1 = 0;
			C2 = 0;
			activePixelNum = 0;
			for (i in ymin...ymax){  // y  
				for (j in xmin...xmax){  // x  
					if (j > 0 && (j < WIDTH - 1) && i > 0 && (i < HEIGHT - 1) && ((s.bitmap().getPixel32(j - xmin, i - ymin) >> 24 & 0xff) == 0xff)) 
					{
						address = i * WIDTH + j;
						A2 += gradA2Array[address];
						A1B2 += gradA1B2Array[address];
						B1 += gradB1Array[address];
						C2 += gradC2Array[address];
						C1 += gradC1Array[address];
						scaleFactor++;
					}
				}
			}
			var delta : Float = (A1B2 * A1B2 - A2 * B1);
			if (delta != 0) {
				// system is not singular - solving by Kramer method
				var deltaX : Float = -(C1 * A1B2 - C2 * B1);
				var deltaY : Float = -(A1B2 * C2 - A2 * C1);
				var Idelta : Float = 8 / delta;
				u = deltaX * Idelta;
				v = deltaY * Idelta;
			}
			else {
				// singular system - find optical flow in gradient direction
				var Norm : Float = (A1B2 + A2) * (A1B2 + A2) + (B1 + A1B2) * (B1 + A1B2);
				if (Norm != 0) {
					var IGradNorm : Float = 8 / Norm;
					var temp : Float = -(C1 + C2) * IGradNorm;
					u = (A1B2 + A2) * temp;
					v = (B1 + A1B2) * temp;
				}
				else {
					u = v = 0;
				}
			}
			
			if (scaleFactor != 0) {
				activePixelNum = scaleFactor;  //store the area of the sprite in pixels  
				scaleFactor /= (2 * WINSIZE * 2 * WINSIZE);
				
				u = u / scaleFactor;
				v = v / scaleFactor;
			}
			
			s.localMotionAmount = Math.round(AMOUNT_SCALE * 2e-4 * activePixelNum * Math.sqrt((u * u) + (v * v)));  // note 2e-4 *activePixelNum is an experimentally tuned threshold for my logitech Pro 9000 webcam - TTH  
			if (s.localMotionAmount > 100) 				  //clip all magnitudes greater than 100  
			s.localMotionAmount = 100;
			if (s.localMotionAmount > (THRESHOLD / 3)) {
				s.localMotionDirection = ((Math.atan2(v, u) * toDegree + 270) % 360) - 180;
			}
			s.localFrameNum = frameNum;
		}
	}
	
	private function analyzeFrame() : Void{
		if (curr == null || prev == null) {
			motionAmount = motionDirection = -1;
			return;
		}
		var winStep : Int = WINSIZE * 2 + 1;
		var wmax : Int = WIDTH - WINSIZE - 1;
		var hmax : Int = HEIGHT - WINSIZE - 1;
		
		var i : Int;
		var j : Int;
		var k : Int;
		var l : Int;
		var address : Int;
		
		var A2 : Float;
		var A1B2 : Float;
		var B1 : Float;
		var C1 : Float;
		var C2 : Float;
		var u : Float;
		var v : Float;
		var uu : Float;
		var vv : Float;
		var n : Int;
		
		uu = vv = n = 0;
		i = WINSIZE + 1;
		while (i < hmax){  // y  
			j = WINSIZE + 1;
			while (j < wmax){  // x  
				A2 = 0;
				A1B2 = 0;
				B1 = 0;
				C1 = 0;
				C2 = 0;
				for (k in -WINSIZE...WINSIZE + 1){  // y  
					for (l in -WINSIZE...WINSIZE + 1){  // x  
						var gradX : Int;
						var gradY : Int;
						var gradT : Int;
						
						address = (i + k) * WIDTH + j + l;
						gradX = (curr[address - 1] & 0xff) - (curr[address + 1] & 0xff);
						gradY = (curr[address - WIDTH] & 0xff) - (curr[address + WIDTH] & 0xff);
						gradT = (prev[address] & 0xff) - (curr[address] & 0xff);
						
						gradA2Array[address] = gradX * gradX;
						gradA1B2Array[address] = gradX * gradY;
						gradB1Array[address] = gradY * gradY;
						gradC2Array[address] = gradX * gradT;
						gradC1Array[address] = gradY * gradT;
						
						A2 += gradA2Array[address];
						A1B2 += gradA1B2Array[address];
						B1 += gradB1Array[address];
						C2 += gradC2Array[address];
						C1 += gradC1Array[address];
					}
				}
				var delta : Float = (A1B2 * A1B2 - A2 * B1);
				if (delta != 0) {
					/* system is not singular - solving by Kramer method */
					var deltaX : Float = -(C1 * A1B2 - C2 * B1);
					var deltaY : Float = -(A1B2 * C2 - A2 * C1);
					var Idelta : Float = 8 / delta;
					u = deltaX * Idelta;
					v = deltaY * Idelta;
				}
				else {
					/* singular system - find optical flow in gradient direction */
					var Norm : Float = (A1B2 + A2) * (A1B2 + A2) + (B1 + A1B2) * (B1 + A1B2);
					if (Norm != 0) {
						var IGradNorm : Float = 8 / Norm;
						var temp : Float = -(C1 + C2) * IGradNorm;
						u = (A1B2 + A2) * temp;
						v = (B1 + A1B2) * temp;
					}
					else {
						u = v = 0;
					}
				}
				if (-winStep < u && u < winStep && -winStep < v && v < winStep) {
					uu += u;
					vv += v;
					n++;
				}
				j += winStep;
			}
			i += winStep;
		}
		uu /= n;
		vv /= n;
		motionAmount = Math.round(AMOUNT_SCALE * Math.sqrt((uu * uu) + (vv * vv)));
		if (motionAmount > THRESHOLD) {
			motionDirection = ((Math.atan2(vv, uu) * toDegree + 270) % 360) - 180;
		}
		analysisDone = true;
	}
}

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

import svgeditor.objs.Graphics;
import svgeditor.objs.Shape;

import flash.display.*;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import svgeditor.objs.ISVGEditable;
import svgeditor.tools.PixelPerfectCollisionDetection;

import svgutils.SVGDisplayRender;
import svgutils.SVGElement;
import svgutils.SVGExport;
import svgutils.SVGImporter;
import svgutils.SVGPath;

class SVGShape extends Shape implements ISVGEditable {
	private var element : SVGElement;
	
	public function new(elem : SVGElement)
	{
		super();
		element = elem;
	}
	
	public function getElement() : SVGElement{
		element.transform = transform.matrix;
		return element;
	}
	
	public function redraw(forHitTest : Bool = false) : Void{
		graphics.clear();
		element.renderPathOn(this, forHitTest);
	}
	
	public function clone() : ISVGEditable{
		var copy : ISVGEditable = new SVGShape(element.clone());
		(try cast(copy, DisplayObject) catch(e:Dynamic) null).transform.matrix = transform.matrix.clone();
		copy.redraw();
		return copy;
	}
	
	private var collisionState : Bool;
	private var testWidth : Float = 2.0;
	private var interval : Float = 0.1;
	private var eraserMode : Bool = false;
	public var debugMode : Bool = false;
	public var distCheck : Float = 0.05;
	public static var bisectionDistCheck : Float = 0.05;
	public static var eraserDistCheck : Float = 0.5;
	public function getAllIntersectionsWithShape(otherShape : DisplayObject, forEraser : Bool = false) : Array<Dynamic>{
		var intersections : Array<Dynamic> = [];
		var g : Graphics = graphics;
		var path : SVGPath = getElement().path;
		var startPos : Point = path.getPos(0);
		collisionState = false;
		eraserMode = forEraser;
		var maxCmdDist1 : Float = 10;
		var maxCmdDist2 : Float = 10;
		var distInterval : Float = 0.75;
		for (i in 1...path.length){
			g.clear();
			g.moveTo(startPos.x, startPos.y);
			setTestStroke();
			SVGPath.renderPathCmd(path[i], g, startPos);
			if (PixelPerfectCollisionDetection.isColliding(this, otherShape)) {
				findIntersections(i, otherShape, intersections);
			}
			else if (collisionState) {
				intersections[intersections.length - 1].end = {
							index : i - 1,
							time : 1,

						};
				collisionState = false;
			}
		}
		
		if (collisionState) {
			intersections[intersections.length - 1].end = {
						index : i - 1,
						time : 1,

					};
			collisionState = false;
		}
		
		return intersections;
	}
	
	private function setTestStroke() : Void{
		if (eraserMode) 
			graphics.lineStyle(element.getAttribute("stroke-width", 1), 0, 1, true, "normal", CapsStyle.ROUND, JointStyle.MITER)
		else 
		graphics.lineStyle(testWidth, 0, 1, false, "normal", CapsStyle.NONE, JointStyle.MITER, 0);
	}
	
	private function findIntersections(index : Int, otherShape : DisplayObject, intersections : Array<Dynamic>) : Void{
		if (debugMode) {
			var y : Float = 0;
			if (debugCD) {
				y = debugCD.y + debugCD.height;
			}
			debugCD = new Sprite();
			parent.addChild(debugCD);
		}
		
		var path : SVGPath = element.path;
		var cmd : Array<Dynamic> = path[index];
		var p1 : Point = path.getPos(index - 1);
		var p2 : Point = path.getPos(index);
		if (cmd[0] == "C" || cmd[0] == "L") {
			var c1 : Point = (cmd[0] == ("C") ? new Point(cmd[1], cmd[2]) : null);
			var c2 : Point = (cmd[0] == ("C") ? new Point(cmd[3], cmd[4]) : null);
			
			var minDist : Float = interval * 2;
			var time : Float = 0;
			var curr : Dynamic = null;
			interval = 0.1;
			while (time > -1){
				time = getNextCollisionChange(time, p1, c1, c2, p2, otherShape);
				if (time > -1) {
					if (collisionState) {
						// Should we make sure that we've moved at least a certain amount?
						//if(!curr || time - curr.end.time > minDist) {
						curr = {
									start : {
										index : index,
										time : time,

									}

								};
						intersections.push(curr);
						interval = Math.min(0.1, interval * 32);
					}
					else {
						intersections[intersections.length - 1].end = {
									index : index,
									time : time,

								};
						interval = 0.1;
					}  //trace('intersecting at ('+time+')');  
				}
				else {
					break;
				}
			}
		}
		
		showIntersections(intersections);
	}
	
	private function getNextCollisionChange(time : Float, p1 : Point, cp1 : Point, cp2 : Point, p2 : Point, otherShape : DisplayObject) : Float{
		var g : Graphics = graphics;
		//trace('getNextCollisionChange('+time+', '+interval+')');
		var i : Float = time + interval;
		while (i <= 1.0){
			g.clear();
			var ct : Float = i - interval;
			var pt : Point = SVGPath.getPosByTime(ct - interval, p1, cp1, cp2, p2);
			g.moveTo(pt.x, pt.y);
			setTestStroke();
			//if(npt) trace("Moving "+npt.subtract(SVGPath.getPosByTime(i, p1, cp1, cp2, p2)).length+" @ t="+i);
			var npt : Point = SVGPath.getPosByTime(i, p1, cp1, cp2, p2);
			g.lineTo(npt.x, npt.y);
			var colliding : Bool = PixelPerfectCollisionDetection.isColliding(this, otherShape);  //, false, debugCD);  
			if (colliding != collisionState) {
				//trace("At time "+ct+" colliding="+colliding)
				if (npt.subtract(pt).length > distCheck) {
					// Recurse to get a more precise time
					interval *= 0.5;
					return getNextCollisionChange(ct, p1, cp1, cp2, p2, otherShape);
				}
				else {
					collisionState = colliding;
					return (colliding) ? i - interval : ct;
				}
			}
			i += interval;
		}
		
		return -1;
	}
	
	public function getPathCmdIndexUnderMouse() : Int{
		if (!element.path || element.path.length < 2) 
			return -1;
		
		var canvas : Shape = new Shape();
		var g : Graphics = canvas.graphics;
		var w : Float = element.getAttribute("stroke-width");
		// TODO: Make this better by making the bitmap size scale if current element is scaled
		w = Math.max(8, ((Math.isNaN(w)) ? 12 : w) + 2);
		g.lineStyle(w, 0xff00FF, 1, true, "normal", CapsStyle.ROUND, JointStyle.MITER);
		
		var forceLines : Bool = (element.path.length < 3);
		var dRect : Rectangle = getBounds(this);
		
		// Adjust the path so that the top left is at 0,0 locally
		// This allows us to create the smallest bitmap for rendering it to
		var bmp : BitmapData = new BitmapData(dRect.width, dRect.height, true, 0);
		var m : Matrix = new Matrix(1, 0, 0, 1, -dRect.topLeft.x, -dRect.topLeft.y);
		
		var lastCP : Point = new Point();
		var startP : Point = new Point();
		var mousePos : Point = new Point(mouseX, mouseY);
		var index : Int = -1;
		var max : UInt = element.path.length - 1;
		for (i in 0...max + 1){
			// Clear the bitmap
			bmp.fillRect(bmp.rect, 0x00000000);
			
			// Draw the path up until point #i
			SVGPath.renderPathCmd(element.path[i], g, lastCP, startP);
			
			// Return this index if the mouse location has been drawn on
			bmp.draw(canvas, m);
			if (bmp.hitTest(dRect.topLeft, 0xFF, mousePos)) {
				index = i;
				break;
			}
		}
		
		bmp.dispose();
		return index;
	}
	
	// Walk the path an try removing any commands to see if they change the shape too much
	public function smoothPath(maxRatio : Float) : Void{
		// Remove the fill so that we're only checking changes in the stroke changing
		var fill : String = getElement().getAttribute("fill");
		getElement().setAttribute("fill", "none");
		var stroke : String = getElement().getAttribute("stroke");
		if (stroke == "none") 
			getElement().setAttribute("stroke", "black")  // Take a snapshot  ;
		
		
		
		redraw();
		var rect : Rectangle = getBounds(stage);
		var img : BitmapData = new BitmapData(rect.width, rect.height, true, 0x00000000);
		var m : Matrix = transform.concatenatedMatrix.clone();
		m.translate(-rect.x, -rect.y);
		
		var removedPoint : Bool = false;
		var start : Float = (Date.now()).getTime();
		var elem : SVGElement = getElement();
		do{
			var index : UInt = 1;
			removedPoint = false;
			var dirty : Bool;
			while (index < elem.path.length){
				// Skip Move and Close commands
				if (elem.path[index][0] == "Z" || elem.path[index][0] == "M") {
					++index;
					continue;
				}
				
				redraw();
				img.fillRect(img.rect, 0);
				img.draw(this, m);
				img.threshold(img, img.rect, new Point(), "<", 0xF0000000, 0, 0xF0000000);
				
				var cmd : Array<Dynamic> = elem.path[index];
				elem.path.splice(index, 1);
				elem.path.adjustPathAroundAnchor(index, 3, 1);
				redraw();
				
				img.draw(this, m, null, BlendMode.ERASE);
				img.threshold(img, img.rect, new Point(), "<", 0xF0000000, 0, 0xF0000000);
				var r : Rectangle = img.getColorBoundsRect(0xFF000000, 0xFF000000, true);
				if (r != null && r.width > 1 && r.height > 1) {
					var pixelCount : UInt = 0;
					for (i in r.left...r.right){for (j in r.top...r.bottom){if ((img.getPixel32(i, j) >> 24) & 0xF0) 
								++pixelCount;
						}
					}
					var len : Float = (new Point(r.width, r.height)).length;
					var ratio : Float = pixelCount / len;
					//trace(r + '    '+ratio + ' > '+maxRatio + ' '+ (ratio > maxRatio ? 'SAVED' : 'DISCARDED'));
					if (ratio > maxRatio) {
						elem.path.splice(index, 0, cmd);
						elem.path.adjustPathAroundAnchor(index);
					}
					else {
						removedPoint = true;
					}
				}
				else {
					removedPoint = true;
				}
				elem.path.adjustPathAroundAnchor(index, 3, 1);
				elem.path.adjustPathAroundAnchor(index, 3, 1);
				elem.path.adjustPathAroundAnchor(index, 3, 1);
				++index;
			}
		}		while ((removedPoint));
		img.dispose();
		
		// Reset stroke and fill then redraw
		getElement().setAttribute("stroke", stroke);
		getElement().setAttribute("fill", fill);
		redraw();
		trace("smoothPath() took " + ((Date.now()).getTime() - start) + "ms.");
	}
	
	// Walk the path an try removing any commands to see if they change the shape too much
	public function smoothPath2(maxRatio : Float) : Void{
		maxRatio *= 0.01;
		
		// Remove the fill so that we're only checking changes in the stroke changing
		var elem : SVGElement = getElement();
		var fill : String = elem.getAttribute("fill");
		elem.setAttribute("fill", "none");
		var stroke : String = elem.getAttribute("stroke");
		var strokeWidth : String = elem.getAttribute("stroke-width");
		if (stroke == "none") {
			elem.setAttribute("stroke", "black");
			elem.setAttribute("stroke-width", 2);
		}  // Take a snapshot  
		
		
		
		redraw();
		var rect : Rectangle = getBounds(stage);
		var img : BitmapData = new BitmapData(rect.width, rect.height, true, 0x00000000);
		var img2 : BitmapData = img.clone();
		var m : Matrix = transform.concatenatedMatrix.clone();
		m.translate(-rect.x, -rect.y);
		
		// Render for comparison
		img.draw(this, m);
		img.threshold(img, img.rect, new Point(), "<", 0xF0000000, 0, 0xF0000000);
		
		// Count the pixels painted
		var or : Rectangle = img.getColorBoundsRect(0xFF000000, 0xFF000000, true);
		var totalPixels : UInt = 0;
		for (i in or.left...or.right){for (j in or.top...or.bottom){if ((img.getPixel32(i, j) >> 24) & 0xF0) 
					++totalPixels;
			}
		}
		
		var removedPoint : Bool = false;
		var start : Float = (Date.now()).getTime();
		var passCount : UInt = 0;
		var endPointDistFromEnd : UInt = elem.path.length - elem.path.getSegmentEndPoints()[1];
		do{
			//trace('Starting pass #'+(passCount+1));
			var tries : UInt = elem.path.length - endPointDistFromEnd;
			var index : UInt = 1;
			removedPoint = false;
			var dirty : Bool;
			while (tries){
				--tries;
				// Pick a random command to try to remove
				index = Math.floor(Math.random() * (elem.path.length - endPointDistFromEnd));
				
				// Skip Move and Close commands
				if (elem.path[index][0] == "Z" || elem.path[index][0] == "M") {
					//++index;
					continue;
				}  // Get a fresh copy of the original render  
				
				
				
				img2.copyPixels(img, img.rect, new Point());
				
				var cmd : Array<Dynamic> = elem.path[index];
				elem.path.splice(index, 1);
				elem.path.adjustPathAroundAnchor(index, 3, 1);
				redraw();
				
				img2.draw(this, m, null, BlendMode.ERASE);
				img2.threshold(img, img.rect, new Point(), "<", 0xF0000000, 0, 0xF0000000);
				var r : Rectangle = img.getColorBoundsRect(0xFF000000, 0xFF000000, true);
				if (r != null && r.width > 1 && r.height > 1) {
					//trace(or + ' : ' + r);
					var pixelCount : UInt = 0;
					for (i in r.left...r.right){for (j in r.top...r.bottom){if ((img2.getPixel32(i, j) >> 24) & 0xF0) 
								++pixelCount;
						}
					}
					var ratio : Float = pixelCount / totalPixels;
					//trace('Cmd #'+index+'    '+ratio + ' > '+maxRatio + ' '+ (ratio > maxRatio ? 'SAVED' : 'DISCARDED'));
					if (ratio > maxRatio) {
						elem.path.splice(index, 0, cmd);
						elem.path.adjustPathAroundAnchor(index);
					}
					else {
						removedPoint = true;
					}
				}
				else {
					removedPoint = true;
				}
				elem.path.adjustPathAroundAnchor(index, 3, 1);
				elem.path.adjustPathAroundAnchor(index, 3, 1);
				elem.path.adjustPathAroundAnchor(index, 3, 1);
			}++;passCount;
		}		while ((removedPoint));
		img.dispose();
		img2.dispose();
		
		// Reset stroke and fill then redraw
		elem.setAttribute("stroke", stroke);
		elem.setAttribute("stroke-width", strokeWidth);
		elem.setAttribute("fill", fill);
		redraw();
	}
	
	// Debugging stuff!
	private static var debugShape : Shape;
	private static var debugCD : Sprite;
	public function showIntersections(intersections : Array<Dynamic>) : Void{
		if (debugMode) {
			if (debugShape != null) {
				if (debugShape.parent) 
					debugShape.parent.removeChild(debugShape);
				debugShape.graphics.clear();
			}
			else {
				debugShape = new Shape();
				debugShape.alpha = 0.25;
			}
			parent.addChild(debugShape);
			debugShape.transform = transform;
		}
		
		for (i in 0...intersections.length){
			var section : Dynamic = intersections[i];
			var stopTime : Float = ((section.end && section.start.index == section.end.index)) ? section.end.time : 1.0;
			showPartialCurve(section.start.index, section.start.time, stopTime);
			if (section.end && section.start.index != section.end.index) {
				if (section.end.index > section.start.index + 1) {
					for (j in section.start.index + 1...section.end.index){showPartialCurve(j, 0, 1);
					}
				}
				showPartialCurve(section.end.index, 0, section.end.time);
			}
		}
	}
	
	public function showPoints() : Void{
		debugShape.graphics.lineStyle(2, 0x00CCFF);
		for (j in 0...element.path.length){
			var pt : Point = element.path.getPos(j);
			debugShape.graphics.drawCircle(pt.x, pt.y, 3);
		}
	}
	
	private function showPartialCurve(index : Int, start : Float, stop : Float) : Void{
		if (!debugMode) 
			return;
		
		var cmd : Array<Dynamic> = element.path[index];
		var p1 : Point = element.path.getPos(index - 1);
		var c1 : Point = new Point(cmd[1], cmd[2]);
		var c2 : Point = new Point(cmd[3], cmd[4]);
		var p2 : Point = new Point(cmd[5], cmd[6]);
		var g : Graphics = debugShape.graphics;
		var pt : Point = SVGPath.getPosByTime(start, p1, c1, c2, p2);
		var overlap : Float = interval;
		g.moveTo(pt.x, pt.y);
		g.lineStyle(5, 0xFF0000, 0.7, true, "normal", CapsStyle.NONE, JointStyle.MITER);
		var i : Float = start;
		while (i <= stop){
			//g.clear();
			var percComp : Float = (i - start) / Math.min(stop - start, 0.01);
			pt = SVGPath.getPosByTime(i - interval - overlap, p1, c1, c2, p2);
			//g.moveTo(pt.x, pt.y);
			//var grn:int = ((1 - percComp) * 0xFF) << 8;
			//g.lineStyle(5, 0xFF0000 + grn, 0.5, false, "normal", CapsStyle.NONE, JointStyle.MITER, 0);
			
			pt = SVGPath.getPosByTime(i, p1, c1, c2, p2);
			g.lineTo(pt.x, pt.y);
			i += interval;
		}
	}
	
	public function connectPaths(otherShape : SVGShape) : Bool{
		var otherElem : SVGElement = otherShape.getElement();
		var strokeWidth : Float = element.getAttribute("stroke-width", 1);
		
		var endPts : Array<Dynamic> = otherElem.path.getSegmentEndPoints();
		if (endPts[2]) 
			return false;
		
		var otherStart : Point = otherShape.localToGlobal(otherElem.path.getPos(endPts[0]));
		var otherEnd : Point = otherShape.localToGlobal(otherElem.path.getPos(endPts[1]));
		
		endPts = element.path.getSegmentEndPoints();
		if (endPts[2]) 
			return false;
		
		var thisStart : Point = localToGlobal(element.path.getPos(endPts[0]));
		var thisEnd : Point = localToGlobal(element.path.getPos(endPts[1]));
		var indexContinued : UInt = 0;
		var endContinued : Bool = false;
		if (thisEnd.subtract(otherStart).length < strokeWidth * 2) {
			indexContinued = endPts[1];
			endContinued = true;
		}
		else if (thisEnd.subtract(otherEnd).length < strokeWidth * 2) {
			indexContinued = endPts[1];
			otherElem.path.reversePath();
			endContinued = true;
		}
		else if (thisStart.subtract(otherEnd).length < strokeWidth * 2) {
			indexContinued = endPts[0];
		}
		// Setup the arguments to call splice() on the existing path
		else if (thisStart.subtract(otherStart).length < strokeWidth * 2) {
			indexContinued = endPts[0];
			otherElem.path.reversePath();
		}
		
		
		
		otherElem.path.transform(otherShape, this);
		var args : Array<Dynamic> = otherElem.path.concat();
		if (endContinued) 
			args.shift();
		
		args.unshift((endContinued) ? 0 : 1);
		
		var insertIndex : Int = ((endContinued) ? indexContinued + 1 : indexContinued);
		args.unshift(insertIndex);
		
		// Insert the curve commands
		var pc : SVGPath = element.path;
		pc.splice.apply(pc, args);
		
		// Close the path?
		endPts = element.path.getSegmentEndPoints();
		if (element.path.getPos(endPts[0]).subtract(element.path.getPos(endPts[1])).length < strokeWidth * 2) {
			element.path.splice(endPts[1] + 1, 0, ["Z"]);
			element.path.adjustPathAroundAnchor(endPts[1]);
			element.path.adjustPathAroundAnchor(endPts[0]);
		}
		return true;
	}
}


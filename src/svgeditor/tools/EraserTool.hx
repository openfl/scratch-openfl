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

import assets.Resources;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.display.CapsStyle;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.LineScaleMode;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import svgeditor.DrawProperties;
import svgeditor.ImageEdit;
import svgeditor.objs.ISVGEditable;
import svgeditor.objs.SVGBitmap;
import svgeditor.objs.SVGGroup;
import svgeditor.objs.SVGShape;

import svgutils.SVGElement;
import svgutils.SVGExport;
import svgutils.SVGPath;

@:final class EraserTool extends SVGTool {
	private var eraserShape : Shape;
	private var lastPos : Point;
	private var eraserWidth : Float;
	private var erased : Bool;
	public function new(ed : ImageEdit)
	{
		super(ed);
		touchesContent = true;
		eraserShape = new Shape();
		lastPos = null;
		erased = false;
		
		cursorHotSpot = new Point(7, 18);
	}
	
	public function updateIcon() : Void{
		var sp : DrawProperties = editor.getShapeProps();
		if (eraserWidth != sp.eraserWidth) {
			var bm : Bitmap = Resources.createBmp("eraserOff");
			var s : Shape = new Shape();
			s.graphics.lineStyle(1);
			s.graphics.drawCircle(0, 0, sp.eraserWidth * 0.65);
			var curBM : BitmapData = new BitmapData(32, 32, true, 0);
			var m : Matrix = new Matrix();
			m.translate(16, 18);
			curBM.draw(s, m);
			m.translate(-cursorHotSpot.x, -cursorHotSpot.y);
			curBM.draw(bm, m);
			editor.setCurrentCursor("eraserOff", curBM, new Point(16, 18), false);
			eraserWidth = sp.eraserWidth;
		}
	}
	
	override private function init() : Void{
		super.init();
		editor.getWorkArea().addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
		STAGE.addChild(eraserShape);
		updateIcon();
	}
	
	override private function shutdown() : Void{
		editor.getWorkArea().removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		super.shutdown();
		STAGE.removeChild(eraserShape);
	}
	
	private function mouseDown(e : MouseEvent) : Void{
		editor.getWorkArea().addEventListener(MouseEvent.MOUSE_MOVE, erase, false, 0, true);
		STAGE.addEventListener(MouseEvent.MOUSE_UP, mouseUp, false, 0, true);
		eraserWidth = editor.getShapeProps().eraserWidth;
		erase();
	}
	
	private function mouseUp(e : MouseEvent) : Void{
		editor.getWorkArea().removeEventListener(MouseEvent.MOUSE_MOVE, erase);
		STAGE.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
		erase();
		lastPos = null;
		dispatchEvent(new Event(Event.CHANGE));
	}
	
	private function erase(e : MouseEvent = null) : Void{
		updateEraserShape();
		
		erased = false;
		var objs : Array<Dynamic> = getObjectsUnderEraser();
		for (i in 0...objs.length){eraseObj(objs[i]);
		}
		
		lastPos = new Point(eraserShape.mouseX, eraserShape.mouseY);
	}
	
	private function getObjectsUnderEraser() : Array<Dynamic>{
		var objs : Array<Dynamic> = [];
		var cl : Sprite = editor.getContentLayer();
		testObjectsOnLayer(cl, objs);
		
		return objs;
	}
	
	private function testObjectsOnLayer(layer : Sprite, objs : Array<Dynamic>) : Void{
		for (i in 0...layer.numChildren){
			var obj : DisplayObject = layer.getChildAt(i);
			if (Std.is(obj, Sprite)) {
				testObjectsOnLayer(try cast(obj, Sprite) catch(e:Dynamic) null, objs);
			}
			else if (Std.is(obj, ISVGEditable) && obj.hitTestObject(eraserShape)) {
				// Don't erase backdrop background elements
				if (Std.is(obj, SVGShape) && (try cast(obj, SVGShape) catch(e:Dynamic) null).getElement().isBackDropBG()) 
					{++i;continue;
				};
				
				objs.push(obj);
			}
		}
	}
	
	private function eraseObj(obj : ISVGEditable) : Void{
		eraserShape.visible = true;
		if (Std.is(obj, SVGBitmap)) {
			var bmObj : SVGBitmap = (try cast(obj, SVGBitmap) catch(e:Dynamic) null);
			eraseFromBitmap(bmObj);
		}
		else if (Std.is(obj, SVGShape)) {
			// Erase shapes that have a stroke
			// TODO: remove this once erasing from fills is implemented
			var shapeObj : SVGShape = try cast(obj, SVGShape) catch(e:Dynamic) null;
			if (shapeObj.getElement().getAttribute("stroke") != "none") 
				eraseFromShape(shapeObj);
		}
		eraserShape.visible = false;
	}
	
	private function updateEraserShape() : Void{
		var g : Graphics = eraserShape.graphics;
		//var w:Number = eraserWidth * editor.getContentLayer().
		g.clear();
		var p : Point = new Point(eraserShape.mouseX, eraserShape.mouseY);
		if (lastPos != null) {
			g.lineStyle(eraserWidth, 0xFF0000, 1, false, LineScaleMode.NORMAL, CapsStyle.ROUND);
			g.moveTo(lastPos.x, lastPos.y);
			//var p:Point = obj.globalToLocal(lastPos).subtract(new Point(obj.mouseX, obj.mouseY));
			g.lineTo(p.x, p.y);
		}
		else {
			g.lineStyle(0, 0, 0);
			g.beginFill(0xFF0000);
			g.drawCircle(p.x, p.y, eraserWidth * 0.65);
			g.endFill();
			g.moveTo(p.x, p.y);
		}  // Force the draw cache to refresh  
		
		
		
		eraserShape.visible = true;
		eraserShape.visible = false;
	}
	
	private function eraseFromBitmap(bmObj : Bitmap) : Void{
		eraserShape.alpha = 1.0;
		var m : Matrix = bmObj.transform.concatenatedMatrix;
		m.invert();
		bmObj.bitmapData.draw(eraserShape, m, null, BlendMode.ERASE, null);
		
		var r : Rectangle = bmObj.bitmapData.getColorBoundsRect(0xFF000000, 0x00000000, false);
		if (r == null || r.width == 0 || r.height == 0) {
			bmObj.parent.removeChild(bmObj);
		}
		
		eraserShape.alpha = 0.5;
	}
	
	private function eraseFromShape(svgShape : SVGShape) : Void{
		// Does the path collide with the backdrop shapes?
		if (!PixelPerfectCollisionDetection.isColliding(svgShape, eraserShape)) 			return  //trace("Path intersects with backdrop!");  ;
		
		
		var thisSW : Dynamic = svgShape.getElement().getAttribute("stroke-width");
		var thisSC : Dynamic = svgShape.getElement().getAttribute("stroke-linecap");
		
		// Make sure that it isn't just the stroke width that is causing the intersection.
		// We want paths which intersect and not just "touch"
		//svgShape.getElement().setAttribute('stroke-width', 2.0);
		svgShape.getElement().setAttribute("stroke-linecap", "butt");
		svgShape.redraw();
		
		//svgShape.debugMode = true;
		if (svgShape.getElement().tag != "path") 
			svgShape.getElement().convertToPath();
		
		svgShape.distCheck = SVGShape.eraserDistCheck;
		var intersections : Array<Dynamic> = svgShape.getAllIntersectionsWithShape(eraserShape, true);
		if (intersections.length) 
			erased = true  // Okay, they definitely intersect, let's find out where  ;
		
		
		
		var path : SVGPath = svgShape.getElement().path;
		
		//trace('___Original Commands___ ('+intersections.length+' intersections)');
		//path.outputCommands();
		//svgShape.showIntersections(intersections);
		
		// Cut the path in two
		var origLen : Int = path.length;
		var closingSegment : Int = -1;
		for (i in 0...intersections.length){
			var ofs : Int = path.length - origLen;
			var inter : Dynamic = intersections[i];
			if (false) {
				var str : String = "Intersection #" + i + ":  start (" + inter.start.index + ", " + inter.start.time + ")";
				if (inter.end) {
					str += "   end (" + inter.end.index + ", " + inter.end.time + ")";
				}
				trace(str);
			}
			var startIndex : Int = inter.start.index + ofs;
			var indices : Array<Dynamic> = path.getSegmentEndPoints(startIndex);
			//trace(indices);
			if (indices[2]) {
				if (svgShape.getElement().getAttribute("fill") != "none" &&
					svgShape.getElement().getAttribute("fill-opacity") != 0) {
					// Save the fill in an independent shape
					var fillShape : ISVGEditable = svgShape.clone();
					fillShape.getElement().setAttribute("stroke", "none");
					fillShape.getElement().setAttribute("stroke-width", null);
					fillShape.redraw();
					svgShape.parent.addChildAt(try cast(fillShape, DisplayObject) catch(e:Dynamic) null, svgShape.parent.getChildIndex(svgShape));
				}  // Open the path!  
				
				
				
				closingSegment = indices[1];
				path.splice(indices[1] + 1, 1);
			}
			
			var endIndex : UInt = Math.min(inter.end.index + ofs, indices[1]);
			var endTime : Float = inter.end.time;
			endIndex = path.splitCurve(endIndex, endTime);
			var pt : Point = path.getPos(endIndex);
			var endCmds : Array<Dynamic> = path.substring(endIndex + 1);
			
			var startTime : Float = inter.start.time;
			if (startIndex == inter.end.index + ofs) {
				startTime = startTime / endTime;
			}
			
			startIndex = path.splitCurve(startIndex, startTime);
			path.length = startIndex + 1;
			path.push(["M", pt.x, pt.y]);
			path.push.apply(path, endCmds);
		}
		svgShape.getElement().setAttribute("stroke-width", thisSW);
		svgShape.getElement().setAttribute("stroke-linecap", thisSC);
		svgShape.redraw();
		
		if (intersections.length) {
			path.removeInvalidSegments(thisSW);
			//trace('___Altered Commands___');
			//path.outputCommands();
			//trace('DONE\n');
			// Bind a segment which had closed the path to the beginning of the path
			if (closingSegment > 0) {
				indices = path.getSegmentEndPoints(closingSegment);
				// Copy the commands but not the ending 'Z' command
				var cmds : Array<Dynamic> = path.splice(indices[0], indices[1] + 1);
				var stitchIndex : Int = cmds.length - 1;
				
				// Re-insert the commands at the beginning
				cmds.unshift(1);
				cmds.unshift(0);
				path.splice.apply(path, cmds);
				
				path.adjustPathAroundAnchor(stitchIndex, 2);
				path.adjustPathAroundAnchor(0, 2);
				indices = path.getSegmentEndPoints(0);
				svgShape.redraw();
			}
			
			if (path.length < 2) {
				svgShape.parent.removeChild(svgShape);
			}
			else {
				indices = path.getSegmentEndPoints(0);
				svgShape.getElement().setAttribute("fill", "none");
				if (indices[1] < path.length - 1) {
					var newShape : SVGShape = try cast(svgShape.clone(), SVGShape) catch(e:Dynamic) null;
					newShape.getElement().path = path.clone();
					newShape.getElement().path.splice(0, indices[1] + 1);
					newShape.getElement().setAttribute("d", SVGExport.pathCmds(newShape.getElement().path));
					newShape.redraw();
					newShape.getElement().path.setDirty();
					svgShape.parent.addChildAt(newShape, svgShape.parent.getChildIndex(svgShape));
					path.length = indices[1] + 1;
				}
				svgShape.getElement().setAttribute("d", SVGExport.pathCmds(path));
				svgShape.getElement().path.setDirty();
				svgShape.redraw();
			}
		}
	}
}


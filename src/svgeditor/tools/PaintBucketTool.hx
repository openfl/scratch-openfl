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

import com.hangunsworld.util.BMPFunctions;
import flash.display.*;
import flash.events.*;
import flash.filters.GlowFilter;
import flash.geom.*;
import svgeditor.*;
import svgeditor.objs.*;

@:final class PaintBucketTool extends SVGTool {
	private var highlightedObj : DisplayObject;
	private var tolerance : UInt;
	private var lastClick : Point;
	private var savedBM : BitmapData;
	public function new(svgEditor : ImageEdit)
	{
		super(svgEditor);
		tolerance = 30;
		lastClick = new Point(editor.mouseX, editor.mouseY);
		cursorBMName = "paintbucketOff";
		cursorHotSpot = new Point(20, 18);
	}
	
	override private function init() : Void{
		super.init();
		var layer : Sprite = (Std.is(editor, (BitmapEdit) ? editor.getWorkArea() : editor.getContentLayer()));
		layer.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown, false, 0, true);
		if (Std.is(editor, SVGEdit)) {
			editor.getContentLayer().addEventListener(MouseEvent.ROLL_OVER, rollOver, false, 0, true);
			editor.getContentLayer().addEventListener(MouseEvent.ROLL_OUT, rollOut, false, 0, true);
		}
	}
	
	override private function shutdown() : Void{
		if (highlightedObj != null) 			highlightedObj.filters = [];
		if (savedBM != null) 			savedBM.dispose();
		
		var layer : Sprite = (Std.is(editor, (BitmapEdit) ? editor.getWorkArea() : editor.getContentLayer()));
		layer.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		if (Std.is(editor, SVGEdit)) {
			editor.getContentLayer().removeEventListener(MouseEvent.ROLL_OVER, rollOver);
			editor.getContentLayer().removeEventListener(MouseEvent.ROLL_OUT, rollOut);
			editor.getContentLayer().removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		}
		super.shutdown();
	}
	
	private function rollOver(e : MouseEvent) : Void{
		editor.getContentLayer().addEventListener(MouseEvent.MOUSE_MOVE, mouseMove, false, 0, true);
		checkUnderMouse();
	}
	
	private function rollOut(e : MouseEvent) : Void{
		editor.getContentLayer().removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		checkUnderMouse();
	}
	
	private function mouseDown(event : MouseEvent) : Void{
		currentEvent = event;
		
		// Override the obj
		var obj : ISVGEditable = getEditableUnderMouse();
		obj = try cast(highlightedObj, ISVGEditable) catch(e:Dynamic) null;
		if (Std.is(obj, SVGBitmap) || Std.is(editor, BitmapEdit)) {
			var bmap : Bitmap = (Std.is(editor, (BitmapEdit) ? editor.getWorkArea().getBitmap() : try cast(obj, Bitmap) catch(e:Dynamic) null));
			
			if (Point.distance(new Point(editor.mouseX, editor.mouseY), lastClick) < 3) {
				tolerance += 10;
				if (savedBM != null) 					bmap.bitmapData = savedBM.clone();
			}
			else {
				tolerance = 30;
				if (savedBM != null) 					savedBM.dispose();
				savedBM = bmap.bitmapData.clone();
			}
			
			if (Std.is(editor, BitmapEdit)) {
				bitmapFloodFill(bmap.bitmapData, bmap.mouseX, bmap.mouseY);
			}
			else {
				var props : DrawProperties = editor.getShapeProps();
				if (tolerance < 1) 
					// Use the native floodFill method
				bmap.bitmapData.floodFill(bmap.mouseX, bmap.mouseY, props.rawColor)
				else 
				BMPFunctions.floodFill(bmap.bitmapData, bmap.mouseX, bmap.mouseY, props.rawColor, tolerance, true);
			}
			
			lastClick = new Point(editor.mouseX, editor.mouseY);
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		if (!(Std.is(obj, SVGBitmap)) && !(Std.is(editor, BitmapEdit)) && savedBM != null) {
			savedBM.dispose();
			savedBM = null;
		}
	}
	
	private function mouseMove(e : MouseEvent) : Void{
		checkUnderMouse();
	}
	
	private function objIsFillable(obj : ISVGEditable) : Bool{
		var objIsFillable : Bool = (Std.is(obj, SVGBitmap));
		return objIsFillable;
	}
	
	private function checkUnderMouse() : Void{
		var obj : ISVGEditable = getEditableUnderMouse(false);
		if (!objIsFillable(obj)) 			obj = null;
		
		if (obj != highlightedObj) {
			if (highlightedObj != null) 				highlightedObj.filters = [];
			highlightedObj = try cast(obj, DisplayObject) catch(e:Dynamic) null;
			if (highlightedObj != null && objIsFillable(obj)) 				highlightedObj.filters = [new GlowFilter(0x28A5DA)];
		}
	}
	
	private function bitmapFloodFill(bm : BitmapData, fillX : Int, fillY : Int) : Void{
		var markerC : UInt = 0xFFFF00FF;  // special color used to mark pixels to be filled  
		
		var tmp : BitmapData = new BitmapData(bm.width, bm.height, true, 0);
		var targetC : UInt = bm.getPixel32(fillX, fillY);
		var tMask : UInt = toleranceMask();
		if (((targetC >> 24) & 0xFF) < 0xFF) {  // target color is not fully opaque  
			tMask &= 0xFF000000;
		}
		tmp.threshold(bm, tmp.rect, new Point(0, 0), "==", targetC, (0xFF000000 | targetC), tMask);
		
		// flood fill with the marker color starting at mouse point and find its bounding box
		tmp.floodFill(fillX, fillY, markerC);
		var r : Rectangle = tmp.getColorBoundsRect(0xFFFFFFFF, markerC);
		r.width = Math.max(r.width, 1);
		r.height = Math.max(r.height, 1);
		
		// create a stencil (mask) for the filled pixels
		var stencil : BitmapData = new BitmapData(r.width, r.height, true, 0);
		stencil.threshold(tmp, r, new Point(0, 0), "==", markerC, 0xFF000000);
		
		// create an inverse of stencil for the unchanged pixels
		var inverse : BitmapData = new BitmapData(r.width, r.height, true, 0);
		inverse.threshold(tmp, r, new Point(0, 0), "!=", markerC, 0xFF000000);  // inverse of stencil  
		
		// create the gradient fill and cookie-cut it with the stencil
		var fill : BitmapData = new BitmapData(r.width, r.height, true, 0);
		gradientFill(fill, fill.rect, fillX - r.x, fillY - r.y);  // rectangle filled with the gradient  
		fill.copyPixels(fill, fill.rect, new Point(0, 0), stencil);
		
		// assemble the new pixels: unchanged pixels (cookie cut with inverse stencil) + stenciled fill
		var newBM : BitmapData = new BitmapData(r.width, r.height, true, 0);
		newBM.copyPixels(bm, r, new Point(0, 0), inverse);
		newBM.draw(new Bitmap(fill));
		
		// insert the new pixels into the original bitmap
		bm.copyPixels(newBM, newBM.rect, r.topLeft);
	}
	
	private function toleranceMask() : UInt{
		var shift : Int = Math.max(0, Math.min(tolerance / 10, 7));
		var mask : Int = (0xFF << shift) & 0xFF;
		return (mask << 24) | (mask << 16) | (mask << 8) | mask;
	}
	
	private function gradientFill(bm : BitmapData, r : Rectangle, centerX : Int, centerY : Int) : Void{
		// Fill the given rectangle of the give bitmap using the current gradient and colors.
		// Use the given coordinates as the center for a radial gradient.
		
		var props : DrawProperties = editor.getShapeProps();
		var colors : Array<Dynamic> = [props.color, props.secondColor];
		var alphas : Array<Dynamic> = [props.alpha, props.secondAlpha];
		var ratios : Array<Dynamic> = [0, 255];
		var m : Matrix = new Matrix();
		
		// render the gradient into a shape
		var shape : Shape = new Shape();
		var g : Graphics = shape.graphics;
		
		var _sw5_ = (props.fillType);		

		switch (_sw5_) {
			case "linearHorizontal":
				m.createGradientBox(r.width, r.height, 0, 0, 0);
				g.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, m);
			case "linearVertical":
				m.createGradientBox(r.width, r.height, (Math.PI / 2), 0, 0);
				g.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, m);
			case "radial":
				var cx : Float = centerX / r.width;
				var cy : Float = centerY / r.height;
				var rScale : Float = (65 + 1.3 * Math.max(Math.abs(cx * 100 - 50), Math.abs(cy * 100 - 50))) / 100;
				var rx : Float = r.width * rScale;
				var ry : Float = r.height * rScale;
				m.createGradientBox(2 * rx, 2 * ry, 0, centerX - rx, centerY - ry);
				g.beginGradientFill(GradientType.RADIAL, colors, alphas, ratios, m,
						SpreadMethod.PAD, InterpolationMethod.RGB, 0);
			default:  // solid fill  
				g.beginFill(colors[0], alphas[0]);
		}
		g.drawRect(0, 0, r.width, r.height);
		
		// draw the shape onto the bitmap
		m = new Matrix();
		m.translate(r.x, r.y);
		bm.draw(shape, m);
	}
}



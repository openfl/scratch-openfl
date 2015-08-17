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

/*
John:
  [x] cursors for select and stamp mode
  [x] deactivate when media library showing (so cursor doesn't disappear)
  [ ] snap costume center to grid
  [ ] allow larger pens (make size slider be non-linear)
  [ ] when converting stage from bitmap to vector, trim white area (?)
  [ ] minor: small shift when baking in after moving selection
  [ ] add readout for pen size
  [ ] add readout for zoom
*/

package svgeditor;

import svgeditor.BitmapData;
import svgeditor.BitmapPencilTool;
import svgeditor.DisplayObject;
import svgeditor.Event;
import svgeditor.ISVGEditable;
import svgeditor.IconButton;
import svgeditor.ImageEdit;
import svgeditor.ImagesPart;
import svgeditor.Matrix;
import svgeditor.ObjectTransformer;
import svgeditor.Point;
import svgeditor.Rectangle;
import svgeditor.SVGBitmap;
import svgeditor.SVGShape;
import svgeditor.SVGTextField;
import svgeditor.Scratch;
import svgeditor.Selection;
import svgeditor.Sprite;

import flash.display.*;
import flash.events.*;
import flash.geom.*;

import scratch.ScratchCostume;

import svgeditor.objs.*;
import svgeditor.tools.*;

import svgutils.SVGElement;

import ui.parts.*;

import uiwidgets.*;

class BitmapEdit extends ImageEdit {
	
	public var stampMode : Bool;
	
	public static var bitmapTools : Array<Dynamic> = [
		{
			name : "bitmapBrush",
			desc : "Brush",

		}, 
		{
			name : "line",
			desc : "Line",

		}, 
		{
			name : "rect",
			desc : "Rectangle",
			shiftDesc : "Square",

		}, 
		{
			name : "ellipse",
			desc : "Ellipse",
			shiftDesc : "Circle",

		}, 
		{
			name : "text",
			desc : "Text",

		}, 
		{
			name : "paintbucket",
			desc : "Fill with color",

		}, 
		{
			name : "bitmapEraser",
			desc : "Erase",

		}, 
		{
			name : "bitmapSelect",
			desc : "Select",

		}];
	
	private var offscreenBM : BitmapData;
	
	public function new(app : Scratch, imagesPart : ImagesPart)
	{
		super(app, imagesPart);
		addStampTool();
		setToolMode("bitmapBrush");
	}
	
	override private function getToolDefs() : Array<Dynamic>{return bitmapTools;
	}
	
	override private function onColorChange(e : Event) : Void{
		var pencilTool : BitmapPencilTool = try cast(currentTool, BitmapPencilTool) catch(e:Dynamic) null;
		if (pencilTool != null) 			pencilTool.updateProperties();
		super.onColorChange(e);
	}
	
	override public function shutdown() : Void{
		super.shutdown();
		
		// Bake and save costume
		bakeIntoBitmap();
		saveToCostume();
	}
	
	// -----------------------------
	// Bitmap selection support
	//------------------------------
	
	override public function snapToGrid(toolsP : Point) : Point{
		var toolsLayer : Sprite = getToolsLayer();
		var contentLayer : Sprite = workArea.getContentLayer();
		var p : Point = contentLayer.globalToLocal(toolsLayer.localToGlobal(toolsP));
		var roundedP : Point = workArea.getScale() == (1) ? new Point(Math.round(p.x), Math.round(p.y)) : new Point(Math.round(p.x * 2) / 2, Math.round(p.y * 2) / 2);
		return toolsLayer.globalToLocal(contentLayer.localToGlobal(roundedP));
	}
	
	public function getSelection(r : Rectangle) : SVGBitmap{
		var bm : BitmapData = workArea.getBitmap().bitmapData;
		r = r.intersection(bm.rect);  // constrain selection to bitmap content  
		if ((r.width < 1) || (r.height < 1)) 			return null  // empty rectangle  ;
		
		var selectionBM : BitmapData = new BitmapData(r.width, r.height, true, 0);
		selectionBM.copyPixels(bm, r, new Point(0, 0));
		if (stampMode) {
			highlightTool("bitmapSelect");
		}
		else {
			bm.fillRect(r, bgColor());
		}
		
		if (isScene) 			removeWhiteAroundSelection(selectionBM);
		
		var el : SVGElement = SVGElement.makeBitmapEl(selectionBM, 0.5);
		var result : SVGBitmap = new SVGBitmap(el, el.bitmap);
		result.redraw();
		result.x = r.x / 2;
		result.y = r.y / 2;
		workArea.getContentLayer().addChild(result);
		return result;
	}
	
	private function removeWhiteAroundSelection(bm : BitmapData) : Void{
		// Clear extra white pixels around the actual content when editing on the stage.
		
		// Find the box around the non-white pixels
		var r : Rectangle = bm.getColorBoundsRect(0xFFFFFFFF, 0xFFFFFFFF, false);
		if ((r.width == 0) || (r.height == 0)) 			return  // if all white, do nothing  ;
		
		r.inflate(1, 1);
		var corners : Array<Dynamic> = [
		new Point(r.x, r.y), 
		new Point(r.right, 0), 
		new Point(0, r.bottom), 
		new Point(r.right, r.bottom)];
		for (p in corners){
			if (bm.getPixel(p.x, p.y) == 0xFFFFFF) 				bm.floodFill(p.x, p.y, 0);
		}
	}
	
	override private function selectHandler(evt : Event = null) : Void{
		if ((Std.is(currentTool, ObjectTransformer) && !(try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).getSelection())) {
			// User clicked away from the object transformer, so bake it in.
			bakeIntoBitmap();
			saveToCostume();
		}
		
		var cropToolEnabled : Bool = (Std.is(currentTool, ObjectTransformer) && !!(try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).getSelection());
		imagesPart.setCanCrop(cropToolEnabled);
	}
	
	public function cropToSelection() : Void{
		var sel : Selection;
		var transformTool : ObjectTransformer = try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null;
		if (transformTool != null) {
			sel = transformTool.getSelection();
		}
		if (sel != null) {
			var bm : BitmapData = workArea.getBitmap().bitmapData;
			bm.fillRect(bm.rect, 0);
			app.runtime.shiftIsDown = false;
			bakeIntoBitmap(false);
		}
	}
	
	public function deletingSelection() : Void{
		if (app.runtime.shiftIsDown) {
			cropToSelection();
		}
	}
	
	// -----------------------------
	// Load and Save Costume
	//------------------------------
	
	override private function loadCostume(c : ScratchCostume) : Void{
		var bm : BitmapData = workArea.getBitmap().bitmapData;
		bm.fillRect(bm.rect, bgColor());  // clear  
		
		var scale : Float = 2 / c.bitmapResolution;
		var costumeBM : BitmapData = c.bitmapForEditor(isScene);
		var destP : Point = (isScene) ? 
		new Point(0, 0) : 
		new Point(480 - (scale * c.rotationCenterX), 360 - (scale * c.rotationCenterY));
		bm.copyPixels(costumeBM, costumeBM.rect, destP);
		if (c.undoList.length == 0) {
			recordForUndo(costumeBM, (scale * c.rotationCenterX), (scale * c.rotationCenterY));
		}
	}
	
	override public function addCostume(c : ScratchCostume, destP : Point) : Void{
		var el : SVGElement = SVGElement.makeBitmapEl(c.bitmapForEditor(isScene), 0.5);
		var sel : SVGBitmap = new SVGBitmap(el, el.bitmap);
		sel.redraw();
		sel.x = destP.x - c.width() / 2;
		sel.y = destP.y - c.height() / 2;
		workArea.getContentLayer().addChild(sel);
		
		setToolMode("bitmapSelect");
		(try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).select(new Selection([sel]));
	}
	
	override public function saveContent(evt : Event = null) : Void{
		// Note: Don't save when there is an active selection or in text entry mode.
		if (Std.is(currentTool, ObjectTransformer)) 			return;
		if (Std.is(currentTool, TextTool)) 			return  // should select the text so it can be manipulated  ;
		bakeIntoBitmap();
		saveToCostume();
	}
	
	private function saveToCostume() : Void{
		// Note: Although the bitmap is double resolution, the rotation center is not doubled,
		// since it is applied to the costume after the bitmap has been scaled down.
		var c : ScratchCostume = targetCostume;
		var bm : BitmapData = workArea.getBitmap().bitmapData;
		if (isScene) {
			c.setBitmapData(bm.clone(), bm.width / 2, bm.height / 2);
		}
		else {
			var r : Rectangle = bm.getColorBoundsRect(0xFF000000, 0, false);
			var newBM : BitmapData;
			if (r.width >= 1 && r.height >= 1) {
				newBM = new BitmapData(r.width, r.height, true, 0);
				newBM.copyPixels(bm, r, new Point(0, 0));
				c.setBitmapData(newBM, Math.floor(480 - r.x), Math.floor(360 - r.y));
			}
			else {
				newBM = new BitmapData(2, 2, true, 0);  // empty bitmap  
				c.setBitmapData(newBM, 0, 0);
			}
		}
		recordForUndo(c.baseLayerBitmap.clone(), c.rotationCenterX, c.rotationCenterY);
		Scratch.app.setSaveNeeded();
	}
	
	override public function setToolMode(newMode : String, bForce : Bool = false, fromButton : Bool = false) : Void{
		imagesPart.setCanCrop(false);
		highlightTool("none");
		var obj : ISVGEditable = null;
		if (newMode != toolMode && Std.is(currentTool, SVGEditTool)) 
			obj = (try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).getObject();
		
		var prevToolMode : String = toolMode;
		super.setToolMode(newMode, bForce, fromButton);
		
		if (obj != null) {
			if (!(Std.is(currentTool, ObjectTransformer))) {
				// User was editing an object and switched tools, bake the object
				bakeIntoBitmap();
				saveToCostume();
			}
		}
	}
	
	private function createdObjectIsEmpty() : Bool{
		// Return true if the created object is empty (i.e. the user clicked without moving the mouse).
		var content : Sprite = workArea.getContentLayer();
		if (content.numChildren == 1) {
			var svgShape : SVGShape = try cast(content.getChildAt(0), SVGShape) catch(e:Dynamic) null;
			if (svgShape != null) {
				var el : SVGElement = svgShape.getElement();
				var attr : Dynamic = el.attributes;
				if (el.tag == "ellipse") {
					if (!attr.rx || (attr.rx < 1)) 						return true;
					if (!attr.ry || (attr.ry < 1)) 						return true;
				}
				if (el.tag == "rect") {
					if (!attr.width || (attr.width < 1)) 						return true;
					if (!attr.height || (attr.height < 1)) 						return true;
				}
			}
		}
		return false;
	}
	
	private function bakeIntoBitmap(doClear : Bool = true) : Void{
		// Render any content objects (text, circle, rectangle, line) into my bitmap.
		// Note: Must do this at low quality setting to avoid antialiasing.
		var content : Sprite = workArea.getContentLayer();
		if (content.numChildren == 0) 			return  // nothing to bake in  ;
		var bm : BitmapData = workArea.getBitmap().bitmapData;
		if (bm != null && (content.numChildren > 0)) {
			var m : Matrix = new Matrix();
			m = content.getChildAt(0).transform.matrix.clone();
			m.scale(2, 2);
			var oldQuality : String = stage.quality;
			if (!Scratch.app.runtime.shiftIsDown) 				stage.quality = StageQuality.LOW;
			for (i in 0...content.numChildren){
				var el : DisplayObject = try cast(content.getChildAt(i), DisplayObject) catch(e:Dynamic) null;
				var textEl : SVGTextField = try cast(el, SVGTextField) catch(e:Dynamic) null;
				if (textEl != null && !Scratch.app.runtime.shiftIsDown) {
					// Even in LOW quality mode, text is anti-aliased.
					// This code forces it to have sharp edges for ease of using the paint bucket.
					var threshold : Int = 0x60 << 24;
					var c : Int = 0xFF000000 | textEl.textColor;
					clearOffscreenBM();
					offscreenBM.draw(el, m, null, null, null, true);
					// force pixels above threshold to be text color, alpha 1.0
					offscreenBM.threshold(
							offscreenBM, offscreenBM.rect, new Point(0, 0),
							">", threshold, c, 0xFF000000, false);
					// force pixels below threshold to be transparent
					offscreenBM.threshold(
							offscreenBM, offscreenBM.rect, new Point(0, 0),
							"<=", threshold, 0, 0xFF000000, false);
					// copy result into work bitmap
					bm.draw(offscreenBM);
				}
				else {
					bm.draw(el, m, null, null, null, true);
				}
			}
			stage.quality = oldQuality;
		}
		if (doClear) 			workArea.clearContent();
		stampMode = false;
	}
	
	private function clearOffscreenBM() : Void{
		var bm : BitmapData = workArea.getBitmap().bitmapData;
		if (offscreenBM == null ||
			(offscreenBM.width != bm.width) ||
			(offscreenBM.height != bm.height)) {
			offscreenBM = new BitmapData(bm.width, bm.height, true, 0);
			return;
		}
		offscreenBM.fillRect(offscreenBM.rect, 0);
	}
	
	// -----------------------------
	// Set costume center support
	//------------------------------
	
	override public function translateContents(x : Float, y : Float) : Void{
		var bm : BitmapData = workArea.getBitmap().bitmapData;
		var newBM : BitmapData = new BitmapData(bm.width, bm.height, true, 0);
		newBM.copyPixels(bm, bm.rect, new Point(Math.round(2 * x), Math.round(2 * y)));
		workArea.getBitmap().bitmapData = newBM;
	}
	
	// -----------------------------
	// Stamp and Flips
	//------------------------------
	
	private function addStampTool() : Void{
		var buttonSize : Point = new Point(37, 33);
		var lastTool : DisplayObject = toolButtonsLayer.getChildAt(toolButtonsLayer.numChildren - 1);
		var btn : IconButton = new IconButton(
		stampBitmap, 
		SoundsPart.makeButtonImg("bitmapStamp", true, buttonSize), 
		SoundsPart.makeButtonImg("bitmapStamp", false, buttonSize));
		btn.x = 0;
		btn.y = lastTool.y + lastTool.height + 4;
		SimpleTooltips.add(btn, {
					text : "Select and duplicate",
					direction : "right",

				});
		registerToolButton("bitmapStamp", btn);
		toolButtonsLayer.addChild(btn);
	}
	
	private function stampBitmap(ignore : Dynamic) : Void{
		setToolMode("bitmapBrush");
		setToolMode("bitmapSelect");
		highlightTool("bitmapStamp");
		stampMode = true;
	}
	
	override private function flipAll(vertical : Bool) : Void{
		var oldBM : BitmapData = workArea.getBitmap().bitmapData;
		var newBM : BitmapData = new BitmapData(oldBM.width, oldBM.height, true, 0);
		var m : Matrix = new Matrix();
		if (vertical) {
			m.scale(1, -1);
			m.translate(0, oldBM.height);
		}
		else {
			m.scale(-1, 1);
			m.translate(oldBM.width, 0);
		}
		newBM.draw(oldBM, m);
		workArea.getBitmap().bitmapData = newBM;
		saveToCostume();
	}
	
	private function getBitmapSelection() : SVGBitmap{
		var content : Sprite = workArea.getContentLayer();
		for (i in 0...content.numChildren){
			var svgBM : SVGBitmap = try cast(content.getChildAt(i), SVGBitmap) catch(e:Dynamic) null;
			if (svgBM != null) 				return svgBM;
		}
		return null;
	}
	
	// -----------------------------
	// Grow/Shrink Tool Support
	//------------------------------
	
	public function scaleAll(scale : Float) : Void{
		var bm : BitmapData = workArea.getBitmap().bitmapData;
		var r : Rectangle = (isScene) ? 
		bm.getColorBoundsRect(0xFFFFFFFF, 0xFFFFFFFF, false) : 
		bm.getColorBoundsRect(0xFF000000, 0, false);
		var newBM : BitmapData = new BitmapData(Math.max(1, r.width * scale), Math.max(1, r.height * scale), true, bgColor());
		var m : Matrix = new Matrix();
		m.translate(-r.x, -r.y);
		m.scale(scale, scale);
		newBM.draw(bm, m);
		var destP : Point = new Point(r.x - ((r.width * (scale - 1)) / 2), r.y - ((r.height * (scale - 1)) / 2));
		bm.fillRect(bm.rect, bgColor());
		bm.copyPixels(newBM, newBM.rect, destP);
		saveToCostume();
	}
	
	// -----------------------------
	// Clear/Undo/Redo
	//------------------------------
	
	override public function canClearCanvas() : Bool{
		// True if canvas has any marks.
		var bm : BitmapData = workArea.getBitmap().bitmapData;
		var r : Rectangle = bm.getColorBoundsRect(0xFFFFFFFF, bgColor(), false);
		return (r.width > 0) && (r.height > 0);
	}
	
	override public function clearCanvas(ignore : Dynamic = null) : Void{
		setToolMode("bitmapBrush");
		var bm : BitmapData = workArea.getBitmap().bitmapData;
		bm.fillRect(bm.rect, bgColor());
		super.clearCanvas();
	}
	
	private function bgColor() : Int{return (isScene) ? 0xFFFFFFFF : 0;
	}
	
	override private function restoreUndoState(undoRec : Array<Dynamic>) : Void{
		var c : ScratchCostume = targetCostume;
		c.setBitmapData(undoRec[0], undoRec[1], undoRec[2]);
		loadCostume(c);
	}
}

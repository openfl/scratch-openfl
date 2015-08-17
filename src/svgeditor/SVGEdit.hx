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

package svgeditor;

import svgeditor.DisplayObject;
import svgeditor.Event;
import svgeditor.ISVGEditable;
import svgeditor.KeyboardEvent;
import svgeditor.SVGExport;
import svgeditor.SVGImporter;
import svgeditor.Scratch;
import svgeditor.Selection;
import svgeditor.Timer;
import svgeditor.TimerEvent;

import flash.display.*;
import flash.events.*;
import flash.filters.GlowFilter;
import flash.geom.*;
import flash.text.*;
import flash.utils.*;

import scratch.ScratchCostume;

import svgeditor.*;
import svgeditor.objs.*;
import svgeditor.tools.*;

import svgutils.*;

import ui.parts.ImagesPart;

import uiwidgets.*;

class SVGEdit extends ImageEdit {
	public static var tools : Array<Dynamic> = [
		{
			name : "select",
			desc : "Select",

		}, 
		{
			name : "pathedit",
			desc : "Reshape",

		}, 
		null,   // Space  
		{
			name : "path",
			desc : "Pencil",

		}, 
		{
			name : "vectorLine",
			desc : "Line",

		}, 
		{
			name : "vectorRect",
			desc : "Rectangle",
			shiftDesc : "Square",

		}, 
		{
			name : "vectorEllipse",
			desc : "Ellipse",
			shiftDesc : "Circle",

		}, 
		{
			name : "text",
			desc : "Text",

		}, 
		null,   // Space  
		{
			name : "vpaintbrush",
			desc : "Color a shape",

		}, 
		{
			name : "clone",
			desc : "Duplicate",
			shiftDesc : "Multiple",

		}, 
		null,   // Space  
		{
			name : "front",
			desc : "Forward a layer",
			shiftDesc : "Bring to front",

		}, 
		{
			name : "back",
			desc : "Back a layer",
			shiftDesc : "Send to back",

		}, 
		{
			name : "group",
			desc : "Group",

		}, 
		{
			name : "ungroup",
			desc : "Ungroup",

		}];
	
	private static var immediateTools : Array<Dynamic> = ["back", "front", "group", "ungroup", "noZoom", "zoomOut"];
	private static var bmptoolist : Array<Dynamic> = ["wand", "lasso", "slice"];
	private static var unimplemented : Array<Dynamic> = ["wand", "lasso", "slice"];
	
	public function new(app : Scratch, imagesPart : ImagesPart)
	{
		super(app, imagesPart);
		
		PathEndPointManager.init(this);
		setToolMode("path");
	}
	
	override private function getToolDefs() : Array<Dynamic>{return tools;
	}
	override private function getImmediateToolList() : Array<Dynamic>{return immediateTools;
	}
	
	override private function selectHandler(event : Event = null) : Void{
		// Send ShapeProperties to the ShapePropertiesUI
		//if(toolMode != 'select') return;
		
		// Reset the smoothness ui
		drawPropsUI.showSmoothnessUI(false);
		
		var objs : Array<Dynamic> = [];
		var isGroup : Bool = false;
		if (Std.is(currentTool, ObjectTransformer)) {
			var s : Selection = (Std.is(currentTool, (ObjectTransformer) ? (try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).getSelection() : null));
			if (s != null) {
				objs = s.getObjs();
				isGroup = s.isGroup();
			}
		}
		else if (Std.is(currentTool, SVGEditTool)) {
			var obj : ISVGEditable = (try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).getObject();
			if (obj != null) {
				objs.push(obj);
				drawPropsUI.showSmoothnessUI((Std.is(obj, SVGShape)), false);
				if (Std.is(obj, SVGTextField)) {
					drawPropsUI.updateFontUI(obj.getElement().getAttribute("font-family"));
				}
			}
		}
		
		lastShape = null;
		if (objs.length == 1) {
							updateShapeUI(objs[0]);
						}(try cast(Reflect.field(toolButtons, "group"), IconButton) catch(e:Dynamic) null).setDisabled(objs.length < 2)  // Toggle the group/ungroup buttons depending on the selection  ;
		(try cast(Reflect.field(toolButtons, "ungroup"), IconButton) catch(e:Dynamic) null).setDisabled(!objs.length || !isGroup);
		(try cast(Reflect.field(toolButtons, "front"), IconButton) catch(e:Dynamic) null).setDisabled(!objs.length);
		(try cast(Reflect.field(toolButtons, "back"), IconButton) catch(e:Dynamic) null).setDisabled(!objs.length);
	}
	
	override public function setWidthHeight(w : Int, h : Int) : Void{
		super.setWidthHeight(w, h);
		toolButtonsLayer.x = w - 25;
	}
	
	private var smoothValue : Float = 20;
	private var lastShape : SVGShape = null;
	public function smoothStroke() : Void{
		var smoothed : Bool = false;
		if (Std.is(currentTool, SVGEditTool)) {
			var shape : SVGShape = try cast((try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).getObject(), SVGShape) catch(e:Dynamic) null;
			if (shape != null) {
				if (shape == lastShape) {
					// Don't go over 40
					smoothValue = Math.min(35, smoothValue + 5);
				}
				else smoothValue = 20;
				
				shape.smoothPath2(smoothValue);
				saveContent();
				currentTool.refresh();
				lastShape = shape;
				smoothed = true;
			}
		}
		
		if (!smoothed) 			lastShape = null;
	}
	
	private function showPanel(panel : Sprite) : Void{
		//panel.fixLayout();
		var dx : Int = (w - panel.width) / 2;
		var dy : Int = (h - panel.height) / 2;
		panel.x = dx;
		panel.y = dy;
		addChild(panel);
	}
	
	override private function runImmediateTool(name : String, shiftKey : Bool, s : Selection) : Void{
		if (!(Std.is(currentTool, ObjectTransformer)) || s == null) 			return;
		
		var bSave : Bool = true;
		switch (name) {
			case "front":
				s.raise(shiftKey);
			case "back":
				s.lower(shiftKey);
			case "group":
				// Highlight the grouped elements
				highlightElements(s, false);
				
				s = s.group();
				(try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).select(null);
				(try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).select(s);
			case "ungroup":
				s = s.ungroup();
				
				// Highlight the separated elements
				highlightElements(s, true);
				
				(try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).select(null);
			default:
				bSave = false;
		}
		
		if (bSave) 			saveContent();
	}
	
	override private function onColorChange(e : Event) : Void{
		if (Std.is(currentTool, SVGEditTool) && (toolMode != "select") && (toolMode != "text")) {
			var obj : ISVGEditable = (try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).getObject();
			if (obj != null) {
				var el : SVGElement = obj.getElement();
				el.setAttribute("stroke-width", drawPropsUI.settings.strokeWidth);
				//el.applyShapeProps(drawPropsUI.settings);
				obj.redraw();
				saveContent();
			}
		}
		else {
			super.onColorChange(e);
		}
	}
	
	override private function stageKeyDownHandler(event : KeyboardEvent) : Bool{
		if (!super.stageKeyDownHandler(event)) {
			// Press 's' to smooth a shape
			if (event.keyCode == 83) {
				smoothStroke();
			}
		}
		return false;
	}
	
	private function highlightElements(s : Selection, separating : Bool) : Void{
		if (!separating) 			return;
		
		var t : Timer = new Timer(20, 25);
		var maxStrength : UInt = 12;
		t.addEventListener(TimerEvent.TIMER, function(e : TimerEvent) : Void{
					var strength : Float = maxStrength * (1 - t.currentCount / t.repeatCount);
					var dist : Float = 6 + strength * 0.5;
					strength += 2;
					var filters : Array<Dynamic> = [new GlowFilter(0xFFFFFF, (1 - t.currentCount / t.repeatCount), dist, dist, strength), new GlowFilter(0x28A5DA)];
					for (dObj/* AS3HX WARNING could not determine type for var: dObj exp: ECall(EField(EIdent(s),getObjs),[]) type: null */ in s.getObjs())
					dObj.filters = filters;
					
					if (t.currentCount == t.repeatCount) 
						t.removeEventListener(TimerEvent.TIMER, arguments.callee);
					
					e.updateAfterEvent();
				});
		
		t.addEventListener(TimerEvent.TIMER_COMPLETE, function(e : TimerEvent) : Void{
					t.removeEventListener(TimerEvent.TIMER_COMPLETE, arguments.callee);
					t.stop();
					t = null;
					//s.toggleHighlight(false);
					
					var filters : Array<Dynamic> = [];
					for (dObj/* AS3HX WARNING could not determine type for var: dObj exp: ECall(EField(EIdent(s),getObjs),[]) type: null */ in s.getObjs())
					dObj.filters = filters;
				});
		t.start();
	}
	
	// -----------------------------
	// Flipping
	//------------------------------
	override private function flipAll(vertical : Bool) : Void{
		//var anchorPt:Point = new Point(targetCostume.rotationCenterX, targetCostume.rotationCenterY);
		
		var cl : Sprite = workArea.getContentLayer();
		if (cl.numChildren == 0) 			return;
		
		var objs : Array<Dynamic> = new Array<Dynamic>(cl.numChildren);
		for (i in 0...cl.numChildren){objs[i] = cl.getChildAt(i);
		}
		
		var s : Selection = new Selection(objs);
		s.flip(vertical);
		s.shutdown();
		saveContent();
	}
	
	override public function stamp() : Void{
		setToolMode("clone");
	}
	
	//---------------------------------
	// Costume edit and save
	//---------------------------------
	
	override private function loadCostume(c : ScratchCostume) : Void{
		workArea.clearContent();
		
		if (c.isBitmap()) {
			insertBitmap(c.baseLayerBitmap.clone(), c.costumeName, true, targetCostume.rotationCenterX, targetCostume.rotationCenterY);
			insertOldTextLayer();
		}
		else {
			if (targetCostume.undoList.length == 0) 				recordForUndo(c.baseLayerData, c.rotationCenterX, c.rotationCenterY);
			installSVGData(c.baseLayerData, c.rotationCenterX, c.rotationCenterY);
		}
		imagesPart.refreshUndoButtons();
		
		// set the initial tool
		if (toolMode == "select" || (c.svgRoot && c.svgRoot.subElements.length && (!isScene || c.svgRoot.subElements.length > 1))) 
			setToolMode("select", true);
	}
	
	override public function addCostume(c : ScratchCostume, destP : Point) : Void{
		var p : Point = new Point(ImageCanvas.canvasWidth / 2, ImageCanvas.canvasHeight / 2);
		p = p.subtract(destP);
		p = p.add(new Point(c.rotationCenterX, c.rotationCenterY));
		if (c.isBitmap()) {
			insertBitmap(c.baseLayerBitmap.clone(), c.costumeName, false, p.x, p.y);
			insertOldTextLayer();
		}
		else {
			installSVGData(c.baseLayerData, Math.round(p.x), Math.round(p.y), true);
		}
		saveContent();
	}
	
	private function insertBitmap(bm : BitmapData, name : String, isLoad : Bool, destX : Float, destY : Float) : Void{
		// Insert the given bitmap.
		if (!bm.transparent) {  // convert to a 32-bit bitmap to support alpha (e.g. eraser tool)  
			var newBM : BitmapData = new BitmapData(bm.width, bm.height, true, 0);
			newBM.copyPixels(bm, bm.rect, new Point(0, 0));
			bm = newBM;
		}
		if (isLoad) 			saveInitialBitmapForUndo(bm, name);
		var imgEl : SVGElement = new SVGElement("image", name);
		imgEl.bitmap = bm;
		imgEl.setAttribute("x", 0);
		imgEl.setAttribute("y", 0);
		imgEl.setAttribute("width", bm.width);
		imgEl.setAttribute("height", bm.height);
		if (!isScene) {
			var xOffset : Int = Math.ceil(ImageCanvas.canvasWidth / 2 - destX);
			var yOffset : Int = Math.ceil(ImageCanvas.canvasHeight / 2 - destY);
			imgEl.transform = new Matrix();
			imgEl.transform.translate(xOffset, yOffset);
		}
		var bmp : SVGBitmap = new SVGBitmap(imgEl);
		bmp.redraw();
		workArea.getContentLayer().addChild(bmp);
	}
	
	private function insertOldTextLayer() : Void{
		if (!targetCostume.text) 			return  // no text layer  ;
		
		var textX : Int = targetCostume.textRect.x;
		var textY : Int = targetCostume.textRect.y;
		if (!isScene) {
			textX += (ImageCanvas.canvasWidth / 2) - targetCostume.rotationCenterX;
			textY += (ImageCanvas.canvasHeight / 2) - targetCostume.rotationCenterY;
		}  // It's fairly close for Helvetica Bold, the default font in Scratch 1.4.    // Not really possible to get this right for all fonts/size.    // the fact that the y-origin for SVG text is the baseline.    // Approximate adjustment for Squeak text placement differences and  
		
		
		
		
		
		
		
		
		
		var tf : TextField = new TextField();
		tf.defaultTextFormat = new TextFormat("Helvetica", targetCostume.fontSize);
		textX += 5;
		textY += Math.round(0.9 * tf.getLineMetrics(0).ascent);
		
		var textEl : SVGElement = new SVGElement("text");
		textEl.text = targetCostume.text;
		textEl.setAttribute("font-family", "Helvetica");
		textEl.setAttribute("font-weight", "bold");
		textEl.setAttribute("font-size", targetCostume.fontSize);
		textEl.setAttribute("stroke", SVGElement.colorToHex(targetCostume.textColor & 0xFFFFFF));
		textEl.setAttribute("text-anchor", "start");
		textEl.transform = new Matrix(1, 0, 0, 1, textX, textY);
		
		var svgText : SVGTextField = new SVGTextField(textEl);
		svgText.redraw();
		workArea.getContentLayer().addChild(svgText);
		
		// Wrap the text
		var maxWidth : Float = 480 - svgText.x;
		var text : String = textEl.text;
		var firstChar : UInt = 0;
		svgText.text = "";
		for (i in 0...text.length){
			svgText.text += text.charAt(i);
			if (svgText.textWidth > maxWidth) {
				var j : UInt = i;
				while (j > firstChar){
					var c : String = text.charAt(j);
					if (c.match(new EReg('\\s', "")) != null) {
						var curText : String = svgText.text;
						svgText.text = curText.substring(0, j) + "\n" + curText.substring(j + 1);
						firstChar = j + 1;
						break;
					}
					--j;
				}
			}
		}
		textEl.text = svgText.text;
		svgText.redraw();
	}
	
	private function installSVGData(data : ByteArray, rotationCenterX : Int, rotationCenterY : Int, isInsert : Bool = false) : Void{
		function imagesLoaded(rootElem : SVGElement) : Void{
			if (isInsert) {
				var origChildren : Array<Dynamic> = [];
				var contentLayer : Sprite = workArea.getContentLayer();
				while (contentLayer.numChildren)origChildren.push(contentLayer.removeChildAt(0));
			}
			
			Renderer.renderToSprite(workArea.getContentLayer(), rootElem);
			if (!isScene) {
				var xOffset : Int = Math.ceil((ImageCanvas.canvasWidth / 2) - rotationCenterX);
				var yOffset : Int = Math.ceil((ImageCanvas.canvasHeight / 2) - rotationCenterY);
				translateContents(xOffset, yOffset);
			}
			
			if (isInsert) {
				while (origChildren.length)contentLayer.addChildAt(origChildren.pop(), 0);
			}
		};
		
		if (!isInsert) 			workArea.clearContent();
		
		var importer : SVGImporter = new SVGImporter(cast((data), XML));
		importer.loadAllImages(imagesLoaded);
	}
	
	override public function saveContent(E : Event = null) : Void{
		var contentLayer : Sprite = workArea.getContentLayer();
		var svgData : ByteArray;
		
		if (isScene) {
			// save the contentLayer without shifting
			svgData = convertToSVG(contentLayer);
			targetCostume.setSVGData(svgData, false);
		}
		else {
			// shift costume contents back to (0, 0) before saving SVG data, then shift back to center
			var r : Rectangle = contentLayer.getBounds(contentLayer);
			var offsetX : Int = Math.floor(r.x);
			var offsetY : Int = Math.floor(r.y);
			
			translateContents(-offsetX, -offsetY);
			svgData = convertToSVG(contentLayer);
			targetCostume.setSVGData(svgData, false);
			translateContents(offsetX, offsetY);
			targetCostume.rotationCenterX = ImageCanvas.canvasWidth / 2 - offsetX;
			targetCostume.rotationCenterY = ImageCanvas.canvasHeight / 2 - offsetY;
			app.viewedObj().updateCostume();
		}
		recordForUndo(svgData, targetCostume.rotationCenterX, targetCostume.rotationCenterY);
		app.setSaveNeeded();
	}
	
	override public function canClearCanvas() : Bool{
		return workArea.getContentLayer().numChildren > 0;
	}
	
	override public function clearCanvas(ignore : Dynamic = null) : Void{
		if (isScene) {
			targetCostume.baseLayerData = ScratchCostume.emptyBackdropSVG();
			installSVGData(targetCostume.baseLayerData, targetCostume.rotationCenterX, targetCostume.rotationCenterY);
		}
		else {
			workArea.clearContent();
		}
		
		super.clearCanvas(ignore);
	}
	
	override public function translateContents(xOffset : Float, yOffset : Float) : Void{
		var contentLayer : Sprite = workArea.getContentLayer();
		for (i in 0...contentLayer.numChildren){
			var obj : DisplayObject = contentLayer.getChildAt(i);
			if (Lambda.has(obj, "getElement")) {
				var m : Matrix = obj.transform.matrix || new Matrix();
				m.translate(xOffset, yOffset);
				obj.transform.matrix = m;
			}
		}
	}
	
	private function convertToSVG(contentLayer : Sprite) : ByteArray{
		var root : SVGElement = new SVGElement("svg", targetCostume.costumeName);
		for (i in 0...contentLayer.numChildren){
			var c : Dynamic = contentLayer.getChildAt(i);
			if (Lambda.has(c, "getElement")) 				root.subElements.push(c.getElement());
		}
		return new SVGExport(root).svgData();
	}
	
	private function saveInitialBitmapForUndo(bm : BitmapData, name : String) : Void{
		var root : SVGElement = new SVGElement("svg", name);
		
		var imgEl : SVGElement = new SVGElement("image", name);
		imgEl.bitmap = bm;
		imgEl.setAttribute("x", 0);
		imgEl.setAttribute("y", 0);
		imgEl.setAttribute("width", bm.width);
		imgEl.setAttribute("height", bm.height);
		root.subElements.push(imgEl);
		var svgData : ByteArray = new SVGExport(root).svgData();
		
		recordForUndo(svgData, targetCostume.rotationCenterX, targetCostume.rotationCenterY);
	}
	
	// -----------------------------
	// Undo/Redo
	//------------------------------
	
	override private function restoreUndoState(undoRec : Array<Dynamic>) : Void{
		var id : String = null;
		if (toolMode == "select") 
			setToolMode("select", true)
		else if (Std.is(currentTool, SVGEditTool) && (try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).getObject()) {
			id = (try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).getObject().getElement().id;
		}
		
		installSVGData(undoRec[0], undoRec[1], undoRec[2]);
		
		// Try to find the element that was being edited.
		if (id != null) {
			var obj : ISVGEditable = getElementByID(id);
			if (obj != null) {
				(try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).setObject(obj);
				currentTool.refresh();
			}
			else 
			(try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).setObject(null);
		}
	}
	
	private function getElementByID(id : String, layer : Sprite = null) : ISVGEditable{
		if (layer == null) 			layer = getContentLayer();
		for (i in 0...layer.numChildren){
			var c : Dynamic = layer.getChildAt(i);
			if (Std.is(c, SVGGroup)) {
				var obj : ISVGEditable = getElementByID(id, try cast(c, Sprite) catch(e:Dynamic) null);
				if (obj != null) 					return obj;
			}
			else if (Std.is(c, ISVGEditable) && (try cast(c, ISVGEditable) catch(e:Dynamic) null).getElement().id == id) {
				return try cast(c, ISVGEditable) catch(e:Dynamic) null;
			}
		}
		return null;
	}
}


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

//import svgeditor.Bitmap;
//import svgeditor.BitmapPencilTool;
//import svgeditor.CloneTool;
//import svgeditor.DisplayObject;
//import svgeditor.EllipseTool;
//import svgeditor.EraserTool;
//import svgeditor.Event;
//import svgeditor.EyeDropperTool;
//import svgeditor.ISVGEditable;
//import svgeditor.IconButton;
//import svgeditor.KeyboardEvent;
//import svgeditor.MouseEvent;
//import svgeditor.ObjectTransformer;
//import svgeditor.PaintBrushTool;
//import svgeditor.PaintBucketTool;
//import svgeditor.PathEditTool;
//import svgeditor.PathTool;
//import svgeditor.RectangleTool;
//import svgeditor.SVGEditTool;
//import svgeditor.SVGTool;
//import svgeditor.Scratch;
//import svgeditor.ScratchSprite;
//import svgeditor.Selection;
//import svgeditor.SetCenterTool;
//import svgeditor.Shape;
//import svgeditor.TextTool;

import assets.Resources;

import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.text.*;
import flash.ui.*;
import flash.utils.ByteArray;

import scratch.*;

import svgeditor.*;
import svgeditor.objs.*;
import svgeditor.tools.*;

import svgutils.*;

import translation.Translator;

import ui.media.MediaInfo;
import ui.parts.ImagesPart;

import uiwidgets.*;

import util.ProjectIO;

class ImageEdit extends Sprite {
	
	public var app : Scratch;
	public var imagesPart : ImagesPart;
	public var targetCostume : ScratchCostume;
	public var isScene : Bool;
	
	private var toolMode : String;
	private var lastToolMode : String;
	private var currentTool : SVGTool;
	private var drawPropsUI : DrawPropertyUI;
	private var toolButtons : Dynamic;
	private var toolButtonsLayer : Sprite;
	private var w : Int;private var h : Int;
	private var workArea : ImageCanvas;
	
	private var uiLayer : Sprite;
	private var toolsLayer : Sprite;
	private var svgEditorMask : Shape;
	private var currentCursor : String;
	
	public function new(app : Scratch, imagesPart : ImagesPart)
	{
		super();
		this.app = app;
		this.imagesPart = imagesPart;
		
		// Create the layers from back to front
		toolsLayer = new Sprite();
		workArea = new ImageCanvas(100, 100, this);
		addChild(workArea);
		addChild(toolsLayer);
		addChild(uiLayer = new Sprite());
		
		svgEditorMask = new Shape();
		mask = svgEditorMask;
		addChild(svgEditorMask);
		
		toolButtons = new Dynamic();
		toolButtonsLayer = new Sprite();
		uiLayer.addChild(toolButtonsLayer);
		
		app.stage.addEventListener(KeyboardEvent.KEY_DOWN, stageKeyDownHandler, false, 0, true);
		workArea.getContentLayer().addEventListener(MouseEvent.MOUSE_OVER, workAreaMouseHandler);
		workArea.getContentLayer().addEventListener(MouseEvent.MOUSE_OUT, workAreaMouseHandler);
		
		createTools();
		addDrawPropsUI();
		
		// Set default shape properties
		var initialColors : DrawProperties = new DrawProperties();
		initialColors.color = 0xFF000000;
		initialColors.strokeWidth = 2;
		initialColors.eraserWidth = initialColors.strokeWidth * 4;
		initialColors.filledShape = (Std.is(this, BitmapEdit));
		drawPropsUI.updateUI(initialColors);
		
		selectHandler();
	}
	
	public static function strings() : Array<Dynamic>{
		var result : Array<Dynamic> = ["Shift:", "Select and duplicate"];
		var toolEntries : Array<Dynamic> = SVGEdit.tools.concat(BitmapEdit.bitmapTools);
		for (entry in toolEntries){
			if (entry != null) {
				if (entry.desc) 					result.push(entry.desc);
				if (entry.shiftDesc) 					result.push(entry.shiftDesc);
			}
		}
		return result;
	}
	
	public function editingScene() : Bool{return isScene;
	}
	public function getCanvasLayer() : Sprite{return workArea.getInteractionLayer();
	}
	public function getContentLayer() : Sprite{return workArea.getContentLayer();
	}
	public function getShapeProps() : DrawProperties{return drawPropsUI.settings;
	}
	public function setShapeProps(props : DrawProperties) : Void{drawPropsUI.settings = props;
	}
	public function getStrokeSmoothness() : Float{return drawPropsUI.getStrokeSmoothness();
	}
	public function getToolsLayer() : Sprite{return toolsLayer;
	}
	public function getWorkArea() : ImageCanvas{return workArea;
	}
	
	public function handleDrop(obj : Dynamic) : Bool{
		function insertCostume(c : ScratchCostume) : Void{addCostume(c, dropPoint);
		};
		function insertSprite(spr : ScratchSprite) : Void{addCostume(spr.currentCostume(), dropPoint);
		};
		var dropPoint : Point;
		var item : MediaInfo = try cast(obj, MediaInfo) catch(e:Dynamic) null;
		if (item != null) {
			dropPoint = workArea.getContentLayer().globalToLocal(new Point(stage.mouseX, stage.mouseY));
			var projIO : ProjectIO = new ProjectIO(app);
			if (item.mycostume) 				insertCostume(item.mycostume)
			else if (item.mysprite) 				insertSprite(item.mysprite)
			else if ("image" == item.objType) 				projIO.fetchImage(item.md5, item.objName, item.objWidth, insertCostume)
			else if ("sprite" == item.objType) 				projIO.fetchSprite(item.md5, insertSprite);
			return true;
		}
		return false;
	}
	
	public function refreshCurrentTool() : Void{
		if (currentTool != null) 			currentTool.refresh();
	}
	
	private function selectHandler(event : Event = null) : Void{
	}
	
	private function workAreaMouseHandler(event : MouseEvent) : Void{
		if (event.type == MouseEvent.MOUSE_OVER && currentCursor != null) {
			CursorTool.setCustomCursor(currentCursor);
		}
		else {
			CursorTool.setCustomCursor(MouseCursor.AUTO);
		}  // Capture mouse down before anyone else in case there is a global tool running  
		
		
		
		if (event.type == MouseEvent.MOUSE_OVER && CursorTool.tool) 
			workArea.getContentLayer().addEventListener(MouseEvent.MOUSE_DOWN, workAreaMouseDown, true, 1, true)
		else 
		workArea.getContentLayer().removeEventListener(MouseEvent.MOUSE_DOWN, workAreaMouseDown);
	}
	
	private var globalToolObject : ISVGEditable;
	private function workAreaMouseDown(event : MouseEvent) : Void{
		if (!CursorTool.tool) {
			globalToolObject = null;
			return;
		}  // raw bitmap, only on the selected marquee (sub-bitmap?)    // BitmapEdit will have to make sure that you can't use the global tools on the  
		
		
		
		
		
		var editable : ISVGEditable = SVGTool.staticGetEditableUnderMouse(this);
		if (editable != null) {
			var obj : DisplayObject = try cast(editable, DisplayObject) catch(e:Dynamic) null;
			if (CursorTool.tool == "grow" || CursorTool.tool == "shrink") {
				var rect : Rectangle = obj.getBounds(obj);
				var center : Point = obj.parent.globalToLocal(obj.localToGlobal(Point.interpolate(rect.topLeft, rect.bottomRight, 0.5)));
				
				var m : Matrix = obj.transform.matrix.clone();
				if (CursorTool.tool == "grow") 
					m.scale(1.05, 1.05)
				else 
				m.scale(0.95, 0.95);
				obj.transform.matrix = m;
				
				rect = obj.getBounds(obj);
				var ofs : Point = center.subtract(obj.parent.globalToLocal(obj.localToGlobal(Point.interpolate(rect.topLeft, rect.bottomRight, 0.5))));
				obj.x += ofs.x;
				obj.y += ofs.y;
				(try cast(obj, ISVGEditable) catch(e:Dynamic) null).getElement();
				event.stopImmediatePropagation();
				workArea.addEventListener(MouseEvent.MOUSE_MOVE, workAreaMouseMove, false, 0, true);
				globalToolObject = editable;
			}
			else if (CursorTool.tool == "cut") {
				app.clearTool();
				// If we're removing the currently selected object then deselect it before removing it
				if (Std.is(currentTool, SVGEditTool) && (try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).getObject() == editable) 
					setToolMode("select", true);
				obj.parent.removeChild(obj);
			}
			else if (CursorTool.tool == "copy") {
				app.clearTool();
				setToolMode("clone", true);
				getCanvasLayer().dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
			}
			
			if (currentTool != null) 				currentTool.refresh();
			saveContent();
		}
		else {
			globalToolObject = null;
		}
	}
	
	public function setWidthHeight(w : Int, h : Int) : Void{
		// Adjust my size and layout to the given width and height.
		// Note: SVGEdit overrides this method to move the tools on the right side.
		this.w = w;
		this.h = h;
		
		var g : Graphics = svgEditorMask.graphics;
		g.clear();
		g.beginFill(0xF0F000);
		g.drawRect(0, 0, w, h + 5);
		g.endFill();
		
		drawPropsUI.setWidthHeight(w, 106);
		drawPropsUI.x = 0;
		drawPropsUI.y = h - drawPropsUI.height;
		
		var leftMargin : UInt = 44;
		var rightMargin : UInt = 30;
		workArea.resize(w - leftMargin - rightMargin, h - drawPropsUI.height - 12);
		workArea.x = leftMargin;
		
		refreshCurrentTool();
	}
	
	public function enableTools(enabled : Bool) : Void{
		uiLayer.mouseChildren = enabled;
		uiLayer.alpha = (enabled) ? 1.0 : 0.6;
		if (!enabled) {
			setToolMode("select");
		}
	}
	
	public function isActive() : Bool{
		// Return true if the editor is currently showing.
		if (!root) 			return false;  // Note: The editor is removed from the display tree when it is inactive.  ;
		if (CursorTool.tool) 			return false;
		return !app.mediaLibrary;
	}
	
	private var clipBoard : Dynamic;
	
	private function stageKeyDownHandler(event : KeyboardEvent) : Bool{
		if (!isActive()) 			return true;
		if (stage && (Std.is(stage.focus, TextField) ||
			(Std.is(stage.focus, SVGTextField) && (try cast(stage.focus, SVGTextField) catch(e:Dynamic) null).type == TextFieldType.INPUT))) 			return true;
		
		if (event.keyCode == 27) {
			// Maybe empty the selection when in BitmapEdit
			setToolMode("select");
			return true;
		}
		else if (toolMode != "select" && Std.is(currentTool, SVGEditTool) && (event.keyCode == Keyboard.DELETE || event.keyCode == Keyboard.BACKSPACE)) {
			// Delete the object being edited
			if (Std.is(this, BitmapEdit)) 				return true;
			
			var et : SVGEditTool = try cast(currentTool, SVGEditTool) catch(e:Dynamic) null;
			var dObj : DisplayObject = try cast(et.getObject(), DisplayObject) catch(e:Dynamic) null;
			if (dObj != null) {
				et.setObject(null);
				dObj.parent.removeChild(dObj);
				saveContent();
			}
			return true;
		}
		else if (event.keyCode == 90 && event.ctrlKey) {
			// Undo (ctrl-z) / Redo (ctrl-shift-z)
			if (event.shiftKey) 				redo()
			else undo();
		}
		else if (event.keyCode == 67 && event.ctrlKey) {
			var s : Selection = null;
			if (Std.is(currentTool, ObjectTransformer)) {
				s = (try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).getSelection();
			}
			else if (Std.is(currentTool, SVGEditTool)) {
				var obj : ISVGEditable = (try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).getObject();
				if (obj != null) 
					s = new Selection([obj]);
			}
			
			if (s != null) {
				clipBoard = s.cloneObjs(workArea.getContentLayer());
				return true;
			}
		}
		else if (event.keyCode == 86 && event.ctrlKey && Std.is(clipBoard, Array)) {
			endCurrentTool();
			setToolMode("clone");
			(try cast(currentTool, CloneTool) catch(e:Dynamic) null).pasteFromClipboard(clipBoard);
		}
		
		return false;
	}
	
	public function updateShapeUI(obj : ISVGEditable) : Void{
		if (Std.is(obj, SVGShape)) {
			var el : SVGElement = obj.getElement();
			var props : DrawProperties = drawPropsUI.settings;
			
			var stroke : String = el.getAttribute("stroke");
			props.strokeWidth = stroke == ("none") ? 0 : parseFloat(el.getAttribute("stroke-width"));
			
			// Don't try to update the current selection
			drawPropsUI.updateUI(props);
		}
	}
	
	// Must be overridden and return an array like this:
	/*[
	{ name: 'select',		desc: 'Select' },
	null, // Space
	{ name: 'path',			desc: 'Pencil' },
	]*/
	private function getToolDefs() : Array<Dynamic>{return [];
	}
	
	// May be overridden to return an array like this:
	/*['tool1', 'tool3']*/
	private function getImmediateToolList() : Array<Dynamic>{return [];
	}
	
	private function createTools() : Void{
		var space : Int = ((Std.is(this, BitmapEdit))) ? 4 : 2;  // normal space between buttons  
		var extraSpace : Int = ((Std.is(this, BitmapEdit))) ? 20 : 8;
		var buttonSize : Point = ((Std.is(this, BitmapEdit))) ? new Point(37, 33) : new Point(24, 22);
		var tools : Array<Dynamic> = getToolDefs();
		var immediateTools : Array<Dynamic> = getImmediateToolList();
		var ib : IconButton;
		var dy : Float = 0;
		var ttDirection : String = (Std.is(this, (SVGEdit) ? "left" : "right"));
		for (i in 0...tools.length){
			if (tools[i] == null) 				dy += extraSpace
			else {
				var toolName : String = tools[i].name;
				var isImmediate : Bool = (immediateTools && Lambda.indexOf(immediateTools, toolName) > -1);
				var iconName : String = toolName;
				if ("bitmapBrush" == toolName) 					iconName = "bitmapBrush";
				if ("bitmapEraser" == toolName) 					iconName = "eraser";
				if ("bitmapSelect" == toolName) 					iconName = "bitmapSelect";
				if ("ellipse" == toolName) 					iconName = "bitmapEllipse";
				if ("paintbucket" == toolName) 					iconName = "bitmapPaintbucket";
				if ("rect" == toolName) 					iconName = "bitmapRect";
				if ("text" == toolName) 					iconName = "bitmapText";
				
				ib = new IconButton(
						(isImmediate) ? handleImmediateTool : selectTool, 
						makeToolButton(iconName, true, buttonSize), 
						makeToolButton(iconName, false, buttonSize), 
						!isImmediate);
				registerToolButton(toolName, ib);
				ib.isMomentary = isImmediate;
				toolButtonsLayer.addChild(ib);
				ib.y = dy;
				
				// Group and ungroup are in the same location
				// Add data to the tools array to indicate this?
				if (toolName != "group") 
					dy += ib.height + space;
			}
		}
		updateTranslation();
	}
	
	public function updateTranslation() : Void{
		var direction : String = (Std.is(this, (SVGEdit) ? "left" : "right"));
		for (tool/* AS3HX WARNING could not determine type for var: tool exp: ECall(EIdent(getToolDefs),[]) type: null */ in getToolDefs()){
			if (tool == null) 				continue;
			var text : String = Translator.map(tool.desc);
			if (tool.shiftDesc) {
				text += " (" + Translator.map("Shift:") + " " + Translator.map(tool.shiftDesc) + ")";
			}
			SimpleTooltips.add(toolButtons[tool.name], {
						text : text,
						direction : direction,

					});
		}
		if (drawPropsUI != null) 			drawPropsUI.updateTranslation();
	}
	
	private function addDrawPropsUI() : Void{
		drawPropsUI = new DrawPropertyUI(this);
		drawPropsUI.x = 200;
		drawPropsUI.y = h - drawPropsUI.height - 40;
		drawPropsUI.addEventListener(DrawPropertyUI.ONCHANGE, onColorChange);
		drawPropsUI.addEventListener(DrawPropertyUI.ONFONTCHANGE, onFontChange);
		uiLayer.addChild(drawPropsUI);
	}
	
	public function registerToolButton(toolName : String, ib : IconButton) : Void{
		ib.name = toolName;
		Reflect.setField(toolButtons, toolName, ib);
	}
	
	public function translateContents(x : Float, y : Float) : Void{
	}
	
	public function handleImmediateTool(btn : IconButton) : Void{
		if (btn == null) 			return;
		
		var s : Selection = null;
		if (currentTool != null) {
			if (toolMode == "select") 
				s = (try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).getSelection()
			else if (Std.is(currentTool, SVGEditTool) && (try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).getObject()) 
				s = new Selection([(try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).getObject()]);
		}
		
		var shiftKey : Bool = (btn.lastEvent && btn.lastEvent.shiftKey);
		var p : Point = null;
		var _sw0_ = (btn.name);		

		switch (_sw0_) {
			case "zoomIn":
				var r : Rectangle = workArea.getVisibleLayer().getRect(stage);
				workArea.zoom(new Point(Math.round((r.right + r.left) / 2), Math.round((r.bottom + r.top) / 2)));
				
				// Center around the selection if we have one
				if (s != null) {
					r = s.getBounds(stage);
					workArea.centerAround(new Point(Math.round((r.right + r.left) / 2), Math.round((r.bottom + r.top) / 2)));
				}
				
				currentTool.refresh();
				if (Reflect.field(toolButtons, toolMode)) 					Reflect.field(toolButtons, toolMode).turnOn();
			case "zoomOut":
				workArea.zoomOut();
				currentTool.refresh();
				if (Reflect.field(toolButtons, toolMode)) 					Reflect.field(toolButtons, toolMode).turnOn();
			case "noZoom":
				workArea.zoom();
				currentTool.refresh();
				if (Reflect.field(toolButtons, toolMode)) 					Reflect.field(toolButtons, toolMode).turnOn();
			default:
				runImmediateTool(btn.name, shiftKey, s);
		}  // Shutdown temporary selection  
		
		
		
		if (toolMode != "select" && s != null) {
			s.shutdown();
		}
		
		btn.turnOff();
		if (btn.lastEvent) {
			btn.lastEvent.stopPropagation();
		}
	}
	
	private function runImmediateTool(name : String, shiftKey : Bool, s : Selection) : Void{
	}
	
	// Override in SVGEdit to add more logic
	private function onColorChange(e : Event) : Void{
		var sel : Selection;
		if (toolMode == "select") {
			sel = (try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).getSelection();
			if (sel != null) {
				sel.setShapeProperties(drawPropsUI.settings);
				currentTool.refresh();
				saveContent();
			}
			return;
		}
		if (toolMode == "eraser" && (Std.is(currentTool, EraserTool))) {
			(try cast(currentTool, EraserTool) catch(e:Dynamic) null).updateIcon();
		}
		if (Std.is(currentTool, ObjectTransformer)) {
			sel = (try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).getSelection();
			if (sel != null) 				sel.setShapeProperties(drawPropsUI.settings);
		}
		if (Std.is(currentTool, TextTool)) {
			var obj : ISVGEditable = (try cast(currentTool, TextTool) catch(e:Dynamic) null).getObject();
			if (obj != null) {
				obj.getElement().applyShapeProps(drawPropsUI.settings);
				obj.redraw();
			}
		}
	}
	
	private function onFontChange(e : Event) : Void{
		var sel : Selection;
		var obj : ISVGEditable;
		var fontName : String = drawPropsUI.settings.fontName;
		if (toolMode == "select") {
			sel = (try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).getSelection();
			if (sel != null) {
				for (obj/* AS3HX WARNING could not determine type for var: obj exp: ECall(EField(EIdent(sel),getObjs),[]) type: null */ in sel.getObjs()){
					if (Std.is(obj, SVGTextField)) 						obj.getElement().setFont(fontName);
					obj.redraw();
				}
			}
		}
		else if (Std.is(currentTool, TextTool)) {
			obj = (try cast(currentTool, TextTool) catch(e:Dynamic) null).getObject();
			if (obj != null) {
				obj.getElement().setFont(fontName);
				obj.redraw();
			}
		}
		currentTool.refresh();
		saveContent();
	}
	
	private function fromHex(s : String) : UInt{
		if (s == null) 			return 0
		else return UInt("0x" + s.substr(1));
	}
	
	public static function makeToolButton(str : String, b : Bool, buttonSize : Point = null) : Sprite{
		var bmp : Bitmap = ((b) ? Resources.createBmp(str + "On") : Resources.createBmp(str + "Off"));
		return buttonFrame(bmp, b, buttonSize);
	}
	
	public static function buttonFrame(bmp : DisplayObject, b : Bool, buttonSize : Point = null) : Sprite{
		var frameW : Int = (buttonSize != null) ? buttonSize.x : bmp.width;
		var frameH : Int = (buttonSize != null) ? buttonSize.y : bmp.height;
		
		var result : Sprite = new Sprite();
		var g : Graphics = result.graphics;
		g.clear();
		g.lineStyle(0.5, CSS.borderColor, 1, true);
		if (b) {
			g.beginFill(CSS.overColor, 0.7);
			bmp.alpha = 0.9;
		}
		else {
			var matr : Matrix = new Matrix();
			matr.createGradientBox(frameW, frameH, Math.PI / 2, 0, 0);
			g.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors, [100, 100], [0x00, 0xFF], matr);
		}
		g.drawRoundRect(0, 0, frameW, frameH, 8);
		g.endFill();
		
		bmp.x = (frameW - bmp.width) / 2;
		bmp.y = (frameH - bmp.height) / 2;
		
		result.addChild(bmp);
		return result;
	}
	
	private function selectTool(btn : IconButton) : Void{
		var newMode : String = ((btn != null) ? btn.name : "select");
		setToolMode(newMode, false, true);
		
		if (btn != null && btn.lastEvent) {
			btn.lastEvent.stopPropagation();
		}
	}
	
	public static var repeatedTools : Array<Dynamic> = ["rect", "ellipse", "vectorRect", "vectorEllipse", "text"];
	public static var selectionTools : Array<Dynamic> = ["select", "bitmapSelect"];
	
	public function setToolMode(newMode : String, bForce : Bool = false, fromButton : Bool = false) : Void{
		if (!fromButton && Lambda.indexOf(selectionTools, newMode) != -1 && Lambda.indexOf(repeatedTools, toolMode) != -1) {
			lastToolMode = toolMode;
		}
		else {
			if (lastToolMode != null) 				highlightTool(newMode);
			lastToolMode = "";
		}
		if (newMode == toolMode && !bForce) 			return;
		
		var toolChanged : Bool = true;  //!currentTool || (immediateTools.indexOf(newMode) == -1);  
		var s : Selection = null;
		if (currentTool != null) {
			if (toolMode == "select" && newMode != "select") 
				s = (try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).getSelection();  // If the next mode is not immediate, shut down the current tool  ;
			
			
			
			if (toolChanged) {
				if (currentTool.parent) 
					toolsLayer.removeChild(currentTool);
				
				if (Std.is(currentTool, SVGEditTool)) 
					currentTool.removeEventListener("select", selectHandler);
				
				currentTool.removeEventListener(Event.CHANGE, saveContent);
				currentTool = null;
				var btn : IconButton = Reflect.field(toolButtons, toolMode);
				if (btn != null) 					btn.turnOff();
				toolChanged = true;
			}
		}
		
		switch (newMode) {
			case "select":currentTool = new ObjectTransformer(this);
			case "pathedit":currentTool = new PathEditTool(this);
			case "path":currentTool = new PathTool(this);
			case "vectorLine", "line":currentTool = new PathTool(this, true);
			case "vectorEllipse", "ellipse":currentTool = new EllipseTool(this);
			case "vectorRect", "rect":currentTool = new RectangleTool(this);
			case "text":currentTool = new TextTool(this);
			case "eraser":currentTool = new EraserTool(this);
			case "clone":currentTool = new CloneTool(this);
			case "eyedropper":currentTool = new EyeDropperTool(this);
			case "vpaintbrush":currentTool = new PaintBrushTool(this);
			case "setCenter":currentTool = new SetCenterTool(this);
			// Add bitmap tools here....
			case "bitmapBrush":currentTool = new BitmapPencilTool(this, false);
			case "bitmapEraser":currentTool = new BitmapPencilTool(this, true);
			case "bitmapSelect":currentTool = new ObjectTransformer(this);
			case "paintbucket":currentTool = new PaintBucketTool(this);
		}
		
		if (Std.is(currentTool, SVGEditTool)) {
			currentTool.addEventListener("select", selectHandler, false, 0, true);
			if (Std.is(currentTool, ObjectTransformer) && s != null) 				(try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).select(s);
		}  // Setup the drawing properties for the next tool  
		
		
		
		updateDrawPropsForTool(newMode);
		
		if (toolChanged) {
			if (currentTool != null) {
				toolsLayer.addChild(currentTool);
				btn = Reflect.field(toolButtons, newMode);
				if (btn != null) 					btn.turnOn();
			}
			
			workArea.toggleContentInteraction(currentTool.interactsWithContent());
			toolMode = newMode;
			
			// Pass the selected path to the path edit tool OR
			// Pass the selected text element to the text tool
			if (Std.is(currentTool, PathEditTool) || Std.is(currentTool, TextTool)) {
				(try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).editSelection(s);
			}  // Listen for any changes to the content  
			
			
			
			currentTool.addEventListener(Event.CHANGE, saveContent, false, 0, true);
		}
		if (lastToolMode != "") 			highlightTool(lastToolMode);  // Make sure the tool selected is visible!  ;
		
		
		
		if (toolButtons.exists(newMode) && currentTool != null) 
			(try cast(Reflect.field(toolButtons, newMode), IconButton) catch(e:Dynamic) null).setDisabled(false);
	}
	
	private function updateDrawPropsForTool(newMode : String) : Void{
		if (newMode == "rect" || newMode == "vectorRect" || newMode == "ellipse" || newMode == "vectorEllipse") 
			drawPropsUI.toggleShapeUI(true, newMode == "ellipse" || newMode == "vectorEllipse")
		else 
		drawPropsUI.toggleShapeUI(false);
		
		drawPropsUI.toggleFillUI(newMode == "vpaintbrush" || newMode == "paintbucket");
		drawPropsUI.showSmoothnessUI(newMode == "path");
		if (newMode == "path") {
			var strokeWidth : Float = drawPropsUI.settings.strokeWidth;
			if (Math.isNaN(strokeWidth) || strokeWidth < 0.25) {
				var props : DrawProperties = drawPropsUI.settings;
				props.strokeWidth = 2;
				drawPropsUI.settings = props;
			}
		}
		
		drawPropsUI.showFontUI("text" == newMode);
		
		var strokeModes : Array<Dynamic> = [
		"bitmapBrush", "line", "rect", "ellipse", 
		"select", "pathedit", "path", "vectorLine", "vectorRect", "vectorEllipse"];
		var eraserModes : Array<Dynamic> = ["bitmapEraser", "eraser"];
		drawPropsUI.showStrokeUI(
				Lambda.indexOf(strokeModes, newMode) > -1,
				Lambda.indexOf(eraserModes, newMode) > -1
				);
	}
	
	public function setCurrentColor(col : UInt, alpha : Float) : Void{
		drawPropsUI.setCurrentColor(col, alpha);
	}
	
	public function endCurrentTool(nextObject : Dynamic = null) : Void{
		setToolMode(((Std.is(this, SVGEdit))) ? "select" : "bitmapSelect");
		
		// If the tool wasn't canceled and an object was created then select it
		if (nextObject != null && (Std.is(nextObject, Selection) || nextObject.parent)) {
			var s : Selection = (Std.is(nextObject, (Selection) ? nextObject : new Selection([nextObject])));
			(try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).select(s);
		}
		saveContent();
	}
	
	public function revertToCreateTool(e : MouseEvent) : Bool{
		// If just finished creating and placing a rect or ellipse, return to that tool.
		if (Lambda.indexOf(selectionTools, toolMode) != -1 && Lambda.indexOf(repeatedTools, lastToolMode) != -1) {
			setToolMode(lastToolMode);
			if (Std.is(currentTool, SVGCreateTool)) {
				(try cast(currentTool, SVGCreateTool) catch(e:Dynamic) null).eventHandler(e);
			}
			else if (Std.is(currentTool, SVGEditTool)) {
				(try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).setObject(null);
				(try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).mouseDown(e);
			}
			return true;
		}
		return false;
	}
	
	private function highlightTool(toolName : String) : Void{
		// Hack! This method forces a given tool to be highlighted even if that's not the actual mode. Used to force shape buttons to stay highlighted even when moving the shape around with the select tool.
		if (toolName == null || (toolName == "")) 			return;
		for (btn/* AS3HX WARNING could not determine type for var: btn exp: EIdent(toolButtons) type: Dynamic */ in toolButtons)btn.turnOff();
		if (Reflect.field(toolButtons, toolName)) 			Reflect.field(toolButtons, toolName).turnOn();
	}
	
	//---------------------------------
	// Costume edit and save
	//---------------------------------
	
	public function editCostume(c : ScratchCostume, forStage : Bool, force : Bool = false) : Void{
		// Edit the given ScratchCostume
		if ((targetCostume == c) && !force) 			return  // already editing  ;
		
		targetCostume = c;
		isScene = forStage;
		if (Reflect.field(toolButtons, "setCenter")) 			(try cast(Reflect.field(toolButtons, "setCenter"), IconButton) catch(e:Dynamic) null).setDisabled(isScene);
		loadCostume(targetCostume);
		if (imagesPart != null) 			imagesPart.refreshUndoButtons();
		
		if (Std.is(currentTool, SVGEditTool)) 
			(try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).setObject(null)
		else 
		currentTool.refresh();
		
		workArea.zoom();
		if (!isScene) {
			var r : Rectangle = workArea.getVisibleLayer().getRect(stage);
			workArea.zoom(new Point(Math.round((r.right + r.left) / 2), Math.round((r.bottom + r.top) / 2)));
		}
	}
	
	private function loadCostume(c : ScratchCostume) : Void{
	}  // replace contents with the given costume  
	public function addCostume(c : ScratchCostume, where : Point) : Void{
	}  // add costume to existing contents  
	
	// MUST call app.setSaveNeeded();
	public function saveContent(E : Event = null) : Void{
	}
	
	public function shutdown() : Void{
		// Called before switching costumes. Should commit any operations that were in
		// progress (e.g. entering text). Forcing a re-select of the current tool should work.
		setToolMode(toolMode, true);
	}
	
	//---------------------------------
	// Zooming
	//---------------------------------
	
	public function getZoomAndScroll() : Array<Dynamic>{return workArea.getZoomAndScroll();
	}
	public function setZoomAndScroll(zoomAndScroll : Array<Dynamic>) : Void{return workArea.setZoomAndScroll(zoomAndScroll);
	}
	public function updateZoomReadout() : Void{if (drawPropsUI != null) 			drawPropsUI.updateZoomReadout();
	}
	
	// -----------------------------
	// Stamp and Flip Buttons
	//------------------------------
	
	public function stamp() : Void{
	}
	
	public function flipContent(vertical : Bool) : Void{
		var sel : Selection;
		if (Std.is(currentTool, ObjectTransformer)) {
			sel = (try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null).getSelection();
		}
		if (sel != null) {
			sel.flip(vertical);
			currentTool.refresh();
			currentTool.dispatchEvent(new Event(Event.CHANGE));
		}
		else flipAll(vertical);
	}
	
	private function flipAll(vertical : Bool) : Void{
	}
	
	// -----------------------------
	// Clearing
	//------------------------------
	
	public function canClearCanvas() : Bool{return false;
	}
	
	// MUST call super
	public function clearCanvas(ignore : Dynamic = null) : Void{
		if (Std.is(currentTool, SVGEditTool)) 
			(try cast(currentTool, SVGEditTool) catch(e:Dynamic) null).setObject(null)
		else 
		currentTool.refresh();
		
		saveContent();
	}
	
	// -----------------------------
	// Undo/Redo
	//------------------------------
	
	public function canUndo() : Bool{
		return targetCostume &&
		(targetCostume.undoList.length > 0) &&
		(targetCostume.undoListIndex > 0);
	}
	
	public function canRedo() : Bool{
		return targetCostume &&
		(targetCostume.undoList.length > 0) &&
		(targetCostume.undoListIndex < (targetCostume.undoList.length - 1));
	}
	
	public function undo(ignore : Dynamic = null) : Void{
		clearSelection();
		if (canUndo()) {
			var undoRec : Array<Dynamic> = targetCostume.undoList[--targetCostume.undoListIndex];
			installUndoRecord(undoRec);
		}
	}
	
	public function redo(ignore : Dynamic = null) : Void{
		clearSelection();
		if (canRedo()) {
			var undoRec : Array<Dynamic> = targetCostume.undoList[++targetCostume.undoListIndex];
			installUndoRecord(undoRec);
		}
	}
	
	private function clearSelection() : Void{
		if (Std.is(this, BitmapEdit)) {
			var ot : Bool = try cast(currentTool, ObjectTransformer) catch(e:Dynamic) null;
			var tt : Bool = Std.is(currentTool, TextTool);
			if (ot || tt) {
				shutdown();
				if (ot) {
					targetCostume.undoList.pop();  // remove last entry (added by shutdown)  
					targetCostume.undoListIndex--;
				}
			}
		}
	}
	
	@:final private function recordForUndo(imgData : Dynamic, rotationCenterX : Int, rotationCenterY : Int) : Void{
		if (targetCostume == null) 			return;
		if (targetCostume.undoListIndex < targetCostume.undoList.length) {
			targetCostume.undoList = targetCostume.undoList.substring(0, targetCostume.undoListIndex + 1);
		}
		targetCostume.undoListIndex = targetCostume.undoList.length;
		targetCostume.undoList.push([imgData, rotationCenterX, rotationCenterY]);
		imagesPart.refreshUndoButtons();
	}
	
	private function installUndoRecord(undoRec : Array<Dynamic>) : Void{
		// Load image editor from the given undo state array.
		
		var data : Dynamic = undoRec[0];
		imagesPart.useBitmapEditor(Std.is(data, BitmapData));
		if (imagesPart.editor != this) {  // switched editors  
			imagesPart.editor.targetCostume = targetCostume;
			imagesPart.editor.isScene = isScene;
		}
		targetCostume.rotationCenterX = undoRec[1];
		targetCostume.rotationCenterY = undoRec[2];
		if (Std.is(data, ByteArray)) 			targetCostume.setSVGData(data, false);
		if (Std.is(data, BitmapData)) 			targetCostume.setBitmapData(data, undoRec[1], undoRec[2]);
		
		imagesPart.editor.restoreUndoState(undoRec);
		imagesPart.refreshUndoButtons();
	}
	
	private function restoreUndoState(undoRec : Array<Dynamic>) : Void{
	}
	
	// -----------------------------
	// Cursor Tool Support
	//------------------------------
	
	private function workAreaMouseMove(event : MouseEvent) : Void{
		if (CursorTool.tool) {
			var editable : ISVGEditable = SVGTool.staticGetEditableUnderMouse(this);
			if (editable != null && editable == globalToolObject) {
				return;
			}
		}
		globalToolObject = null;
		workArea.removeEventListener(MouseEvent.MOUSE_MOVE, workAreaMouseMove);
		app.clearTool();
	}
	
	public function setCurrentCursor(name : String, bmp : Dynamic = null, hotSpot : Point = null, reuse : Bool = true) : Void{
		//trace('setting cursor to '+name);
		if (name == null || [MouseCursor.HAND, MouseCursor.BUTTON].indexOf(name) > -1) {
			currentCursor = (name == (null) ? MouseCursor.AUTO : name);
			CursorTool.setCustomCursor(currentCursor);
		}
		else {
			if (Std.is(bmp, String)) 				bmp = Resources.createBmp(name).bitmapData;
			CursorTool.setCustomCursor(name, bmp, hotSpot, reuse);
			currentCursor = name;
		}  // When needed for display, pass the alias to the existing cursor property  
		
		
		
		if (stage && workArea.getInteractionLayer().hitTestPoint(stage.mouseX, stage.mouseY, true) &&
			!uiLayer.hitTestPoint(stage.mouseX, stage.mouseY, true)) {
			CursorTool.setCustomCursor(currentCursor);
		}
		else {
			CursorTool.setCustomCursor(MouseCursor.AUTO);
		}
	}
	
	public function snapToGrid(toolsP : Point) : Point{
		// Overridden by BitmapEdit to snap to the nearest pixel.
		return toolsP;
	}
}


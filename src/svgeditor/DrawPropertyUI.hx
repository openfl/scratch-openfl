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

import svgeditor.Button;
import svgeditor.Event;
import svgeditor.IconButton;
import svgeditor.ImageEdit;
import svgeditor.Menu;
import svgeditor.Shape;
import svgeditor.Slider;

import flash.display.*;
import flash.events.*;
import flash.filters.GlowFilter;
import flash.geom.*;
import flash.text.TextField;
import assets.Resources;
import translation.Translator;
import ui.parts.UIPart;
import uiwidgets.*;
import flash.text.TextFormat;

class DrawPropertyUI extends Sprite {
	public var settings(get, set) : DrawProperties;

	
	public static inline var ONCHANGE : String = "onchange";
	public static inline var ONFONTCHANGE : String = "onfontchange";
	
	private var editor : ImageEdit;
	private var currentValues : DrawProperties;
	private var disableEvents : Bool;
	
	// Stroke and eraser UI
	private var strokeWidthDisplay : Shape;
	private var strokeWidthSlider : Slider;
	private var strokeSmoothnessSlider : Slider;
	private var smoothStrokeBtn : Button;
	private var eraserStrokeDisplay : Sprite;
	private var eraserStrokeMode : Bool;
	
	// Fill UI
	private var fillUI : Sprite;
	private var fillBtnSolid : IconButton;
	private var fillBtnHorizontal : IconButton;
	private var fillBtnVertical : IconButton;
	private var fillBtnRadial : IconButton;
	
	// Font UI
	private var fontLabel : TextField;
	private var fontMenuButton : IconButton;
	
	// Shape UI
	private var shapeUI : Sprite;
	private var shapeBtnFill : IconButton;
	private var shapeBtnHollow : IconButton;
	private var isEllipse : Bool;
	
	// Smoothness UI
	private var smoothnessUI : Sprite;
	
	// Color picker
	private var colorPicker : ColorPicker;
	
	// Other UI elements
	private var bg : Shape;  // background rectangle  
	private var zoomButtons : Sprite;
	private var modeLabel : TextField;
	private var modeButton : Button;
	
	// Readouts
	private var sizeLabel : TextField;
	private var sizeReadout : TextField;
	private var zoomReadout : TextField;
	
	public function new(editor : ImageEdit)
	{
		super();
		this.editor = editor;
		currentValues = new DrawProperties();
		disableEvents = false;
		eraserStrokeMode = false;
		
		addChild(bg = new Shape());
		addChild(colorPicker = new ColorPicker(editor, this));
		makeShapeUI();
		makeStrokeUI();
		makeFillUI();
		makeFontUI();
		makeSmoothnessUI();
		makeZoomButtons();
		makeModeLabelAndButton();
		makeReadouts();
		
		addEventListener(ONCHANGE, updateStrokeWidthDisplay);
		updateStrokeWidthDisplay();
	}
	
	public static function strings() : Array<Dynamic>{
		return [
		"Smooth", "Set Costume Center", "Font:", 
		"Bitmap Mode", "Vector Mode", 
		"Convert to bitmap", "Convert to vector", 
		"Line width", "Eraser width"];
	}
	
	public var w : Int;public var h : Int;
	public function setWidthHeight(w : Int, h : Int) : Void{
		this.w = w;
		this.h = h;
		var g : Graphics = bg.graphics;
		g.clear();
		g.lineStyle(1, CSS.borderColor);
		g.beginFill(0xF6F6F6);
		g.drawRect(0, 0, w - 1, h);
		fixLayout(w, h);
	}
	
	private function fixLayout(w : Int, h : Int) : Void{
		colorPicker.x = 105 + Math.max(0, Math.floor((w - 390) / 2));
		colorPicker.y = 6;
		zoomButtons.x = w - zoomButtons.width - 5;
		zoomButtons.y = 5;
		
		var modeX : Int = w - 5 - Math.max(modeLabel.width, modeButton.width) / 2;
		modeLabel.x = modeX - modeLabel.width / 2;
		modeLabel.y = h - 47;
		modeButton.x = modeX - modeButton.width / 2;
		modeButton.y = modeLabel.y + 22;
		
		// hide in embedded editor???
		//modeLabel.visible = modeButton.visible = !isEmbedded;
		updateZoomReadout();
	}
	
	private function get_Settings() : DrawProperties{
		return currentValues;
	}
	
	private function set_Settings(props : DrawProperties) : DrawProperties{
		currentValues = props;
		colorPicker.pickColor();
		strokeWidthSlider.value = (eraserStrokeMode) ? props.eraserWidth : props.strokeWidth;
		updateStrokeWidthDisplay();
		return props;
	}
	
	public function getStrokeSmoothness() : Float{
		return strokeSmoothnessSlider.value;
	}
	
	public function updateUI(props : DrawProperties) : Void{
		disableEvents = true;
		settings = props;
		disableEvents = false;
	}
	
	public function updateZoomReadout() : Void{
		var percent : Int = Math.floor(100 * editor.getZoomAndScroll()[0]);
		zoomReadout.text = percent + "%";
		zoomReadout.x = zoomButtons.x + ((zoomButtons.width - zoomReadout.textWidth) / 2);
		zoomReadout.y = zoomButtons.y + zoomButtons.height + 3;
	}
	
	public function setCurrentColor(color : UInt, alpha : Float) : Void{
		colorPicker.setCurrentColor(color, alpha);
	}
	
	public function toggleFillUI(enabled : Bool) : Void{
		fillUI.visible = enabled;
		eraserStrokeDisplay.visible = !enabled && eraserStrokeMode;
		strokeWidthDisplay.visible = !enabled && !eraserStrokeMode;
		strokeWidthSlider.visible = !enabled;
		if (enabled) {
			updateFillUI();
			for (i in 0...fillUI.numChildren){if (Std.is(fillUI.getChildAt(i), IconButton)) {
					var ib : IconButton = (try cast(fillUI.getChildAt(i), IconButton) catch(e:Dynamic) null);
					ib.setOn(ib.name == settings.fillType);
				}
			}
		}
	}
	
	public function toggleShapeUI(enabled : Bool, ellipse : Bool = false) : Void{
		shapeUI.visible = enabled;
		isEllipse = ellipse;
		updateShapeUI();
		shapeBtnFill.setOn(currentValues.filledShape);
		shapeBtnHollow.setOn(!currentValues.filledShape);
	}
	
	public function showSmoothnessUI(flag : Bool, forDrawing : Bool = true) : Void{
		smoothnessUI.visible = flag;
		if (flag) {
			smoothStrokeBtn.visible = !forDrawing;
		}
	}
	
	public function showStrokeUI(isStroke : Bool, isEraser : Bool) : Void{
		eraserStrokeDisplay.visible = isEraser;
		eraserStrokeMode = isEraser;
		strokeWidthDisplay.visible = isStroke;
		strokeWidthSlider.visible = isStroke || isEraser;
		disableEvents = true;
		SimpleTooltips.add(strokeWidthSlider.parent, {
					text : ((isEraser) ? "Eraser width" : "Line width"),
					direction : "top",

				});
		strokeWidthSlider.value = (isEraser) ? currentValues.eraserWidth : currentValues.strokeWidth;
		disableEvents = false;
		updateStrokeWidthDisplay();
	}
	
	public function sendChangeEvent() : Void{
		if (!disableEvents) 			dispatchEvent(new Event(ONCHANGE));
		if (fillUI.visible) 			updateFillUI();
		if (shapeUI.visible) 			updateShapeUI();
	}
	
	private function makeFillUI() : Void{
		fillUI = new Sprite();
		
		fillBtnSolid = new IconButton(setFillStyle, null, null, true);
		fillBtnSolid.name = "solid";
		fillBtnSolid.setOn(true);
		fillUI.addChild(fillBtnSolid);
		
		fillBtnHorizontal = new IconButton(setFillStyle, null, null, true);
		fillBtnHorizontal.name = "linearHorizontal";
		fillBtnHorizontal.x = 42;
		fillUI.addChild(fillBtnHorizontal);
		
		fillBtnVertical = new IconButton(setFillStyle, null, null, true);
		fillBtnVertical.name = "linearVertical";
		fillBtnVertical.y = 31;
		fillUI.addChild(fillBtnVertical);
		
		fillBtnRadial = new IconButton(setFillStyle, null, null, true);
		fillBtnRadial.name = "radial";
		fillBtnRadial.x = 42;
		fillBtnRadial.y = 31;
		fillUI.addChild(fillBtnRadial);
		
		fillUI.x = 15;
		fillUI.y = 15;
		fillUI.visible = false;
		
		updateFillUI();
		addChild(fillUI);
	}
	
	private function updateFillUI() : Void{
		// Update the icons of the fill UI with new colors.
		fillBtnSolid.setImage(
				makeFillIcon("solid", true),
				makeFillIcon("solid", false));
		fillBtnHorizontal.setImage(
				makeFillIcon("linearHorizontal", true),
				makeFillIcon("linearHorizontal", false));
		fillBtnVertical.setImage(
				makeFillIcon("linearVertical", true),
				makeFillIcon("linearVertical", false));
		fillBtnRadial.setImage(
				makeFillIcon("radial", true),
				makeFillIcon("radial", false));
	}
	
	private function makeFillIcon(fill : String, isOn : Bool) : Sprite{
		// Fill button icon. Fill is one of: 'solid', 'linearHorizontal', 'linearVertical', or 'radial'
		
		var buttonSize : Point = new Point(37, 25);
		var iconW : Int = 29;
		var iconH : Int = 17;
		
		var colors : Array<Dynamic> = [currentValues.color, currentValues.secondColor];
		if (currentValues.alpha < 1) 			colors[0] = 0xFFFFFF;
		if (currentValues.secondAlpha < 1) 			colors[1] = 0xFFFFFF;
		var icon : Shape = new Shape();
		var m : Matrix = new Matrix();
		var g : Graphics = icon.graphics;
		
		switch (fill) {
			case "linearHorizontal":
				m.createGradientBox(iconW, iconH, 0, 0, 0);
				g.beginGradientFill(GradientType.LINEAR, colors, [1, 1], [0, 255], m);
			case "linearVertical":
				m.createGradientBox(iconW, iconH, (Math.PI / 2), 0, 0);
				g.beginGradientFill(GradientType.LINEAR, colors, [1, 1], [0, 255], m);
			case "radial":
				m.createGradientBox(iconW, iconH);
				g.beginGradientFill(GradientType.RADIAL, colors, [1, 1], [0, 255], m);
			case "hollow", "solid":

				switch (fill) {case "hollow":
						g.lineStyle(4, colors[0]);
				}
				g.beginFill(colors[0]);
			default:
				g.beginFill(colors[0]);
		}
		g.drawRect(0, 0, iconW, iconH);
		return ImageEdit.buttonFrame(icon, isOn, buttonSize);
	}
	
	private function makeFontUI() : Void{
		function fontMenu() : Void{
			var m : Menu = new Menu(fontSelected);
			m.itemHeight = 20;
			m.addItem("Donegal");
			m.addItem("Gloria");
			m.addItem("Helvetica");
			m.addItem("Marker");
			m.addItem("Mystery");
			m.addItem("Scratch");
			m.showOnStage(Scratch.app.stage);
		};
		function fontSelected(fontName : String) : Void{
			updateFontUI(fontName);
			currentValues.fontName = fontName;
			if (!disableEvents) 				dispatchEvent(new Event(ONFONTCHANGE));
		};
		var fmt : TextFormat = new TextFormat(CSS.font, 14, CSS.textColor, true);
		addChild(fontLabel = Resources.makeLabel(Translator.map("Font:"), fmt, 8, 8));
		addChild(fontMenuButton = UIPart.makeMenuButton("Hevetica", fontMenu, true, CSS.textColor));
		fontMenuButton.x = 12;
		fontMenuButton.y = 30;
	}
	
	public function showFontUI(flag : Bool) : Void{
		fontLabel.visible = flag;
		fontMenuButton.visible = flag;
		if (flag) 			updateFontUI(currentValues.fontName);
	}
	
	public function updateFontUI(fontName : String) : Void{
		var onImg : Sprite = UIPart.makeButtonLabel(fontName, CSS.buttonLabelOverColor, true);
		var offImg : Sprite = UIPart.makeButtonLabel(fontName, CSS.textColor, true);
		fontMenuButton.setImage(onImg, offImg);
		currentValues.fontName = fontName;
	}
	
	public function updateTranslation() : Void{
		fontLabel.text = Translator.map("Font:");
		smoothStrokeBtn.setLabel(Translator.map("Smooth"));
		modeLabel.text = Translator.map(Std.is(editor, (SVGEdit) ? "Vector Mode" : "Bitmap Mode"));
		modeButton.setLabel(Translator.map(Std.is(editor, (SVGEdit) ? "Convert to bitmap" : "Convert to vector")));
		SimpleTooltips.add(strokeWidthSlider.parent, {
					text : (eraserStrokeMode) ? "Eraser width" : "Line width",
					direction : "top",

				});
		fixLayout(w, h);
	}
	
	private function makeShapeUI() : Void{
		shapeUI = new Sprite();
		
		shapeBtnFill = new IconButton(setShapeStyle, null, null, true);
		shapeBtnFill.x = 40;
		shapeBtnFill.name = "filled";
		shapeUI.addChild(shapeBtnFill);
		
		shapeBtnHollow = new IconButton(setShapeStyle, null, null, true);
		shapeBtnHollow.name = "hollow";
		shapeBtnHollow.setOn(true);
		shapeUI.addChild(shapeBtnHollow);
		
		shapeUI.x = 15;
		shapeUI.y = 15;
		shapeUI.visible = false;
		
		updateShapeUI();
		addChild(shapeUI);
	}
	
	private function updateShapeUI(ignore : Dynamic = null) : Void{
		// Update the icons of the fill UI with new colors.
		shapeBtnFill.setImage(
				makeShapeIcon("solid", true),
				makeShapeIcon("solid", false));
		shapeBtnHollow.setImage(
				makeShapeIcon("hollow", true),
				makeShapeIcon("hollow", false));
	}
	
	private function makeShapeIcon(fill : String, isOn : Bool) : Sprite{
		// Shape button icon. Fill is 'hollow' or 'solid'.
		
		var buttonSize : Point = new Point(37, 25);
		var iconW : Int = 29;
		var iconH : Int = 17;
		var lineW : Int = 3;
		
		var icon : Shape = new Shape();
		var g : Graphics = icon.graphics;
		
		if ("hollow" == fill) 			g.lineStyle(lineW, currentValues.color)
		else g.beginFill(currentValues.color);
		
		var inset : Float = (("hollow" == fill)) ? lineW / 2 : 0;
		
		if (isEllipse) 			g.drawEllipse(inset, inset, iconW, iconH)
		else g.drawRect(inset, inset, iconW, iconH);
		
		return ImageEdit.buttonFrame(icon, isOn, buttonSize);
	}
	
	private function setShapeStyle(ib : IconButton) : Void{
		currentValues.filledShape = (ib.name == "filled");
		
		// If they want to draw a hollow shape and the stroke width was zero, set it to 2.
		if (!currentValues.filledShape && currentValues.strokeWidth == 0) {
			currentValues.strokeWidth = 2;
		}
	}
	
	private function setFillStyle(ib : IconButton) : Void{
		currentValues.fillType = ib.name;
	}
	
	private function makeSmoothnessUI() : Void{
		function smoothStroke() : Void{
			(try cast(editor, SVGEdit) catch(e:Dynamic) null).smoothStroke();
		};
		function updateSmoothness(s : Float) : Void{
			currentValues.smoothness = s;
		};
		smoothnessUI = new Sprite();
		smoothnessUI.x = 10;
		smoothnessUI.y = 10;
		smoothnessUI.visible = false;
		smoothStrokeBtn = new Button(Translator.map("Smooth"), smoothStroke);
		smoothStrokeBtn.x = 22;
		smoothnessUI.addChild(smoothStrokeBtn);
		strokeSmoothnessSlider = new Slider(100, 6, updateSmoothness);
		strokeSmoothnessSlider.min = 0.1;
		strokeSmoothnessSlider.max = 40;
		strokeSmoothnessSlider.value = 1;
		strokeSmoothnessSlider.y = 25;
		strokeSmoothnessSlider.visible = false;
		smoothnessUI.addChild(strokeSmoothnessSlider);
		addChild(smoothnessUI);
	}
	
	private function makeStrokeUI() : Void{
		function updateStrokeWidth(w : Float) : Void{
			if (eraserStrokeMode) {
				currentValues.eraserWidth = w;
			}
			else {
				currentValues.strokeWidth = w;
			}
			updateStrokeWidthDisplay();
			sendChangeEvent();
		};
		
		var ttBg : Sprite = new Sprite();
		addChild(ttBg);
		
		strokeWidthSlider = new Slider(85, 6, updateStrokeWidth);
		strokeWidthSlider.min = 0.1;
		strokeWidthSlider.max = 15;
		strokeWidthSlider.value = 2.0;
		strokeWidthSlider.x = 10;
		strokeWidthSlider.y = 90;
		ttBg.addChild(strokeWidthSlider);
		
		strokeWidthDisplay = new Shape();
		strokeWidthDisplay.x = strokeWidthSlider.x + 10;
		strokeWidthDisplay.y = 65;
		ttBg.addChild(strokeWidthDisplay);
		
		eraserStrokeDisplay = new Sprite();
		eraserStrokeDisplay.visible = false;
		eraserStrokeDisplay.x = strokeWidthDisplay.x - 7;
		eraserStrokeDisplay.y = strokeWidthDisplay.y - 20;
		ttBg.addChild(eraserStrokeDisplay);
		
		// Draw an area that will be used for showing tooltips
		updateStrokeWidthDisplay();
		var r : Rectangle = ttBg.getBounds(ttBg);
		ttBg.graphics.beginFill(0xFF0000, 0);
		ttBg.graphics.drawRect(r.x, r.y, r.width, r.height);
		ttBg.graphics.endFill();
	}
	
	private function updateStrokeWidthDisplay(ignore : Dynamic = null) : Void{
		var w : Float = (eraserStrokeMode) ? currentValues.eraserWidth : currentValues.strokeWidth;
		if (Std.is(editor, BitmapEdit)) {
			if (19 == w) 				w = 17;
			if (29 == w) 				w = 20
			else if (47 == w) 				w = 25
			else if (75 == w) 				w = 30
			else w = w + 1;
		}
		var g : Graphics;
		if (eraserStrokeMode) {
			g = eraserStrokeDisplay.graphics;
			g.clear();
			g.lineStyle(1, 0, 1);
			var m : Matrix = new Matrix();
			m.scale(0.25, 0.25);
			g.beginBitmapFill(Resources.createBmp("canvasGrid").bitmapData, m);
			g.drawCircle(40, 0, w);
			g.endFill();
		}
		else {
			g = strokeWidthDisplay.graphics;
			g.clear();
			g.lineStyle(w, currentValues.color, currentValues.alpha);
			g.moveTo(0, 0);
			g.lineTo(65, 0);
			strokeWidthDisplay.filters = (currentValues.alpha == (0) ? [new GlowFilter(0x28A5DA)] : []);
		}
		updateStrokeReadout();
	}
	
	private function updateStrokeReadout() : Void{
		// xxx to be done
		
	}
	
	/* Right-side elements */
	
	private function makeZoomButtons() : Void{
		addChild(zoomButtons = new Sprite());
		var zoomToolNames : Array<Dynamic> = ["zoomOut", "noZoom", "zoomIn"];
		var x : Int = 0;
		for (toolName in zoomToolNames){
			var ib : IconButton = new IconButton(
			editor.handleImmediateTool, 
			Resources.createBmp(toolName + "On"), 
			Resources.createBmp(toolName + "Off"), 
			false);
			ib.isRadioButton = true;
			ib.name = name;
			ib.x = x;
			x += ib.width;
			editor.registerToolButton(toolName, ib);
			zoomButtons.addChild(ib);
		}
	}
	
	private function makeModeLabelAndButton() : Void{
		function convertToBitmap() : Void{editor.imagesPart.convertToBitmap();
		};
		function convertToVector() : Void{editor.imagesPart.convertToVector();
		};
		
		modeLabel = Resources.makeLabel(
						Translator.map(((Std.is(editor, SVGEdit))) ? "Vector Mode" : "Bitmap Mode"),
						CSS.titleFormat, 0, 71);
		addChild(modeLabel);
		
		modeButton = ((Std.is(editor, SVGEdit))) ? 
				new Button(Translator.map("Convert to bitmap"), convertToBitmap, true) : 
				new Button(Translator.map("Convert to vector"), convertToVector, true);
		addChild(modeButton);
	}
	
	private function makeReadouts() : Void{
		addChild(sizeLabel = Resources.makeLabel("", CSS.normalTextFormat, 0, 0));
		addChild(sizeReadout = Resources.makeLabel("", CSS.normalTextFormat, 0, 0));
		addChild(zoomReadout = Resources.makeLabel("", CSS.normalTextFormat, 0, 0));
	}
}

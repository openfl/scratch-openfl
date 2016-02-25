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

import CSS;

import openfl.display.*;
import openfl.events.*;
import openfl.filters.DropShadowFilter;
import openfl.text.*;
import translation.Translator;
import ui.parts.UIPart;

class DialogBox extends Sprite
{

	private var fields : Map<String,DisplayObject> = new Map<String,DisplayObject>();
	private var booleanFields : Map<String, IconButton> = new Map<String, IconButton>();
	public var widget : InteractiveObject;
	private var w : Int;private var h : Int;
	public var leftJustify : Bool;

	private var context : Map<String, String>;
	private var title : TextField;
	private var buttons : Array<Button> = [];
	private var labelsAndFields : Array<{label:TextField, field:TextField}> = [];
	private var booleanLabelsAndFields : Array<{label:TextField, field:IconButton}> = [];
	private var textLines : Array<TextField> = [];
	private var maxLabelWidth : Int = 0;
	private var maxFieldWidth : Int = 0;
	private var heightPerField : Int;// = Std.int(Math.max(makeLabel("foo").height, makeField(10).height) + 10);
	private inline static var spaceAfterText : Int = 18;
	private inline static var blankLineSpace : Int = 7;

	private var acceptFunction : Dynamic->Void;  // if not nil, called when menu interaction is accepted  
	private var cancelFunction : Dynamic->Void;  // if not nil, called when menu interaction is canceled  

	public function new(acceptFunction : Dynamic->Void = null, cancelFunction : Dynamic -> Void = null)
	{
		super();
		heightPerField = Std.int(Math.max(makeLabel("foo").height, makeField(10).height) + 10);
		this.acceptFunction = acceptFunction;
		this.cancelFunction = cancelFunction;
		addFilters();
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
		addEventListener(FocusEvent.KEY_FOCUS_CHANGE, focusChange);
	}

	public static function ask(question : String, defaultAnswer : String, stage : Stage = null, resultFunction : String->Void = null, context : Map<String, String> = null) : Void {
		var d : DialogBox = null;	
		function done(param:Dynamic) : Void{if (resultFunction != null)                 resultFunction(cast(d.fields["answer"], TextField).text);
		};
		d = new DialogBox(done);
		d.addTitle(question);
		d.addField("answer", 120, defaultAnswer, false);
		d.addButton("OK", d.accept);
		if (context != null)             d.updateContext(context);
		d.showOnStage((stage != null) ? stage : Scratch.app.stage);
	}

	public static function confirm(question : String, stage : Stage = null, okFunction : Dynamic->Void = null, cancelFunction : Dynamic->Void= null, context : Map<String, String> = null) : Void{
		var d : DialogBox = new DialogBox(okFunction, cancelFunction);
		d.addTitle(question);
		d.addAcceptCancelButtons("OK");
		if (context != null)             d.updateContext(context);
		d.showOnStage((stage != null) ? stage : Scratch.app.stage);
	}

	public static function notify(title : String, msg : String, stage : Stage = null, leftJustify : Bool = false, okFunction : Dynamic->Void= null, cancelFunction : Dynamic->Void= null, context : Map<String, String> = null) : Void{
		var d : DialogBox = new DialogBox(okFunction, cancelFunction);
		d.leftJustify = leftJustify;
		d.addTitle(title);
		d.addText(msg);
		d.addButton("OK", d.accept);
		if (context != null)             d.updateContext(context);
		d.showOnStage((stage != null) ? stage : Scratch.app.stage);
	}

	// Updates the context for variable substitution in the dialog's text, or sets it if there was none before.
	// Make sure any text values in the context are already translated: they will not be translated here.
	// Calling this will update the text of the dialog immediately.
	public function updateContext(c : Map<String, String>) : Void{
		if (context == null)             context = new Map<String, String>();
		for (key in c.keys()){
			context[key] = c[key];
		}
		for (i in 0...numChildren){
			var f : VariableTextField = try cast(getChildAt(i), VariableTextField) catch(e:Dynamic) null;
			if (f != null) {
				f.applyContext(context);
			}
		}
	}

	public function addTitle(s : String) : Void{
		title = makeLabel(Translator.map(s), true);
		addChild(title);
	}

	public function addText(text : String) : Void{
		for (s in text.split("\n")){
			var line : TextField = makeLabel(Translator.map(s));
			addChild(line);
			textLines.push(line);
		}
	}

	public function addWidget(o : InteractiveObject) : Void{
		widget = o;
		addChild(o);
	}

	public function addField(fieldName : String, width : Int, defaultValue : String = null, showLabel : Bool = true) : Void{
		var l : TextField = null;
		if (showLabel) {
			l = makeLabel(Translator.map(fieldName) + ":");
			addChild(l);
		}
		var f : TextField = makeField(width);
		if (defaultValue != null)             f.text = defaultValue;
		addChild(f);
		fields[fieldName] = f;
		labelsAndFields.push({label:l, field:f});
	}

	public function addBoolean(fieldName : String, defaultValue : Bool = false, isRadioButton : Bool = false) : Void{
		var l : TextField = makeLabel(Translator.map(fieldName) + ":");
		addChild(l);
		var f : IconButton = (isRadioButton) ? 
		new IconButton(null, null, null, true) : 
		new IconButton(null, getCheckMark(true), getCheckMark(false));
		if (defaultValue)             f.turnOn()
		else f.turnOff();
		addChild(f);
		booleanFields[fieldName] = f;
		booleanLabelsAndFields.push({label:l, field:f});
	}

	private function getCheckMark(b : Bool) : Sprite{
		var spr : Sprite = new Sprite();
		var g : Graphics = spr.graphics;
		g.clear();
		g.beginFill(0xFFFFFF);
		g.lineStyle(1, 0x929497, 1, true);
		g.drawRoundRect(0, 0, 17, 17, 3, 3);
		g.endFill();
		if (b) {
			g.lineStyle(2, 0x4c4d4f, 1, true);
			g.moveTo(3, 7);
			g.lineTo(5, 7);
			g.lineTo(8, 13);
			g.lineTo(14, 3);
		}
		return spr;
	}

	public function addAcceptCancelButtons(acceptLabel : String = null) : Void{
		// Add a cancel button and an optional accept button with the given label.
		if (acceptLabel != null)             addButton(acceptLabel, accept);
		addButton("Cancel", cancel);
	}

	public function addButton(label : String, action : Void->Void) : Void{
		function doAction() : Void{
			remove();
			if (action != null)                 action();
		};
		var b : Button = new Button(Translator.map(label), doAction);
		addChild(b);
		buttons.push(b);
	}

	public function showOnStage(stage : Stage, center : Bool = true) : Void{
		fixLayout();
		if (center) {
			x = (stage.stageWidth - width) / 2;
			y = (stage.stageHeight - height) / 2;
		}
		else {
			x = stage.mouseX + 10;
			y = stage.mouseY + 10;
		}
		x = Math.max(0, Math.min(x, stage.stageWidth - width));
		y = Math.max(0, Math.min(y, stage.stageHeight - height));
		stage.addChild(this);
		if (labelsAndFields.length > 0) {
			// note: doesn't work when testing from FlexBuilder; works when deployed
			stage.focus = labelsAndFields[0].field;
		}
	}

	public static function findDialogBoxes(targetTitle : String, stage : Stage) : Array<DialogBox>{
		// Return an array of all dialogs on the stage with the given title.
		// If the given title is null then return all dialogs.
		var result : Array<DialogBox> = [];
		if (targetTitle != null)             targetTitle = Translator.map(targetTitle);
		for (i in 0...stage.numChildren){
			if (Std.is(stage.getChildAt(i), DialogBox)) {
				var d : DialogBox = cast(stage.getChildAt(i), DialogBox);
				if (targetTitle != null) {
					if (d.title != null && (d.title.text == targetTitle))                         result.push(d);
				}
				else {
					result.push(d);
				}
			}
		}
		return result;
	}

	public function accept() : Void{
		if (acceptFunction != null)             acceptFunction(this);
		remove();
	}

	public function cancel() : Void{
		if (cancelFunction != null)             cancelFunction(this);
		remove();
	}

	public function getField(fieldName : String) : Dynamic{
		if (fields.exists(fieldName))             return fields[fieldName].__textEngine.text;
		if (booleanFields.exists(fieldName))             return booleanFields[fieldName].isOn();
		return null;
	}

	public function setPasswordField(fieldName : String, flag : Bool = true) : Void{
		var field : Dynamic = fields[fieldName];
		if (Std.is(field, TextField)) {
			cast(field, TextField).displayAsPassword = flag;
		}
	}

	private function remove() : Void{
		if (parent != null)             parent.removeChild(this);
	}

	private function makeLabel(s : String, forTitle : Bool = false) : TextField{
		var normalFormat : TextFormat = new TextFormat(CSS.font, 14, CSS.textColor);
		var result : VariableTextField = new VariableTextField();
		result.autoSize = TextFieldAutoSize.LEFT;
		result.selectable = false;
		result.background = false;
		result.setText(s, context);
		result.setTextFormat((forTitle) ? CSS.titleFormat : normalFormat);
		return result;
	}

	private function makeField(width : Int) : TextField{
		var result : TextField = new TextField();
		result.selectable = true;
		result.type = TextFieldType.INPUT;
		result.background = true;
		result.border = true;
		result.defaultTextFormat = CSS.normalTextFormat;
		result.width = width;
		result.height = result.defaultTextFormat.size + 8;

		result.backgroundColor = 0xFFFFFF;
		result.borderColor = CSS.borderColor;

		return result;
	}

	public function fixLayout() : Void{
		var label : TextField;
		var i : Int;
		var totalW : Int;
		fixSize();
		var fieldX:Int = maxLabelWidth + 17;
		var fieldY:Int = 15;
		if (title != null) {
			title.x = (w - title.width) / 2;
			title.y = 5;
			fieldY = Std.int(title.y + title.height + 20);
		}
		// fields  
		for (i in 0...labelsAndFields.length){
			label = labelsAndFields[i].label;
			var field : TextField = labelsAndFields[i].field;
			if (label != null) {
				label.x = fieldX - 5 - label.width;
				label.y = fieldY;
			}
			field.x = fieldX;
			field.y = fieldY + 1;
			fieldY += heightPerField;
		}
		
		// widget  
		if (widget != null) {
			widget.x = (width - widget.width) / 2;
			widget.y = fieldY;  // (title != null) ? title.y + title.height + 10 : 10;  
			fieldY = Std.int(widget.y + widget.height + 15);
		}  
		// boolean fields  
		for (i in 0...booleanLabelsAndFields.length){
			label = booleanLabelsAndFields[i].label;
			var ib : IconButton = booleanLabelsAndFields[i].field;
			if (label != null) {
				label.x = fieldX - 5 - label.width;
				label.y = fieldY + 5;
			}
			ib.x = fieldX - 2;
			ib.y = fieldY + 5;
			fieldY += heightPerField;
		}  // text lines  

		for (line in textLines){
			line.x = (leftJustify) ? 15 : (w - line.width) / 2;
			line.y = fieldY;
			fieldY += Std.int(line.height);
			if (line.text.length == 0)                 fieldY += blankLineSpace;
		}
		if (textLines.length > 0)             fieldY += spaceAfterText;  // buttons  ;

		if (buttons.length > 0) {
			totalW = (buttons.length - 1) * 10;
			for (i in 0...buttons.length){totalW += Std.int(buttons[i].width);
			}
			var buttonX : Int = Std.int((w - totalW) / 2);
			var buttonY : Int = Std.int(h - (buttons[0].height + 15));
			for (i in 0...buttons.length){
				buttons[i].x = buttonX;
				buttons[i].y = buttonY;
				buttonX += Std.int(buttons[i].width + 10);
			}
		}
	}

	private function fixSize() : Void{
		var i : Int;
		var totalW : Int;
		w = h = 0;
		// title
		if (title != null) {
			w = Std.int(Math.max(w, title.width));
			h += Std.int(10 + title.height);
		}  // fields  

		maxLabelWidth = 0;
		maxFieldWidth = 0;
		for (i in 0...labelsAndFields.length){
			var r : {label:TextField,field:TextField};
			r = labelsAndFields[i];
			if (r.label != null)                 maxLabelWidth = Std.int(Math.max(maxLabelWidth, r.label.width));
			maxFieldWidth = Std.int(Math.max(maxFieldWidth, r.field.width));
			h += heightPerField;
		}  // boolean fields  

		for (i in 0...booleanLabelsAndFields.length) {
			var r:{label:TextField, field:IconButton};
			r = booleanLabelsAndFields[i];
			if (r.label != null)                 maxLabelWidth = Std.int(Math.max(maxLabelWidth, r.label.width));
			maxFieldWidth = Std.int(Math.max(maxFieldWidth, r.field.width));
			h += heightPerField;
		}
		w = Std.int(Math.max(w, maxLabelWidth + maxFieldWidth + 5));
		// widget
		if (widget != null) {
			w = Std.int(Math.max(w, widget.width));
			h += Std.int(10 + widget.height);
		}  // text lines  

		for (line in textLines){
			w = Std.int(Math.max(w, line.width));
			h += Std.int(line.height);
			if (line.length == 0)                 h += blankLineSpace;
		}
		if (textLines.length > 0)             h += spaceAfterText;  // buttons  ;

		totalW = 0;
		for (i in 0...buttons.length){totalW += Std.int(buttons[i].width + 10);
		}
		w = Std.int(Math.max(w, totalW));
		if (buttons.length > 0)             h += Std.int(buttons[0].height + 15);
		if ((labelsAndFields.length > 0) || (booleanLabelsAndFields.length > 0))             h += 15;
		w += 30;
		h += 10;
		drawBackground();
	}

	private function drawBackground() : Void{
		var titleBarColors : Array<UInt> = [0xE0E0E0, 0xD0D0D0];  // old: CSS.titleBarColors;  
		var borderColor : Int = 0xB0B0B0;  // old: CSS.borderColor;  
		var g : Graphics = graphics;
		g.clear();
		UIPart.drawTopBar(g, titleBarColors, UIPart.getTopBarPath(w, h), w, CSS.titleBarH, borderColor);
		g.lineStyle(0.5, borderColor, 1, true);
		g.beginFill(0xFFFFFF);
		g.drawRect(0, CSS.titleBarH, w - 1, h - CSS.titleBarH - 1);
	}

	private function addFilters() : Void{
		var f : DropShadowFilter = new DropShadowFilter();

		f.blurX = f.blurY = 8;
		f.distance = 5;
		f.alpha = 0.75;
		f.color = 0x333333;
		filters = [f];
	}

	/* Events */

	private function focusChange(evt : Event) : Void{
		evt.preventDefault();
		if (labelsAndFields.length == 0)             return;
		var focusIndex : Int = -1;
		for (i in 0...labelsAndFields.length){
			if (stage.focus == labelsAndFields[i].field)                 focusIndex = i;
		}
		focusIndex++;
		if (focusIndex >= labelsAndFields.length)             focusIndex = 0;
		stage.focus = labelsAndFields[focusIndex].field;
	}

	private function mouseDown(evt : MouseEvent) : Void{if (evt.target == this || evt.target == title)             startDrag();
	}
	private function mouseUp(evt : MouseEvent) : Void{stopDrag();
	}

	private function keyDown(evt : KeyboardEvent) : Void{
		if ((evt.keyCode == 10) || (evt.keyCode == 13))             accept();
		if (evt.keyCode == 27)             cancel();
	}
}

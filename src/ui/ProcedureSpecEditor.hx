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

package ui;


import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.text.*;
import assets.Resources;
import blocks.*;
import uiwidgets.*;
import util.*;
import translation.Translator;

class ProcedureSpecEditor extends Sprite
{

	private var base : Shape;
	private var blockShape : BlockShape;
	private var row : Array<Dynamic> = [];

	private var moreLabel : TextField;
	private var moreButton : IconButton;
	private var buttonLabels : Array<Dynamic> = [];
	private var buttons : Array<Dynamic> = [];

	private var warpCheckbox : IconButton;
	private var warpLabel : TextField;

	private var deleteButton : IconButton;
	private var focusItem : DisplayObject;

	private static inline var labelColor : Int = 0x8738bf;  // 0x6c36b3; // 0x9c35b3;  
	private static inline var selectedLabelColor : Int = 0xefa6ff;

	public function new(originalSpec : String, inputNames : Array<Dynamic>, warpFlag : Bool)
	{
		super();
		addChild(base = new Shape());
		setWidthHeight(350, 10);

		blockShape = new BlockShape(BlockShape.CmdShape, Specs.procedureColor);
		blockShape.setWidthAndTopHeight(100, 25, true);
		addChild(blockShape);

		addChild(moreLabel = makeLabel("Options", 12));
		moreLabel.addEventListener(MouseEvent.MOUSE_DOWN, toggleButtons);

		addChild(moreButton = new IconButton(toggleButtons, "reveal"));
		moreButton.disableMouseover();

		addButtonsAndLabels();
		addwarpCheckbox();

		addChild(deleteButton = new IconButton(deleteItem, Resources.createBmp("removeItem")));

		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(Event.CHANGE, textChange);
		addEventListener(FocusEvent.FOCUS_OUT, focusChange);
		addEventListener(FocusEvent.FOCUS_IN, focusChange);

		addSpecElements(originalSpec, inputNames);
		warpCheckbox.setOn(warpFlag);
		showButtons(false);
	}

	public static function strings() : Array<Dynamic>{
		return [
		"Options", "Run without screen refresh", 
		"Add number input:", 
		"Add string input:", 
		"Add boolean input:", 
		"Add label text:", 
		"text"];
	}

	private function setWidthHeight(w : Int, h : Int) : Void{
		var g : Graphics = base.graphics;
		g.clear();
		g.beginFill(CSS.white);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}

	private function clearRow() : Void{
		for (el in row){
			if (el.parent)                 el.parent.removeChild(el);
		}
		row = [];
	}

	private function addSpecElements(spec : String, inputNames : Array<Dynamic>) : Void{
		function addElement(o : DisplayObject) : Void{
			row.push(o);
			addChild(o);
		};
		clearRow();
		var i : Int = 0;
		for (s/* AS3HX WARNING could not determine type for var: s exp: ECall(EField(EIdent(ReadStream),tokenize),[EIdent(spec)]) type: null */ in ReadStream.tokenize(spec)){
			if (s.length >= 2 && s.charAt(0) == "%") {  // argument spec  
				var argSpec : String = s.charAt(1);
				var arg : BlockArg = null;
				if (argSpec == "b")                     arg = makeBooleanArg();
				if (argSpec == "n")                     arg = makeNumberArg();
				if (argSpec == "s")                     arg = makeStringArg();
				if (arg != null) {
					arg.setArgValue(inputNames[i++]);
					addElement(arg);
				}
			}
			else {
				if ((row.length > 0) && (Std.is(row[row.length - 1], TextField))) {
					var tf : TextField = row[row.length - 1];
					tf.appendText(" " + ReadStream.unescape(s));
					fixLabelWidth(tf);
				}
				else {
					addElement(makeTextField(ReadStream.unescape(s)));
				}
			}
		}
		if ((row.length == 0) || (Std.is(row[row.length - 1], BlockArg)))             addElement(makeTextField(""));
		fixLayout();
	}

	public function spec() : String{
		var result : String = "";
		for (o in row){
			if (Std.is(o, TextField))                 result += ReadStream.escape(cast((o), TextField).text);
			if (Std.is(o, BlockArg))                 result += "%" + cast((o), BlockArg).type;
			if ((result.length > 0) && (result.charAt(result.length - 1) != " "))                 result += " ";
		}
		if ((result.length > 0) && (result.charAt(result.length - 1) == " "))             result = result.substring(0, result.length - 1);
		return result;
	}

	public function defaultArgValues() : Array<Dynamic>{
		var result : Array<Dynamic> = [];
		for (el in row){
			if (Std.is(el, BlockArg)) {
				var arg : BlockArg = cast((el), BlockArg);
				var v : Dynamic = 0;
				if (arg.type == "b")                     v = false;
				if (arg.type == "n")                     v = 1;
				if (arg.type == "s")                     v = "";
				result.push(v);
			}
		}
		return result;
	}

	public function warpFlag() : Bool{
		// True if the 'run without screen refresh' (i.e. 'warp speed') box is checked.
		return warpCheckbox.isOn();
	}

	public function inputNames() : Array<Dynamic>{
		var result : Array<Dynamic> = [];
		for (o in row){
			if (Std.is(o, BlockArg))                 result.push(uniqueName(result, cast((o), BlockArg).field.text));
		}
		return result;
	}

	private function addButtonsAndLabels() : Void{
		buttonLabels = [
				makeLabel("Add number input:", 14), 
				makeLabel("Add string input:", 14), 
				makeLabel("Add boolean input:", 14), 
				makeLabel("Add label text:", 14)];
		buttons = [
				new Button("", function() : Void{appendObj(makeNumberArg());
				}), 
				new Button("", function() : Void{appendObj(makeStringArg());
				}), 
				new Button("", function() : Void{appendObj(makeBooleanArg());
				}), 
				new Button(Translator.map("text"), function() : Void{appendObj(makeTextField(""));
				})];

		var lightGray : Int = 0xA0A0A0;

		var icon : BlockShape;
		icon = new BlockShape(BlockShape.NumberShape, lightGray);
		icon.setWidthAndTopHeight(25, 14, true);
		buttons[0].setIcon(icon);

		icon = new BlockShape(BlockShape.RectShape, lightGray);
		icon.setWidthAndTopHeight(22, 14, true);
		buttons[1].setIcon(icon);

		icon = new BlockShape(BlockShape.BooleanShape, lightGray);
		icon.setWidthAndTopHeight(25, 14, true);
		buttons[2].setIcon(icon);

		for (label in buttonLabels)addChild(label);
		for (b in buttons)addChild(b);
	}

	private function addwarpCheckbox() : Void{
		addChild(warpCheckbox = new IconButton(null, "checkbox"));
		warpCheckbox.disableMouseover();
		addChild(warpLabel = makeLabel("Run without screen refresh", 14));
	}

	private function makeLabel(s : String, fontSize : Int) : TextField{
		var tf : TextField = new TextField();
		tf.selectable = false;
		tf.defaultTextFormat = new TextFormat(CSS.font, fontSize, CSS.textColor);
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.text = Translator.map(s);
		addChild(tf);
		return tf;
	}

	private function toggleButtons(ignore : Dynamic) : Void{
		var buttonsShowing : Bool = buttons[0].parent != null;
		showButtons(!buttonsShowing);
	}

	private function deleteItem(ignore : Dynamic) : Void{
		if (focusItem != null) {
			var oldIndex : Int = Lambda.indexOf(row, focusItem) - 1;
			removeChild(focusItem);
			if (oldIndex > -1)                 setFocus(row[oldIndex]);
			fixLayout();
		}
		if (row.length == 0) {
			appendObj(makeTextField(""));
			cast((row[0]), TextField).width = 27;
		}
	}

	private function showButtons(showParams : Bool) : Void{
		var label : TextField;
		var b : Button;
		if (showParams) {
			for (label in buttonLabels)addChild(label);
			for (b in buttons)addChild(b);
			addChild(warpCheckbox);
			addChild(warpLabel);
		}
		else {
			for (label in buttonLabels)if (label.parent != null)                 removeChild(label);
			for (b in buttons)if (b.parent != null)                 removeChild(b);
			if (warpCheckbox.parent != null)                 removeChild(warpCheckbox);
			if (warpLabel.parent != null)                 removeChild(warpLabel);
		}

		moreButton.setOn(showParams);

		setWidthHeight(Std.int(base.width), (showParams) ? 215 : 55);
		deleteButton.visible = showParams && (row.length > 1);
		if (Std.is(parent, DialogBox))             cast((parent), DialogBox).fixLayout();
	}

	private function makeBooleanArg() : BlockArg{
		var result : BlockArg = new BlockArg("b", 0xFFFFFF, true);
		result.setArgValue(unusedArgName("boolean"));
		return result;
	}

	private function makeNumberArg() : BlockArg{
		var result : BlockArg = new BlockArg("n", 0xFFFFFF, true);
		result.field.restrict = null;  // allow any string to be entered, not just numbers  
		result.setArgValue(unusedArgName("number"));
		return result;
	}

	private function makeStringArg() : BlockArg{
		var result : BlockArg = new BlockArg("s", 0xFFFFFF, true);
		result.setArgValue(unusedArgName("string"));
		return result;
	}

	private function unusedArgName(prefix : String) : String{
		var usedNames : Array<Dynamic> = [];
		for (el in row){
			if (Std.is(el, BlockArg))                 usedNames.push(el.field.text);
		}
		var i : Int = 1;
		while (Lambda.indexOf(usedNames, prefix + i) > -1)i++;
		return prefix + i;
	}

	private function appendObj(o : DisplayObject) : Void{
		row.push(o);
		addChild(o);
		if (stage != null) {
			if (Std.is(o, TextField))                 stage.focus = cast((o), TextField);
			if (Std.is(o, BlockArg))                 cast((o), BlockArg).startEditing();
		}
		fixLayout();
	}

	private function makeTextField(contents : String) : TextField{
		var result : TextField = new TextField();
		result.borderColor = 0;
		result.backgroundColor = labelColor;
		result.background = true;
		result.type = TextFieldType.INPUT;
		result.defaultTextFormat = Block.blockLabelFormat;
		if (contents.length > 0) {
			result.width = 1000;
			result.text = contents;
			result.width = Math.max(10, result.textWidth + 2);
		}
		else {
			result.width = 27;
		}
		result.height = result.textHeight + 5;
		return result;
	}

	private function removeDeletedElementsFromRow() : Void{
		// Remove elements that have been delete (e.g. args that were being dragged out).
		// Also, ensure that there is exactly one text field between args.
		var tf : TextField;
		var newRow : Array<Dynamic> = [];
		for (el in row){
			if (el.parent)                 newRow.push(el);
		}
		row = newRow;
	}

	private function fixLayout(updateDelete : Bool = true) : Void{
		removeDeletedElementsFromRow();
		blockShape.x = 10;
		blockShape.y = 10;
		var nextX : Int = Std.int(blockShape.x + 6);
		var nextY : Int = Std.int(blockShape.y + 5);
		var maxH : Int = 0;
		for (o in row)maxH = Std.int(Math.max(maxH, o.height));
		for (o in row){
			o.x = nextX;
			o.y = nextY + Std.parseInt((maxH - o.height) / 2) + (((Std.is(o, TextField))) ? 1 : 1);
			nextX += o.width + 4;
			if ((Std.is(o, BlockArg)) && (cast((o), BlockArg).type == "s"))                 nextX -= 2;
		}
		var blockW : Int = Std.int(Math.max(40, nextX + 4 - blockShape.x));
		blockShape.setWidthAndTopHeight(blockW, maxH + 11, true);

		moreButton.x = 0;
		moreButton.y = blockShape.y + blockShape.height + 12;

		moreLabel.x = 10;
		moreLabel.y = moreButton.y - 4;

		var labelX : Int = Std.int(blockShape.x + 45);
		var buttonX : Int = 240;
		for (l in buttonLabels){
			buttonX = Std.int(Math.max(buttonX, labelX + l.textWidth + 10));
		}

		var rowY : Int = Std.int(blockShape.y + blockShape.height + 30);
		for (i in 0...buttons.length){
			var label : TextField = buttonLabels[i];
			buttonLabels[i].x = labelX;
			buttonLabels[i].y = rowY;
			buttons[i].x = buttonX;
			buttons[i].y = rowY - 4;
			rowY += 30;
		}

		warpCheckbox.x = blockShape.x + 46;
		warpCheckbox.y = rowY + 4;

		warpLabel.x = warpCheckbox.x + 18;
		warpLabel.y = warpCheckbox.y - 3;

		if (updateDelete)             updateDeleteButton();
		if (Std.is(parent, DialogBox))             cast((parent), DialogBox).fixLayout();
	}

	/* Editing Parameter Names */

	public function click(evt : MouseEvent) : Void{editArg(evt);
	}
	public function doubleClick(evt : MouseEvent) : Void{editArg(evt);
	}

	private function editArg(evt : MouseEvent) : Void{
		var arg : BlockArg = try cast(evt.target.parent, BlockArg) catch(e:Dynamic) null;
		if (arg != null && arg.isEditable)             arg.startEditing();
	}

	private function mouseDown(evt : MouseEvent) : Void{
		if ((evt.target == this) && blockShape.hitTestPoint(evt.stageX, evt.stageY)) {
			// make the first text field the input focus when user clicks on the block shape
			// but misses all the text fields
			for (o in row){
				if (Std.is(o, TextField)) {stage.focus = cast((o), TextField);return;
				}
			}
		}
	}

	private function textChange(evt : Event) : Void{
		var tf : TextField = try cast(evt.target, TextField) catch(e:Dynamic) null;
		if (tf != null)             fixLabelWidth(tf);
		fixLayout();
	}

	private function fixLabelWidth(tf : TextField) : Void{
		tf.width = 1000;
		tf.text = tf.text;  // recompute textWidth  
		tf.width = Math.max(10, tf.textWidth + 6);
	}

	public function setInitialFocus() : Void{
		if (row.length == 0)             appendObj(makeTextField(""));
		var tf : TextField = try cast(row[0], TextField) catch(e:Dynamic) null;
		if (tf != null) {
			if (tf.text.length == 0)                 tf.width = 27
			else fixLabelWidth(tf);
			fixLayout();
		}
		setFocus(row[0]);
	}

	private function setFocus(o : DisplayObject) : Void{
		if (stage == null)             return;
		if (Std.is(o, TextField))             stage.focus = cast((o), TextField);
		if (Std.is(o, BlockArg))             cast((o), BlockArg).startEditing();
	}

	private function uniqueName(taken : Array<Dynamic>, name : String) : String{
		if (Lambda.indexOf(taken, name) == -1)             return name;
		var e : Array<Dynamic> = new EReg('\\d+$', "").exec(name);
		var n : String = (e != null) ? e[0] : "";
		var base : String = name.substring(0, name.length - n.length);
		var i : Int = Std.parseInt(n != null ? n : "1") + 1;
		while (Lambda.indexOf(taken, base + i) != -1){
			i++;
		}
		return base + i;
	}

	private function focusChange(evt : FocusEvent) : Void{
		var params : Array<Dynamic> = [];
		var change : Bool = false;
		// Update label fields to show focus.
		var tf : TextField ;
		for (o in row){
			if (Std.is(o, TextField)) {
				tf = cast((o), TextField);
				var hasFocus : Bool = (stage != null) && (tf == stage.focus);
				tf.textColor = (hasFocus) ? 0 : 0xFFFFFF;
				tf.backgroundColor = (hasFocus) ? selectedLabelColor : labelColor;
			}
			else if (Std.is(o, BlockArg)) {
				tf = cast((o), BlockArg).field;
				if (Lambda.indexOf(params, tf.text) != -1) {
					cast((o), BlockArg).setArgValue(uniqueName(params, tf.text));
					change = true;
				}
				params.push(tf.text);
			}
		}
		if (change)             fixLayout(false)
		else if (evt.type == FocusEvent.FOCUS_IN)             updateDeleteButton();
	}

	private function updateDeleteButton() : Void{
		// Adjust the position and visibility of the delete button.
		var hasFocus : Bool;
		var labelCount : Int = 0;
		if (stage == null)             return;
		if (row.length > 0)             focusItem = row[0];
		for (o in row){
			if (Std.is(o, TextField)) {
				if (stage.focus == o)                     focusItem = o;
				labelCount++;
			}
			if (Std.is(o, BlockArg)) {
				if (stage.focus == cast((o), BlockArg).field)                     focusItem = o;
			}
		}
		if (focusItem != null) {
			var r : Rectangle = focusItem.getBounds(this);
			deleteButton.x = r.x + Std.parseInt(r.width / 2) - 6;
		}
		deleteButton.visible = (row.length > 1);
		deleteButton.y = -6;
	}
}

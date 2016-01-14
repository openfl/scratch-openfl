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

// Watcher.as
// Paula Bonta, Summer 2010
// John Maloney, April 2011
//
// Represents a variable display.

package watchers;


import blocks.BlockIO;

import openfl.display.*;
//import openfl.filters.BevelFilter;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.text.*;
import interpreter.*;
import scratch.*;
import uiwidgets.*;
import util.*;
import blocks.Block;
import translation.Translator;

class Watcher extends Sprite implements DragClient
{

	private static inline var decimalPlaces : Int = 6;
	public static function formatValue(value : Dynamic) : String{
		if (Std.is(value, Float) || (Std.is(value, String) && Std.string(Std.parseFloat(value)) == value)) {
			// show at most N digits after the decimal point
			value = Std.parseFloat(Compat.toFixed(Std.parseFloat(value), decimalPlaces));
		}
		return "" + value;
	}
	
	private var format : TextFormat = new TextFormat(CSS.font, 11, 0, true);

	private static inline var NORMAL_MODE : Int = 1;
	private static inline var LARGE_MODE : Int = 2;
	private static inline var SLIDER_MODE : Int = 3;
	private static inline var TEXT_MODE : Int = 4;

	public var target : ScratchObj;
	private var cmd : String;
	private var param : String;
	private var mode : Int = NORMAL_MODE;

	private var frame : ResizeableFrame;
	private var label : TextField;
	private var readout : WatcherReadout;
	private var slider : Shape;
	private var knob : Shape;

	// stepping
	private var lastValue : Dynamic;

	// slider support
	private var sliderMin : Float = 0;
	private var sliderMax : Float = 100;
	private var isDiscrete : Bool = true;
	private var mouseMoved : Bool;

	public function new()
	{
		super();
		frame = new ResizeableFrame(0x949191, 0xC1C4C7, 8);
		addChild(frame);
		addLabel();
		readout = new WatcherReadout();
		addChild(readout);
		addSliderAndKnob();
		slider.visible = knob.visible = false;
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
	}

	public static function strings() : Array<String>{
		return [
		"Max", "Min", "Slider Range", 
		"normal readout", "large readout", "slider", "set slider min and max", "hide"];
	}

	public function initWatcher(target : ScratchObj, cmd : String, param : String, color : Int) : Void{
		this.target = target;
		this.cmd = cmd;
		this.param = param;
		this.mode = NORMAL_MODE;
		setColor(color);
		updateLabel();
	}

	public function initForVar(target : ScratchObj, varName : String) : Void{
		this.target = target;
		this.cmd = "getVar:";
		this.param = varName;
		this.mode = NORMAL_MODE;
		// link to this watcher from its variable
		var v : Variable = target.lookupVar(param);
		if (v != null)             v.watcher = this;
		setColor(Specs.variableColor);
		setLabel(((target.isStage)) ? varName : (target.objName + ": " + varName));
	}

	public function changeVarName(varName : String) : Void{
		if (cmd != "getVar:")             return;
		param = varName;
		setLabel(((target.isStage)) ? varName : (target.objName + ": " + varName));
	}

	public function isVarWatcherFor(target : ScratchObj, vName : String) : Bool{
		return ((cmd == "getVar:") && (this.target == target) && (param == vName));
	}

	public function isReporterWatcher(target : ScratchObj, cmd : String, param : String) : Bool{
		return ((this.target == target) && (this.cmd == cmd) && this.param == param);
	}

	public function setMode(m : Int) : Void{
		mode = m;
		readout.beLarge(mode == LARGE_MODE);
		fixLayout();
	}

	public function setColor(c : Int) : Void{readout.setColor(c);
	}

	public function setSliderMinMax(min : Float, max : Float, val : Float) : Void{
		// Set slider range. Make it discrete if min, max, and current value are all integral.
		sliderMin = min;
		sliderMax = max;
		isDiscrete = (Std.int(min) == min) && (Std.int(max) == max) && (Std.int(val) == val);
	}

	override public function hitTestPoint(globalX : Float, globalY : Float, shapeFlag : Bool = true) : Bool{
		if (!visible)             return false;
		if (frame.visible)             return frame.hitTestPoint(globalX, globalY, shapeFlag);
		return readout.hitTestPoint(globalX, globalY, shapeFlag);
	}

	/* Stepping */

	public function step(runtime : ScratchRuntime) : Void{
		var newValue : Dynamic = getValue(runtime);
		if (newValue != lastValue) {
			showValue(newValue);
			runtime.interp.redraw();
		}
		lastValue = newValue;
		updateLabel();
	}

	private function updateLabel() : Void{
		// update in case variable name or sprite name changes

		if (cmd == "getVar:") {
			if (target.isStage) {
				setLabel(param);
			}
			else {
				setLabel(target.objName + ": " + param);
			}
		}
		else if (cmd == "sensor:") 
			setLabel(Translator.map(param + " sensor value"))
		else if (cmd == "sensorPressed:") 
			setLabel(Translator.map("sensor " + param + "?"))
		else if (cmd == "timeAndDate") 
			setLabel(Translator.map(param))
		else if (cmd == "senseVideoMotion") 
			setLabel(((target.isStage) ? "" : target.objName + ": ") + Translator.map("video " + param))
		else 
		setLabel(((target.isStage) ? "" : target.objName + ": ") + specForCmd());
	}

	private function specForCmd() : String{
		var i : Int = cmd.indexOf(".");
		//if (i > -1) {
			//var spec : Array<Dynamic> = Scratch.app.extensionManager.specForCmd(cmd);
			//if (spec != null)                 return cmd.substr(0, i) + ": " + spec[0];
		//}

		for (entry/* AS3HX WARNING could not determine type for var: entry exp: EField(EIdent(Specs),commands) type: null */ in Specs.commands){
			if (entry[3] == cmd)                 return Translator.map(entry[0]);
		}
		return "";
	}

	private function showValue(value : Dynamic) : Void{
		readout.setContents(formatValue(value));
		fixLayout();
	}

	private function getValue(runtime : ScratchRuntime) : Dynamic{
		if (target == null)             return "";
		if (targetIsVariable()) {
			var v : Variable = target.lookupVar(param);
			return ((v == null)) ? "unknown var: " + param : v.value;
		}
		var app : Scratch = runtime.app;
		if (cmd == "senseVideoMotion") {
			var prim : Block->Dynamic = app.interp.getPrim(cmd);
			if (prim == null)                 return 0;
			var block : Block = new Block("video %s on %s", "r", 0, "senseVideoMotion", [param, target.objName]);
			return prim(block);
		}
		if (Std.is(target, ScratchSprite)) {
			switch (cmd)
			{
				case "costumeIndex":return cast((target), ScratchSprite).costumeNumber();
				case "xpos":return cast((target), ScratchSprite).scratchX;
				case "ypos":return cast((target), ScratchSprite).scratchY;
				case "heading":return cast((target), ScratchSprite).direction;
				case "scale":return Math.round(cast((target), ScratchSprite).getSize());
			}
		}
		switch (cmd)
		{
			case "backgroundIndex":return app.stagePane.costumeNumber();
			case "sceneName":return app.stagePane.currentCostume().costumeName;
			case "tempo":return app.stagePane.tempoBPM;
			case "volume":return target.volume;
			case "answer":return runtime.lastAnswer;
			case "timer":return Math.round(10 * runtime.timer()) / 10;  // round to 10's of seconds  
			case "soundLevel":return runtime.soundLevel();
			case "isLoud":return runtime.isLoud();
			//case "sensor:":return runtime.getSensor(param);
			case "sensorPressed:":return runtime.getBooleanSensor(param);
			case "timeAndDate":return runtime.getTimeString(param);
			case "xScroll":return app.stagePane.xScroll;
			case "yScroll":return app.stagePane.yScroll;
		}

		//if (cmd.indexOf(".") > -1) {
			//var spec : Array<Dynamic> = Scratch.app.extensionManager.specForCmd(cmd);
			//if (spec != null) {
				//block = new Block(spec[0], spec[1], Specs.blockColor(spec[2]), spec[3]);
				//return Scratch.app.interp.evalCmd(block);
			//}
		//}

		return "unknown: " + cmd;
	}

	private function targetIsVariable() : Bool{return (cmd == "getVar:");
	}

	/* Layout */

	private function addLabel() : Void{
		label = new TextField();
		label.type = TextFieldType.DYNAMIC;
		label.selectable = false;
		label.defaultTextFormat = format;
		label.text = "";
		label.width = label.textWidth + 5;
		label.height = label.textHeight + 5;
		label.x = 4;
		label.y = 2;
		addChild(label);
	}

	private function setLabel(s : String) : Void{
		if (!label.visible || label.text == s)             return;  // no change  ;
		label.text = s;
		label.width = label.textWidth + 5;
		label.height = label.textHeight + 5;
		fixLayout();
	}

	private function addSliderAndKnob() : Void{
		slider = new Shape();  // slider is drawn by fixLayout()  
		//var f : BevelFilter = new BevelFilter(2);
		//f.angle = 225;
		//f.shadowAlpha = 0.5;
		//f.highlightAlpha = 0.5;
		//slider.filters = [f];
		slider.filters = [];
		addChild(slider);

		knob = new Shape();
		var g : Graphics = knob.graphics;
		g.lineStyle(1, 0x808080);
		g.beginFill(0xFFFFFF);
		g.drawCircle(5, 5, 5);
		//f = new BevelFilter(2);
		//f.blurX = f.blurY = 5;
		//knob.filters = [f];
		//knob.filters = [];
		addChild(knob);
	}

	private function fixLayout() : Void{
		adjustReadoutSize();
		if (mode == LARGE_MODE) {
			frame.visible = label.visible = false;
			readout.x = 0;
			readout.y = 3;
		}
		else {
			frame.visible = label.visible = true;
			readout.x = label.width + 8;
			readout.y = 3;
		}
		if (mode == SLIDER_MODE) {
			slider.visible = knob.visible = true;
			slider.x = 6;
			slider.y = 22;

			// re-draw slider
			var g : Graphics = slider.graphics;
			g.clear();
			g.beginFill(0xC0C0C0);
			g.drawRoundRect(0, 0, frame.w - 12, 5, 5, 5);

			setKnobPosition();
		}
		else {
			slider.visible = knob.visible = false;
		}
	}

	private function adjustReadoutSize() : Void{
		frame.w = Std.int(label.width + readout.width + 15);
		frame.h = ((mode == NORMAL_MODE)) ? 21 : 31;
		frame.setWidthHeight(frame.w, frame.h);
	}

	private function setKnobPosition() : Void{
		var fraction : Float = (Std.parseFloat(readout.contents) - sliderMin) / (sliderMax - sliderMin);
		fraction = Math.max(0, Math.min(fraction, 1));
		var xOffset : Int = Math.round(fraction * (slider.width - 10));
		knob.x = slider.x + xOffset;
		knob.y = slider.y - 3;
	}

	/* Dragging */

	public function objToGrab(evt : MouseEvent) : Watcher{return this;
	}  // allow dragging  

	/* Double-Click */

	public function doubleClick(evt : MouseEvent) : Void{
		if (!Scratch.app.editMode)             return;
		var newMode : Int = mode + 1;
		if (targetIsVariable()) {
			if (newMode > 3)                 newMode = 1;
		}
		else {
			if (newMode > 2)                 newMode = 1;
		}
		setMode(newMode);
	}

	/* Menu */

	public function menu(evt : MouseEvent) : Menu{
		function handleMenu(item : Int) : Void{
			if ((1 <= item) && (item <= 3))                 setMode(item);
			if (5 == item)                 sliderMinMaxDialog();
			if (item == 10) {
				visible = false;
				Scratch.app.updatePalette(false);
			}
		};
		if (!Scratch.app.editMode)             return null;
		var m : Menu = new Menu(handleMenu);
		m.addItem("normal readout", 1);
		m.addItem("large readout", 2);
		if (targetIsVariable()) {
			m.addItem("slider", 3);
			//			m.addItem("text", 4);
			if (mode == SLIDER_MODE) {
				m.addLine();
				m.addItem("set slider min and max", 5);
			}
		}
		m.addLine();
		m.addItem("hide", 10);
		return m;
	}

	private function sliderMinMaxDialog() : Void{
		var d : DialogBox = null;
		function setMinMax(param:Dynamic) : Void{
			var min : String = d.getField("Min");
			var max : String = d.getField("Max");
			var minVal : Float = Std.parseFloat(min);
			var maxVal : Float = Std.parseFloat(max);
			if (Math.isNaN(minVal) || Math.isNaN(maxVal))                 return;
			sliderMin = Math.min(minVal, maxVal);
			sliderMax = Math.max(minVal, maxVal);
			isDiscrete = (min.indexOf(".") < 0) && (max.indexOf(".") < 0);
			setSliderValue(sliderMin);
			Scratch.app.setSaveNeeded();
		};
		d = new DialogBox(setMinMax);
		d.addTitle("Slider Range");
		d.addField('Min', 120, isDiscrete || Std.int(sliderMin) != sliderMin ? sliderMin : Std.int(sliderMin) + '.0');
		d.addField("Max", 120, sliderMax);
		d.addAcceptCancelButtons("OK");
		d.showOnStage(stage);
	}

	/* Slider */

	private function mouseDown(evt : MouseEvent) : Void{
		if (mode != SLIDER_MODE)             return;
		var p : Point = globalToLocal(new Point(evt.stageX, evt.stageY));
		if (p.y > 20)             Scratch.app.gh.setDragClient(this, evt);
	}

	public function dragBegin(evt : MouseEvent) : Void{
		mouseMoved = false;
	}

	public function dragMove(evt : MouseEvent) : Void{
		var p : Point = globalToLocal(new Point(evt.stageX, evt.stageY));
		var xOffset : Float = p.x - slider.x - 4;
		setSliderValue(((xOffset / (slider.width - 10)) * (sliderMax - sliderMin)) + sliderMin);
		mouseMoved = true;
	}

	public function dragEnd(evt : MouseEvent) : Void{
		var p : Point = globalToLocal(new Point(evt.stageX, evt.stageY));
		if (!mouseMoved)             clickAt(p.x);
	}

	private function clickAt(localX : Float) : Void{
		var sign : Float = ((localX < knob.x)) ? -1 : 1;
		var delta : Float = ((isDiscrete)) ? sign : sign * ((sliderMax - sliderMin) / 100.0);
		setSliderValue(Std.parseFloat(readout.contents) + delta);
	}

	private function setSliderValue(newValue : Float) : Void{
		var sliderVal : Float = (isDiscrete) ? Math.round(newValue) : Math.round(newValue * 100) / 100;
		sliderVal = Math.max(sliderMin, Math.min(sliderVal, sliderMax));
		if (target != null)             target.setVarTo(param, sliderVal);
		showValue(sliderVal);
	}

	// JSON save/restore

	public function writeJSON(json : util.JSON) : Void{
		json.writeKeyValue("target", target.objName);
		json.writeKeyValue("cmd", cmd);
		json.writeKeyValue("param", param);
		json.writeKeyValue("color", readout.getColor());
		json.writeKeyValue("label", label.text);
		json.writeKeyValue("mode", mode);
		json.writeKeyValue("sliderMin", sliderMin);
		json.writeKeyValue("sliderMax", sliderMax);
		json.writeKeyValue("isDiscrete", isDiscrete);
		json.writeKeyValue("x", x);
		json.writeKeyValue("y", y);
		json.writeKeyValue("visible", visible);
	}

	public function readJSON(obj : Dynamic) : Void{
		if (obj.cmd == "getVar:")             initForVar(obj.target, obj.param)
		else initWatcher(obj.target, obj.cmd, obj.param, obj.color);
		sliderMin = obj.sliderMin;
		sliderMax = obj.sliderMax;
		isDiscrete = obj.isDiscrete;
		setMode(obj.mode);
		x = obj.x;
		y = obj.y;
		visible = obj.visible;
	}
}

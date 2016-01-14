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

package scratch;


import openfl.display.*;
import openfl.events.*;
import openfl.geom.*;
import openfl.ui.*;
import blocks.*;
import filters.*;
import sound.*;
import translation.Translator;
import ui.ProcedureSpecEditor;
import uiwidgets.*;
import util.*;

class BlockMenus implements DragClient
{

	private var app : Scratch;
	private var startX : Float;
	private var startY : Float;
	private var block : Block;
	private var blockArg : BlockArg;  // null if menu is invoked on a block  

	private static var basicMathOps : Array<Dynamic> = ["+", "-", "*", "/"];
	private static var comparisonOps : Array<Dynamic> = ["<", "=", ">"];

	private static var spriteAttributes : Array<Dynamic> = ["x position", "y position", "direction", "costume #", "costume name", "size", "volume"];
	private static var stageAttributes : Array<Dynamic> = ["backdrop #", "backdrop name", "volume"];

	public static function BlockMenuHandler(evt : MouseEvent, parent: Dynamic, blockArg : BlockArg = null, menuName : String = null) : Void {
		var block : Block = parent;
		var menuHandler : BlockMenus = new BlockMenus(block, blockArg);
		var op : String = block.op;
		if (menuName == null) {  // menu gesture on a block (vs. an arg)  
			if (op == Specs.GET_LIST)                 menuName = "list";
			if (op == Specs.GET_VAR)                 menuName = "var";
			if ((op == Specs.PROCEDURE_DEF) || (op == Specs.CALL))                 menuName = "procMenu";
			if ((op == "broadcast:") || (op == "doBroadcastAndWait") || (op == "whenIReceive"))                 menuName = "broadcastInfoMenu";
			if ((Lambda.indexOf(basicMathOps, op)) > -1) {menuHandler.changeOpMenu(evt, basicMathOps);return;
			}
			if ((Lambda.indexOf(comparisonOps, op)) > -1) {menuHandler.changeOpMenu(evt, comparisonOps);return;
			}
			if (menuName == null) {menuHandler.genericBlockMenu(evt);return;
			}
		}
		if (op.indexOf(".") > -1 && menuHandler.extensionMenu(evt, menuName))             return;
		if (menuName == "attribute")             menuHandler.attributeMenu(evt);
		if (menuName == "backdrop")             menuHandler.backdropMenu(evt);
		if (menuName == "booleanSensor")             menuHandler.booleanSensorMenu(evt);
		if (menuName == "broadcast")             menuHandler.broadcastMenu(evt);
		if (menuName == "broadcastInfoMenu")             menuHandler.broadcastInfoMenu(evt);
		if (menuName == "colorPicker")             menuHandler.colorPicker(evt);
		if (menuName == "costume")             menuHandler.costumeMenu(evt);
		if (menuName == "direction")             menuHandler.dirMenu(evt);
		//if (menuName == "drum")             menuHandler.drumMenu(evt);
		if (menuName == "effect")             menuHandler.effectMenu(evt);
		//if (menuName == "instrument")             menuHandler.instrumentMenu(evt);
		if (menuName == "key")             menuHandler.keyMenu(evt);
		if (menuName == "list")             menuHandler.listMenu(evt);
		if (menuName == "listDeleteItem")             menuHandler.listItem(evt, true);
		if (menuName == "listItem")             menuHandler.listItem(evt, false);
		if (menuName == "mathOp")             menuHandler.mathOpMenu(evt);
		if (menuName == "motorDirection")             menuHandler.motorDirectionMenu(evt);
		//if (menuName == "note")             menuHandler.notePicker(evt);
		if (menuName == "procMenu")             menuHandler.procMenu(evt);
		if (menuName == "rotationStyle")             menuHandler.rotationStyleMenu(evt);
		if (menuName == "scrollAlign")             menuHandler.scrollAlignMenu(evt);
		if (menuName == "sensor")             menuHandler.sensorMenu(evt);
		if (menuName == "sound")             menuHandler.soundMenu(evt);
		if (menuName == "spriteOnly")             menuHandler.spriteMenu(evt, false, false, false, true);
		if (menuName == "spriteOrMouse")             menuHandler.spriteMenu(evt, true, false, false, false);
		if (menuName == "spriteOrStage")             menuHandler.spriteMenu(evt, false, false, true, false);
		if (menuName == "touching")             menuHandler.spriteMenu(evt, true, true, false, false);
		if (menuName == "stageOrThis")             menuHandler.stageOrThisSpriteMenu(evt);
		if (menuName == "stop")             menuHandler.stopMenu(evt);
		if (menuName == "timeAndDate")             menuHandler.timeAndDateMenu(evt);
		if (menuName == "triggerSensor")             menuHandler.triggerSensorMenu(evt);
		if (menuName == "var")             menuHandler.varMenu(evt);
		if (menuName == "videoMotionType")             menuHandler.videoMotionTypeMenu(evt);
		if (menuName == "videoState")             menuHandler.videoStateMenu(evt);
	}

	public static function strings() : Array<String>{
		// Exercises all the menus to cause their items to be recorded.
		// Return a list of additional strings (e.g. from the key menu).
		var events : Array<Dynamic> = [new MouseEvent("dummy"), new MouseEvent("shift-dummy")];
		events[1].shiftKey = true;
		var handler : BlockMenus = new BlockMenus(new Block("dummy"), null);
		for (evt in events){
			handler.attributeMenu(evt);
			handler.backdropMenu(evt);
			handler.booleanSensorMenu(evt);
			handler.broadcastMenu(evt);
			handler.broadcastInfoMenu(evt);
			handler.costumeMenu(evt);
			handler.dirMenu(evt);
			//handler.drumMenu(evt);
			handler.effectMenu(evt);
			handler.genericBlockMenu(evt);
			//handler.instrumentMenu(evt);
			handler.listMenu(evt);
			handler.listItem(evt, true);
			handler.listItem(evt, false);
			handler.mathOpMenu(evt);
			handler.motorDirectionMenu(evt);
			handler.procMenu(evt);
			handler.rotationStyleMenu(evt);
			//			handler.scrollAlignMenu(evt);
			handler.sensorMenu(evt);
			handler.soundMenu(evt);
			handler.spriteMenu(evt, false, false, false, true);
			handler.spriteMenu(evt, true, false, false, false);
			handler.spriteMenu(evt, false, false, true, false);
			handler.spriteMenu(evt, true, true, false, false);
			handler.stageOrThisSpriteMenu(evt);
			handler.stopMenu(evt);
			handler.timeAndDateMenu(evt);
			handler.triggerSensorMenu(evt);
			handler.varMenu(evt);
			handler.videoMotionTypeMenu(evt);
			handler.videoStateMenu(evt);
		}
		return [
		"up arrow", "down arrow", "right arrow", "left arrow", "space", 
		"other scripts in sprite", "other scripts in stage", 
		"backdrop #", "backdrop name", "volume", "OK", "Cancel", 
		"Edit Block", "Rename", "New name", "Delete", "Broadcast", "New Message", "Message Name", 
		"delete variable", "rename variable", 
		"video motion", "video direction", 
		"Low C", "Middle C", "High C"];
	}

	public function new(block : Block, blockArg : BlockArg)
	{
		app = Scratch.app;
		this.startX = app.mouseX;
		this.startY = app.mouseY;
		this.blockArg = blockArg;
		this.block = block;
	}

	public static function shouldTranslateItemForMenu(item : String, menuName : String) : Bool{
		// Return true if the given item from the given menu parameter slot should be
		// translated. This mechanism prevents translating proper names such as sprite,
		// costume, or variable names.
		function isGeneric(s : String) : Bool{
			return ["duplicate", "delete", "add comment", "clean up"].indexOf(s) > -1;
		};
		switch (menuName)
		{
			case "attribute":
				return Lambda.indexOf(spriteAttributes, item) > -1 || Lambda.indexOf(stageAttributes, item) > -1;
			case "backdrop":
				return ["next backdrop", "previous backdrop"].indexOf(item) > -1;
			case "broadcast":
				return ["new message..."].indexOf(item) > -1;
			case "costume":
				return false;
			case "list":
				if (isGeneric(item))                     return true;
				return ["delete list"].indexOf(item) > -1;
			case "sound":
				return ["record..."].indexOf(item) > -1;
			case "sprite", "spriteOnly", "spriteOrMouse", "spriteOrStage", "touching":
				return false;  // handled directly by menu code  
			case "var":
				if (isGeneric(item))                     return true;
				return ["delete variable", "rename variable"].indexOf(item) > -1;
		}
		return true;
	}

	private function showMenu(m : Menu) : Void{
		m.color = block.base.color;
		m.itemHeight = 22;
		if (blockArg != null) {
			var p : Point = blockArg.localToGlobal(new Point(0, blockArg.height));
			m.showOnStage(app.stage, Std.int(p.x - 9), Std.int(p.y));
		}
		else {
			m.showOnStage(app.stage);
		}
	}

	private function setBlockArg(selection : Dynamic) : Void{
		if (blockArg != null)             blockArg.setArgValue(selection);
		Scratch.app.setSaveNeeded();
		///* AS3HX WARNING namespace modifier SCRATCH::allow3d */{Scratch.app.runtime.checkForGraphicEffects();
		//}
	}

	private function attributeMenu(evt : MouseEvent) : Void{
		var obj : ScratchObj = null;
		if (block != null && block.args[1]) {
			obj = app.stagePane.objNamed(block.args[1].argValue);
		}
		var attributes : Array<Dynamic> = Std.is(obj, ScratchStage) ? stageAttributes : spriteAttributes;
		var m : Menu = new Menu(setBlockArg, "attribute");
		for (s in attributes)m.addItem(s);
		if (Std.is(obj, ScratchObj)) {
			m.addLine();
			var varNames = obj.varNames();
			varNames.sort(function(a, b) { 
				if (a < b) return -1;
				if (b > a) return 1;
				return 0;
			});
			for (s in varNames)
				m.addItem(s);
		}
		showMenu(m);
	}

	private function backdropMenu(evt : MouseEvent) : Void{
		var m : Menu = new Menu(setBlockArg, "backdrop");
		for (scene in app.stageObj().costumes){
			m.addItem(scene.costumeName);
		}
		if (block != null && block.op.indexOf("startScene") > -1 || Menu.stringCollectionMode) {
			m.addLine();
			m.addItem("next backdrop");
			m.addItem("previous backdrop");
		}
		showMenu(m);
	}

	private function booleanSensorMenu(evt : MouseEvent) : Void{
		var sensorNames : Array<Dynamic> = [
		"button pressed", "A connected", "B connected", "C connected", "D connected"];
		var m : Menu = new Menu(setBlockArg, "booleanSensor");
		for (s in sensorNames)m.addItem(s);
		showMenu(m);
	}

	private function colorPicker(evt : MouseEvent) : Void{
		app.gh.setDragClient(this, evt);
	}

	private function costumeMenu(evt : MouseEvent) : Void{
		var m : Menu = new Menu(setBlockArg, "costume");
		if (app.viewedObj() == null)             return;
		for (c in app.viewedObj().costumes){
			m.addItem(c.costumeName);
		}
		showMenu(m);
	}

	private function dirMenu(evt : MouseEvent) : Void{
		var m : Menu = new Menu(setBlockArg, "direction");
		m.addItem("(90) " + Translator.map("right"), 90);
		m.addItem("(-90) " + Translator.map("left"), -90);
		m.addItem("(0) " + Translator.map("up"), 0);
		m.addItem("(180) " + Translator.map("down"), 180);
		showMenu(m);
	}

	//private function drumMenu(evt : MouseEvent) : Void{
		//var m : Menu = new Menu(setBlockArg, "drum");
		//for (i in 1...SoundBank.drumNames.length + 1){
			//m.addItem("(" + i + ") " + Translator.map(SoundBank.drumNames[i - 1]), i);
		//}
		//showMenu(m);
	//}

	private function effectMenu(evt : MouseEvent) : Void{
		var m : Menu = new Menu(setBlockArg, "effect");
		if (app.viewedObj() == null)             return;
		for (s in FilterPack.filterNames)m.addItem(s);
		showMenu(m);
	}

	private function extensionMenu(evt : MouseEvent, menuName : String) : Bool{
		//var items : Array<Dynamic> = app.extensionManager.menuItemsFor(block.op, menuName);
		//if (items == null)             return false;
		//var m : Menu = new Menu(setBlockArg);
		//for (s in items)m.addItem(s);
		//showMenu(m);
		//return true;
		return false;
	}

	//private function instrumentMenu(evt : MouseEvent) : Void{
		//var m : Menu = new Menu(setBlockArg, "instrument");
		//for (i in 1...SoundBank.instrumentNames.length + 1){
			//m.addItem("(" + i + ") " + Translator.map(SoundBank.instrumentNames[i - 1]), i);
		//}
		//showMenu(m);
	//}

	private function keyMenu(evt : MouseEvent) : Void{
		var ch : Int;
		var namedKeys : Array<Dynamic> = ["space", "up arrow", "down arrow", "right arrow", "left arrow", "any"];
		var m : Menu = new Menu(setBlockArg, "key");
		for (s in namedKeys)m.addItem(s);
		for (ch in 97...123){m.addItem(String.fromCharCode(ch));
		}  // a-z  
		for (ch in 48...58){m.addItem(String.fromCharCode(ch));
		}  // 0-9  
		showMenu(m);
	}

	private function listItem(evt : MouseEvent, forDelete : Bool) : Void{
		var m : Menu = new Menu(setBlockArg, "listItem");
		m.addItem("1");
		m.addItem("last");
		if (forDelete) {
			m.addLine();
			m.addItem("all");
		}
		else {
			m.addItem("random");
		}
		showMenu(m);
	}

	private function mathOpMenu(evt : MouseEvent) : Void{
		var ops : Array<Dynamic> = ["abs", "floor", "ceiling", "sqrt", "sin", "cos", "tan", "asin", "acos", "atan", "ln", "log", "e ^", "10 ^"];
		var m : Menu = new Menu(setBlockArg, "mathOp");
		for (op in ops)m.addItem(op);
		showMenu(m);
	}

	private function motorDirectionMenu(evt : MouseEvent) : Void{
		var ops : Array<Dynamic> = ["this way", "that way", "reverse"];
		var m : Menu = new Menu(setBlockArg, "motorDirection");
		for (s in ops)m.addItem(s);
		showMenu(m);
	}

	//private function notePicker(evt : MouseEvent) : Void{
		//var piano : Piano = new Piano(block.base.color, app.viewedObj().instrument, setBlockArg);
		//if (!Math.isNaN(blockArg.argValue)) {
			//piano.selectNote(Std.parseInt(blockArg.argValue));
		//}
		//var p : Point = blockArg.localToGlobal(new Point(blockArg.width, blockArg.height));
		//piano.showOnStage(app.stage, Std.parseInt(p.x - piano.width / 2), p.y);
	//}

	private function rotationStyleMenu(evt : MouseEvent) : Void{
		var rotationStyles : Array<Dynamic> = ["left-right", "don't rotate", "all around"];
		var m : Menu = new Menu(setBlockArg, "rotationStyle");
		for (s in rotationStyles)m.addItem(s);
		showMenu(m);
	}

	private function scrollAlignMenu(evt : MouseEvent) : Void{
		var options : Array<Dynamic> = [
		"bottom-left", "bottom-right", "middle", "top-left", "top-right"];
		var m : Menu = new Menu(setBlockArg, "scrollAlign");
		for (s in options)m.addItem(s);
		showMenu(m);
	}

	private function sensorMenu(evt : MouseEvent) : Void{
		var sensorNames : Array<Dynamic> = [
		"slider", "light", "sound", 
		"resistance-A", "resistance-B", "resistance-B", "resistance-C", "resistance-D"];
		var m : Menu = new Menu(setBlockArg, "sensor");
		for (s in sensorNames)m.addItem(s);
		showMenu(m);
	}

	private function soundMenu(evt : MouseEvent) : Void{
		function setSoundArg(s : Dynamic) : Void{
			if (Reflect.isFunction(s))                 s();
			else setBlockArg(s);
		};
		var m : Menu = new Menu(setSoundArg, "sound");
		if (app.viewedObj() == null)             return;
		for (i in 0...app.viewedObj().sounds.length){
			m.addItem(app.viewedObj().sounds[i].soundName);
		}
		m.addLine();
		m.addItem("record...", recordSound);
		showMenu(m);
	}

	private function recordSound() : Void{
		app.setTab("sounds");
		app.soundsPart.recordSound();
	}

	private function spriteMenu(evt : MouseEvent, includeMouse : Bool, includeEdge : Bool, includeStage : Bool, includeSelf : Bool) : Void{
		function setSpriteArg(s : Dynamic) : Void{
			if (blockArg == null)                 return;
			if (s == "edge")                 blockArg.setArgValue("_edge_", Translator.map("edge"))
			else if (s == "mouse-pointer")                 blockArg.setArgValue("_mouse_", Translator.map("mouse-pointer"))
			else if (s == "myself")                 blockArg.setArgValue("_myself_", Translator.map("myself"))
			else if (s == "Stage")                 blockArg.setArgValue("_stage_", Translator.map("Stage"))
			else blockArg.setArgValue(s);
			if (block.op == "getAttribute:of:") {
				var obj : ScratchObj = app.stagePane.objNamed(s);
				var attr : String = block.args[0].argValue;
				var validAttrs : Array<Dynamic> = obj != null && (obj.isStage) ? stageAttributes : spriteAttributes;
				if (Lambda.indexOf(validAttrs, attr) == -1 && !obj.ownsVar(attr)) {
					block.args[0].setArgValue(validAttrs[0]);
				}
			}
			Scratch.app.setSaveNeeded();
		};
		var spriteNames : Array<String> = [];
		var m : Menu = new Menu(setSpriteArg, "sprite");
		if (includeMouse)             m.addItem(Translator.map("mouse-pointer"), "mouse-pointer");
		if (includeEdge)             m.addItem(Translator.map("edge"), "edge");
		m.addLine();
		if (includeStage) {
			m.addItem(app.stagePane.objName, "Stage");
			m.addLine();
		}
		if (includeSelf && !app.viewedObj().isStage) {
			m.addItem(Translator.map("myself"), "myself");
			m.addLine();
			spriteNames.push(app.viewedObj().objName);
		}
		for (sprite in app.stagePane.sprites()){
			if (sprite != app.viewedObj())                 spriteNames.push(sprite.objName);
		}
		spriteNames.sort(function(a, b) {
			if (a.toLowerCase() < b.toLowerCase()) return -1;
			if (a.toLowerCase() > b.toLowerCase()) return 1;
			return 0;
		});
		for (spriteName in spriteNames){
			m.addItem(spriteName);
		}
		showMenu(m);
	}

	private function stopMenu(evt : MouseEvent) : Void{
		function setStopType(selection : Dynamic) : Void{
			blockArg.setArgValue(selection);
			block.setTerminal((selection == "all") || (selection == "this script"));
			block.type = (block.isTerminal) ? "f" : " ";
			Scratch.app.setSaveNeeded();
		};
		var m : Menu = new Menu(setStopType, "stop");
		if (block.nextBlock == null) {
			m.addItem("all");
			m.addItem("this script");
		}
		m.addItem((app.viewedObj().isStage) ? "other scripts in stage" : "other scripts in sprite");
		showMenu(m);
	}

	private function stageOrThisSpriteMenu(evt : MouseEvent) : Void{
		var m : Menu = new Menu(setBlockArg, "stageOrThis");
		m.addItem(app.stagePane.objName);
		if (!app.viewedObj().isStage)             m.addItem("this sprite");
		showMenu(m);
	}

	private function timeAndDateMenu(evt : MouseEvent) : Void{
		var m : Menu = new Menu(setBlockArg, "timeAndDate");
		m.addItem("year");
		m.addItem("month");
		m.addItem("date");
		m.addItem("day of week");
		m.addItem("hour");
		m.addItem("minute");
		m.addItem("second");
		showMenu(m);
	}

	private function triggerSensorMenu(evt : MouseEvent) : Void{
		function setTriggerType(s : String) : Void{
			if ("video motion" == s)                 app.libraryPart.showVideoButton();
			setBlockArg(s);
		};
		var m : Menu = new Menu(setTriggerType, "triggerSensor");
		m.addItem("loudness");
		m.addItem("timer");
		m.addItem("video motion");
		showMenu(m);
	}

	private function videoMotionTypeMenu(evt : MouseEvent) : Void{
		var m : Menu = new Menu(setBlockArg, "videoMotion");
		m.addItem("motion");
		m.addItem("direction");
		showMenu(m);
	}

	private function videoStateMenu(evt : MouseEvent) : Void{
		var m : Menu = new Menu(setBlockArg, "videoState");
		m.addItem("off");
		m.addItem("on");
		m.addItem("on-flipped");
		showMenu(m);
	}

	// ***** Generic block menu *****

	private function genericBlockMenu(evt : MouseEvent) : Void{
		if (block == null || block.isEmbeddedParameter())             return;
		var m : Menu = new Menu(null, "genericBlock");
		addGenericBlockItems(m);
		showMenu(m);
	}

	private function addGenericBlockItems(m : Menu) : Void{
		if (block == null)             return;
		m.addLine();
		if (!isInPalette(block)) {
			if (!block.isProcDef()) {
				m.addItem("duplicate", duplicateStack);
			}
			m.addItem("delete", block.deleteStack);
			m.addLine();
			m.addItem("add comment", block.addComment);
		}
		m.addItem("help", block.showHelp);
		m.addLine();
	}

	private function duplicateStack() : Void{
		block.duplicateStack(app.mouseX - startX, app.mouseY - startY);
	}

	private function changeOpMenu(evt : MouseEvent, opList : Array<Dynamic>) : Void{
		function opMenu(selection : Dynamic) : Void{
			if (Reflect.isFunction(selection)) {selection();return;
			}
			block.changeOperator(selection);
		};
		if (block == null)             return;
		var m : Menu = new Menu(opMenu, "changeOp");
		addGenericBlockItems(m);
		if (!isInPalette(block))             for (op in opList)m.addItem(op);
		showMenu(m);
	}

	// ***** Procedure menu (for procedure definition hats and call blocks) *****

	private function procMenu(evt : MouseEvent) : Void{
		var m : Menu = new Menu(null, "proc");
		addGenericBlockItems(m);
		m.addItem("edit", editProcSpec);
		if (block.op == Specs.CALL) {
			m.addItem("define", jumpToProcDef);
		}
		showMenu(m);
	}

	private function jumpToProcDef() : Void{
		if (!app.editMode)             return;
		if (block.op != Specs.CALL)             return;
		var def : Block = app.viewedObj().lookupProcedure(block.spec);
		if (def == null)             return;
		var pane : ScriptsPane = try cast(def.parent, ScriptsPane) catch(e:Dynamic) null;
		if (pane == null)             return;
		if (Std.is(pane.parent, ScrollFrame)) {
			pane.x = 5 - def.x * pane.scaleX;
			pane.y = 5 - def.y * pane.scaleX;
			cast(pane.parent, ScrollFrame).constrainScroll();
			cast(pane.parent, ScrollFrame).updateScrollbars();
		}
	}

	private function editProcSpec() : Void{
		if (block.op == Specs.CALL) {
			var def : Block = app.viewedObj().lookupProcedure(block.spec);
			if (def == null)                 return;
			block = def;
		}
		var d : DialogBox = new DialogBox(editSpec2);
		d.addTitle("Edit Block");
		d.addWidget(new ProcedureSpecEditor(block.spec, block.parameterNames, block.warpProcFlag));
		d.addAcceptCancelButtons("OK");
		d.showOnStage(app.stage, true);
		cast((d.widget), ProcedureSpecEditor).setInitialFocus();
	}

	private function editSpec2(dialog : DialogBox) : Void{
		var newSpec : String = cast((dialog.widget), ProcedureSpecEditor).spec();
		if (newSpec.length == 0)             return;
		if (block != null) {
			var oldSpec : String = block.spec;
			block.parameterNames = cast((dialog.widget), ProcedureSpecEditor).inputNames();
			block.defaultArgValues = cast((dialog.widget), ProcedureSpecEditor).defaultArgValues();
			block.warpProcFlag = cast((dialog.widget), ProcedureSpecEditor).warpFlag();
			block.setSpec(newSpec);
			if (block.nextBlock != null)                 block.nextBlock.allBlocksDo(function(b : Block) : Void{
						if (b.op == Specs.GET_PARAM)                             b.parameterIndex = -1;  // parameters may have changed; clear cached indices  ;
					});
			for (caller in app.runtime.allCallsOf(oldSpec, app.viewedObj())){
				var oldArgs : Array<Dynamic> = caller.args;
				caller.setSpec(newSpec, block.defaultArgValues);
				for (i in 0...oldArgs.length){
					var arg : Dynamic = oldArgs[i];
					if (Std.is(arg, BlockArg))                         arg = arg.argValue;
					caller.setArg(i, arg);
				}
				caller.fixArgLayout();
			}
		}
		app.runtime.updateCalls();
		app.scriptsPane.fixCommentLayout();
		app.updatePalette();
	}

	// ***** Variable and List menus *****

	private function listMenu(evt : MouseEvent) : Void{
		var m : Menu = new Menu(varOrListSelection, "list");
		var isGetter : Bool = block.op == Specs.GET_LIST;
		if (isGetter) {
			if (isInPalette(block))                 m.addItem("delete list", deleteVarOrList);  // list reporter in palette  ;
			addGenericBlockItems(m);
			m.addLine();
		}
		var myName : String = (isGetter) ? blockVarOrListName() : null;
		var listName : String;
		for (listName in app.stageObj().listNames()){
			if (listName != myName)                 m.addItem(listName);
		}
		if (!app.viewedObj().isStage) {
			m.addLine();
			for (listName in app.viewedObj().listNames()){
				if (listName != myName)                     m.addItem(listName);
			}
		}
		showMenu(m);
	}

	private function varMenu(evt : MouseEvent) : Void{
		var m : Menu = new Menu(varOrListSelection, "var");
		var isGetter : Bool = (block.op == Specs.GET_VAR);
		if (isGetter && isInPalette(block)) {  // var reporter in palette  
			m.addItem("rename variable", renameVar);
			m.addItem("delete variable", deleteVarOrList);
			addGenericBlockItems(m);
		}
		else {
			if (isGetter)                 addGenericBlockItems(m);
			var myName : String = blockVarOrListName();
			for (vName in app.stageObj().varNames()){
				if (!isGetter || (vName != myName))                     m.addItem(vName);
			}
			if (!app.viewedObj().isStage) {
				m.addLine();
				for (vName in app.viewedObj().varNames()){
					if (!isGetter || (vName != myName))                         m.addItem(vName);
				}
			}
		}
		showMenu(m);
	}

	private function isInPalette(b : Block) : Bool{
		var o : DisplayObject = b;
		while (o != null){
			if (o == app.palette)                 return true;
			o = o.parent;
		}
		return false;
	}

	private function varOrListSelection(selection : Dynamic) : Void{
		if (Reflect.isFunction(selection)) {selection();return;
		}
		setBlockVarOrListName(selection);
	}

	private function renameVar() : Void{
		var oldName : String = blockVarOrListName();
		function doVarRename(dialog : DialogBox) : Void{
			var newName : String = dialog.getField("New name").replace(new EReg('^\\s+|\\s+$', "g"), "");
			if (newName.length == 0 || block.op != Specs.GET_VAR)                 return;

			if (oldName.charAt(0) == "\u2601") {  // Retain the cloud symbol  
				newName = "\u2601 " + newName;
			}

			app.runtime.renameVariable(oldName, newName);
		};
		var d : DialogBox = new DialogBox(doVarRename);
		d.addTitle(Translator.map("Rename") + " " + blockVarOrListName());
		d.addField("New name", 120, oldName);
		d.addAcceptCancelButtons("OK");
		d.showOnStage(app.stage);
	}

	private function deleteVarOrList() : Void{
		function doDelete(selection : Dynamic) : Void{
			if (block.op == Specs.GET_VAR) {
				app.runtime.deleteVariable(blockVarOrListName());
			}
			else {
				app.runtime.deleteList(blockVarOrListName());
			}
			app.updatePalette();
			app.setSaveNeeded();
		};
		DialogBox.confirm(Translator.map("Delete") + " " + blockVarOrListName() + "?", app.stage, doDelete);
	}

	private function blockVarOrListName() : String{
		return ((blockArg != null)) ? blockArg.argValue : block.spec;
	}

	private function setBlockVarOrListName(newName : String) : Void{
		if (newName.length == 0)             return;
		if ((block.op == Specs.GET_VAR) || (block.op == Specs.SET_VAR) || (block.op == Specs.CHANGE_VAR)) {
			app.runtime.createVariable(newName);
		}
		if (blockArg != null)             blockArg.setArgValue(newName);
		if (block != null && (block.op == Specs.GET_VAR || block.op == Specs.GET_LIST)) {
			block.setSpec(newName);
			block.fixExpressionLayout();
		}
		Scratch.app.setSaveNeeded();
	}

	// ***** Color picker support *****

	public function dragBegin(evt : MouseEvent) : Void{
	}

	public function dragEnd(evt : MouseEvent) : Void{
		if (pickingColor) {
			pickingColor = false;
			//Mouse.cursor = MouseCursor.AUTO;
			app.stage.removeChild(colorPickerSprite);
			app.stage.removeEventListener(Event.RESIZE, fixColorPickerLayout);
		}
		else {
			pickingColor = true;
			app.gh.setDragClient(this, evt);
			//Mouse.cursor = MouseCursor.BUTTON;
			app.stage.addEventListener(Event.RESIZE, fixColorPickerLayout);
			app.stage.addChild(colorPickerSprite = new Sprite());
			fixColorPickerLayout();
		}
	}

	public function dragMove(evt : MouseEvent) : Void{
		if (pickingColor) {
			blockArg.setArgValue(pixelColorAt(Std.int(evt.stageX), Std.int(evt.stageY)));
			Scratch.app.setSaveNeeded();
		}
	}

	private function fixColorPickerLayout(event : Event = null) : Void{
		var g : Graphics = colorPickerSprite.graphics;
		g.clear();
		g.beginFill(0, 0);
		g.drawRect(0, 0, app.stage.stageWidth, app.stage.stageHeight);
	}

	private var pickingColor : Bool = false;
	private var colorPickerSprite : Sprite;
	private var onePixel : BitmapData = new BitmapData(1, 1);

	private function pixelColorAt(x : Int, y : Int) : Int{
		var m : Matrix = new Matrix();
		m.translate(-x, -y);
		onePixel.fillRect(onePixel.rect, 0);
		if (app.isIn3D)             app.stagePane.visible = true;
		onePixel.draw(app.rootDisplayObject(), m);
		if (app.isIn3D)             app.stagePane.visible = false;
		var x : Int = onePixel.getPixel32(0, 0);
		return (x != 0) ? x | 0xFF000000 : 0xFFFFFFFF;
	}

	// ***** Broadcast menu *****

	private function renameBroadcast() : Void{
		function doVarRename(dialog : DialogBox) : Void{
			var newName : String = dialog.getField("New name").replace(new EReg('^\\s+|\\s+$', "g"), "");
			if (newName.length == 0)                 return;
			var oldName : String = block.broadcastMsg;

			app.runtime.renameBroadcast(oldName, newName);
		};
		var d : DialogBox = new DialogBox(doVarRename);
		d.addTitle(Translator.map("Rename") + " " + block.broadcastMsg);
		d.addField("New name", 120, block.broadcastMsg);
		d.addAcceptCancelButtons("OK");
		d.showOnStage(app.stage);
	}

	private function broadcastMenu(evt : MouseEvent) : Void{
		function broadcastMenuSelection(selection : Dynamic) : Void{
			if (Reflect.isFunction(selection))                 selection()
			else setBlockArg(selection);
		};
		var msgNames : Array<String> = app.runtime.collectBroadcasts();
		if (Lambda.indexOf(msgNames, "message1") <= -1)             msgNames.push("message1");
		msgNames.sort(function(a, b) { 
				if (a < b) return -1;
				if (b > a) return 1;
				return 0;
			});

		var m : Menu = new Menu(broadcastMenuSelection, "broadcast");
		for (msg in msgNames)m.addItem(msg);
		m.addLine();
		m.addItem("new message...", newBroadcast);
		showMenu(m);
	}

	private function newBroadcast() : Void{
		function changeBroadcast(dialog : DialogBox) : Void{
			var newName : String = dialog.getField("Message Name");
			if (newName.length == 0)                 return;
			setBlockArg(newName);
		};
		var d : DialogBox = new DialogBox(changeBroadcast);
		d.addTitle("New Message");
		d.addField("Message Name", 120);
		d.addAcceptCancelButtons("OK");
		d.showOnStage(app.stage);
	}

	private function broadcastInfoMenu(evt : MouseEvent) : Void{
		function showBroadcasts(selection : Dynamic) : Void{
			if (Reflect.isFunction(selection)) {selection();return;
			}
			var msg : String = block.args[0].argValue;
			var sprites : Array<Dynamic> = [];
			if (selection == "show senders")                 sprites = app.runtime.allSendersOfBroadcast(msg);
			if (selection == "show receivers")                 sprites = app.runtime.allReceiversOfBroadcast(msg);
			if (selection == "clear senders/receivers")                 sprites = [];
			app.highlightSprites(sprites);
		};
		var m : Menu = new Menu(showBroadcasts, "broadcastInfo");
		addGenericBlockItems(m);
		if (!isInPalette(block)) {
			m.addItem("rename broadcast", renameBroadcast);
			m.addItem("show senders");
			m.addItem("show receivers");
			m.addItem("clear senders/receivers");
		}
		showMenu(m);
	}
}

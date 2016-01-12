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

// PaletteBuilder.as
// John Maloney, September 2010
//
// PaletteBuilder generates the contents of the blocks palette for a given
// category, including the blocks, buttons, and watcher toggle boxes.

package scratch;
import blocks.*;

//import extensions.*;

import flash.display.*;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.net.*;
import flash.text.*;

import translation.Translator;

import ui.ProcedureSpecEditor;
import ui.media.MediaLibrary;
import ui.parts.UIPart;

import uiwidgets.*;

class PaletteBuilder {

	private var app:Scratch;
	private var nextY:Int;

	public function new(app:Scratch) {
		this.app = app;
	}

	public static function strings():Array<String> {
		return [
			'Stage selected:', 'No motion blocks',
			'Make a Block', 'Make a List', 'Make a Variable',
			'New List', 'List name', 'New Variable', 'Variable name',
			'New Block', 'Add an Extension', 'when Stage clicked'];
	}

	public function showBlocksForCategory(selectedCategory:Int, scrollToOrigin:Bool, shiftKey:Bool = false):Void {
		if (app.palette == null) return;
		app.palette.clear(scrollToOrigin);
		nextY = 7;

		if (selectedCategory == Specs.dataCategory) return showDataCategory();
		if (selectedCategory == Specs.myBlocksCategory) return showMyBlocksPalette(shiftKey);

		var catName:String = Specs.categories[selectedCategory][1];
		var catColor:Int = Specs.blockColor(selectedCategory);
		if (app.viewedObj() != null && app.viewedObj().isStage) {
			// The stage has different blocks for some categories:
			var stageSpecific:Array<String> = ['Control', 'Looks', 'Motion', 'Pen', 'Sensing'];
			if (stageSpecific.indexOf(catName) != -1) selectedCategory += 100;
			if (catName == 'Motion') {
				addItem(makeLabel(Translator.map('Stage selected:')));
				nextY -= 6;
				addItem(makeLabel(Translator.map('No motion blocks')));
				return;
			}
		}
		addBlocksForCategory(selectedCategory, catColor);
		updateCheckboxes();
	}

	private function addBlocksForCategory(category:Int, catColor:Int):Void {
		var cmdCount:Int = 0;
		var targetObj:ScratchObj = app.viewedObj();
		for (spec in Specs.commands) {
			if ((spec.length > 3) && (spec[2] == category)) {
				var blockColor:Int = (app.interp.isImplemented(spec[3])) ? catColor : 0x505050;
				var defaultArgs:Array<Dynamic> = targetObj.defaultArgsFor(spec[3], spec.slice(4));
				var label:String = spec[0];
				if (targetObj.isStage && spec[3] == 'whenClicked') label = 'when Stage clicked';
				var block:Block = new Block(label, spec[1], blockColor, spec[3], defaultArgs);
				var showCheckbox:Bool = isCheckboxReporter(spec[3]);
				if (showCheckbox) addReporterCheckbox(block);
				addItem(block, showCheckbox);
				cmdCount++;
			} else {
				if ((spec.length == 1) && (cmdCount > 0)) nextY += Std.int(10 * spec[0].length); // add some space
				cmdCount = 0;
			}
		}
	}

	private function addItem(o:DisplayObject, hasCheckbox:Bool = false):Void {
		o.x = hasCheckbox ? 23 : 6;
		o.y = nextY;
		app.palette.addChild(o);
		app.palette.updateSize();
		nextY += Std.int(o.height + 5);
	}

	private function makeLabel(label:String):TextField {
		var t:TextField = new TextField();
		t.autoSize = TextFieldAutoSize.LEFT;
		t.selectable = false;
		t.background = false;
		t.text = label;
		t.setTextFormat(CSS.normalTextFormat);
		return t;
	}

	private function showMyBlocksPalette(shiftKey:Bool):Void {
		// show creation button, hat, and call blocks
		var catColor:Int = Specs.blockColor(Specs.procedureColor);
		addItem(new Button(Translator.map('Make a Block'), makeNewBlock, false, '/help/studio/tips/blocks/make-a-block/'));
		var definitions:Array<Block> = app.viewedObj().procedureDefinitions();
		if (definitions.length > 0) {
			nextY += 5;
			for (proc in definitions) {
				var b:Block = new Block(proc.spec, ' ', Specs.procedureColor, Specs.CALL, proc.defaultArgValues);
				addItem(b);
			}
			nextY += 5;
		}

		//addExtensionButtons();
		//for (ext in app.extensionManager.enabledExtensions()) {
			//addExtensionSeparator(ext);
			//addBlocksForExtension(ext);
		//}

		updateCheckboxes();
	}

	//private function addExtensionButtons():Void {
		//addAddExtensionButton();
		//if (Scratch.app.isExtensionDevMode) {
			//var extensionDevManager:ExtensionDevManager = cast(Scratch.app.extensionManager, ExtensionDevManager);
			//if (extensionDevManager) {
				//addItem(extensionDevManager.makeLoadExperimentalExtensionButton());
			//}
		//}
	//}

	private function addAddExtensionButton():Void {
		//addItem(new Button(Translator.map('Add an Extension'), showAnExtension, false, '/help/studio/tips/blocks/add-an-extension/'));
	}

	private function showDataCategory():Void {
		var catColor:Int = Specs.variableColor;

		// variable buttons, reporters, and set/change blocks
		addItem(new Button(Translator.map('Make a Variable'), makeVariable));
		var sortedVarNames = app.runtime.allVarNames();
		sortedVarNames.sort(
			function(a, b) { 
				if (a < b) return -1;
				if (b > a) return 1;
				return 0;
			});
		var varNames:Array<String> = sortedVarNames;
		if (varNames.length > 0) {
			for (n in varNames) {
				addVariableCheckbox(n, false);
				addItem(new Block(n, 'r', catColor, Specs.GET_VAR), true);
			}
			nextY += 10;
			addBlocksForCategory(Specs.dataCategory, catColor);
			nextY += 15;
		}

		// lists
		catColor = Specs.listColor;
		addItem(new Button(Translator.map('Make a List'), makeList));

		var listNames:Array<String> = app.runtime.allListNames();
		listNames.sort(
			function(a, b) { 
				if (a < b) return -1;
				if (b > a) return 1;
				return 0;
			});
		if (listNames.length > 0) {
			for (n in listNames) {
				addVariableCheckbox(n, true);
				addItem(new Block(n, 'r', catColor, Specs.GET_LIST), true);
			}
			nextY += 10;
			addBlocksForCategory(Specs.listCategory, catColor);
		}
		updateCheckboxes();
	}

	private function createVar(name:String, varSettings:VariableSettings):Dynamic {
		var obj:ScratchObj = (varSettings.isLocal) ? app.viewedObj() : app.stageObj();
		if (obj.hasName(name)) {
			DialogBox.notify("Cannot Add", "That name is already in use.");
			return null;
		}
		var variable:Dynamic = (varSettings.isList ? obj.lookupOrCreateList(name) : obj.lookupOrCreateVar(name));

		app.runtime.showVarOrListFor(name, varSettings.isList, obj);
		app.setSaveNeeded();

		return variable;
	}

	private function makeVariable():Void {
		var d:DialogBox = null;
		var varSettings:VariableSettings = null;
		function makeVar2(param: Dynamic):Void {
			var n:String = d.getField('Variable name').replace(~/^\s+|\s+$/g, '');
			if (n.length == 0) return;

			createVar(n, varSettings);
		}

		d = new DialogBox(makeVar2);
		varSettings = makeVarSettings(false, app.viewedObj().isStage);
		d.addTitle('New Variable');
		d.addField('Variable name', 150);
		d.addWidget(varSettings);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	private function makeList():Void {
		var varSettings:VariableSettings = null;
		function makeList2(d:DialogBox):Void {
			var n:String = d.getField('List name').replace(~/^\s+|\s+$/g, '');
			if (n.length == 0) return;

			createVar(n, varSettings);
		}

		var d:DialogBox = new DialogBox(makeList2);
		varSettings = makeVarSettings(true, app.viewedObj().isStage);
		d.addTitle('New List');
		d.addField('List name', 150);
		d.addWidget(varSettings);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	private function makeVarSettings(isList:Bool, isStage:Bool):VariableSettings {
		return new VariableSettings(isList, isStage);
	}

	private function makeNewBlock():Void {
		var specEditor:ProcedureSpecEditor = new ProcedureSpecEditor('', [], false);
		function addBlockHat(dialog:DialogBox):Void {
			var spec:String = (~/^\s+|\s+$/g).replace(specEditor.spec(), '');
			if (spec.length == 0) return;
			var newHat:Block = new Block(spec, 'p', Specs.procedureColor, Specs.PROCEDURE_DEF);
			newHat.parameterNames = specEditor.inputNames();
			newHat.defaultArgValues = specEditor.defaultArgValues();
			newHat.warpProcFlag = specEditor.warpFlag();
			newHat.setSpec(spec);
			newHat.x = 10 - app.scriptsPane.x + Math.random() * 100;
			newHat.y = 10 - app.scriptsPane.y + Math.random() * 100;
			app.scriptsPane.addChild(newHat);
			app.scriptsPane.saveScripts();
			app.runtime.updateCalls();
			app.updatePalette();
			app.setSaveNeeded();
		}

		var d:DialogBox = new DialogBox(addBlockHat);
		d.addTitle('New Block');
		d.addWidget(specEditor);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage, true);
		specEditor.setInitialFocus();
	}

	private function showAnExtension():Void {
		//function addExt(ext:ScratchExtension):Void {
			//if (ext.isInternal) {
				//app.extensionManager.setEnabled(ext.name, true);
			//} else {
				//app.extensionManager.loadCustom(ext);
			//}
			//app.updatePalette();
		//}
//
		//var lib:MediaLibrary = app.getMediaLibrary('extension', addExt);
		//lib.open();
	}

	private function addReporterCheckbox(block:Block):Void {
		var b:IconButton = new IconButton(toggleWatcher, 'checkbox');
		b.disableMouseover();
		var targetObj:ScratchObj = isSpriteSpecific(block.op) ? app.viewedObj() : app.stagePane;
		b.clientData = {
			type: 'reporter',
			targetObj: targetObj,
			cmd: block.op,
			block: block,
			color: block.base.color
		};
		b.x = 6;
		b.y = nextY + 5;
		app.palette.addChild(b);
	}

	private function isCheckboxReporter(op:String):Bool {
		var checkboxReporters:Array<String> = [
			'xpos', 'ypos', 'heading', 'costumeIndex', 'scale', 'volume', 'timeAndDate',
			'backgroundIndex', 'sceneName', 'tempo', 'answer', 'timer', 'soundLevel', 'isLoud',
			'sensor:', 'sensorPressed:', 'senseVideoMotion', 'xScroll', 'yScroll',
			'getDistance', 'getTilt'];
		return checkboxReporters.indexOf(op) > -1;
	}

	private function isSpriteSpecific(op:String):Bool {
		var spriteSpecific:Array<String> = ['costumeIndex', 'xpos', 'ypos', 'heading', 'scale', 'volume'];
		return spriteSpecific.indexOf(op) > -1;
	}

	private function getBlockArg(b:Block, i:Int):String {
		var arg:BlockArg = cast(b.args[i], BlockArg);
		if (arg != null) return arg.argValue;
		return '';
	}

	private function addVariableCheckbox(varName:String, isList:Bool):Void {
		var b:IconButton = new IconButton(toggleWatcher, 'checkbox');
		b.disableMouseover();
		var targetObj:ScratchObj = app.viewedObj();
		if (isList) {
			if (targetObj.listNames().indexOf(varName) < 0) targetObj = app.stagePane;
		} else {
			if (targetObj.varNames().indexOf(varName) < 0) targetObj = app.stagePane;
		}
		b.clientData = {
			type: 'variable',
			isList: isList,
			targetObj: targetObj,
			varName: varName
		};
		b.x = 6;
		b.y = nextY + 5;
		app.palette.addChild(b);
	}

	private function toggleWatcher(b:IconButton):Void {
		var data:Dynamic = b.clientData;
		if (data.block) {
			switch (data.block.op) {
				case 'senseVideoMotion':
					data.targetObj = getBlockArg(data.block, 1) == 'Stage' ? app.stagePane : app.viewedObj();
				case 'sensor:':
				case 'sensorPressed:':
				case 'timeAndDate':
					data.param = getBlockArg(data.block, 0);
					//break;
			}
		}
		var showFlag:Bool = !app.runtime.watcherShowing(data);
		app.runtime.showWatcher(data, showFlag);
		b.setOn(showFlag);
		app.setSaveNeeded();
	}

	private function updateCheckboxes():Void {
		for (i in 0...app.palette.numChildren) {
			var b:IconButton = cast(app.palette.getChildAt(i), IconButton);
			if (b != null && b.clientData) {
				b.setOn(app.runtime.watcherShowing(b.clientData));
			}
		}
	}

	//private function getExtensionMenu(ext:ScratchExtension):Menu {
		//function showAbout():Void {
			//if (ext.isInternal) {
				//// Internal extensions are handled specially by tip-bar.js
				//app.showTip('ext:' + ext.name);
			//}
			//else if (ext.url) {
				//// Open in the tips window if the URL starts with /info/ and another tab otherwise
				//if (ext.url.indexOf('/info/') == 0) app.showTip(ext.url);
				//else if (ext.url.indexOf('http') == 0) navigateToURL(new URLRequest(ext.url));
				//else DialogBox.notify('Extensions', 'Unable to load about page: the URL given for extension "' + ext.name + '" is not formatted correctly.');
			//}
		//}
//
		//function hideExtension():Void {
			//app.extensionManager.setEnabled(ext.name, false);
			//app.updatePalette();
		//}

		//var m:Menu = new Menu();
		//m.addItem(Translator.map('About') + ' ' + ext.name + ' ' + Translator.map('extension') + '...', showAbout, !!ext.url);
		//m.addItem('Remove extension blocks', hideExtension);
//
		//var extensionDevManager:ExtensionDevManager = cast(Scratch.app.extensionManager, ExtensionDevManager);
//
		//if (!ext.isInternal && extensionDevManager) {
			//m.addLine();
			//var localFileName:String = extensionDevManager.getLocalFileName(ext);
			//if (localFileName) {
				//if (extensionDevManager.isLocalExtensionDirty()) {
					//m.addItem('Load changes from ' + localFileName, function ():Void {
						//extensionDevManager.loadLocalCode();
					//});
				//}
				//m.addItem('Disconnect from ' + localFileName, function ():Void {
					//extensionDevManager.stopWatchingExtensionFile();
				//});
			//}
		//}
//
		//return m;
	//}

	private static inline var pwidth:Int = 215;

	//private function addExtensionSeparator(ext:ScratchExtension):Void {
		//function extensionMenu(ignore:Dynamic):Void {
			//var m:Menu = getExtensionMenu(ext);
			//m.showOnStage(app.stage);
		//}

		//nextY += 7;
//
		//var titleButton:IconButton = UIPart.makeMenuButton(ext.name, extensionMenu, true, CSS.textColor);
		//titleButton.x = 5;
		//titleButton.y = nextY;
		//app.palette.addChild(titleButton);
//
		//addLineForExtensionTitle(titleButton, ext);
//
		//var indicator:IndicatorLight = new IndicatorLight(ext);
		//indicator.addEventListener(MouseEvent.CLICK, function (e:Event):Void {
			//Scratch.app.showTip('extensions');
		//}, false, 0, true);
		//app.extensionManager.updateIndicator(indicator, ext);
		//indicator.x = pwidth - 40;
		//indicator.y = nextY + 2;
		//app.palette.addChild(indicator);
//
		//nextY += titleButton.height + 10;

		//var extensionDevManager:ExtensionDevManager = cast(Scratch.app.extensionManager, ExtensionDevManager);
		//if (extensionDevManager) {
			//// Show if this extension is being updated by a file
			//var fileName:String = extensionDevManager.getLocalFileName(ext);
			//if (fileName) {
				//var extensionEditStatus:TextField = UIPart.makeLabel('Connected to ' + fileName, CSS.normalTextFormat, 8, nextY - 5);
				//app.palette.addChild(extensionEditStatus);
//
				//nextY += extensionEditStatus.textHeight + 3;
			//}
		//}
	//}

	@:meta(Embed(source="../assets/reload.png"))
	private static var ReloadIcon:Class<Dynamic>;

	//private function addLineForExtensionTitle(titleButton:IconButton, ext:ScratchExtension):Void {
		//var x:Int = titleButton.width + 12;
		//var w:Int = pwidth - x - 48;
		//var extensionDevManager:ExtensionDevManager = cast(Scratch.app.extensionManager, ExtensionDevManager);
		//var dirty:Bool = extensionDevManager && extensionDevManager.isLocalExtensionDirty(ext);
		//if (dirty)
			//w -= 15;
		//addLine(x, nextY + 9, w);
//
		//if (dirty) {
			//var reload:Bitmap = new ReloadIcon();
			//reload.scaleX = 0.75;
			//reload.scaleY = 0.75;
			//var reloadBtn:Sprite = new Sprite();
			//reloadBtn.addChild(reload);
			//reloadBtn.x = x + w + 6;
			//reloadBtn.y = nextY + 2;
			//app.palette.addChild(reloadBtn);
			//SimpleTooltips.add(reloadBtn, {
				//text: 'Click to load changes (running old code from ' + extensionDevManager.getLocalCodeDate() + ')',
				//direction: 'top'
			//});
//
			//reloadBtn.addEventListener(MouseEvent.MOUSE_DOWN, function (e:MouseEvent):Void {
				//SimpleTooltips.hideAll();
				//extensionDevManager.loadLocalCode();
			//});
//
			//reloadBtn.addEventListener(MouseEvent.ROLL_OVER, function (e:MouseEvent):Void {
				//reloadBtn.transform.colorTransform = new ColorTransform(2, 2, 2);
			//});
//
			//reloadBtn.addEventListener(MouseEvent.ROLL_OUT, function (e:MouseEvent):Void {
				//reloadBtn.transform.colorTransform = new ColorTransform();
			//});
		//}
	//}

	//private function addBlocksForExtension(ext:ScratchExtension):Void {
		//var blockColor:Int = Specs.extensionsColor;
		//var opPrefix:String = ext.useScratchPrimitives ? '' : ext.name + '.';
		//for (spec in ext.blockSpecs) {
			//if (spec.length >= 3) {
				//var op:String = opPrefix + spec[2];
				//var defaultArgs:Array = spec.slice(3);
				//var block:Block = new Block(spec[1], spec[0], blockColor, op, defaultArgs);
				//var showCheckbox:Bool = (spec[0] == 'r' && defaultArgs.length == 0);
				//if (showCheckbox) addReporterCheckbox(block);
				//addItem(block, showCheckbox);
			//} else {
				//if (spec.length == 1) nextY += 10 * spec[0].length; // add some space
			//}
		//}
	//}

	private function addLine(x:Int, y:Int, w:Int):Void {
		var light:Int = 0xF2F2F2;
		var dark:Int = CSS.borderColor - 0x141414;
		var line:Shape = new Shape();
		var g:Graphics = line.graphics;

		g.lineStyle(1, dark, 1, true);
		g.moveTo(0, 0);
		g.lineTo(w, 0);

		g.lineStyle(1, light, 1, true);
		g.moveTo(0, 1);
		g.lineTo(w, 1);
		line.x = x;
		line.y = y;
		app.palette.addChild(line);
	}

}


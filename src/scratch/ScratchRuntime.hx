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

// ScratchRuntime.as
// John Maloney, September 2010

package scratch;
import flash.display.*;
import flash.events.*;
import flash.geom.Rectangle;
import flash.media.*;
import flash.net.*;
import flash.system.System;
import flash.text.TextField;
import flash.utils.*;
import blocks.Block;
import blocks.BlockArg;
import interpreter.*;
//import primitives.VideoMotionPrims;
//import sound.ScratchSoundPlayer;
import translation.*;
import ui.media.MediaInfo;
import ui.BlockPalette;
import uiwidgets.DialogBox;
import util.*;
import watchers.*;

class ScratchRuntime {

	public var app:Scratch;
	public var interp:Interpreter;
	//public var motionDetector:VideoMotionPrims;
	public var keyIsDown:Array<Dynamic> = Compat.newArray(128, null); // new Array<Dynamic>(128); // records key up/down state
	public var shiftIsDown:Bool;
	public var lastAnswer:String = '';
	public var cloneCount:Int;
	public var edgeTriggersEnabled:Bool = false; // initially false, becomes true when project first run

	//private var microphone:Microphone;
	private var timerBase:UInt;

	private var projectToInstall:ScratchStage;
	private var saveAfterInstall:Bool;

	public function new(app:Scratch, interp:Interpreter) {
		this.app = app;
		this.interp = interp;
		timerBase = interp.currentMSecs;
		clearKeyDownArray();
	}

	// -----------------------------
	// Running and stopping
	//------------------------------

	public function stepRuntime():Void {
		if (projectToInstall != null && (app.isOffline || app.isExtensionDevMode)) {
			installProject(projectToInstall);
			if (saveAfterInstall) app.setSaveNeeded(true);
			projectToInstall = null;
			saveAfterInstall = false;
			return;
		}

		if (recording) saveFrame(); // Recording a YouTube video?  Old / Unused currently.
		//app.extensionManager.step();
		//if (motionDetector) motionDetector.step(); // Video motion detection

		// Step the stage, sprites, and watchers
		app.stagePane.step(this);

		// run scripts and commit any pen strokes
		processEdgeTriggeredHats();
		interp.stepThreads();
		app.stagePane.commitPenStrokes();
	}

//-------- recording test ---------
	public var recording:Bool;
	private var frames:Array<Dynamic> = [];

	private function saveFrame():Void {
		var f:BitmapData = new BitmapData(480, 360);
		f.draw(app.stagePane);
		frames.push(f);
		if ((frames.length % 100) == 0) {
			trace('frames: ' + frames.length + ' mem: ' + System.totalMemory);
		}
	}

	public function startRecording():Void {
		clearRecording();
		recording = true;
	}

	public function stopRecording():Void {
		recording = false;
	}

	public function clearRecording():Void {
		recording = false;
		frames = [];
		System.gc();
		trace('mem: ' + System.totalMemory);
	}

	//// TODO: If keeping this then make it write each frame while recording AND add sound recording
	//public function saveRecording():Void {
		//var myWriter:SimpleFlvWriter = SimpleFlvWriter.getInstance();
		//var data:ByteArray = new ByteArray();
		//myWriter.createFile(data, 480, 360, 30, frames.length / 30.0);
		//for (i in 0...frames.length) {
			//myWriter.saveFrame(frames[i]);
			//frames[i] = null;
		//}
		//frames = [];
		//trace('data: ' + data.length);
		//new FileReference().save(data, 'movie.flv');
	//}

//----------
	public function stopAll():Void {
		interp.stopAllThreads();
		clearRunFeedback();
		app.stagePane.deleteClones();
		cloneCount = 0;
		clearKeyDownArray();
		//ScratchSoundPlayer.stopAllSounds();
		//app.extensionManager.stopButtonPressed();
		app.stagePane.clearFilters();
		for (s in app.stagePane.sprites()) {
			s.clearFilters();
			s.hideBubble();
		}
		clearAskPrompts();
		app.removeLoadProgressBox();
		//motionDetector = null;
	}

	// -----------------------------
	// Hat Blocks
	//------------------------------

	public function startGreenFlags(firstTime:Bool = false):Void {
		function startIfGreenFlag(stack:Block, target:ScratchObj):Void {
			if (stack.op == 'whenGreenFlag') interp.toggleThread(stack, target);
		}
		stopAll();
		lastAnswer = '';
		if (firstTime && app.stagePane.info.videoOn) {
			// turn on video the first time if project was saved with camera on
			app.stagePane.setVideoState('on');
		}
		clearEdgeTriggeredHats();
		timerReset();
		haxe.Timer.delay(function():Void {
			allStacksAndOwnersDo(startIfGreenFlag);
		}, 0);
	}

	public function startClickedHats(clickedObj:ScratchObj):Void {
		for (stack in clickedObj.scripts) {
			if (stack.op == 'whenClicked') {
				interp.restartThread(stack, clickedObj);
			}
		}
	}

	public function startKeyHats(ch:Int):Void {
		var keyName:String = null;
		if (('a'.charCodeAt(0) <= ch) && (ch <= 'z'.charCodeAt(0))) keyName = String.fromCharCode(ch);
		if (('0'.charCodeAt(0) <= ch) && (ch <= '9'.charCodeAt(0))) keyName = String.fromCharCode(ch);
		if (28 == ch) keyName = 'left arrow';
		if (29 == ch) keyName = 'right arrow';
		if (30 == ch) keyName = 'up arrow';
		if (31 == ch) keyName = 'down arrow';
		if (32 == ch) keyName = 'space';
		function startMatchingKeyHats(stack:Block, target:ScratchObj):Void {
			if (stack.op == 'whenKeyPressed') {
				var k:String = stack.args[0].argValue;
				if (k == 'any' || k == keyName) {
					// only start the stack if it is not already running
					if (!interp.isRunning(stack, target)) interp.toggleThread(stack, target);
				}
			}
		}
		allStacksAndOwnersDo(startMatchingKeyHats);
	}

	public function collectBroadcasts():Array<String> {
		var result:Array<String> = [];
		function addBlock(b:Block):Void {
			if ((b.op == 'broadcast:') ||
					(b.op == 'doBroadcastAndWait') ||
					(b.op == 'whenIReceive')) {
				if (Std.is(b.args[0], BlockArg)) {
					var msg:String = b.args[0].argValue;
					if (result.indexOf(msg) < 0) result.push(msg);
				}
			}
		}
		allStacksAndOwnersDo(function (stack:Block, target:ScratchObj):Void {
			stack.allBlocksDo(addBlock);
		});
		var palette:BlockPalette = app.palette;
		for (i in 0...palette.numChildren) {
			var b:Block = cast(palette.getChildAt(i), Block);
			if (b != null) addBlock(b);
		}
		result.sort(
			function(a, b) { 
				if (a < b) return -1;
				if (b > a) return 1;
				return 0;
			});
		return result;
	}

	public function hasUnofficialExtensions():Bool {
		var found:Bool = false;
		allStacksAndOwnersDo(function (stack:Block, target:ScratchObj):Void {
			if(found) return;
			stack.allBlocksDo(function (b:Block):Void {
				if(found) return;
				if(isUnofficialExtensionBlock(b))
					found = true;
			});
		});
		return found;
	}

	private function isUnofficialExtensionBlock(b:Block):Bool {
		return true;
		//var i:Int = b.op.indexOf('.');
		//if(i == -1) return false;
		//var extName:String = b.op.substr(0, i);
		//return !app.extensionManager.isInternal(extName);
	}

	/*
	SCRATCH::allow3d
	public function hasGraphicEffects():Bool {
		var found:Bool = false;
		allStacksAndOwnersDo(function (stack:Block, target:ScratchObj):Void {
			if(found) return;
			stack.allBlocksDo(function (b:Block):Void {
				if(found) return;
				if(isGraphicEffectBlock(b))
					found = true;
			});
		});
		return found;
	}

	SCRATCH::allow3d
	private function isGraphicEffectBlock(b:Block):Bool {
		return ('op' in b && (b.op == 'changeGraphicEffect:by:' || b.op == 'setGraphicEffect:to:') &&
		('argValue' in b.args[0]) && b.args[0].argValue != 'ghost' && b.args[0].argValue != 'brightness');
	}
	*/

	// -----------------------------
	// Edge-trigger sensor hats
	//------------------------------

	private var triggeredHats:Array<Dynamic> = [];

	private function clearEdgeTriggeredHats():Void { edgeTriggersEnabled = true; triggeredHats = []; }

	// hats whose triggering condition is currently true
	private var activeHats:Array<Dynamic> = [];
	private function startEdgeTriggeredHats(hat:Block, target:ScratchObj):Void {
		return;
		//if (!hat.isHat || hat.nextBlock == null) return; // skip disconnected hats
//
		//if ('whenSensorGreaterThan' == hat.op) {
			//var sensorName:String = interp.arg(hat, 0);
			//var threshold:Float = interp.numarg(hat, 1);
			//if (('loudness' == sensorName && soundLevel() > threshold) ||
					//('timer' == sensorName && timer() > threshold) ||
					//('video motion' == sensorName && target.visible && VideoMotionPrims.readMotionSensor('motion', target) > threshold)) {
				//if (triggeredHats.indexOf(hat) == -1) { // not already trigged
					//// only start the stack if it is not already running
					//if (!interp.isRunning(hat, target)) interp.toggleThread(hat, target);
				//}
				//activeHats.push(hat);
			//}
		//} else if ('whenSensorConnected' == hat.op) {
			//if (getBooleanSensor(interp.arg(hat, 0))) {
				//if (triggeredHats.indexOf(hat) == -1) { // not already trigged
					//// only start the stack if it is not already running
					//if (!interp.isRunning(hat, target)) interp.toggleThread(hat, target);
				//}
				//activeHats.push(hat);
			//}
		//} else if (app.jsEnabled) {
			//var dotIndex:Int = hat.op.indexOf('.');
			//if (dotIndex > -1) {
				//var extName:String = hat.op.substr(0, dotIndex);
				////if (app.extensionManager.extensionActive(extName)) {
					////var op:String = hat.op.substr(dotIndex+1);
					////var args:Array<Dynamic> = hat.args;
					////var finalArgs:Array<Dynamic> = new Array(args.length);
					////for (i in 0...args.length)
						////finalArgs[i] = interp.arg(hat, i);
////
					////processExtensionReporter(hat, target, extName, op, finalArgs);
				////}
			//}
		//}
	}

	private function processExtensionReporter(hat:Block, target:ScratchObj, extName:String, op:String, finalArgs:Array<Dynamic>):Void {
		// TODO: Is it safe to do this in a callback, or must it happen before we return from startEdgeTriggeredHats?
		//app.externalCall('ScratchExtensions.getReporter', function(triggerCondition:Bool):Void {
			//if (triggerCondition) {
				//if (triggeredHats.indexOf(hat) == -1) { // not already trigged
					//// only start the stack if it is not already running
					//if (!interp.isRunning(hat, target)) interp.toggleThread(hat, target);
				//}
				//activeHats.push(hat);
			//}
		//}, extName, op, finalArgs);
	}

	private function processEdgeTriggeredHats():Void {
		if (!edgeTriggersEnabled) return;
		activeHats = [];
		allStacksAndOwnersDo(startEdgeTriggeredHats);
		triggeredHats = activeHats;
	}

	public function blockDropped(stack:Block):Void {
		// Turn on video the first time a video sensor reporter or hat block is added.
		stack.allBlocksDo(function(b:Block):Void {
			var op:String = b.op;
			if (('senseVideoMotion' == op) ||
					(('whenSensorGreaterThan' == op) && ('video motion' == interp.arg(b, 0)))) {
				app.libraryPart.showVideoButton();
			}
/*
			SCRATCH::allow3d {
				// Should we go 3D?
				if(isGraphicEffectBlock(b))
					app.go3D();
			}
*/			
		});
	}

	// -----------------------------
	// Project Loading and Installing
	//------------------------------

	public function installEmptyProject():Void {
		app.saveForRevert(null, true);
		app.oldWebsiteURL = '';
		installProject(new ScratchStage());
	}

	public function installNewProject():Void {
		installEmptyProject();
	}

	public function selectProjectFile():Void {
		// Prompt user for a file name and load that file.
		var fileName:String = null, data:ByteArray = null;
		function doInstall(ignore:Dynamic = null):Void {
			installProjectFromFile(fileName, data);
		}
		function fileLoadHandler(event:Event):Void {
			var file:FileReference = cast(event.target, FileReference);
			fileName = file.name;
			data = file.data;
			if (app.stagePane.isEmpty()) doInstall();
			else DialogBox.confirm('Replace contents of the current project?', app.stage, doInstall);
		}
		stopAll();

		var filter:FileFilter;
		if (Scratch.app.isExtensionDevMode) {
			filter = new FileFilter('ScratchX Project', '*.sbx;*.sb;*.sb2');
		}
		else {
			filter = new FileFilter('Scratch Project', '*.sb;*.sb2');
		}
		Scratch.loadSingleFile(fileLoadHandler, filter);
	}

	public function installProjectFromFile(fileName:String, data:ByteArray):Void {
		// Install a project from a file with the given name and contents.
		stopAll();
		app.oldWebsiteURL = '';
		app.loadInProgress = true;
		installProjectFromData(data);
		app.setProjectName(fileName);
	}

	public function installProjectFromData(data:ByteArray, saveForRevert:Bool = true):Void {
		var newProject:ScratchStage;
		stopAll();
		data.position = 0;
		if (data.length < 8 || data.readUTFBytes(8) != 'ScratchV') {
			data.position = 0;
			newProject = new ProjectIO(app).decodeProjectFromZipFile(data);
			if (newProject == null) {
				projectLoadFailed();
				return;
			}
		} else {
			var info:Object = null;
			var objTable:Array<Dynamic> = null;
			data.position = 0;
			var reader:ObjReader = new ObjReader(data);
			try { info = reader.readInfo(); } catch (e:flash.errors.Error) { data.position = 0; }
			try { objTable = reader.readObjTable(); } catch (e:flash.errors.Error) { }
			if (objTable == null) {
				projectLoadFailed();
				return;
			}
			newProject = new OldProjectReader().extractProject(objTable);
			newProject.info = info;
			if (info != null) info.thumbnail = null; //delete info.thumbnail; // delete old thumbnail
		}
		if (saveForRevert) app.saveForRevert(data, false);
		//app.extensionManager.clearImportedExtensions();
		decodeImagesAndInstall(newProject);
	}

	public function projectLoadFailed(ignore:Dynamic = null):Void {
		app.removeLoadProgressBox();
		//DialogBox.notify('Error!', 'Project did not load.', app.stage);
		app.loadProjectFailed();
	}

	public function decodeImagesAndInstall(newProject:ScratchStage):Void {
		function imagesDecoded():Void { projectToInstall = newProject; } // stepRuntime() will finish installation
		new ProjectIO(app).decodeAllImages(newProject.allObjects(), imagesDecoded);
	}

	private function installProject(project:ScratchStage):Void {
		if (app.stagePane != null) stopAll();
		if (app.scriptsPane != null) app.scriptsPane.viewScriptsFor(null);

		/*
		 SCRATCH::allow3d { if(app.isIn3D) app.render3D.setStage(project, project.penLayer); }
		 */

		for (obj in project.allObjects()) {
			obj.showCostume(obj.currentCostumeIndex);
			if (Scratch.app.isIn3D) obj.updateCostume();
			if (Std.is(obj, ScratchSprite))
			{
				var spr:ScratchSprite = cast(obj, ScratchSprite);
				spr.setDirection(spr.direction);
			}
		}

		app.resetPlugin();
		//app.extensionManager.clearImportedExtensions();
		//app.extensionManager.loadSavedExtensions(project.info.savedExtensions);
		app.installStage(project);
		app.updateSpriteLibrary(true);
		// set the active sprite
		var allSprites:Array<ScratchSprite> = app.stagePane.sprites();
		if (allSprites.length > 0) {
			allSprites.sort(function(a, b) {
				if (a.indexInLibrary < b.indexInLibrary) return -1;
				if (a.indexInLibrary > b.indexInLibrary) return 1;
				return 0;
			});
			app.selectSprite(allSprites[0]);
		} else {
			app.selectSprite(app.stagePane);
		}
		//app.extensionManager.step();
		app.projectLoaded();
/*		
		SCRATCH::allow3d { checkForGraphicEffects(); }
*/		
	}

/*	
	SCRATCH::allow3d
	public function checkForGraphicEffects():Void {
		if(hasGraphicEffects()) app.go3D();
		else app.go2D();
	}
*/	

	// -----------------------------
	// Ask prompter
	//------------------------------

	public function showAskPrompt(question:String = ''):Void {
		var p:AskPrompter = new AskPrompter(question, app);
		interp.askThread = interp.activeThread;
		p.x = 15;
		p.y = ScratchObj.STAGEH - p.height - 5;
		app.stagePane.addChild(p);
		haxe.Timer.delay(p.grabKeyboardFocus, 100); // workaround for Window keyboard event handling
	}

	public function hideAskPrompt(p:AskPrompter):Void {
		interp.askThread = null;
		lastAnswer = p.answer();
		if (p.parent != null) {
			p.parent.removeChild(p);
		}
		app.stage.focus = null;
	}

	public function askPromptShowing():Bool {
		var uiLayer:Sprite = app.stagePane.getUILayer();
		for (i in 0...uiLayer.numChildren) {
			if (Std.is(uiLayer.getChildAt(i), AskPrompter))
				return true;
		}
		return false;
	}

	public function clearAskPrompts():Void {
		interp.askThread = null;
		var allPrompts:Array<Dynamic> = [];
		var uiLayer:Sprite = app.stagePane.getUILayer();
		var c:DisplayObject;
		for (i in 0...uiLayer.numChildren) {
			if (Std.is((c = uiLayer.getChildAt(i)), AskPrompter)) allPrompts.push(c);
		}
		for (c in allPrompts) uiLayer.removeChild(c);
	}

	// -----------------------------
	// Keyboard input handling
	//------------------------------

	public function keyDown(evt:KeyboardEvent):Void {
		shiftIsDown = evt.shiftKey;
		var ch:Int = evt.charCode;
		if (evt.charCode == 0) ch = mapArrowKey(evt.keyCode);
		if ((65 <= ch) && (ch <= 90)) ch += 32; // map A-Z to a-z
		if (!Std.is(evt.target, TextField)) startKeyHats(ch);
		if (ch < 128) keyIsDown[ch] = true;
	}

	public function keyUp(evt:KeyboardEvent):Void {
		shiftIsDown = evt.shiftKey;
		var ch:Int = evt.charCode;
		if (evt.charCode == 0) ch = mapArrowKey(evt.keyCode);
		if ((65 <= ch) && (ch <= 90)) ch += 32; // map A-Z to a-z
		if (ch < 128) keyIsDown[ch] = false;
	}

	private function clearKeyDownArray():Void {
		for (i in 0...128) keyIsDown[i] = false;
	}

	private function mapArrowKey(keyCode:Int):Int {
		// map key codes for arrow keys to ASCII, other key codes to zero
		if (keyCode == 37) return 28;
		if (keyCode == 38) return 30;
		if (keyCode == 39) return 29;
		if (keyCode == 40) return 31;
		return 0;
	}

	// -----------------------------
	// Sensors
	//------------------------------

	//public function getSensor(sensorName:String):Float {
		//return app.extensionManager.getStateVar('PicoBoard', sensorName, 0);
	//}

	public function getBooleanSensor(sensorName:String):Bool {
		//if (sensorName == 'button pressed') return app.extensionManager.getStateVar('PicoBoard', 'button', 1023) < 10;
		//if (sensorName.indexOf('connected') > -1) { // 'A connected' etc.
			//sensorName = 'resistance-' + sensorName.charAt(0);
			//return app.extensionManager.getStateVar('PicoBoard', sensorName, 1023) < 10;
		//}
		return false;
	}

	public function getTimeString(which:String):Dynamic {
		// Return local time properties.
		var now:Date = Date.now();
		switch (which) {
			case 'hour': return now.getHours();
			case 'minute': return now.getMinutes();
			case 'second': return now.getSeconds();
			case 'year': return now.getFullYear(); // four digit year (e.g. 2012)
			case 'month': return now.getMonth() + 1; // 1-12
			case 'date': return now.getDate(); // 1-31
			case 'day of week': return now.getDay() + 1; // 1-7, where 1 is Sunday
		}
		return ''; // shouldn't happen
	}

	// -----------------------------
	// Variables
	//------------------------------

	public function createVariable(varName:String):Void {
		app.viewedObj().lookupOrCreateVar(varName);
	}

	public function deleteVariable(varName:String):Void {
		var v:Variable = app.viewedObj().lookupVar(varName);

		if (app.viewedObj().ownsVar(varName)) {
			app.viewedObj().deleteVar(varName);
		} else {
			app.stageObj().deleteVar(varName);
		}
		clearAllCaches();
	}

	public function allVarNames():Array<String> {
		var result:Array<String> = [], v:Variable;
		for (v in app.stageObj().variables) result.push(v.name);
		if (!app.viewedObj().isStage) {
			for (v in app.viewedObj().variables) result.push(v.name);
		}
		return result;
	}

	public function renameVariable(oldName:String, newName:String):Void {
		if (oldName == newName) return;
		var owner:ScratchObj = app.viewedObj();
		if (!owner.ownsVar(oldName)) owner = app.stagePane;
		if (owner.hasName(newName)) {
			DialogBox.notify("Cannot Rename", "That name is already in use.");
			return;
		}

		var v:Variable = owner.lookupVar(oldName);
		if (v != null) {
			v.name = newName;
			if (v.watcher) v.watcher.changeVarName(newName);
		} else {
			owner.lookupOrCreateVar(newName);
		}
		updateVarRefs(oldName, newName, owner);
		app.updatePalette();
	}

	public function updateVariable(v:Variable):Void {}
	public function makeVariable(varObj:Object):Variable { return new Variable(varObj.name, varObj.value); }
	public function makeListWatcher():ListWatcher { return new ListWatcher(); }

	private function updateVarRefs(oldName:String, newName:String, owner:ScratchObj):Void {
		// Change the variable name in all blocks that use it.
		for (b in allUsesOfVariable(oldName, owner)) {
			if (b.op == Specs.GET_VAR) {
				b.setSpec(newName);
				b.fixExpressionLayout();
			} else {
				b.args[0].setArgValue(newName);
			}
		}
	}

	// -----------------------------
	// Lists
	//------------------------------

	public function allListNames():Array<String> {
		var result:Array<String> = app.stageObj().listNames();
		if (!app.viewedObj().isStage) {
			result = result.concat(app.viewedObj().listNames());
		}
		return result;
	}

	public function deleteList(listName:String):Void {
		if (app.viewedObj().ownsList(listName)) {
			app.viewedObj().deleteList(listName);
		} else {
			app.stageObj().deleteList(listName);
		}
		clearAllCaches();
	}

	// -----------------------------
	// Sensing
	//------------------------------

	public function timer():Float { return (interp.currentMSecs - timerBase) / 1000; }
	public function timerReset():Void { timerBase = interp.currentMSecs; }
	public function isLoud():Bool { return soundLevel() > 10; }

	public function soundLevel():Int {
		if (microphone == null) {
			microphone = Microphone.getMicrophone();
			if(microphone != null) {
				microphone.setLoopBack(true);
				microphone.soundTransform = new SoundTransform(0, 0);
			}
		}
		return microphone != null ? Std.int(microphone.activityLevel) : 0;
	}

	// -----------------------------
	// Script utilities
	//------------------------------

	public function renameCostume(newName:String):Void {
		var obj:ScratchObj = app.viewedObj();
		var costume:ScratchCostume = obj.currentCostume();
		costume.costumeName = '';
		var oldName:String = costume.costumeName;
		newName = obj.unusedCostumeName(newName != null ? newName : Translator.map('costume1'));
		costume.costumeName = newName;
		updateArgs(obj.isStage ? allUsesOfBackdrop(oldName) : allUsesOfCostume(oldName), newName);
	}

	public function renameSprite(newName:String):Void {
		var obj:ScratchObj = app.viewedObj();
		var oldName:String = obj.objName;
		obj.objName = '';
		newName = app.stagePane.unusedSpriteName(newName != null ? newName : 'Sprite1');
		obj.objName = newName;
		for (lw  in app.viewedObj().lists) {
			lw.updateTitle();
		}
		updateArgs(allUsesOfSprite(oldName), newName);
	}

	private function updateArgs(args:Array<Dynamic>, newValue:Dynamic):Void {
		for (a in args) {
			a.setArgValue(newValue);
		}
		app.setSaveNeeded();
	}

	public function renameSound(s:ScratchSound, newName:String):Void {
		var obj:ScratchObj = app.viewedObj();
		var oldName:String = s.soundName;
		s.soundName = '';
		newName = obj.unusedSoundName(newName != null ? newName : Translator.map('sound1'));
		s.soundName = newName;
		allUsesOfSoundDo(oldName, function (a:BlockArg):Void {
			a.setArgValue(newName);
		});
		app.setSaveNeeded();
	}

	public function clearRunFeedback():Void {
		if(app.editMode) {
			for (stack in allStacks()) {
				stack.allBlocksDo(function(b:Block):Void {
					b.hideRunFeedback();
				});
			}
		}
		app.updatePalette();
	}

	public function allSendersOfBroadcast(msg:String):Array<Dynamic> {
		// Return an array of all Scratch objects that broadcast the given message.
		var result:Array<Dynamic> = [];
		for (o in app.stagePane.allObjects()) {
			if (sendsBroadcast(o, msg)) result.push(o);
		}
		return result;
	}

	public function allReceiversOfBroadcast(msg:String):Array<Dynamic> {
		// Return an array of all Scratch objects that receive the given message.
		var result:Array<Dynamic> = [];
		for (o in app.stagePane.allObjects()) {
			if (receivesBroadcast(o, msg)) result.push(o);
		}
		return result;
	}

	public function renameBroadcast(oldMsg:String, newMsg:String):Void {
		if (oldMsg == newMsg) return;

		if (allSendersOfBroadcast(newMsg).length > 0 ||
			allReceiversOfBroadcast(newMsg).length > 0) {
			DialogBox.notify("Cannot Rename", "That name is already in use.");
			return;
		}

		for (obj in allBroadcastBlocksWithMsg(oldMsg)) {
				cast(obj,Block).broadcastMsg = newMsg;
		}

		app.updatePalette();
	}

	private function sendsBroadcast(obj:ScratchObj, msg:String):Bool {
		for  (stack in obj.scripts) {
			var found:Bool = false;
			stack.allBlocksDo(function (b:Block):Void {
				if (b.op == 'broadcast:' || b.op == 'doBroadcastAndWait') {
					if (b.broadcastMsg == msg) found = true;
				}
			});
			if (found) return true;
		}
		return false;
	}

	private function receivesBroadcast(obj:ScratchObj, msg:String):Bool {
		msg = msg.toLowerCase();
		for (stack in obj.scripts) {
			var found:Bool = false;
			stack.allBlocksDo(function (b:Block):Void {
				if (b.op == 'whenIReceive') {
					if (b.broadcastMsg.toLowerCase() == msg) found = true;
				}
			});
			if (found) return true;
		}
		return false;
	}

	private function allBroadcastBlocksWithMsg(msg:String):Array<Dynamic> {
		var result:Array<Dynamic> = [];
		for ( o in app.stagePane.allObjects()) {
			for (stack in o.scripts) {
				stack.allBlocksDo(function (b:Block):Void {
					if (b.op == 'broadcast:' || b.op == 'doBroadcastAndWait' || b.op == 'whenIReceive') {
						if (b.broadcastMsg == msg) result.push(b);
					}
				});
			}
		}
		return result;
	}

	public function allUsesOfBackdrop(backdropName:String):Array<Dynamic> {
		var result:Array<Dynamic> = [];
		allStacksAndOwnersDo(function (stack:Block, target:ScratchObj):Void {
			stack.allBlocksDo(function (b:Block):Void {
				for  (a in b.args) {
					if (Std.is(a, BlockArg) && a.menuName == 'backdrop' && a.argValue == backdropName) result.push(a);
				}
			});
		});
		return result;
	}

	public function allUsesOfCostume(costumeName:String):Array<Dynamic> {
		var result:Array<Dynamic> = [];
		for (stack in app.viewedObj().scripts) {
			stack.allBlocksDo(function (b:Block):Void {
				for (a in b.args) {
					if (Std.is(a, BlockArg) && a.menuName == 'costume' && a.argValue == costumeName) result.push(a);
				}
			});
		}
		return result;
	}

	public function allUsesOfSprite(spriteName:String):Array<Dynamic> {
		var spriteMenus:Array<Dynamic> = ["spriteOnly", "spriteOrMouse", "spriteOrStage", "touching"];
		var result:Array<Dynamic> = [];
		for (stack in allStacks()) {
			// for each block in stack
			stack.allBlocksDo(function (b:Block):Void {
				for (a in b.args) {
					if (Std.is(a, BlockArg) && spriteMenus.indexOf(a.menuName) != -1 && a.argValue == spriteName) result.push(a);
				}
			});
		}
		return result;
	}

	public function allUsesOfVariable(varName:String, owner:ScratchObj):Array<Dynamic> {
		var variableBlocks:Array<Dynamic> = [Specs.SET_VAR, Specs.CHANGE_VAR, "showVariable:", "hideVariable:"];
		var result:Array<Dynamic> = [];
		var stacks:Array<Dynamic> = owner.isStage ? allStacks() : owner.scripts;
		for (stack in stacks) {
			// for each block in stack
			stack.allBlocksDo(function (b:Block):Void {
				if (b.op == Specs.GET_VAR && b.spec == varName) result.push(b);
				if (variableBlocks.indexOf(b.op) != -1 && b.args[0].argValue == varName) result.push(b);
			});
		}
		return result;
	}

	public function allUsesOfSoundDo(soundName:String, f:BlockArg->Void):Void {
		for (stack in app.viewedObj().scripts) {
			stack.allBlocksDo(function (b:Block):Void {
				for (a in b.args) {
					if (Std.is(a, BlockArg) && a.menuName == 'sound' && a.argValue == soundName) f(a);
				}
			});
		}
	}

	public function allCallsOf(callee:String, owner:ScratchObj, includeRecursive:Bool = true):Array<Block> {
		var result:Array<Block> = [];
		for (stack in owner.scripts) {
			if (!includeRecursive && stack.op == Specs.PROCEDURE_DEF && stack.spec == callee) continue;
			// for each block in stack
			stack.allBlocksDo(function (b:Block):Void {
				if (b.op == Specs.CALL && b.spec == callee) result.push(b);
			});
		}
		return result;
	}

	public function updateCalls():Void {
		allStacksAndOwnersDo(function (b:Block, target:ScratchObj):Void {
			if (b.op == Specs.CALL) {
				if (target.lookupProcedure(b.spec) == null) {
					b.base.setColor(0xFF0000);
					b.base.redraw();
				}
				else b.base.setColor(Specs.procedureColor);
			}
		});
		clearAllCaches();
	}

	public function allStacks():Array<Block> {
		// return an array containing all stacks in all objects
		var result:Array<Block> = [];
		allStacksAndOwnersDo(
				function (stack:Block, target:ScratchObj):Void { result.push(stack); } );
		return result;
	}

	public function allStacksAndOwnersDo(f:Block->ScratchObj->Void):Void {
		// Call the given function on every stack in the project, passing the stack and owning sprite/stage.
		// This method is used by broadcast, so enumerate sprites/stage from front to back to match Scratch.
		var stage:ScratchStage = app.stagePane;
		var stack:Block;
		var i = stage.numChildren - 1;
		while (i >= 0) {
			var o:Dynamic = stage.getChildAt(i);
			if (Std.is(o, ScratchObj)) {
				for (stack in cast(o, ScratchObj).scripts) f(stack, o);
			}
			i--;
		}
		for (stack in stage.scripts) f(stack, stage);
	}

	public function clearAllCaches():Void {
		for (obj in app.stagePane.allObjects()) obj.clearCaches();
	}

	// -----------------------------
	// Variable, List, and Reporter Watchers
	//------------------------------

	public function showWatcher(data:Object, showFlag:Bool):Void {
		if ('variable' == data.type) {
			if (showFlag) showVarOrListFor(data.varName, data.isList, data.targetObj);
			else hideVarOrListFor(data.varName, data.isList, data.targetObj);
		}
		if ('reporter' == data.type) {
			var w:Watcher = findReporterWatcher(data);
			if (w != null) {
				w.visible = showFlag;
			} else {
				if (showFlag) {
					w = new Watcher();
					w.initWatcher(data.targetObj, data.cmd, data.param, data.color);
					showOnStage(w);
				}
			}
		}

		app.setSaveNeeded();
	}

	public function showVarOrListFor(varName:String, isList:Bool, targetObj:ScratchObj):Void {
		if (targetObj.isClone) {
			// Clone's can't show local variables/lists (but can show global ones)
			if (!isList && targetObj.ownsVar(varName)) return;
			if (isList && targetObj.ownsList(varName)) return;
		}
		var w:DisplayObject = isList ? watcherForList(targetObj, varName) : watcherForVar(targetObj, varName);
		if (Std.is(w, ListWatcher)) cast(w,ListWatcher).prepareToShow();
		if (w != null && (!w.visible || w.parent == null)) {
			showOnStage(w);
			app.updatePalette(false);
		}
	}

	private function showOnStage(w:DisplayObject):Void {
		if (w.parent == null) setInitialPosition(w);
		w.visible = true;
		app.stagePane.addChild(w);
	}

	private function setInitialPosition(watcher:DisplayObject):Void {
		var wList:Array<Dynamic> = app.stagePane.watchers();
		var w:Int = Std.int(watcher.width);
		var h:Int = Std.int(watcher.height);
		var x:Int = 5;
		while (x < 400) {
			var maxX:Int = 0;
			var y:Int = 5;
			while (y < 320) {
				var otherWatcher:DisplayObject = watcherIntersecting(wList, new Rectangle(x, y, w, h));
				if (otherWatcher == null) {
					watcher.x = x;
					watcher.y = y;
					return;
				}
				y = Std.int(otherWatcher.y + otherWatcher.height + 5);
				maxX = Std.int(otherWatcher.x + otherWatcher.width);
			}
			x = maxX + 5;
		}
		// Couldn't find an unused place, so pick a random spot
		watcher.x = 5 + Math.floor(400 * Math.random());
		watcher.y = 5 + Math.floor(320 * Math.random());
	}

	private function watcherIntersecting(watchers:Array<Dynamic>, r:Rectangle):DisplayObject {
		for (w in watchers) {
			if (r.intersects(w.getBounds(app.stagePane))) return w;
		}
		return null;
	}

	public function hideVarOrListFor(varName:String, isList:Bool, targetObj:ScratchObj):Void {
		var w:DisplayObject = isList ? watcherForList(targetObj, varName) : watcherForVar(targetObj, varName);
		if (w != null && w.visible) {
			w.visible = false;
			app.updatePalette(false);
		}
	}

	public function watcherShowing(data:Object):Bool {
		if ('variable' == data.type) {
			var targetObj:ScratchObj = data.targetObj;
			var varName:String = data.varName;
			var uiLayer:Sprite = app.stagePane.getUILayer();
			var i:Int;
			if(data.isList)
				for (i in 0...uiLayer.numChildren) {
					var listW:ListWatcher = cast(uiLayer.getChildAt(i), ListWatcher);
					if (listW != null && (listW.listName == varName) && listW.visible) return true;
				}
			else
				for (i in 0...uiLayer.numChildren) {
					var varW:Watcher = cast(uiLayer.getChildAt(i), Watcher);
					if (varW != null && varW.isVarWatcherFor(targetObj, varName) && varW.visible) return true;
				}
		}
		if ('reporter' == data.type) {
			var w:Watcher = findReporterWatcher(data);
			return w != null && w.visible;
		}
		return false;
	}

	private function findReporterWatcher(data:Object):Watcher {
		var uiLayer:Sprite = app.stagePane.getUILayer();
		for (i in 0...uiLayer.numChildren) {
			var child = uiLayer.getChildAt(i);
			if (Std.is(child, Watcher))
			{
				var w:Watcher = cast(child, Watcher);
				if (w.isReporterWatcher(data.targetObj, data.cmd, data.param)) return w;
			}
		}
		return null;
	}

	private function watcherForVar(targetObj:ScratchObj, vName:String):DisplayObject {
		var v:Variable = targetObj.lookupVar(vName);
		if (v == null) return null; // variable is not defined
		if (v.watcher == null) {
			if (app.stagePane.ownsVar(vName)) targetObj = app.stagePane; // global
			var existing:Watcher = existingWatcherForVar(targetObj, vName);
			if (existing != null) {
				v.watcher = existing;
			} else {
				v.watcher = new Watcher();
				cast(v.watcher, Watcher).initForVar(targetObj, vName);
			}
		}
		return v.watcher;
	}

	private function watcherForList(targetObj:ScratchObj, listName:String):DisplayObject {
		var w:ListWatcher;
		for (w in targetObj.lists) {
			if (w.listName == listName) return w;
		}
		for (w in app.stagePane.lists) {
			if (w.listName == listName) return w;
		}
		return null;
	}

	private function existingWatcherForVar(target:ScratchObj, vName:String):Watcher {
		var uiLayer:Sprite = app.stagePane.getUILayer();
		for (i in 0...uiLayer.numChildren) {
			var c:Dynamic = uiLayer.getChildAt(i);
			if (Std.is(c, Watcher) && (c.isVarWatcherFor(target, vName))) return c;
		}
		return null;
	}

	// -----------------------------
	// Undelete support
	//------------------------------

	private var lastDelete:Array<Dynamic>; // object, x, y, owner (for blocks/stacks/costumes/sounds)

	public function canUndelete():Bool { return lastDelete != null; }
	public function clearLastDelete():Void { lastDelete = null; }

	public function recordForUndelete(obj:Dynamic, x:Int, y:Int, index:Int, owner:Dynamic = null):Void {
		if (Std.is(obj, Block)) {
			var comments:Array<Dynamic> = (cast(obj, Block)).attachedCommentsIn(app.scriptsPane);
			if (comments.length != 0) {
				for (c in comments) {
					c.parent.removeChild(c);
				}
				app.scriptsPane.fixCommentLayout();
				obj = [obj, comments];
			}
		}
		lastDelete = [obj, x, y, index, owner];
	}

	public function undelete():Void {
		if (lastDelete == null) return;
		var obj:Dynamic = lastDelete[0];
		var x:Int = lastDelete[1];
		var y:Int = lastDelete[2];
		var index:Int = lastDelete[3];
		var previousOwner:Dynamic = lastDelete[4];
		doUndelete(obj, x, y, previousOwner);
		lastDelete = null;
	}

	private function doUndelete(obj:Dynamic, x:Int, y:Int, prevOwner:Dynamic):Void {
		if (Std.is(obj, MediaInfo)) {
			if (Std.is(prevOwner, ScratchObj)) {
				app.selectSprite(prevOwner);
				if (obj.mycostume) app.addCostume(cast(obj.mycostume, ScratchCostume));
				if (obj.mysound) app.addSound(cast(obj.mysound, ScratchSound));
			}
		} else if (Std.is(obj, ScratchSprite)) {
			app.addNewSprite(obj);
			obj.setScratchXY(x, y);
			app.selectSprite(obj);
		} else if (Std.is(obj, Array) || Std.is(obj, Block) || Std.is(obj, ScratchComment)) {
			app.selectSprite(prevOwner);
			app.setTab('scripts');
			var b:DisplayObject = Std.is(obj, Array) ? obj[0] : obj;
			b.x = app.scriptsPane.padding;
			b.y = app.scriptsPane.padding;
			if (Std.is(b, Block)) b.cacheAsBitmap = true;
			app.scriptsPane.addChild(b);
			if (Std.is(obj, Array)) {
				var comments:Array<Dynamic> = obj[1];
				for (c in comments) {
					app.scriptsPane.addChild(c);
				}
			}
			app.scriptsPane.saveScripts();
			if (Std.is(b, Block)) app.updatePalette();
		}
	}

}

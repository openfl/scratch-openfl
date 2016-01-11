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

// ScratchObj.as
// John Maloney, April 2010
//
// This is the superclass for both ScratchStage and ScratchSprite,
// containing the variables and methods common to both.

package scratch;

import blocks.*;

import filters.FilterPack;

import flash.display.*;
import flash.events.MouseEvent;
import flash.geom.ColorTransform;
import flash.utils.*;

import interpreter.*;

import scratch.ScratchComment;
import scratch.ScratchSprite;

import translation.Translator;

import util.*;

import watchers.*;

class ScratchObj extends Sprite
{

	@:meta(Embed(source="../assets/pop.wav",mimeType="application/octet-stream"))
private static var Pop : Class<Dynamic>;

	public static inline var STAGEW : Int = 480;
	public static inline var STAGEH : Int = 360;

	public var objName : String = "no name";
	public var isStage : Bool = false;
	public var variables : Array<Dynamic> = [];
	public var lists : Array<Dynamic> = [];
	public var scripts : Array<Dynamic> = [];
	public var scriptComments : Array<Dynamic> = [];
	public var sounds : Array<Dynamic> = [];
	public var costumes : Array<Dynamic> = [];
	public var currentCostumeIndex : Float;
	public var volume : Float = 100;
	public var instrument : Int = 0;
	public var filterPack : FilterPack;
	public var isClone : Bool;

	public var img : Sprite;  // holds a bitmap or svg object, after applying image filters, scale, and rotation  
	private var lastCostume : ScratchCostume;

	// Caches used by the interpreter:
	public var listCache : Dynamic = { };
	public var procCache : Dynamic = { };
	public var varCache : Dynamic = { };

	public function clearCaches() : Void{
		// Clear the list, procedure, and variable caches for this object.
		listCache = { };
		procCache = { };
		varCache = { };
	}

	public function allObjects() : Array<Dynamic>{return [this];
	}

	public function deleteCostume(c : ScratchCostume) : Void{
		if (costumes.length < 2)             return  // a sprite must have at least one costume  ;
		var i : Int = Lambda.indexOf(costumes, c);
		if (i < 0)             return;
		costumes.splice(i, 1);
		if (currentCostumeIndex >= i)             showCostume(currentCostumeIndex - 1);
		if (Scratch.app != null)             Scratch.app.setSaveNeeded();
	}

	public function deleteSound(snd : ScratchSound) : Void{
		var i : Int = Lambda.indexOf(sounds, snd);
		if (i < 0)             return;
		sounds.splice(i, 1);
		if (Scratch.app != null)             Scratch.app.setSaveNeeded();
	}

	public function showCostumeNamed(n : String) : Void{
		var i : Int = indexOfCostumeNamed(n);
		if (i >= 0)             showCostume(i);
	}

	public function indexOfCostumeNamed(n : String) : Int{
		for (i in 0...costumes.length){
			if (cast((costumes[i]), ScratchCostume).costumeName == n)                 return i;
		}
		return -1;
	}

	public function showCostume(costumeIndex : Float) : Void{
		if (isNaNOrInfinity(costumeIndex))             costumeIndex = 0;
		currentCostumeIndex = costumeIndex % costumes.length;
		if (currentCostumeIndex < 0)             currentCostumeIndex += costumes.length;
		var c : ScratchCostume = currentCostume();
		if (c == lastCostume)             return;  // optimization: already showing that costume  ;
		lastCostume = (c.isBitmap()) ? c : null;  // cache only bitmap costumes for now  

		updateImage();
	}

	public function updateCostume() : Void{updateImage();
	}

	public function currentCostume() : ScratchCostume{
		return costumes[Math.round(currentCostumeIndex) % costumes.length];
	}

	public function costumeNumber() : Int{
		// One-based costume number as seen by user (currentCostumeIndex is 0-based)
		return Std.int(currentCostumeIndex + 1);
	}

	public function unusedCostumeName(baseName : String = "") : String{
		// Create a unique costume name by appending a number if necessary.
		if (baseName == "")             baseName = Translator.map((isStage) ? "backdrop1" : "costume1");
		var existingNames : Array<Dynamic> = [];
		for (c in costumes){
			existingNames.push(c.costumeName.toLowerCase());
		}
		var lcBaseName : String = baseName.toLowerCase();
		if (Lambda.indexOf(existingNames, lcBaseName) < 0)             return baseName;  // basename is not already used  ;
		lcBaseName = withoutTrailingDigits(lcBaseName);
		var i : Int = 2;
		while (Lambda.indexOf(existingNames, lcBaseName + i) >= 0){i++;
		}  // find an unused name  
		return withoutTrailingDigits(baseName) + i;
	}

	public function unusedSoundName(baseName : String = "") : String{
		// Create a unique sound name by appending a number if necessary.
		if (baseName == "")             baseName = "sound";
		var existingNames : Array<Dynamic> = [];
		for (snd in sounds){
			existingNames.push(snd.soundName.toLowerCase());
		}
		var lcBaseName : String = baseName.toLowerCase();
		if (Lambda.indexOf(existingNames, lcBaseName) < 0)             return baseName;  // basename is not already used  ;
		lcBaseName = withoutTrailingDigits(lcBaseName);
		var i : Int = 2;
		while (Lambda.indexOf(existingNames, lcBaseName + i) >= 0){i++;
		}  // find an unused name  
		return withoutTrailingDigits(baseName) + i;
	}

	private function withoutTrailingDigits(s : String) : String{
		var i : Int = s.length - 1;
		while ((i >= 0) && ("0123456789".indexOf(s.charAt(i)) > -1))i--;
		return s.substring(0, i + 1);
	}

	private function updateImage() : Void{
		var currChild : DisplayObject = (img.numChildren == (1) ? img.getChildAt(0) : null);
		var currDispObj : DisplayObject = currentCostume().displayObj();
		var change : Bool = (currChild != currDispObj);
		if (change) {
			while (img.numChildren > 0)img.removeChildAt(0);
			img.addChild(currDispObj);
		}
		clearCachedBitmap();
		adjustForRotationCenter();
		updateRenderDetails(0);
	}

	private function updateRenderDetails(reason : Int) : Void{
		///* AS3HX WARNING namespace modifier SCRATCH::allow3d */{
			//if (Std.is(this, ScratchStage) || Std.is(this, ScratchSprite) || (parent != null&& Std.is(parent, ScratchStage))) {
				//var renderOpts : Dynamic = { };
				//var costume : ScratchCostume = currentCostume();
				//
				//// 0 - costume change, 1 - rotation style change
				//if (reason == 0) {
					//if (costume != null && costume.baseLayerID == ScratchCostume.WasEdited) 
						//costume.prepareToSave();
					//
					//var id : String = ((costume != null) ? costume.baseLayerMD5 : null);
					//if (id == null)                         id = objName + ((costume != null) ? costume.costumeName : "_" + currentCostumeIndex)
					//else if (costume != null && costume.textLayerMD5 != null)                         id += costume.textLayerMD5;
					//
					//renderOpts.bitmap = (costume != null && (costume.bitmap != null) ? costume.bitmap : null);
				//}  // TODO: Clip original bitmap to match visible bounds?  
				//
				//
				//
				//if (reason == 1) 
					//renderOpts.costumeFlipped = (Std.is(this, ScratchSprite) ? cast(this, ScratchSprite).isCostumeFlipped() : false);
				//
				//if (reason == 0) {
					//if (Std.is(this, ScratchSprite)) {
						//renderOpts.bounds = cast(this, ScratchSprite).getVisibleBounds(this);
						//renderOpts.raw_bounds = getBounds(this);
					//}
					//else 
					//renderOpts.bounds = getBounds(this);
				//}
				////if (Scratch.app.isIn3D)                     Scratch.app.render3D.updateRender((Std.is(this, (ScratchStage) ? img : this)), id, renderOpts);
			//}
		//}
	}

	private function adjustForRotationCenter() : Void{
		// Adjust the offset of img relative to it's parent. If this object is a
		// ScratchSprite, then img is adjusted based on the costume's rotation center.
		// If it is a ScratchStage, img is centered on the stage.
		var costumeObj : DisplayObject = img.getChildAt(0);
		if (isStage) {
			if (Std.is(costumeObj, Bitmap)) {
				img.x = (STAGEW - costumeObj.width) / 2;
				img.y = (STAGEH - costumeObj.height) / 2;
			}
			else {
				// SVG costume; don't center for now
				img.x = img.y = 0;
			}
		}
		else {
			var c : ScratchCostume = currentCostume();
			costumeObj.scaleX = 1 / c.bitmapResolution;  // don't flip  
			img.x = -c.rotationCenterX / c.bitmapResolution;
			img.y = -c.rotationCenterY / c.bitmapResolution;
			if ((try cast(this, ScratchSprite) catch(e:Dynamic) null).isCostumeFlipped()) {
				costumeObj.scaleX = -1 / c.bitmapResolution;  // flip  
				img.x = -img.x;
			}
		}
	}

	public function clearCachedBitmap() : Void{
		// Does nothing here, but overridden in ScratchSprite

	}

	private static var cTrans : ColorTransform = new ColorTransform();
	public function applyFilters(forDragging : Bool = false) : Void{
		img.filters = filterPack.buildFilters(forDragging);
		clearCachedBitmap();
		if (!Scratch.app.isIn3D || forDragging) {
			var n : Float = Math.max(0, Math.min(filterPack.getFilterSetting("ghost"), 100));
			cTrans.alphaMultiplier = 1.0 - (n / 100.0);
			n = 255 * Math.max(-100, Math.min(filterPack.getFilterSetting("brightness"), 100)) / 100;
			cTrans.redOffset = cTrans.greenOffset = cTrans.blueOffset = n;
			img.transform.colorTransform = cTrans;
		}
		else {
			updateEffectsFor3D();
		}
	}

	public function updateEffectsFor3D() : Void{
		///* AS3HX WARNING namespace modifier SCRATCH::allow3d */{
			//if ((parent != null && Std.is(parent, ScratchStage)) || Std.is(this, ScratchStage)) {
				//if (Std.is(parent, ScratchStage)) 
					//(try cast(parent, ScratchStage) catch(e:Dynamic) null).updateSpriteEffects(this, filterPack.getAllSettings())
				//else {
					//(try cast(this, ScratchStage) catch(e:Dynamic) null).updateSpriteEffects(img, filterPack.getAllSettings());
				//}
			//}
		//}
	}

	private function shapeChangedByFilter() : Bool{
		var filters : Dynamic = filterPack.getAllSettings();
		return (Reflect.field(filters, "fisheye") != 0 || Reflect.field(filters, "whirl") != 0 || Reflect.field(filters, "mosaic") != 0);
	}

	public static var clearColorTrans : ColorTransform = new ColorTransform();
	public function clearFilters() : Void{
		filterPack.resetAllFilters();
		img.filters = [];
		img.transform.colorTransform = clearColorTrans;
		clearCachedBitmap();

		///* AS3HX WARNING namespace modifier SCRATCH::allow3d */{
			//if (parent != null && Std.is(parent, ScratchStage)) {
				//(try cast(parent, ScratchStage) catch(e:Dynamic) null).updateSpriteEffects(this, null);
			//}
		//}
	}

	public function setMedia(media : Array<Dynamic>, currentCostume : ScratchCostume) : Void{
		var newCostumes : Array<Dynamic> = [];
		sounds = [];
		for (m in media){
			if (Std.is(m, ScratchSound))                 sounds.push(m);
			if (Std.is(m, ScratchCostume))                 newCostumes.push(m);
		}
		if (newCostumes.length > 0)             costumes = newCostumes;
		var i : Int = Lambda.indexOf(costumes, currentCostume);
		currentCostumeIndex = ((i < 0)) ? 0 : i;
		showCostume(i);
	}

	public function defaultArgsFor(op : String, specDefaults : Array<Dynamic>) : Array<Dynamic>{
		// Return an array of default parameter values for the given operation (primitive name).
		// For most ops, this will simply return the array of default arg values from the command spec.
		var sprites : Array<Dynamic>;

		if ((["broadcast:", "doBroadcastAndWait", "whenIReceive"].indexOf(op)) > -1) {
			var msgs : Array<Dynamic> = Scratch.app.runtime.collectBroadcasts();
			return ((msgs.length > 0)) ? [msgs[0]] : ["message1"];
		}
		if ((["lookLike:", "startScene", "startSceneAndWait", "whenSceneStarts"].indexOf(op)) > -1) {
			return [costumes[costumes.length - 1].costumeName];
		}
		if ((["playSound:", "doPlaySoundAndWait"].indexOf(op)) > -1) {
			return ((sounds.length > 0)) ? [sounds[sounds.length - 1].soundName] : [""];
		}
		if ("createCloneOf" == op) {
			if (!isStage)                 return ["_myself_"];
			sprites = Scratch.app.stagePane.sprites();
			return ((sprites.length > 0)) ? [sprites[sprites.length - 1].objName] : [""];
		}
		if ("getAttribute:of:" == op) {
			sprites = Scratch.app.stagePane.sprites();
			return ((sprites.length > 0)) ? ["x position", sprites[sprites.length - 1].objName] : ["volume", "_stage_"];
		}

		if ("setVar:to:" == op)             return [defaultVarName(), 0];
		if ("changeVar:by:" == op)             return [defaultVarName(), 1];
		if ("showVariable:" == op)             return [defaultVarName()];
		if ("hideVariable:" == op)             return [defaultVarName()];

		if ("append:toList:" == op)             return ["thing", defaultListName()];
		if ("deleteLine:ofList:" == op)             return [1, defaultListName()];
		if ("insert:at:ofList:" == op)             return ["thing", 1, defaultListName()];
		if ("setLine:ofList:to:" == op)             return [1, defaultListName(), "thing"];
		if ("getLine:ofList:" == op)             return [1, defaultListName()];
		if ("lineCountOfList:" == op)             return [defaultListName()];
		if ("list:contains:" == op)             return [defaultListName(), "thing"];
		if ("showList:" == op)             return [defaultListName()];
		if ("hideList:" == op)             return [defaultListName()];

		return specDefaults;
	}

	public function defaultVarName() : String{
		if (variables.length > 0)             return variables[variables.length - 1].name;  // local var  ;
		return (isStage) ? "" : Scratch.app.stagePane.defaultVarName();
	}

	public function defaultListName() : String{
		if (lists.length > 0)             return lists[lists.length - 1].listName;  // local list  ;
		return (isStage) ? "" : Scratch.app.stagePane.defaultListName();
	}

	/* Scripts */

	public function allBlocks() : Array<Dynamic>{
		var result : Array<Dynamic> = [];
		for (script in scripts){
			script.allBlocksDo(function(b : Block) : Void{result.push(b);
					});
		}
		return result;
	}

	/* Sounds */

	public function findSound(arg : Dynamic) : ScratchSound{
		// Return a sound describe by arg, which can be a string (sound name),
		// a number (sound index), or a string representing a number (sound index).
		if (sounds.length == 0)             return null;
		if (Std.is(arg, Float) || Std.is(arg, Int)) {
			var i : Int = Math.round(arg - 1) % sounds.length;
			if (i < 0)                 i += sounds.length;  // ensure positive  ;
			return sounds[i];
		}
		else if (Std.is(arg, String)) {
			for (snd in sounds){
				if (snd.soundName == arg)                     return snd;  // arg matches a sound name  ;
			}  // try converting string arg to a number  

			var n : Float = Std.parseFloat(arg);
			if (Math.isNaN(n))                 return null;
			return findSound(n);
		}
		return null;
	}

	public function setVolume(vol : Float) : Void{
		volume = Math.max(0, Math.min(vol, 100));
	}

	public function setInstrument(instr : Float) : Void{
		instrument = Std.int(Math.max(1, Math.min(Math.round(instr), 128)));
	}

	/* Procedures */

	public function procedureDefinitions() : Array<Dynamic>{
		var result : Array<Dynamic> = [];
		for (i in 0...scripts.length){
			var b : Block = try cast(scripts[i], Block) catch(e:Dynamic) null;
			if (b != null && (b.op == Specs.PROCEDURE_DEF))                 result.push(b);
		}
		return result;
	}

	public function lookupProcedure(procName : String) : Block{
		for (i in 0...scripts.length){
			var b : Block = try cast(scripts[i], Block) catch(e:Dynamic) null;
			if (b != null && (b.op == Specs.PROCEDURE_DEF) && (b.spec == procName))                 return b;
		}
		return null;
	}

	/* Variables */

	public function varNames() : Array<Dynamic>{
		var varList : Array<Dynamic> = [];
		for (v in variables)varList.push(v.name);
		return varList;
	}

	public function setVarTo(varName : String, value : Dynamic) : Void{
		var v : Variable = lookupOrCreateVar(varName);
		v.value = value;
		Scratch.app.runtime.updateVariable(v);
	}

	public function ownsVar(varName : String) : Bool{
		// Return true if this object owns a variable of the given name.
		for (v in variables){
			if (v.name == varName)                 return true;
		}
		return false;
	}

	public function hasName(varName : String) : Bool{
		var p : ScratchObj = try cast(parent, ScratchObj) catch(e:Dynamic) null;
		return ownsVar(varName) || ownsList(varName) || p != null && (p.ownsVar(varName) || p.ownsList(varName));
	}

	public function lookupOrCreateVar(varName : String) : Variable{
		// Lookup and return a variable. If lookup fails, create the variable in this object.
		var v : Variable = lookupVar(varName);
		if (v == null) {  // not found; create it  
			v = new Variable(varName, 0);
			variables.push(v);
			Scratch.app.updatePalette(false);
		}
		return v;
	}

	public function lookupVar(varName : String) : Variable{
		// Look for variable first in sprite (local), then stage (global).
		// Return null if not found.
		var v : Variable;
		for (v in variables){
			if (v.name == varName)                 return v;
		}
		for (v/* AS3HX WARNING could not determine type for var: v exp: EField(EField(EField(EIdent(Scratch),app),stagePane),variables) type: null */ in Scratch.app.stagePane.variables){
			if (v.name == varName)                 return v;
		}
		return null;
	}

	public function deleteVar(varToDelete : String) : Void{
		var newVars : Array<Dynamic> = [];
		for (v in variables){
			if (v.name == varToDelete) {
				if ((v.watcher != null) && (v.watcher.parent != null)) {
					v.watcher.parent.removeChild(v.watcher);
				}
				v.watcher = v.value = null;
			}
			else newVars.push(v);
		}
		variables = newVars;
	}

	/* Lists */

	public function listNames() : Array<Dynamic>{
		var result : Array<Dynamic> = [];
		for (list in lists)result.push(list.listName);
		return result;
	}

	public function ownsList(listName : String) : Bool{
		// Return true if this object owns a list of the given name.
		for (w in lists){
			if (w.listName == listName)                 return true;
		}
		return false;
	}

	public function lookupOrCreateList(listName : String) : ListWatcher{
		// Look and return a list. If lookup fails, create the list in this object.
		var list : ListWatcher = lookupList(listName);
		if (list == null) {  // not found; create it  
			list = new ListWatcher(listName, [], this);
			lists.push(list);
			Scratch.app.updatePalette(false);
		}
		return list;
	}

	public function lookupList(listName : String) : ListWatcher{
		// Look for list first in this sprite (local), then stage (global).
		// Return null if not found.
		var list : ListWatcher;
		for (list in lists){
			if (list.listName == listName)                 return list;
		}
		for (list/* AS3HX WARNING could not determine type for var: list exp: EField(EField(EField(EIdent(Scratch),app),stagePane),lists) type: null */ in Scratch.app.stagePane.lists){
			if (list.listName == listName)                 return list;
		}
		return null;
	}

	public function deleteList(listName : String) : Void{
		var newLists : Array<Dynamic> = [];
		for (w in lists){
			if (w.listName == listName) {
				if (w.parent)                     w.parent.removeChild(w);
			}
			else {
				newLists.push(w);
			}
		}
		lists = newLists;
	}

	/* Events */

	private static inline var DOUBLE_CLICK_MSECS : Int = 300;
	private var lastClickTime : Int;

	public function click(evt : MouseEvent) : Void{
		var app : Scratch = try cast(root, Scratch) catch(e:Dynamic) null;
		if (app == null)             return;
		var now : Int = Math.round(haxe.Timer.stamp() * 1000);
		app.runtime.startClickedHats(this);
		if ((now - lastClickTime) < DOUBLE_CLICK_MSECS) {
			if (isStage || cast((this), ScratchSprite).isClone)                 return;
			app.selectSprite(this);
			lastClickTime = 0;
		}
		else {
			lastClickTime = now;
		}
	}

	/* Translation */

	public function updateScriptsAfterTranslation() : Void{
		// Update the scripts of this object after switching languages.
		var newScripts : Array<Dynamic> = [];
		for (b in scripts){
			var newStack : Block = BlockIO.arrayToStack(BlockIO.stackToArray(b), isStage);
			newStack.x = b.x;
			newStack.y = b.y;
			newScripts.push(newStack);
			if (b.parent) {  // stack in the scripts pane; replace it  
				b.parent.addChild(newStack);
				b.parent.removeChild(b);
			}
		}
		scripts = newScripts;
		var blockList : Array<Dynamic> = allBlocks();
		for (c in scriptComments){
			c.updateBlockRef(blockList);
		}
	}

	/* Saving */

	public function writeJSON(json : util.JSON) : Void{
		var allScripts : Array<Dynamic> = [];
		for (b in scripts){
			allScripts.push([b.x, b.y, BlockIO.stackToArray(b)]);
		}
		var allComments : Array<Dynamic> = [];
		for (c in scriptComments){
			allComments.push(c.toArray());
		}
		json.writeKeyValue("objName", objName);
		if (variables.length > 0)             json.writeKeyValue("variables", variables);
		if (lists.length > 0)             json.writeKeyValue("lists", lists);
		if (scripts.length > 0)             json.writeKeyValue("scripts", allScripts);
		if (scriptComments.length > 0)             json.writeKeyValue("scriptComments", allComments);
		if (sounds.length > 0)             json.writeKeyValue("sounds", sounds);
		json.writeKeyValue("costumes", costumes);
		json.writeKeyValue("currentCostumeIndex", currentCostumeIndex);
	}

	public function readJSON(jsonObj : Dynamic) : Void{
		objName = jsonObj.objName;
		variables = jsonObj.variables != null ?  jsonObj.variables: [];
		for (i in 0...variables.length){
			var varObj : Dynamic = variables[i];
			variables[i] = Scratch.app.runtime.makeVariable(varObj);
		}
		lists = jsonObj.lists != null ? jsonObj.lists : [];
		scripts = jsonObj.scripts != null ? jsonObj.scripts: [];
		scriptComments = jsonObj.scriptComments != null ? jsonObj.scriptComments: [];
		sounds = jsonObj.sounds != null ? jsonObj.sounds: [];
		costumes = jsonObj.costumes != null ? jsonObj.costumes: [];
		currentCostumeIndex = jsonObj.currentCostumeIndex;
		if (isNaNOrInfinity(currentCostumeIndex))             currentCostumeIndex = 0;
	}

	private function isNaNOrInfinity(n : Float) : Bool{
		if (n != n)             return true;  // NaN  ;
		if (n == Math.POSITIVE_INFINITY)             return true;
		if (n == Math.NEGATIVE_INFINITY)             return true;
		return false;
	}

	public function instantiateFromJSON(newStage : ScratchStage) : Void{
		var i : Int;
		var jsonObj : Dynamic;

		// lists
		for (i in 0...lists.length){
			jsonObj = lists[i];
			var newList : ListWatcher = new ListWatcher();
			newList.readJSON(jsonObj);
			newList.target = this;
			newStage.addChild(newList);
			newList.updateTitleAndContents();
			lists[i] = newList;
		}  // scripts  



		for (i in 0...scripts.length){
			// entries are of the form: [x y stack]
			var entry : Array<Dynamic> = scripts[i];
			var b : Block = BlockIO.arrayToStack(entry[2], isStage);
			b.x = entry[0];
			b.y = entry[1];
			scripts[i] = b;
		}  // script comments  



		for (i in 0...scriptComments.length){
			scriptComments[i] = ScratchComment.fromArray(scriptComments[i]);
		}  // sounds  



		for (i in 0...sounds.length){
			jsonObj = sounds[i];
			sounds[i] = new ScratchSound("json temp", null);
			sounds[i].readJSON(jsonObj);
		}  // costumes  



		for (i in 0...costumes.length){
			jsonObj = costumes[i];
			costumes[i] = new ScratchCostume("json temp", null);
			costumes[i].readJSON(jsonObj);
		}
	}

	public function getSummary() : String{
		var s : Array<Dynamic> = [];
		s.push(h1(objName));
		if (variables.length != 0) {
			s.push(h2(Translator.map("Variables")));
			for (v in variables){
				s.push("- " + v.name + " = " + v.value);
			}
			s.push("");
		}
		if (lists.length != 0) {
			s.push(h2(Translator.map("Lists")));
			for (list in lists){
				s.push("- " + list.listName + ((list.contents.length) ? ":" : ""));
				for (item/* AS3HX WARNING could not determine type for var: item exp: EField(EIdent(list),contents) type: null */ in list.contents){
					s.push("    - " + item);
				}
			}
			s.push("");
		}
		s.push(h2(Translator.map((isStage) ? "Backdrops" : "Costumes")));
		for (costume in costumes){
			s.push("- " + costume.costumeName);
		}
		s.push("");
		if (sounds.length != 0) {
			s.push(h2(Translator.map("Sounds")));
			for (sound in sounds){
				s.push("- " + sound.soundName);
			}
			s.push("");
		}
		if (scripts.length != 0) {
			s.push(h2(Translator.map("Scripts")));
			for (script in scripts){
				s.push(script.getSummary());
				s.push("");
			}
		}
		return s.join("\n");
	}

	private static function h1(s : String, ch : String = "=") : String{
		return s + "\n" + new Array<Dynamic>(s.length + 1).join(ch) + "\n";
	}
	private static function h2(s : String) : String{
		return h1(s, "-");
	}

	public function new()
	{
		super();
	}
}

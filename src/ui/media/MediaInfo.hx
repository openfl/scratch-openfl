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

// MediaInfo.as
// John Maloney, December 2011
//
// This object represent a sound, image, or script. It is used:
//	* to represent costumes, backdrops, or sounds in a MediaPane
//	* to represent images, sounds, and sprites in the backpack (a BackpackPart)
//	* to drag between the backpack and the media pane

package ui.media;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.text.*;
	import assets.Resources;
	import blocks.*;
	import scratch.*;
	import translation.Translator;
	import ui.parts.*;
	import uiwidgets.*;

class MediaInfo extends Sprite {

	public var frameWidth:Int = 81;
	private var frameHeight:Int = 94;
	private var thumbnailWidth:Int = 68;
	private var thumbnailHeight:Int = 51;

	// at most one of the following is non-null:
	public var mycostume:ScratchCostume;
	public var mysprite:ScratchSprite;
	public var mysound:ScratchSound;
	public var scripts:Array<Dynamic>;

	public var objType:String = 'unknown';
	public var objName:String = '';
	public var objWidth:Int = 0;
	public var md5:String;

	public var owner:ScratchObj; // object owning a sound or costume in MediaPane; null for other cases
	public var isBackdrop:Bool;
	public var forBackpack:Bool;

	private var frame:Shape; // visible when selected
	private var thumbnail:Bitmap;
	private var label:TextField;
	private var info:TextField;
	private var deleteButton:IconButton;

	public function new(obj:Dynamic, owningObj:ScratchObj = null) {
		super();
		owner = owningObj;
		if (Std.is(obj, ScratchCostume)) {
			mycostume = cast(obj, ScratchCostume);
			objType = 'image';
			objName = mycostume.costumeName;
			md5 = mycostume.baseLayerMD5;
		} else if (Std.is(obj, ScratchSound)) {
			mysound = cast(obj, ScratchSound);
			objType = 'sound';
			objName = mysound.soundName;
			md5 = mysound.md5;
			if (owner != null) frameHeight = 75; // use a shorter frame for sounds in a MediaPane
		} else if (Std.is(obj, ScratchSprite)) {
			mysprite = cast(obj, ScratchSprite);
			objType = 'sprite';
			objName = mysprite.objName;
			md5 = null; // initially null
		} else if ((Std.is(obj, Block)) || (Std.is(obj, Array))) {
			// scripts holds an array of blocks, stacks, and comments in Array form
			// initialize script list from either a stack (Block) or an array of stacks already in array form
			objType = 'script';
			objName = '';
			scripts = (Std.is(obj, Block)) ? [BlockIO.stackToArray(obj)] : obj;
			md5 = null; // scripts don't have an MD5 hash
		} else {
			// initialize from a JSON object
			objType = obj.type ? obj.type : '';
			objName = obj.name ? obj.name : '';
			objWidth = obj.width ? obj.width : 0;
			scripts = obj.scripts;
			md5 = ('script' != objType) ? obj.md5 : null;
		}
		addFrame();
		addThumbnail();
		addLabelAndInfo();
		unhighlight();
		addDeleteButton();
		updateLabelAndInfo(false);
	}

	public static function strings():Array<String> {
		return ['Backdrop', 'Costume', 'Script', 'Sound', 'Sprite', 'save to local file'];
	}

	// -----------------------------
	// Highlighting (for MediaPane)
	//------------------------------

	public function highlight():Void {
		if (frame.alpha != 1) { frame.alpha = 1; showDeleteButton(true); }
	}

	public function unhighlight():Void {
		if (frame.alpha != 0) { frame.alpha = 0; showDeleteButton(false); }
	}

	private function showDeleteButton(flag:Bool):Void {
		if (deleteButton != null) {
			deleteButton.visible = flag;
			if (flag && mycostume != null && owner != null && (owner.costumes.length < 2)) deleteButton.visible = false;
		}
	}

	// -----------------------------
	// Thumbnail
	//------------------------------

	public function updateMediaThumbnail():Void { /* xxx */ }
	public function thumbnailX():Int { return Std.int(thumbnail.x); }
	public function thumbnailY():Int { return Std.int(thumbnail.y); }

	public function computeThumbnail():Bool {
		if (mycostume != null) setLocalCostumeThumbnail();
		else if (mysprite != null) setLocalSpriteThumbnail();
		else if (scripts != null) setScriptThumbnail();
		else return false;

		return true;
	}

	private function setLocalCostumeThumbnail():Void {
		// Set the thumbnail for a costume local to this project (and not necessarily saved to the server).
		var forStage:Bool = owner != null && owner.isStage;
		var bm:BitmapData = mycostume.thumbnail(thumbnailWidth, thumbnailHeight, forStage);
		isBackdrop = forStage;
		setThumbnailBM(bm);
	}

	private function setLocalSpriteThumbnail():Void {
		// Set the thumbnail for a sprite local to this project (and not necessarily saved to the server).
		setThumbnailBM(mysprite.currentCostume().thumbnail(thumbnailWidth, thumbnailHeight, false));
	}

	private function fileType(s:String):String {
		if (s == null) return '';
		var i:Int = s.lastIndexOf('.');
		return (i < 0) ? '' : s.substr(i + 1);
	}

	private function setScriptThumbnail():Void {
		if (scripts == null || (scripts.length < 1)) return; // no scripts
		var script:Block = BlockIO.arrayToStack(scripts[0]);
		var scale:Float = Math.min(thumbnailWidth / script.width, thumbnailHeight / script.height);
		var bm:BitmapData = new BitmapData(thumbnailWidth, thumbnailHeight, true, 0);
		var m:Matrix = new Matrix();
		m.scale(scale, scale);
		bm.draw(script, m);
		setThumbnailBM(bm);
	}

	private function setThumbnailBM(bm:BitmapData):Void {
		thumbnail.bitmapData = bm;
		thumbnail.x = (frameWidth - thumbnail.width) / 2;
	}

	private function setInfo(s:String):Void {
		info.text = s;
		info.x = Math.max(0, (frameWidth - info.textWidth) / 2);
	}

	// -----------------------------
	// Label and Info
	//------------------------------

	public function updateLabelAndInfo(forBackpack:Bool):Void {
		this.forBackpack = forBackpack;
		setText(label, (forBackpack ? backpackTitle() : objName));
		label.x = ((frameWidth - label.textWidth) / 2) - 2;

		setText(info, (forBackpack ? objName: infoString()));
		info.x = Math.max(0, (frameWidth - info.textWidth) / 2);
	}

	public function hideTextFields():Void {
		setText(label, '');
		setText(info, '');
	}

	private function backpackTitle():String {
		if ('image' == objType) return Translator.map(isBackdrop ? 'Backdrop' : 'Costume');
		if ('script' == objType) return Translator.map('Script');
		if ('sound' == objType) return Translator.map('Sound');
		if ('sprite' == objType) return Translator.map('Sprite');
		return objType;
	}

	private function infoString():String {
		if (mycostume != null) return costumeInfoString();
		if (mysound != null) return soundInfoString(mysound.getLengthInMsec());
		return '';
	}

	private function costumeInfoString():String {
		// Use the actual dimensions (rounded up to an integer) of my costume.
		var w:Int, h:Int;
		var dispObj:DisplayObject = mycostume.displayObj();
		if (Std.is(dispObj, Bitmap)) {
			w = Std.int(dispObj.width);
			h = Std.int(dispObj.height);
		} else {
			var r:Rectangle = dispObj.getBounds(dispObj);
			w = Std.int(Math.ceil(r.width));
			h = Std.int(Math.ceil(r.height));
		}
		return w + 'x' + h;
	}

	private function soundInfoString(msecs:Float):String {
		// Return a formatted time in MM:SS.HH (where HH is hundredths of a second).
		function twoDigits(n:Int):String { return (n < 10) ? '0' + n : '' + n; }

		var secs:Int = Std.int(msecs / 1000);
		var hundredths:Int = Std.int((msecs % 1000) / 10);
		return twoDigits(Std.int(secs / 60)) + ':' + twoDigits(secs % 60) + '.' + twoDigits(hundredths);
	}

	// -----------------------------
	// Backpack Support
	//------------------------------

	public function objToGrab(evt:MouseEvent):Dynamic {
		var result:MediaInfo = Scratch.app.createMediaInfo({
			type: objType,
			name: objName,
			width: objWidth,
			md5: md5
		});
		if (mycostume != null) result = Scratch.app.createMediaInfo(mycostume, owner);
		if (mysound != null) result = Scratch.app.createMediaInfo(mysound, owner);
		if (mysprite != null) result = Scratch.app.createMediaInfo(mysprite);
		if (scripts != null) result = Scratch.app.createMediaInfo(scripts);

		result.removeDeleteButton();
		if (thumbnail.bitmapData != null) result.thumbnail.bitmapData = thumbnail.bitmapData;
		result.hideTextFields();
		return result;
	}

	public function addDeleteButton():Void {
		removeDeleteButton();
		deleteButton = new IconButton(deleteMe, Resources.createBmp('removeItem'));
		deleteButton.x = frame.width - deleteButton.width + 5;
		deleteButton.y = 3;
		deleteButton.visible = false;
		addChild(deleteButton);
	}

	public function removeDeleteButton():Void {
		if (deleteButton != null) {
			removeChild(deleteButton);
			deleteButton = null;
		}
	}

	public function backpackRecord():Dynamic {
		// Return an object to be saved in the backpack.
		var result:Dynamic = {
			type: objType,
			name: objName,
			md5: md5
		};
		if (mycostume != null) {
			result.width = mycostume.width();
			result.height = mycostume.height();
		}
		if (mysound != null) {
			result.seconds = mysound.getLengthInMsec() / 1000;
		}
		if (scripts != null) {
			result.scripts = scripts;
			result.md5 = null; //delete result.md5;
		}
		return result;
	}

	// -----------------------------
	// Parts
	//------------------------------

	private function addFrame():Void {
		frame = new Shape();
		var g:Graphics = frame.graphics;
		g.lineStyle(3, CSS.overColor, 1, true);
		g.beginFill(CSS.itemSelectedColor);
		g.drawRoundRect(0, 0, frameWidth, frameHeight, 12, 12);
		g.endFill();
		addChild(frame);
	}

	private function addThumbnail():Void {
		if ('sound' == objType) {
			thumbnail = Resources.createBmp('speakerOff');
			thumbnail.x = 18;
			thumbnail.y = 16;
		} else {
			thumbnail = Resources.createBmp('questionMark');
			thumbnail.x = (frameWidth - thumbnail.width) / 2;
			thumbnail.y = 13;
		}
		addChild(thumbnail);
		if (owner != null) computeThumbnail();
	}

	private function addLabelAndInfo():Void {
		label = Resources.makeLabel('', CSS.thumbnailFormat);
		label.y = frameHeight - 28;
		addChild(label);
		info = Resources.makeLabel('', CSS.thumbnailExtraInfoFormat);
		info.y = frameHeight - 14;
		addChild(info);
	}

	private function setText(tf:TextField, s:String):Void {
		// Set the text of the given TextField, truncating if necessary.
		var desiredWidth:Int = Std.int(frame.width - 6);
		tf.text = s;
		while ((tf.textWidth > desiredWidth) && (s.length > 0)) {
			s = s.substring(0, s.length - 1);
			tf.text = s + '\u2026'; // truncated name with ellipses
		}
	}

	// -----------------------------
	// User interaction
	//------------------------------

	public function click(evt:MouseEvent):Void {
		if (getBackpack() == null) {
			var app:Scratch = Scratch.app;
			if (mycostume != null) {
				app.viewedObj().showCostumeNamed(mycostume.costumeName);
				app.selectCostume();
			}
			if (mysound != null) app.selectSound(mysound);
		}
	}

	public function handleTool(tool:String, evt:MouseEvent):Void {
		if (tool == 'copy') duplicateMe();
		if (tool == 'cut') deleteMe();
		if (tool == 'help') Scratch.app.showTip('scratchUI');	}

	public function menu(evt:MouseEvent):Menu {
		var m:Menu = new Menu();
		addMenuItems(m);
		return m;
	}

	private function addMenuItems(m:Menu):Void {
		if (getBackpack() == null) m.addItem('duplicate', duplicateMe);
		m.addItem('delete', deleteMe);
		m.addLine();
		if (mycostume != null) {
			m.addItem('save to local file', exportCostume);
		}
		if (mysound != null) {
			m.addItem('save to local file', exportSound);
		}
	}

	private function duplicateMe():Void {
		if (owner != null && getBackpack() == null) {
			if (mycostume != null ) Scratch.app.addCostume(mycostume.duplicate());
			if (mysound != null) Scratch.app.addSound(mysound.duplicate());
		}
	}

	private function deleteMe(ignore:Dynamic  = null):Void {
		if (owner != null) {
			Scratch.app.runtime.recordForUndelete(this, 0, 0, 0, owner);
			if (mycostume != null) {
				owner.deleteCostume(mycostume);
				Scratch.app.refreshImageTab(false);
			}
			if (mysound != null) {
				owner.deleteSound(mysound);
				Scratch.app.refreshSoundTab();
			}
		}
	}

	private function exportCostume():Void {
		if (mycostume == null) return;
		mycostume.prepareToSave();
		var ext:String = ScratchCostume.fileExtension(mycostume.baseLayerData);
		var defaultName:String = mycostume.costumeName + ext;
		new FileReference().save(mycostume.baseLayerData, defaultName);
	}

	private function exportSound():Void {
		if (mysound == null) return;
		mysound.prepareToSave();
		var defaultName:String = mysound.soundName + '.wav';
		new FileReference().save(mysound.soundData, defaultName);
	}

	private function getBackpack():UIPart {
		return null;
	}
}

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

// MediaLibraryItem.as
// John Maloney, April 2013
//
// This object represents an image, sound, or sprite in the MediaLibrary. It displays
// a name, thumbnail, and a line of information for the media object it represents.

package ui.media;


import flash.display.*;
import flash.events.MouseEvent;
import flash.net.URLLoader;
import flash.text.*;
import flash.utils.ByteArray;
import assets.Resources;
import scratch.*;
//import sound.ScratchSoundPlayer;
//import sound.mp3.MP3SoundPlayer;
//import svgutils.SVGImporter;
import translation.Translator;
import uiwidgets.*;
import util.*;

class MediaLibraryItem extends Sprite
{

	public var dbObj : Dynamic;
	public var isSound : Bool;

	public var frameWidth : Int;
	public var frameHeight : Int;
	private var thumbnailWidth : Int;
	private var thumbnailHeight : Int;

	private var labelFormat : TextFormat = new TextFormat(CSS.font, 14, CSS.textColor);
	private var infoFormat : TextFormat = new TextFormat(CSS.font, 10, CSS.textColor);

	private static var spriteCache : Dynamic = { };  // maps md5 -> JSON for sprites  
	private static var thumbnailCache : Dynamic = { };

	private var frame : Shape;  // visible when selected  
	private var thumbnail : Bitmap;
	private var label : DisplayObject;
	private var info : TextField;
	private var playButton : IconButton;

	private var sndData : ByteArray;
	//private var sndPlayer : ScratchSoundPlayer;

	private var loaders : Array<URLLoader> = [];  // list of URLLoaders for stopLoading()  

	public function new(dbObject : Dynamic = null)
	{
		super();
		this.dbObj = dbObject;
		if (dbObj.seconds)             isSound = true;

		frameWidth = (isSound) ? 115 : 140;
		frameHeight = (isSound) ? 95 : 140;
		thumbnailWidth = (isSound) ? 68 : 120;
		thumbnailHeight = (isSound) ? 51 : 90;

		addFrame();
		addThumbnail();
		addLabel();
		addInfo();
		unhighlight();
		if (isSound)             addPlayButton();
	}

	public static function strings() : Array<Dynamic>{return ["Costumes:", "Scripts:"];
	}

	// -----------------------------
	// Thumbnail
	//------------------------------

	public function loadThumbnail(done : Void->Void) : Void{
		var ext : String = fileType(dbObj.md5);
		if (["gif", "png", "jpg", "jpeg", "svg"].indexOf(ext) > -1)             setImageThumbnail(dbObj.md5, done)
		else if (ext == "json")             setSpriteThumbnail(done);
	}

	public function stopLoading() : Void{
		var app : Scratch = try cast(root, Scratch) catch(e:Dynamic) null;
		for (loader in loaders)if (loader != null)             loader.close();
		loaders = [];
	}

	private function fileType(s : String) : String{
		if (s == null)             return "";
		var i : Int = s.lastIndexOf(".");
		return ((i < 0)) ? "" : s.substring(i + 1);
	}

	// all paths must call done() even on failure!
	private function setImageThumbnail(md5 : String, done : Void->Void, spriteMD5 : String = null) : Void{
		var forStage : Bool = (dbObj.width == 480);  // if width is 480, format thumbnail for stage  
		var importer : SVGImporter;
		function gotSVGData(data : ByteArray) : Void{
			if (data != null) {
				importer = new SVGImporter(cast((data), XML));
				importer.loadAllImages(svgImagesLoaded);
			}
			else {
				done();
			}
		};
		function svgImagesLoaded() : Void{
			var c : ScratchCostume = new ScratchCostume("", null);
			c.setSVGRoot(importer.root, false);
			setThumbnail(c.thumbnail(thumbnailWidth, thumbnailHeight, forStage));
			done();
		};
		function setThumbnail(bm : BitmapData) : Void{
			if (bm != null) {
				Reflect.setField(thumbnailCache, md5, bm);
				if (spriteMD5 != null)                     Reflect.setField(thumbnailCache, spriteMD5, bm);
				setThumbnailBM(bm);
			}
			done();
		}  // first, check the thumbnail cache  ;

		var cachedBM : BitmapData = Reflect.field(thumbnailCache, md5);
		if (cachedBM != null) {setThumbnailBM(cachedBM);done();return;
		}  // if not in the thumbnail cache, fetch/compute it  



		if (fileType(md5) == "svg")             loaders.push(Scratch.app.server.getAsset(md5, gotSVGData))
		else loaders.push(Scratch.app.server.getThumbnail(md5, thumbnailWidth, thumbnailHeight, setThumbnail));
	}

	// all paths must call done() even on failure!
	private function setSpriteThumbnail(done : Void->Void) : Void{
		function gotJSONData(data : String) : Void{
			var md5 : String;
			if (data != null) {
				var sprObj : Dynamic = util.JSON.parse(data);
				Reflect.setField(spriteCache, spriteMD5, data);
				dbObj.scriptCount = ((Std.is(sprObj.scripts, Array))) ? sprObj.scripts.length : 0;
				dbObj.costumeCount = ((Std.is(sprObj.costumes, Array))) ? sprObj.costumes.length : 0;
				dbObj.soundCount = ((Std.is(sprObj.sounds, Array))) ? sprObj.sounds.length : 0;
				if (dbObj.scriptCount > 0)                     setInfo(Translator.map("Scripts:") + " " + dbObj.scriptCount)
				else if (dbObj.costumeCount > 1)                     setInfo(Translator.map("Costumes:") + " " + dbObj.costumeCount)
				else setInfo("");
				if ((Std.is(sprObj.costumes, Array)) && (Std.is(sprObj.currentCostumeIndex, Float))) {
					var cList : Array<Dynamic> = sprObj.costumes;
					var cObj : Dynamic = cList[Math.round(sprObj.currentCostumeIndex) % cList.length];
					if (cObj != null)                         md5 = cObj.baseLayerMD5;
				}
			}
			if (md5 != null) {
				setImageThumbnail(md5, done, spriteMD5);
			}
			else {
				done();
			}
		}  // first, check the thumbnail cache  ;

		var spriteMD5 : String = dbObj.md5;
		var cachedBM : BitmapData = Reflect.field(thumbnailCache, spriteMD5);
		if (cachedBM != null) {setThumbnailBM(cachedBM);done();return;
		}

		if (Reflect.field(spriteCache, spriteMD5))             gotJSONData(Reflect.field(spriteCache, spriteMD5))
		else loaders.push(Scratch.app.server.getAsset(spriteMD5, gotJSONData));
	}

	private function setThumbnailBM(bm : BitmapData) : Void{
		thumbnail.bitmapData = bm;
		thumbnail.x = (frameWidth - thumbnail.width) / 2;
	}

	private function setInfo(s : String) : Void{
		info.text = s;
		info.x = Math.max(0, (frameWidth - info.textWidth) / 2);
	}

	// -----------------------------
	// Parts
	//------------------------------

	private function addFrame() : Void{
		frame = new Shape();
		var g : Graphics = frame.graphics;
		g.lineStyle(3, CSS.overColor, 1, true);
		g.beginFill(CSS.itemSelectedColor);
		g.drawRoundRect(0, 0, frameWidth, frameHeight, 12, 12);
		g.endFill();
		addChild(frame);
	}

	private function addThumbnail() : Void{
		if (isSound) {
			thumbnail = Resources.createBmp("speakerOff");
			thumbnail.x = 22;
			thumbnail.y = 25;
		}
		else {
			var blank : BitmapData = new BitmapData(1, 1, true, 0);
			thumbnail = new Bitmap(blank);
			thumbnail.x = (frameWidth - thumbnail.width) / 2;
			thumbnail.y = 13;
		}
		addChild(thumbnail);
	}

	private function addLabel() : Void{
		var objName : String = (dbObj.name) ? dbObj.name : "";
		var tf : TextField = Resources.makeLabel(objName, labelFormat);
		label = tf;
		label.x = ((frameWidth - tf.textWidth) / 2) - 2;
		label.y = frameHeight - 32;
		addChild(label);
	}

	private function addInfo() : Void{
		info = Resources.makeLabel("", infoFormat);
		info.x = Math.max(0, (frameWidth - info.textWidth) / 2);
		info.y = frameHeight - 17;
		addChild(info);
	}

	private function addPlayButton() : Void{
		playButton = new IconButton(toggleSoundPlay, "play");
		playButton.x = 75;
		playButton.y = 28;
		addChild(playButton);
	}

	private function setText(tf : TextField, s : String) : Void{
		// Set the text of the given TextField, truncating if necessary.
		var desiredWidth : Int = frame.width - 6;
		tf.text = s;
		while ((tf.textWidth > desiredWidth) && (s.length > 0)){
			s = s.substring(0, s.length - 1);
			tf.text = s + "\u2026";
		}
	}

	// -----------------------------
	// User interaction
	//------------------------------

	public function click(evt : MouseEvent) : Void{
		if (!evt.shiftKey)             unhighlightAll();
		toggleHighlight();
	}

	public function doubleClick(evt : MouseEvent) : Void{
		if (!evt.shiftKey)             unhighlightAll();
		highlight();
		var lib : MediaLibrary = try cast(parent.parent.parent, MediaLibrary) catch(e:Dynamic) null;
		if (lib != null)             lib.addSelected();
	}

	// -----------------------------
	// Highlighting
	//------------------------------

	public function isHighlighted() : Bool{return frame.alpha == 1;
	}
	private function toggleHighlight() : Void{if (frame.alpha == 1)             unhighlight()
		else highlight();
	}

	private function highlight() : Void{
		if (frame.alpha != 1) {
			frame.alpha = 1;
			info.visible = true;
		}
	}

	private function unhighlight() : Void{
		if (frame.alpha != 0) {
			frame.alpha = 0;
			info.visible = false;
		}
	}

	private function unhighlightAll() : Void{
		var contents : ScrollFrameContents = try cast(parent, ScrollFrameContents) catch(e:Dynamic) null;
		if (contents != null) {
			for (i in 0...contents.numChildren){
				var item : MediaLibraryItem = try cast(contents.getChildAt(i), MediaLibraryItem) catch(e:Dynamic) null;
				if (item != null)                     item.unhighlight();
			}
		}
	}

	// -----------------------------
	// Play Sound
	//------------------------------

	private function toggleSoundPlay(b : IconButton) : Void{
		//if (sndPlayer != null)             stopPlayingSound(null)
		//else startPlayingSound();
	}

	private function stopPlayingSound(ignore : Dynamic) : Void{
		//if (sndPlayer != null)             sndPlayer.stopPlaying();
		//sndPlayer = null;
		//playButton.turnOff();
	}

	private function startPlayingSound() : Void{
		//if (sndData != null) {
			//if (ScratchSound.isWAV(sndData)) {
				//sndPlayer = new ScratchSoundPlayer(sndData);
			//}
			//else {
				//sndPlayer = new MP3SoundPlayer(sndData);
			//}
		//}
		//if (sndPlayer != null) {
			//sndPlayer.startPlaying(stopPlayingSound);
			//playButton.turnOn();
		//}
		//else {
			//downloadAndPlay();
		//}
	}

	private function downloadAndPlay() : Void{
		//// Download and play a library sound.
		//function gotSoundData(wavData : ByteArray) : Void{
			//if (wavData == null)                 return;
			//sndData = wavData;
			//startPlayingSound();
		//};
		//Scratch.app.server.getAsset(dbObj.md5, gotSoundData);
	}
}

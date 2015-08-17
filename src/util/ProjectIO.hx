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

// ProjectIO.as
// John Maloney, September 2010
//
// Support for project saving/loading, either to the local file system or a server.
// Three types of projects are supported: old Scratch projects (.sb), new Scratch
// projects stored as a JSON project file and a collection of media files packed
// in a single ZIP file, and new Scratch projects stored on a server as a collection
// of separate elements.

package util;

import util.Dictionary;
import util.Event;
import util.IOErrorEvent;
import util.Loader;
import util.SVGElement;
import util.SVGImporter;
import util.Scratch;
import util.ScratchCostume;
import util.ScratchObj;
import util.ScratchSound;
import util.ScratchSprite;
import util.ScratchStage;
import util.ZipIO;

import flash.display.*;
import flash.events.*;
import flash.net.URLLoader;
import flash.utils.*;

import scratch.*;

import sound.WAVFile;
import sound.mp3.MP3Loader;

import svgutils.*;

import translation.Translator;

import uiwidgets.DialogBox;

class ProjectIO {
	
	private var app : Scratch;
	private var images : Array<Dynamic> = [];
	private var sounds : Array<Dynamic> = [];
	
	public function new(app : Scratch)
	{
		this.app = app;
	}
	
	public static function strings() : Array<Dynamic>{
		return [];
	}
	
	//----------------------------
	// Encode a project or sprite as a ByteArray (a 'one-file' project)
	//----------------------------
	
	public function encodeProjectAsZipFile(proj : ScratchStage) : ByteArray{
		// Encode a project into a ByteArray. The format is a ZIP file containing
		// the JSON project data and all images and sounds as files.
		This is an intentional compilation error. See the README for handling the delete keyword
		delete proj.info.penTrails  // remove the penTrails bitmap saved in some old projects' info  ;
		proj.savePenLayer();
		proj.updateInfo();
		recordImagesAndSounds(proj.allObjects(), false, proj);
		var zip : ZipIO = new ZipIO();
		zip.startWrite();
		addJSONData("project.json", proj, zip);
		addImagesAndSounds(zip);
		proj.clearPenLayer();
		return zip.endWrite();
	}
	
	public function encodeSpriteAsZipFile(spr : ScratchSprite) : ByteArray{
		// Encode a sprite into a ByteArray. The format is a ZIP file containing
		// the JSON sprite data and all images and sounds as files.
		recordImagesAndSounds([spr], false);
		var zip : ZipIO = new ZipIO();
		zip.startWrite();
		addJSONData("sprite.json", spr, zip);
		addImagesAndSounds(zip);
		return zip.endWrite();
	}
	
	private function getScratchStage() : ScratchStage{
		return new ScratchStage();
	}
	
	private function addJSONData(fileName : String, obj : Dynamic, zip : ZipIO) : Void{
		var jsonData : ByteArray = new ByteArray();
		jsonData.writeUTFBytes(util.JSON.stringify(obj));
		zip.write(fileName, jsonData, true);
	}
	
	private function addImagesAndSounds(zip : ZipIO) : Void{
		var i : Int;
		var ext : String;
		for (i in 0...images.length){
			var imgData : ByteArray = images[i][1];
			ext = ScratchCostume.fileExtension(imgData);
			zip.write(i + ext, imgData);
		}
		for (i in 0...sounds.length){
			var sndData : ByteArray = sounds[i][1];
			ext = (ScratchSound.isWAV(sndData)) ? ".wav" : ".mp3";
			zip.write(i + ext, sndData);
		}
	}
	
	//----------------------------
	// Decode a project or sprite from a ByteArray containing ZIP data
	//----------------------------
	
	public function decodeProjectFromZipFile(zipData : ByteArray) : ScratchStage{
		return try cast(decodeFromZipFile(zipData), ScratchStage) catch(e:Dynamic) null;
	}
	
	public function decodeSpriteFromZipFile(zipData : ByteArray, whenDone : Function, fail : Function = null) : Void{
		function imagesDecoded() : Void{
			spr.showCostume(spr.currentCostumeIndex);
			whenDone(spr);
		};
		var spr : ScratchSprite = try cast(decodeFromZipFile(zipData), ScratchSprite) catch(e:Dynamic) null;
		if (spr != null) 			decodeAllImages([spr], imagesDecoded, fail)
		else if (fail != null) 			Assert.fail();
	}
	
	private function decodeFromZipFile(zipData : ByteArray) : ScratchObj{
		var jsonData : String;
		images = [];
		sounds = [];
		try{
			var files : Array<Dynamic> = new ZipIO().read(zipData);
		}		catch (e : Dynamic){
			app.log("Bad zip file; attempting to recover");
			try{
				files = new ZipIO().recover(zipData);
			}			catch (e : Dynamic){
				return null;
			}
		}
		for (f/* AS3HX WARNING could not determine type for var: f exp: EIdent(files) type: null */ in files){
			var fName : String = f[0];
			if (fName.indexOf("__MACOSX") > -1) 				continue  // skip MacOS meta info in zip file  ;
			var fIndex : Int = as3hx.Compat.parseInt(integerName(fName));
			var contents : ByteArray = f[1];
			if (fName.substring(-4) == ".gif") 				images[fIndex] = contents;
			if (fName.substring(-4) == ".jpg") 				images[fIndex] = contents;
			if (fName.substring(-4) == ".png") 				images[fIndex] = contents;
			if (fName.substring(-4) == ".svg") 				images[fIndex] = contents;
			if (fName.substring(-4) == ".wav") 				sounds[fIndex] = contents;
			if (fName.substring(-4) == ".mp3") 				sounds[fIndex] = contents;
			if (fName.substring(-5) == ".json") 				jsonData = contents.readUTFBytes(contents.length);
		}
		if (jsonData == null) 			return null;
		var jsonObj : Dynamic = util.JSON.parse(jsonData);
		if (Reflect.field(jsonObj, "children")) {  // project JSON  
			var proj : ScratchStage = getScratchStage();
			proj.readJSON(jsonObj);
			if (proj.penLayerID >= 0) 				proj.penLayerPNG = images[proj.penLayerID]
			else if (proj.penLayerMD5) 				proj.penLayerPNG = images[0];
			installImagesAndSounds(proj.allObjects());
			return proj;
		}
		if (Reflect.field(jsonObj, "direction") != null) {  // sprite JSON  
			var sprite : ScratchSprite = new ScratchSprite();
			sprite.readJSON(jsonObj);
			sprite.instantiateFromJSON(app.stagePane);
			installImagesAndSounds([sprite]);
			return sprite;
		}
		return null;
	}
	
	private function integerName(s : String) : String{
		// Return the substring of digits preceding the last '.' in the given string.
		// For example integerName('123.jpg') -> '123'.
		var digits : String = "1234567890";
		var end : Int = s.lastIndexOf(".");
		if (end < 0) 			end = s.length;
		var start : Int = end - 1;
		if (start < 0) 			return s;
		while ((start >= 0) && (digits.indexOf(s.charAt(start)) >= 0))start--;
		return s.substring(start + 1, end);
	}
	
	private function installImagesAndSounds(objList : Array<Dynamic>) : Void{
		// Install the images and sounds for the given list of ScratchObj objects.
		for (obj in objList){
			for (c/* AS3HX WARNING could not determine type for var: c exp: EField(EIdent(obj),costumes) type: null */ in obj.costumes){
				if (images[c.baseLayerID] != null) 					c.baseLayerData = images[c.baseLayerID];
				if (images[c.textLayerID] != null) 					c.textLayerData = images[c.textLayerID];
			}
			for (snd/* AS3HX WARNING could not determine type for var: snd exp: EField(EIdent(obj),sounds) type: null */ in obj.sounds){
				var sndData : Dynamic = sounds[snd.soundID];
				if (sndData != null) {
					snd.soundData = sndData;
					snd.convertMP3IfNeeded();
				}
			}
		}
	}
	
	public function decodeAllImages(objList : Array<Dynamic>, whenDone : Function, fail : Function = null) : Void{
		// Load all images in all costumes from their image data, then call whenDone.
		function imageDecoded() : Void{
			for (o/* AS3HX WARNING could not determine type for var: o exp: EIdent(imageDict) type: null */ in imageDict){
				if (o == "loading...") 					return  // not yet finished loading  ;
			}
			allImagesLoaded();
		};
		var error : Bool = false;
		function decodeError() : Void{
			if (error) 				return;
			error = true;
			if (fail != null) 				Assert.fail();
		};
		function allImagesLoaded() : Void{
			if (error) 				return;
			for (c/* AS3HX WARNING could not determine type for var: c exp: EIdent(allCostumes) type: null */ in allCostumes){
				if ((c.baseLayerData != null) && (c.baseLayerBitmap == null)) {
					var img : Dynamic = imageDict[c.baseLayerData];
					if (Std.is(img, BitmapData)) 						c.baseLayerBitmap = img;
					if (Std.is(img, SVGElement)) 						c.setSVGRoot(img, false);
				}
				if ((c.textLayerData != null) && (c.textLayerBitmap == null)) 					c.textLayerBitmap = imageDict[c.textLayerData];
			}
			for (c/* AS3HX WARNING could not determine type for var: c exp: EIdent(allCostumes) type: null */ in allCostumes)c.generateOrFindComposite(allCostumes);
			whenDone();
		};
		
		var c : ScratchCostume;
		var allCostumes : Array<Dynamic> = [];
		for (o in objList){
			for (c/* AS3HX WARNING could not determine type for var: c exp: EField(EIdent(o),costumes) type: null */ in o.costumes)allCostumes.push(c);
		}
		var imageDict : Dictionary = new Dictionary();  // maps image data to BitmapData  
		for (c in allCostumes){
			if ((c.baseLayerData != null) && (c.baseLayerBitmap == null)) {
				if (ScratchCostume.isSVGData(c.baseLayerData)) 					decodeSVG(c.baseLayerData, imageDict, imageDecoded)
				else decodeImage(c.baseLayerData, imageDict, imageDecoded, decodeError);
			}
			if ((c.textLayerData != null) && (c.textLayerBitmap == null)) 				decodeImage(c.textLayerData, imageDict, imageDecoded, decodeError);
		}
		imageDecoded();
	}
	
	private function decodeImage(imageData : ByteArray, imageDict : Dictionary, doneFunction : Function, fail : Function) : Void{
		function loadDone(e : Event) : Void{
			Reflect.setField(imageDict, Std.string(imageData), e.target.content.bitmapData);
			doneFunction();
		};
		function loadError(e : Event) : Void{
			if (fail != null) 				Assert.fail();
		};
		if (Reflect.field(imageDict, Std.string(imageData)) != null) 			return  // already loading or loaded  ;
		if (imageData == null || imageData.length == 0) {
			if (fail != null) 				Assert.fail();
			return;
		}
		Reflect.setField(imageDict, Std.string(imageData), "loading...");
		var loader : Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadDone);
		loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadError);
		loader.loadBytes(imageData);
	}
	
	private function decodeSVG(svgData : ByteArray, imageDict : Dictionary, doneFunction : Function) : Void{
		function loadDone(svgRoot : SVGElement) : Void{
			Reflect.setField(imageDict, Std.string(svgData), svgRoot);
			doneFunction();
		};
		if (Reflect.field(imageDict, Std.string(svgData)) != null) 			return  // already loading or loaded  ;
		var importer : SVGImporter = new SVGImporter(cast((svgData), XML));
		if (importer.hasUnloadedImages()) {
			Reflect.setField(imageDict, Std.string(svgData), "loading...");
			importer.loadAllImages(loadDone);
		}
		else {
			Reflect.setField(imageDict, Std.string(svgData), importer.root);
		}
	}
	
	public function downloadProjectAssets(projectData : ByteArray) : Void{
		function assetReceived(md5 : String, data : ByteArray) : Void{
			assetDict[md5] = data;
			assetCount++;
			if (data == null) {
				app.log("missing asset: " + md5);
			}
			if (app.lp) {
				app.lp.setProgress(assetCount / assetsToFetch.length);
				app.lp.setInfo(
						assetCount + " " +
						Translator.map("of") + " " + assetsToFetch.length + " " +
						Translator.map("assets loaded"));
			}
			if (assetCount == assetsToFetch.length) {
				installAssets(proj.allObjects(), assetDict);
				app.runtime.decodeImagesAndInstall(proj);
			}
		};
		projectData.position = 0;
		var projObject : Dynamic = util.JSON.parse(projectData.readUTFBytes(projectData.length));
		var proj : ScratchStage = getScratchStage();
		proj.readJSON(projObject);
		var assetsToFetch : Array<Dynamic> = collectAssetsToFetch(proj.allObjects());
		var assetDict : Dynamic = new Dynamic();
		var assetCount : Int = 0;
		for (md5 in assetsToFetch)fetchAsset(md5, assetReceived);
	}
	
	//----------------------------
	// Fetch a costume or sound from the server
	//----------------------------
	
	public function fetchImage(id : String, costumeName : String, width : Int, whenDone : Function, otherData : Dynamic = null) : URLLoader{
		// Fetch an image asset from the server and call whenDone with the resulting ScratchCostume.
		var c : ScratchCostume;
		function gotCostumeData(data : ByteArray) : Void{
			if (data == null) {
				app.log("Image not found on server: " + id);
				return;
			}
			if (ScratchCostume.isSVGData(data)) {
				if (otherData != null && otherData.centerX) 
					c = new ScratchCostume(costumeName, data, otherData.centerX, otherData.centerY, otherData.bitmapResolution)
				else 
				c = new ScratchCostume(costumeName, data);
				c.baseLayerMD5 = id;
				whenDone(c);
			}
			else {
				var loader : Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, imageError);
				loader.loadBytes(data);
			}
		};
		function imageError(event : IOErrorEvent) : Void{
			app.log("ProjectIO failed to load: " + id);
		};
		function imageLoaded(e : Event) : Void{
			if (otherData != null && otherData.centerX) 
				c = new ScratchCostume(costumeName, e.target.content.bitmapData, otherData.centerX, otherData.centerY, otherData.bitmapResolution)
			else 
			c = new ScratchCostume(costumeName, e.target.content.bitmapData);
			if (width != 0) 				c.bitmapResolution = c.baseLayerBitmap.width / width;
			c.baseLayerMD5 = id;
			whenDone(c);
		};
		return app.server.getAsset(id, gotCostumeData);
	}
	
	public function fetchSound(id : String, sndName : String, whenDone : Function) : Void{
		// Fetch a sound asset from the server and call whenDone with the resulting ScratchSound.
		function gotSoundData(sndData : ByteArray) : Void{
			if (sndData == null) {
				app.log("Sound not found on server: " + id);
				return;
			}
			var snd : ScratchSound;
			try{
				snd = new ScratchSound(sndName, sndData);
			}			catch (e : Dynamic){ };
			if (snd != null && (snd.sampleCount > 0)) {  // WAV data  
				snd.md5 = id;
				whenDone(snd);
			}
			else {  // try to read data as an MP3 file  
				MP3Loader.convertToScratchSound(sndName, sndData, whenDone);
			}
		};
		app.server.getAsset(id, gotSoundData);
	}
	
	//----------------------------
	// Download a sprite from the server
	//----------------------------
	
	public function fetchSprite(md5AndExt : String, whenDone : Function) : Void{
		// Fetch a sprite with the md5 hash.
		function jsonReceived(data : ByteArray) : Void{
			if (data == null) 				return;
			spr.readJSON(util.JSON.parse(data.readUTFBytes(data.length)));
			spr.instantiateFromJSON(app.stagePane);
			fetchSpriteAssets([spr], assetsReceived);
		};
		function assetsReceived(assetDict : Dynamic) : Void{
			installAssets([spr], assetDict);
			decodeAllImages([spr], done);
		};
		function done() : Void{
			spr.showCostume(spr.currentCostumeIndex);
			spr.setDirection(spr.direction);
			whenDone(spr);
		};
		var spr : ScratchSprite = new ScratchSprite();
		app.server.getAsset(md5AndExt, jsonReceived);
	}
	
	private function fetchSpriteAssets(objList : Array<Dynamic>, whenDone : Function) : Void{
		// Download all media for the given list of ScratchObj objects.
		function assetReceived(md5 : String, data : ByteArray) : Void{
			if (data == null) {
				app.log("missing sprite asset: " + md5);
			}
			assetDict[md5] = data;
			assetCount++;
			if (assetCount == assetsToFetch.length) 				whenDone(assetDict);
		};
		var assetDict : Dynamic = new Dynamic();
		var assetCount : Int = 0;
		var assetsToFetch : Array<Dynamic> = collectAssetsToFetch(objList);
		for (md5 in assetsToFetch)fetchAsset(md5, assetReceived);
	}
	
	private function collectAssetsToFetch(objList : Array<Dynamic>) : Array<Dynamic>{
		// Return list of MD5's for all project assets.
		var list : Array<Dynamic> = new Array<Dynamic>();
		for (obj in objList){
			for (c/* AS3HX WARNING could not determine type for var: c exp: EField(EIdent(obj),costumes) type: null */ in obj.costumes){
				if (Lambda.indexOf(list, c.baseLayerMD5) < 0) 					list.push(c.baseLayerMD5);
				if (c.textLayerMD5) {
					if (Lambda.indexOf(list, c.textLayerMD5) < 0) 						list.push(c.textLayerMD5);
				}
			}
			for (snd/* AS3HX WARNING could not determine type for var: snd exp: EField(EIdent(obj),sounds) type: null */ in obj.sounds){
				if (Lambda.indexOf(list, snd.md5) < 0) 					list.push(snd.md5);
			}
		}
		return list;
	}
	
	private function installAssets(objList : Array<Dynamic>, assetDict : Dynamic) : Void{
		var data : ByteArray;
		for (obj in objList){
			for (c/* AS3HX WARNING could not determine type for var: c exp: EField(EIdent(obj),costumes) type: null */ in obj.costumes){
				data = assetDict[c.baseLayerMD5];
				if (data != null) 					c.baseLayerData = data
				else {
					// Asset failed to load so use an empty costume
					// BUT retain the original MD5 and don't break the reference to the costume that failed to load.
					var origMD5 : String = c.baseLayerMD5;
					c.baseLayerData = ScratchCostume.emptySVG();
					c.baseLayerMD5 = origMD5;
				}
				if (c.textLayerMD5) 					c.textLayerData = assetDict[c.textLayerMD5];
			}
			for (snd/* AS3HX WARNING could not determine type for var: snd exp: EField(EIdent(obj),sounds) type: null */ in obj.sounds){
				data = assetDict[snd.md5];
				if (data != null) {
					snd.soundData = data;
					snd.convertMP3IfNeeded();
				}
				else {
					snd.soundData = WAVFile.empty();
				}
			}
		}
	}
	
	public function fetchAsset(md5 : String, whenDone : Function) : URLLoader{
		return app.server.getAsset(md5, function(data : Dynamic) : Void{whenDone(md5, data);
				});
	}
	
	//----------------------------
	// Record unique images and sounds
	//----------------------------
	
	private function recordImagesAndSounds(objList : Array<Dynamic>, uploading : Bool, proj : ScratchStage = null) : Void{
		var recordedAssets : Dynamic = { };
		images = [];
		sounds = [];
		
		app.clearCachedBitmaps();
		if (!uploading && proj != null) 			proj.penLayerID = recordImage(proj.penLayerPNG, proj.penLayerMD5, recordedAssets, uploading);
		
		for (obj in objList){
			for (c/* AS3HX WARNING could not determine type for var: c exp: EField(EIdent(obj),costumes) type: null */ in obj.costumes){
				c.prepareToSave();  // encodes image and computes md5 if necessary  
				c.baseLayerID = recordImage(c.baseLayerData, c.baseLayerMD5, recordedAssets, uploading);
				if (c.textLayerBitmap) {
					c.textLayerID = recordImage(c.textLayerData, c.textLayerMD5, recordedAssets, uploading);
				}
			}
			for (snd/* AS3HX WARNING could not determine type for var: snd exp: EField(EIdent(obj),sounds) type: null */ in obj.sounds){
				snd.prepareToSave();  // compute md5 if necessary  
				snd.soundID = recordSound(snd, snd.md5, recordedAssets, uploading);
			}
		}
	}
	
	public function convertSqueakSounds(scratchObj : ScratchObj, done : Function) : Void{
		// Pre-convert any Squeak sounds (asynch, with a progress bar) before saving a project.
		// Note: If this is not called before recordImagesAndSounds(), sounds will
		// be converted synchronously, but there may be a long delay without any feedback.
		function convertASound() : Void{
			if (i < soundsToConvert.length) {
				var sndToConvert : ScratchSound = try cast(soundsToConvert[i++], ScratchSound) catch(e:Dynamic) null;
				sndToConvert.prepareToSave();
				app.lp.setProgress(i / soundsToConvert.length);
				app.lp.setInfo(sndToConvert.soundName);
				setTimeout(convertASound, 50);
			}
			else {
				app.removeLoadProgressBox();
				// Note: Must get user click in order to proceed with saving...
				DialogBox.notify("", "Sounds converted", app.stage, false, soundsConverted);
			}
		};
		function soundsConverted(ignore : Dynamic) : Void{done();
		};
		var soundsToConvert : Array<Dynamic> = [];
		for (obj/* AS3HX WARNING could not determine type for var: obj exp: ECall(EField(EIdent(scratchObj),allObjects),[]) type: null */ in scratchObj.allObjects()){
			for (snd/* AS3HX WARNING could not determine type for var: snd exp: EField(EIdent(obj),sounds) type: null */ in obj.sounds){
				if ("squeak" == snd.format) 					soundsToConvert.push(snd);
			}
		}
		var i : Int;
		if (soundsToConvert.length > 0) {
			app.addLoadProgressBox("Converting sounds...");
			setTimeout(convertASound, 50);
		}
		else done();
	}
	
	private function recordImage(img : Dynamic, md5 : String, recordedAssets : Dynamic, uploading : Bool) : Int{
		var id : Int = recordedAssetID(md5, recordedAssets, uploading);
		if (id > -2) 			return id  // image was already added  ;
		images.push([md5, img]);
		id = images.length - 1;
		Reflect.setField(recordedAssets, md5, id);
		return id;
	}
	
	private function recordedAssetID(md5 : String, recordedAssets : Dynamic, uploading : Bool) : Int{
		var id : Dynamic = Reflect.field(recordedAssets, md5);
		return id != (null) ? id : -2;
	}
	
	private function recordSound(snd : ScratchSound, md5 : String, recordedAssets : Dynamic, uploading : Bool) : Int{
		var id : Int = recordedAssetID(md5, recordedAssets, uploading);
		if (id > -2) 			return id  // image was already added  ;
		sounds.push([md5, snd.soundData]);
		id = sounds.length - 1;
		Reflect.setField(recordedAssets, md5, id);
		return id;
	}
}

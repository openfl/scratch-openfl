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

package ui.media;
import flash.display.*;
import flash.events.*;
import flash.media.Sound;
import flash.net.*;
import flash.text.*;
import flash.utils.*;
import assets.Resources;
import extensions.ScratchExtension;
import scratch.*;
import sound.mp3.MP3Loader;
import translation.Translator;
import uiwidgets.*;
import util.*;

class MediaLibrary extends Sprite {

	private inline static var titleFormat:TextFormat = new TextFormat(CSS.font, 24, 0x444143);

	private static inline var backdropCategories:Array<String> = [
		'All', 'Indoors', 'Outdoors', 'Other'];
	private static inline var costumeCategories:Array<String> = [
		'All', 'Animals', 'Fantasy', 'Letters', 'People', 'Things', 'Transportation'];
	private static inline var extensionCategories:Array<String> = [
		'All', 'Hardware'];
	private static inline var soundCategories:Array<String> = [
		'All', 'Animal', 'Effects', 'Electronic', 'Human', 'Instruments',
		'Music Loops', 'Percussion', 'Vocals'];

	private static inline var backdropThemes:Array<String> = [
		'Castle', 'City', 'Flying', 'Holiday', 'Music and Dance', 'Nature', 'Space', 'Sports', 'Underwater'];
	private static inline var costumeThemes:Array<String> = [
		'Castle', 'City', 'Flying', 'Holiday', 'Music and Dance', 'Space', 'Sports', 'Underwater', 'Walking'];

	private static inline var imageTypes:Array<String> = ['All', 'Bitmap', 'Vector'];

	private static inline var spriteFeatures:Array<String> = ['All', 'Scripts', 'Costumes > 1', 'Sounds'];

	private var app:Scratch;
	private var assetType:String;
	private var whenDone:Function;
	private var allItems:Array<Dynamic> = [];

	private var title:TextField;
	private var outerFrame:Shape;
	private var innerFrame:Shape;
	private var resultsFrame:ScrollFrame;
	private var resultsPane:ScrollFrameContents;

	private var categoryFilter:MediaFilter;
	private var themeFilter:MediaFilter;
	private var imageTypeFilter:MediaFilter;
	private var spriteFeaturesFilter:MediaFilter;

	private var closeButton:IconButton;
	private var okayButton:Button;
	private var cancelButton:Button;

	private static var libraryCache:Dynamic = {}; // cache of all mediaLibrary entries

	public function new(app:Scratch, type:String, whenDone:Function) {
		this.app = app;
		this.assetType = type;
		this.whenDone = whenDone;

		addChild(outerFrame = new Shape());
		addChild(innerFrame = new Shape());
		addTitle();
		addFilters();
		addResultsFrame();
		addButtons();
	}

	public static function strings():Array<String> {
		var result:Array<String> = [
			'Backdrop Library', 'Costume Library', 'Sprite Library', 'Sound Library',
			'Category', 'Theme', 'Type', 'Features',
			'Uploading image...', 'Uploading sprite...', 'Uploading sound...',
			'Importing sound...', 'Converting mp3...',
		];
		result = result.concat(backdropCategories);
		result = result.concat(costumeCategories);
		result = result.concat(extensionCategories);
		result = result.concat(soundCategories);

		result = result.concat(backdropThemes);
		result = result.concat(costumeThemes);

		result = result.concat(imageTypes);
		result = result.concat(spriteFeatures);

		return result;
	}

	public function open():Void {
		app.closeTips();
		app.mediaLibrary = this;
		setWidthHeight(app.stage.stageWidth, app.stage.stageHeight);
		app.addChild(this);
		viewLibrary();
	}

	public function importFromDisk():Void {
		if (parent) close();
		if (assetType == 'sound') importSoundsFromDisk();
		else importImagesOrSpritesFromDisk();
	}

	public function close(ignore:Dynamic = null):Void {
		stopLoadingThumbnails();
		parent.removeChild(this);
		app.mediaLibrary = null;
		app.reopenTips();
	}

	public function setWidthHeight(w:Int, h:Int):Void {
		var inset:Int = 30; // inset around entire dialog
		var rightInset:Int = 15;

		title.x = inset + 20;
		title.y = inset + 15;

		closeButton.x = w - (inset + closeButton.width + 10);
		closeButton.y = inset + 10;

		cancelButton.x = w - (inset + cancelButton.width + rightInset);
		cancelButton.y = h - (inset + cancelButton.height + 10);
		okayButton.x = cancelButton.x - (okayButton.width + 10);
		okayButton.y = cancelButton.y;

		drawBackground(w, h);

		outerFrame.x = inset;
		outerFrame.y = inset;
		drawOuterFrame(w - (2 * inset), h - (2 * inset));

		innerFrame.x = title.x + title.textWidth + 25;
		innerFrame.y = inset + 35;
		drawInnerFrame(w - (innerFrame.x + inset + rightInset), h - (innerFrame.y + inset + cancelButton.height + 20));

		resultsFrame.x = innerFrame.x + 5;
		resultsFrame.y = innerFrame.y + 5;
		resultsFrame.setWidthHeight(innerFrame.width - 10, innerFrame.height - 10);

		var nextX:Int = title.x + 3;
		var nextY:Int = inset + 60;
		var spaceBetweenFilteres:Int = 12;

		categoryFilter.x = nextX;
		categoryFilter.y = nextY;
		nextY += categoryFilter.height + spaceBetweenFilteres;

		if (themeFilter.visible) {
			themeFilter.x = nextX;
			themeFilter.y = nextY;
			nextY += themeFilter.height + spaceBetweenFilteres;
		}

		if (imageTypeFilter.visible) {
			imageTypeFilter.x = nextX;
			imageTypeFilter.y = nextY;
			nextY += imageTypeFilter.height + spaceBetweenFilteres;
		}

		if (spriteFeaturesFilter.visible) {
			spriteFeaturesFilter.x = nextX;
			spriteFeaturesFilter.y = nextY;
		}

	}

	private function drawBackground(w:Int, h:Int):Void {
		var bgColor:Int = 0;
		var bgAlpha:Number = 0.6;
		var g:Graphics = this.graphics;
		g.clear();
		g.beginFill(bgColor, bgAlpha);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}

	private function drawOuterFrame(w:Int, h:Int):Void {
		var g:Graphics = outerFrame.graphics;
		g.clear();
		g.beginFill(CSS.tabColor);
		g.drawRoundRect(0, 0, w, h, 12, 12);
		g.endFill();
	}

	private function drawInnerFrame(w:Int, h:Int):Void {
		var g:Graphics = innerFrame.graphics;
		g.clear();
		g.beginFill(CSS.white, 1);
		g.drawRoundRect(0, 0, w, h, 8, 8);
		g.endFill();
	}

	private function addTitle():Void {
		var s:String = assetType;
		if ('backdrop' == s) s = 'Backdrop Library';
		if ('costume' == s) s = 'Costume Library';
		if ('extension' == s) s = 'Extension Library';
		if ('sprite' == s) s = 'Sprite Library';
		if ('sound' == s) s = 'Sound Library';
		addChild(title = Resources.makeLabel(Translator.map(s), titleFormat));
	}

	private function addFilters():Void {
		var categories:Array = [];
		if ('backdrop' == assetType) categories = backdropCategories;
		if ('costume' == assetType) categories = costumeCategories;
		if ('extension' == assetType) categories = extensionCategories;
		if ('sprite' == assetType) categories = costumeCategories;
		if ('sound' == assetType) categories = soundCategories;
		categoryFilter = new MediaFilter('Category', categories, filterChanged);
		addChild(categoryFilter);

		themeFilter = new MediaFilter(
			'Theme',
			('backdrop' == assetType) ? backdropThemes : costumeThemes,
			filterChanged);
		themeFilter.currentSelection = '';
		addChild(themeFilter);

		imageTypeFilter = new MediaFilter('Type', imageTypes, filterChanged);
		addChild(imageTypeFilter);

		spriteFeaturesFilter = new MediaFilter('Features', spriteFeatures, filterChanged);
		addChild(spriteFeaturesFilter);

		themeFilter.visible = (['sprite', 'costume', 'backdrop'].indexOf(assetType) > -1);
		imageTypeFilter.visible = (['sprite', 'costume'].indexOf(assetType) > -1);
		spriteFeaturesFilter.visible = ('sprite' == assetType);
spriteFeaturesFilter.visible = false; // disable features filter for now
	}

	private function filterChanged(filter:MediaFilter):Void {
		if (filter == categoryFilter) themeFilter.currentSelection = '';
		if (filter == themeFilter) categoryFilter.currentSelection = '';
		showFilteredItems();

		// scroll to top when filters change
		resultsPane.y = 0;
		resultsFrame.updateScrollbars();
	}

	private function addResultsFrame():Void {
		resultsPane = new ScrollFrameContents();
		resultsPane.color = CSS.white;
		resultsPane.hExtra = 0;
		resultsPane.vExtra = 5;
		resultsFrame = new ScrollFrame();
		resultsFrame.setContents(resultsPane);
		addChild(resultsFrame);
	}

	private function addButtons():Void {
		addChild(closeButton = new IconButton(close, 'close'));
		addChild(okayButton = new Button(Translator.map('OK'), addSelected));
		addChild(cancelButton = new Button(Translator.map('Cancel'), close));
	}

	// -----------------------------
	// Library Contents
	//------------------------------

	private function viewLibrary():Void {
		function gotLibraryData(data:ByteArray):Void {
			if (!data) return; // failure
			var s:String = data.readUTFBytes(data.length);
			libraryCache[assetType] = cast (util.JSON.parse(stripComments(s)), Array);
			collectEntries();
		}
		function collectEntries():Void {
			allItems = [];
			for (entry in libraryCache[assetType]) {
				if (entry.type == assetType) {
					if (Std.is (entry.tags, Array)) entry.category = entry.tags[0];
					var info:Array = cast (entry.info, Array);
					if (info != null) {
						if (entry.type == 'backdrop') {
							entry.width = info[0];
							entry.height = info[1];
						}
						if (entry.type == 'sound') {
							entry.seconds = info[0];
						}
						if (entry.type == 'sprite') {
							entry.scriptCount = info[0];
							entry.costumeCount = info[1];
							entry.soundCount = info[2];
						}
					}
					allItems.push(new MediaLibraryItem(entry));
				}
			}
			showFilteredItems();
			startLoadingThumbnails();
		}
		if ('extension' == assetType) {
			addScratchExtensions();
			return;
		}
		if (!libraryCache[assetType]) app.server.getMediaLibrary(assetType, gotLibraryData);
		else collectEntries();
	}


	private function addScratchExtensions():Void {
		var extList:Array = [
			ScratchExtension.PicoBoard(),
			ScratchExtension.WeDo()];
		allItems = [];
		for (ext in extList) {
			allItems.push(new MediaLibraryItem({
				extension: ext,
				name: ext.name,
				md5: ext.thumbnailMD5,
				tags: ext.tags
			}));
		}
		showFilteredItems();
		startLoadingThumbnails();
	}

	private function stripComments(s:String):String {
		// Remove full-line comments starting with '//'. The comment delimiter must be at the very start of the line.
		var result:String = '';
		for (line in s.split('\n')) {
			var isComment:Bool = false;
			if ((line.length > 0) && (line.charAt(0) == '<')) isComment = true; // Full-line comments starting with '<!--' (added by Gaia).
			if ((line.length > 1) && (line.charAt(0) == '/') && (line.charAt(1) == '/')) isComment = true;
			if (!isComment) result += line + '\n';
		}
		return result;
	}

	private function showFilteredItems():Void {
		var tag:String = '';
		if (categoryFilter.currentSelection != '') tag = categoryFilter.currentSelection;
		if (themeFilter.currentSelection != '') tag = themeFilter.currentSelection;
		tag = tag.replace(new RegExp(' ', 'g'), '-'); // e.g., change 'Music and Dance' -> 'Music-and-Dance'
		tag = tag.toLowerCase();
		var showAll:Bool = ('all' == tag);
		var filtered:Array = [];
		for (item in allItems) {
			if ((showAll || (item.dbObj.tags.indexOf(tag) > -1)) && hasSelectedFeatures(item.dbObj)) {
				filtered.push(item);
			}
		}
		while (resultsPane.numChildren > 0) resultsPane.removeChildAt(0);
		appendItems(filtered);
	}

	private function hasSelectedFeatures(item:Dynamic):Bool {
		var imageType:String = imageTypeFilter.currentSelection;
		if (imageTypeFilter.visible && (imageType != 'All')) {
			if (imageType == 'Vector') {
				if (item.tags.indexOf('vector') == -1) return false;
			} else {
				if (item.tags.indexOf('vector') != -1) return false;
			}
		}
		var spriteFeatures:String = spriteFeaturesFilter.currentSelection;
		if (spriteFeaturesFilter.visible && (spriteFeatures != 'All')) {
			if (('Scripts' == spriteFeatures) && (item.scriptCount == 0)) return false;
			if (('Costumes > 1' == spriteFeatures) && (item.costumeCount <= 1)) return false;
			if (('Sounds' == spriteFeatures) && (item.soundCount == 0)) return false;
		}
		return true;
	}

	private function appendItems(items:Array<Dynamic>):Void {
		if (items.length == 0) return;
		var itemWidth:Int = cast (items[0], MediaLibraryItem).frameWidth + 6;
		var totalWidth:Int = resultsFrame.width - 15;
		var columnCount:Int = totalWidth / itemWidth;
		var extra:Int = (totalWidth - (columnCount * itemWidth)) / columnCount; // extra space per column

		var colNum:Int = 0;
		var nextX:Int = 2;
		var nextY:Int = 2;
		for (item in items) {
			item.x = nextX;
			item.y = nextY;
			resultsPane.addChild(item);
			nextX += item.frameWidth + 6 + extra;
			if (++colNum == columnCount) {
				colNum = 0;
				nextX = 2;
				nextY += item.frameHeight + 5;
			}
		}
		if (nextX > 5) nextY += item.frameHeight + 2; // if there's anything on this line, start a new one
		resultsPane.updateSize();
	}

	public function addSelected():Void {
		// Close dialog and call whenDone() with an array of selected media items.
		var io:ProjectIO = new ProjectIO(app);
		close();
		for (i in 0...resultsPane.numChildren) {
			var item:MediaLibraryItem = cast (resultsPane.getChildAt(i), MediaLibraryItem);
			if (item != null && item.isHighlighted()) {
				var md5AndExt:String = item.dbObj.md5;
				var obj:Dynamic = null;
				if (assetType == 'extension') {
					whenDone(item.dbObj.extension);
				} else if (md5AndExt.slice(-5) == '.json') {
					io.fetchSprite(md5AndExt, whenDone);
				} else if (assetType == 'sound') {
					io.fetchSound(md5AndExt, item.dbObj.name, whenDone);
				} else if (assetType == 'costume') {
					obj = {
						centerX: item.dbObj.info[0],
						centerY: item.dbObj.info[1],
						bitmapResolution: 1
					};
					if (item.dbObj.info.length == 3)
						obj.bitmapResolution = item.dbObj.info[2];

					io.fetchImage(md5AndExt, item.dbObj.name, 0, whenDone, obj);
				} else { // assetType == backdrop
					if (item.dbObj.info.length == 3) {
						obj = {centerX: 99999, centerY: 99999, bitmapResolution: item.dbObj.info[2]};
					} else if (item.dbObj.info.length == 2 && item.dbObj.info[0] == 960 && item.dbObj.info[1] == 720) {
						obj = {centerX: 99999, centerY: 99999, bitmapResolution: 2};
					}
					io.fetchImage(md5AndExt, item.dbObj.name, 0, whenDone, obj);
				}
			}
		}
	}

	// -----------------------------
	// Thumbnail loading
	//------------------------------

	private function startLoadingThumbnails():Void {
		function loadSomeThumbnails():Void {
			var count:Int = 10 - inProgress;
			while ((next < allItems.length) && (count-- > 0)) {
				inProgress++;
				allItems[next++].loadThumbnail(loadDone);
			}
			if ((next < allItems.length) || inProgress) setTimeout(loadSomeThumbnails, 40);
		}
		function loadDone():Void { inProgress--; }

		var next:Int = 0;
		var inProgress:Int = 0;
		loadSomeThumbnails();
	}

	private function stopLoadingThumbnails():Void {
		for (i in 0...resultsPane.numChildren) {
			var item:MediaLibraryItem = cast (resultsPane.getChildAt(i), MediaLibraryItem);
			if (item != null) item.stopLoading();
		}
	}

	// -----------------------------
	// Import from disk
	//------------------------------

	private function importImagesOrSpritesFromDisk():Void {
		function fileSelected(e:Event):Void {
			for (j in 0...files.fileList.length) {
				var file:FileReference = FileReference(files.fileList[j]);
				file.addEventListener(Event.COMPLETE, fileLoaded);
				file.load();
			}
		}
		function fileLoaded(e:Event):Void {
			var fRef:FileReference = cast (e.target, FileReference);
			if (fRef != null) convertAndUploadImageOrSprite(fRef.name, fRef.data);
		}
		var costumeOrSprite:Dynamic;
		var files:FileReferenceList = new FileReferenceList();
		files.addEventListener(Event.SELECT, fileSelected);
		try {
			// Ignore the exception that happens when you call browse() with the file browser open
			files.browse();
		} catch(e:Dynamic) {}
	}

	private function uploadCostume(costume:ScratchCostume, whenDone:Function):Void {
		whenDone();
	}

	private function uploadSprite(sprite:ScratchSprite, whenDone:Function):Void {
		whenDone();
	}

	private function convertAndUploadImageOrSprite(fName:String, data:ByteArray):Void {
		function imageDecoded(e:Event):Void {
			var bm:BitmapData = ScratchCostume.scaleForScratch(e.target.content.bitmapData);
			costumeOrSprite = new ScratchCostume(fName, bm);
			uploadCostume(costumeOrSprite, uploadComplete);
		}
		function spriteDecoded(s:ScratchSprite):Void {
			costumeOrSprite = s;
			uploadSprite(s, uploadComplete);
		}
		function imagesDecoded():Void {
			sprite.updateScriptsAfterTranslation();
			spriteDecoded(sprite);
		}
		function uploadComplete():Void {
			app.removeLoadProgressBox();
			whenDone(costumeOrSprite);
		}
		function decodeError():Void {
			DialogBox.notify('Error decoding image', 'Sorry, Scratch was unable to load the image '+fName+'.', Scratch.app.stage);
		}
		function spriteError():Void {
			DialogBox.notify('Error decoding sprite', 'Sorry, Scratch was unable to load the sprite '+fName+'.', Scratch.app.stage);
		}
		var costumeOrSprite:Dynamic;
		var fExt:String = '';
		var i:Int = fName.lastIndexOf('.');
		if (i > 0) {
			fExt = fName.slice(i).toLowerCase();
			fName = fName.slice(0, i);
		}

		if ((fExt == '.png') || (fExt == '.jpg') || (fExt == '.jpeg')) {
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageDecoded);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):Void { decodeError(); });
			try {
				loader.loadBytes(data);
			} catch(e:Dynamic) {
				decodeError();
			}
		} else if (fExt == '.gif') {
			try {
				importGIF(fName, data);
			} catch(e:Dynamic) {
				decodeError();
			}
		} else if (ScratchCostume.isSVGData(data)) {
			data = svgAddGroupIfNeeded(data); // wrap group around imported elements
			costumeOrSprite = new ScratchCostume(fName, null);
			costumeOrSprite.setSVGData(data, true);
			uploadCostume(cast (costumeOrSprite, ScratchCostume), uploadComplete);
		} else {
			data.position = 0;
			if (data.readUTFBytes(4) != 'ObjS') {
				data.position = 0;
				new ProjectIO(app).decodeSpriteFromZipFile(data, spriteDecoded, spriteError);
			} else {
				var info:Dynamic;
				var objTable:Array = null;
				data.position = 0;
				var reader:ObjReader = new ObjReader(data);
				try { info = reader.readInfo(); } catch (e:Error) { data.position = 0; }
				try { objTable = reader.readObjTable(); } catch (e:Error) { }
				if (objTable == null) {
					spriteError();
					return;
				}
				var newProject:ScratchStage = new OldProjectReader().extractProject(objTable);
				var sprite:ScratchSprite = newProject.numChildren > 3 ? cast (newProject.getChildAt(3), ScratchSprite) : null;
				if (sprite == null) {
					spriteError();
					return;
				}
				new ProjectIO(app).decodeAllImages(newProject.allObjects(), imagesDecoded, spriteError);
			}
		}
	}

	private function importGIF(fName:String, data:ByteArray):Void {
		var gifReader:GIFDecoder = new GIFDecoder();
		gifReader.read(data);
		if (gifReader.frames.length == 0) return; // bad GIF (error; no images)
		var newCostumes:Array = [];
		for (i in 0...gifReader.frames.length) {
			newCostumes.push(new ScratchCostume(fName + '-' + i, gifReader.frames[i]));
		}

		gifImported(newCostumes);
	}

	private function gifImported(newCostumes:Array<Dynamic>):Void {
		whenDone(newCostumes);
	}

	private function svgAddGroupIfNeeded(svgData:ByteArray):ByteArray {
		var xml:XML = XML(svgData);
		if (!svgNeedsGroup(xml)) return svgData;

		var groupNode:XML = new XML('<g></g>');
		for (el in xml.elements()) {
			if (el.localName() != 'defs') {
				//delete xml.children()[el.childIndex()];
				groupNode.appendChild(el); // move all non-def elements into group
			}
		}
		xml.appendChild(groupNode);

		// fix for an apparent bug in Flash XML parser (changes 'xml' namespace to 'aaa')
		for (k in xml.attributes()) {
			//if (k.localName() == 'space') delete xml.@[k.name()];
		}
		//xml.@['xml:space'] = 'preserve';

		var newSVG:XML = xml;
		var data: ByteArray = new ByteArray();
		data.writeUTFBytes(newSVG.toXMLString());
		return data;
	}

	private function svgNeedsGroup(xml:XML):Bool {
		// Return true if the given SVG contains more than one non-defs element.
		var nonDefsCount:Int;
		for (el in xml.elements()) {
			if (el.localName() != 'defs') nonDefsCount++;
		}
		return nonDefsCount > 1;
	}

	private function importSoundsFromDisk():Void {
		function fileSelected(e:Event):Void {
			for (j in 0...files.fileList.length) {
				var file:FileReference = FileReference(files.fileList[j]);
				file.addEventListener(Event.COMPLETE, fileLoaded);
				file.load();
			}
		}
		function fileLoaded(e:Event):Void {
			convertAndUploadSound(FileReference(e.target).name, FileReference(e.target).data);
		}
		var files:FileReferenceList = new FileReferenceList();
		files.addEventListener(Event.SELECT, fileSelected);
		try {
			// Ignore the exception that happens when you call browse() with the file browser open
			files.browse();
		} catch(e:Dynamic) {}
	}

	private function startSoundUpload(sndToUpload:ScratchSound, origName:String, whenDone:Function):Void {
		if(!sndToUpload) {
			DialogBox.notify(
					'Sorry!',
					'The sound file '+origName+' is not recognized by Scratch.  Please use MP3 or WAV sound files.',
					stage);
			return;
		}
		whenDone();
	}

	private function convertAndUploadSound(sndName:String, data:ByteArray):Void {
		function uploadComplete():Void {
			app.removeLoadProgressBox();
			whenDone(snd);
		}
		var snd:ScratchSound;
		var origName:String = sndName;
		var i:Int = sndName.lastIndexOf('.');
		if (i > 0) sndName = sndName.slice(0, i); // remove extension

		app.addLoadProgressBox('Importing sound...');
		try {
			snd = new ScratchSound(sndName, data); // try reading the data as a WAV file
		} catch (e:Error) { }

		if (snd && snd.sampleCount > 0) { // WAV data
			startSoundUpload(snd, origName, uploadComplete);
		} else { // try to read data as an MP3 file
			if (app.lp) app.lp.setTitle('Converting mp3 file...');
			var sound:Sound;
			#if allow3d
				sound = new Sound();
				try {
					data.position = 0;
					sound.loadCompressedDataFromByteArray(data, data.length);
					MP3Loader.extractSamples(origName, sound, sound.length * 44.1, function (out:ScratchSound):Void {
						snd = out;
						startSoundUpload(out, origName, uploadComplete);
					});
				}
				catch(e:Error) {
					trace(e);
					uploadComplete();
				}
			#end

			if (!sound)
				setTimeout(function():Void {
					MP3Loader.convertToScratchSound(sndName, data, function(s:ScratchSound):Void {
						snd = s;
						startSoundUpload(s, origName, uploadComplete);
					});
				}, 1);
		}
	}

}

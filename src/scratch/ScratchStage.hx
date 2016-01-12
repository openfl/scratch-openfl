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

// ScratchStage.as
// John Maloney, April 2010
//
// A Scratch stage object. Supports a drawing surface for the pen commands.

package scratch;
import blocks.BlockArg;

import flash.display.*;
import flash.geom.*;
import flash.media.*;
import flash.events.*;
import flash.system.Capabilities;
import flash.utils.ByteArray;
import flash.net.FileReference;
import blocks.Block;
import filters.FilterPack;
import translation.Translator;
import uiwidgets.Menu;
import ui.media.MediaInfo;
import util.*;
import watchers.*;
//import by.blooddy.crypto.image.PNG24Encoder;
//import by.blooddy.crypto.image.PNGFilter;
//import by.blooddy.crypto.MD5;

class ScratchStage extends ScratchObj {

	public var info:Dynamic = {};
	public var tempoBPM:Float = 60;

	public var penActivity:Bool;
	public var newPenStrokes:Shape;
	public var penLayer:Bitmap;

	public var penLayerPNG:ByteArray;
	public var penLayerID:Int = -1;
	public var penLayerMD5:String;

	private var bg:Shape;

	// camera support
	public var videoImage:Bitmap;
	static private var camera:Camera;
	private var video:Video;
	private var videoAlpha:Float = 0.5;
	private var flipVideo:Bool = true;

	public function ScratchStage() {
		objName = 'Stage';
		isStage = true;
		scrollRect = new Rectangle(0, 0, ScratchObj.STAGEW, ScratchObj.STAGEH); // clip drawing to my bounds
		cacheAsBitmap = true; // clip damage reports to my bounds
		filterPack = new FilterPack(this);

		addWhiteBG();
		img = new Sprite();
		img.addChild(new Bitmap(new BitmapData(1, 1)));
		img.cacheAsBitmap = true;
		addChild(img);
		addPenLayer();
		initMedia();
		showCostume(0);
	}

	public function setTempo(bpm:Float):Void {
		tempoBPM = Math.max(20, Math.min(bpm, 500));
	}

	public function objNamed(s:String):ScratchObj {
		// Return the object with the given name, or null if not found.
		if (('_stage_' == s) || (objName == s)) return this;
		return spriteNamed(s);
	}

	public function spriteNamed(spriteName:String):ScratchSprite {
		// Return the sprite (but not a clone) with the given name, or null if not found.
		for (spr in sprites()) {
			if ((spr.objName == spriteName) && !spr.isClone) return spr;
		}
		var app:Scratch = Scratch.app;
		if ((app != null) && Std.is(app.gh.carriedObj, ScratchSprite)) {
			var spr:ScratchSprite = cast(app.gh.carriedObj, ScratchSprite);
			if ((spr.objName == spriteName) && !spr.isClone) return spr;
		}
		return null;
	}

	public function spritesAndClonesNamed(spriteName:String):Array<Dynamic> {
		// Return all sprites and clones with the given name.
		var result:Array<Dynamic> = [];
		for (i in 0...numChildren) {
			var c:Dynamic = getChildAt(i);
			if (Std.is(c, ScratchSprite) && (c.objName == spriteName)) result.push(c);
		}
		var app:Scratch = cast(parent, Scratch);
		if (app != null) {
			var spr:ScratchSprite = cast(app.gh.carriedObj, ScratchSprite);
			if (spr != null && (spr.objName == spriteName)) result.push(spr);
		}
		return result;
	}

	public function unusedSpriteName(baseName:String):String {
		var existingNames:Array<String> = ['_mouse_', '_stage_', '_edge_', '_myself_'];
		for (s in sprites()) {
			existingNames.push(s.objName.toLowerCase());
		}
		var lcBaseName:String = baseName.toLowerCase();
		if (existingNames.indexOf(lcBaseName) < 0) return baseName; // basename is not already used
		lcBaseName = withoutTrailingDigits(lcBaseName);
		var i:Int = 2;
		while (existingNames.indexOf(lcBaseName + i) >= 0) { i++; } // find an unused name
		return withoutTrailingDigits(baseName) + i;
	}

	override public function hasName(varName:String):Bool {
		// Return true if this object owns a variable of the given name.
		for (s in sprites()) {
			if (s.ownsVar(varName) || s.ownsList(varName)) return true;
		}
		return ownsVar(varName) || ownsList(varName);
	}

	private function initMedia():Void {
		costumes.push(ScratchCostume.emptyBitmapCostume(Translator.map('backdrop1'), true));
		sounds.push(new ScratchSound(Translator.map('pop'), new Pop()));
		sounds[0].prepareToSave();
	}

	private function addWhiteBG():Void {
		bg = new Shape();
		bg.graphics.beginFill(0xFFFFFF);
		bg.graphics.drawRect(0, 0, ScratchObj.STAGEW, ScratchObj.STAGEH);
		addChild(bg);
	}

	private function addPenLayer():Void {
		newPenStrokes = new Shape();
		var bm:BitmapData = new BitmapData(ScratchObj.STAGEW, ScratchObj.STAGEH, true, 0);
		penLayer = new Bitmap(bm);
		addChild(penLayer);
	}

	public function baseW():Float { return bg.width; }
	public function baseH():Float { return bg.height; }

	public function scratchMouseX():Int { return Std.int(Math.max( -240, Math.min(mouseX - (ScratchObj.STAGEW / 2), 240))); }
	public function scratchMouseY():Int { return Std.int(-Math.max( -180, Math.min(mouseY - (ScratchObj.STAGEH / 2), 180))); }

	public override function allObjects():Array<ScratchObj> {
		// Return an array of all sprites in this project plus the stage.
		var result:Array<ScratchObj> = [];
		for (spr in sprites())
			result.push(spr);
		result.push(this);
		return result;
	}

	public function sprites():Array<ScratchSprite> {
		// Return an array of all sprites in this project.
		var result:Array<ScratchSprite> = [];
		for (i in 0...numChildren) {
			var o:Dynamic = getChildAt(i);
			if (Std.is(o, ScratchSprite) && !o.isClone) result.push(cast(o,ScratchSprite));
		}
		return result;
	}

	public function deleteClones():Void {
		var clones:Array<Dynamic> = [];
		for (i in 0...numChildren) {
			var o:Dynamic = getChildAt(i);
			if (Std.is(o, ScratchSprite) && o.isClone) {
				if (o.bubble && o.bubble.parent) o.bubble.parent.removeChild(o.bubble);
				clones.push(o);
			}
		}
		for (c in clones) removeChild(c);
	}

	public function watchers():Array<Dynamic> {
		// Return an array of all variable and lists on the stage, visible or not.
		var result:Array<Dynamic> = [];
		var uiLayer:Sprite = getUILayer();
		for (i in 0...uiLayer.numChildren) {
			var o:Dynamic = uiLayer.getChildAt(i);
			if (Std.is(o, Watcher) || Std.is(o, ListWatcher)) result.push(o);
		}
		return result;
	}

	public function removeObsoleteWatchers():Void {
		// Called after deleting a sprite.
		var toDelete:Array<Dynamic> = [];
		var uiLayer:Sprite = getUILayer();
		for (i in 0...uiLayer.numChildren) {
			var w:Watcher = cast(uiLayer.getChildAt(i), Watcher);
			if (w != null && !w.target.isStage && (w.target.parent != this)) toDelete.push(w);

			var lw:ListWatcher = cast(uiLayer.getChildAt(i), ListWatcher);
			if (lw != null && !lw.target.isStage && (lw.target.parent != this)) toDelete.push(lw);
		}
		for (c in toDelete) uiLayer.removeChild(c);
	}

	/* Menu */

	public function menu(evt:MouseEvent):Menu {
		var m:Menu = new Menu();
		m.addItem('save picture of stage', saveScreenshot);
		return m;
	}

	private function saveScreenshot():Void {
		var bitmapData:BitmapData = new BitmapData(ScratchObj.STAGEW, ScratchObj.STAGEH, true, 0);
		bitmapData.draw(this);
		//var pngData:ByteArray = PNG24Encoder.encode(bitmapData, PNGFilter.PAETH);
		//var file:FileReference = new FileReference();
		//file.save(pngData, 'stage.png');
	}

	/* Scrolling support */

	public var xScroll:Float = 0;
	public var yScroll:Float = 0;

	public function scrollAlign(s:String):Void {
		var c:DisplayObject = currentCostume().displayObj();
		var sceneW:Int = Std.int(Math.max(c.width, ScratchObj.STAGEW));
		var sceneH:Int = Std.int(Math.max(c.height, ScratchObj.STAGEH));
		switch (s) {
		case 'top-left':
			xScroll = 0;
			yScroll = sceneH - ScratchObj.STAGEH;
			//break;
		case 'top-right':
			xScroll = sceneW - ScratchObj.STAGEW;
			yScroll = sceneH - ScratchObj.STAGEH;
			//break;
		case 'middle':
			xScroll = Math.floor((sceneW - ScratchObj.STAGEW) / 2);
			yScroll = Math.floor((sceneH - ScratchObj.STAGEH) / 2);
			//break;
		case 'bottom-left':
			xScroll = 0;
			yScroll = 0;
			//break;
		case 'bottom-right':
			xScroll = sceneW - ScratchObj.STAGEW;
			yScroll = 0;
			//break;
		}
		updateImage();
	}

	public function scrollRight(n:Float):Void { xScroll += n; updateImage(); }
	public function scrollUp(n:Float):Void { yScroll += n; updateImage(); }

	public function getUILayer():Sprite {
		/*
		SCRATCH::allow3d {
			if(Scratch.app.isIn3D) return Scratch.app.render3D.getUIContainer();
		}
		*/
		return this;
	}

	override private function updateImage():Void {
		super.updateImage();
		/*
		SCRATCH::allow3d {
			if (Scratch.app.isIn3D)
				Scratch.app.render3D.getUIContainer().transform.matrix = transform.matrix.clone();
		}
		*/

		return; // scrolling background support is disabled; see note below

		// NOTE: The following code supports the scrolling backgrounds
		// feature, which was explored but removed before launch.
		// This prototype implementation renders SVG backdrops to a bitmap
		// (to allow wrapping) but that causes pixelation in presentation mode.
		// If the scrolling backgrounds feature is ever resurrected this code
		// is a good starting point but the pixelation issue should be fixed.
		clearCachedBitmap();
		while (img.numChildren > 0) img.removeChildAt(0);

		var c:DisplayObject = currentCostume().displayObj();
		var sceneW:Int = Std.int(Math.max(c.width, ScratchObj.STAGEW));
		var sceneH:Int = Std.int(Math.max(c.height, ScratchObj.STAGEH));

		// keep x and y scroll within range 0 .. sceneW/sceneH
		xScroll = xScroll % sceneW;
		yScroll = yScroll % sceneH;
		if (xScroll < 0) xScroll += sceneW;
		if (yScroll < 0) yScroll += sceneH;

		if ((xScroll == 0) && (yScroll == 0) && (c.width == ScratchObj.STAGEW) && (c.height == ScratchObj.STAGEH)) {
			img.addChild(currentCostume().displayObj());
			return;
		}

		var bm:BitmapData;
		if (Std.is(c, BitmapData) && (c.width >= ScratchObj.STAGEW) && (c.height >= ScratchObj.STAGEH)) {
			bm = cast(c, BitmapData);
		} else {
			// render SVG to a bitmap. also centers scenes smaller than the stage
			var m:Matrix = null;
			var insetX:Int = Std.int(Math.max(0, (ScratchObj.STAGEW - c.width) / 2));
			var insetY:Int = Std.int(Math.max(0, (ScratchObj.STAGEH - c.height) / 2));
			//if (currentCostume().svgRoot) insetX = insetY = 0;
			if ((insetX > 0) || (insetY > 0)) {
				m = new Matrix();
				m.scale(c.scaleX, c.scaleY);
				m.translate(insetX, insetY);
			}
			bm = new BitmapData(sceneW, sceneH, false);
			bm.draw(c, m);
		}

		var stageBM:BitmapData = bm;
		if ((xScroll != 0) || (yScroll != 0)) {
			var yBase:Int = ScratchObj.STAGEH - sceneH;
			stageBM = new BitmapData(ScratchObj.STAGEW, ScratchObj.STAGEH, false, 0x505050);
			stageBM.copyPixels(bm, bm.rect, new Point(-xScroll, yBase + yScroll));
			stageBM.copyPixels(bm, bm.rect, new Point(sceneW - xScroll, yBase + yScroll));
			stageBM.copyPixels(bm, bm.rect, new Point(-xScroll, yBase + yScroll - sceneH));
			stageBM.copyPixels(bm, bm.rect, new Point(sceneW - xScroll, yBase + yScroll - sceneH));
		}

		img.addChild(new Bitmap(stageBM));
		img.x = img.y = 0;
	}

	/* Camera support */

	public function step(runtime:ScratchRuntime):Void {
		if (videoImage != null) {
			if (flipVideo) {
				// flip the image like a mirror
				var m:Matrix = new Matrix();
				m.scale(-1, 1);
				m.translate(video.width, 0);
				videoImage.bitmapData.draw(video, m);
			} else {
				videoImage.bitmapData.draw(video);
			}
			/*
			SCRATCH::allow3d { if(Scratch.app.isIn3D) Scratch.app.render3D.updateRender(videoImage); }
			*/
		}
		cachedBitmapIsCurrent = false;

		// Step the watchers
		var uiContainer:Sprite = getUILayer();
		for (i in 0...uiContainer.numChildren) {
			var c:DisplayObject = uiContainer.getChildAt(i);
			if (c.visible == true) {
				if (Std.is(c, Watcher)) cast(c, Watcher).step(runtime);
				if (Std.is(c, ListWatcher)) cast(c, ListWatcher).step();
			}
		}
	}

	private var stampBounds:Rectangle = new Rectangle();
	public function stampSprite(s:ScratchSprite, stampAlpha:Float):Void {
		if(s == null) return;
//		if(!testBM.parent) {
//			//testBM.filters = [new GlowFilter(0xFF00FF, 0.8)];
//			testBM.y = 360; testBM.x = 15;
//			stage.addChild(testBM);
//		}

		var penBM:BitmapData = penLayer.bitmapData;
		var m:Matrix = new Matrix();

		function stamp2d():Void {
			var wasVisible:Bool = s.visible;
			s.visible = true;  // if this is done after commitPenStrokes, it doesn't work...
			commitPenStrokes();
			m.rotate((Math.PI * s.rotation) / 180);
			m.scale(s.scaleX, s.scaleY);
			m.translate(s.x, s.y);
			var oldGhost:Float = s.filterPack.getFilterSetting('ghost');
			s.filterPack.setFilter('ghost', 0);
			s.applyFilters();
			penBM.draw(s, m, new ColorTransform(1, 1, 1, stampAlpha));
			s.filterPack.setFilter('ghost', oldGhost);
			s.applyFilters();
			s.visible = wasVisible;
		}

		/*
		if (SCRATCH::allow3d) {
			if (Scratch.app.isIn3D) {
				var bmd:BitmapData = getBitmapOfSprite(s, stampBounds);
				if (!bmd) return;

				// TODO: Optimize for garbage collection
				var childCenter:Point = stampBounds.topLeft;
				commitPenStrokes();
				m.translate(childCenter.x * s.scaleX, childCenter.y * s.scaleY);
				m.rotate((Math.PI * s.rotation) / 180);
				m.translate(s.x, s.y);
				penBM.draw(bmd, m, new ColorTransform(1, 1, 1, stampAlpha), null, null, (s.rotation % 90 != 0));
				Scratch.app.render3D.updateRender(penLayer);
//	    		testBM.bitmapData = bmd;
			}
			else {
				stamp2d();
			}
		}
		else {
		*/
			stamp2d();
		/*	
		}
		*/
	}

	/*
	SCRATCH::allow3d
	public function getBitmapOfSprite(s:ScratchSprite, bounds:Rectangle, for_carry:Bool = false):BitmapData {
		var b:Rectangle = s.currentCostume().bitmap ? s.img.getChildAt(0).getBounds(s) : s.getVisibleBounds(s);
		bounds.width = b.width; bounds.height = b.height; bounds.x = b.x; bounds.y = b.y;
		if(!Scratch.app.render3D || s.width < 1 || s.height < 1) return null;

		var ghost:Number = s.filterPack.getFilterSetting('ghost');
		var oldBright:Number = s.filterPack.getFilterSetting('brightness');
		s.filterPack.setFilter('ghost', 0);
		s.filterPack.setFilter('brightness', 0);
		s.updateEffectsFor3D();
		var bmd:BitmapData = Scratch.app.render3D.getRenderedChild(s, b.width * s.scaleX, b.height * s.scaleY, for_carry);
		s.filterPack.setFilter('ghost', ghost);
		s.filterPack.setFilter('brightness', oldBright);
		s.updateEffectsFor3D();

		return bmd;
	}
*/
	public function setVideoState(newState:String):Void {
		if ('off' == newState) {
			if (video != null) video.attachCamera(null); // turn off camera
			if (videoImage != null && videoImage.parent != null) videoImage.parent.removeChild(videoImage);
			video = null;
			videoImage = null;
			return;
		}
		Scratch.app.libraryPart.showVideoButton();
		flipVideo = ('on' == newState); // 'on' means mirrored; 'on-flip' means unmirrored
		if (camera == null) {
			// Set up the camera only the first time it is used.
			camera = Camera.getCamera();
			if (camera == null) return; // no camera available or access denied
			camera.setMode(640, 480, 30);
		}
		if (video == null) {
			video = new Video(480, 360);
			video.attachCamera(camera);
			videoImage = new Bitmap(new BitmapData(Std.int(video.width), Std.int(video.height), false));
			videoImage.alpha = videoAlpha;
			/*
			SCRATCH::allow3d {
				updateSpriteEffects(videoImage, {'ghost': 100 * (1 - videoAlpha)});
			}
			*/
			addChildAt(videoImage, getChildIndex(penLayer) + 1);
		}
	}

	public function setVideoTransparency(transparency:Float):Void {
		videoAlpha = 1 - Math.max(0, Math.min(transparency / 100, 1));
		if (videoImage != null) {
			videoImage.alpha = videoAlpha;
			/*
			SCRATCH::allow3d {
				updateSpriteEffects(videoImage, {'ghost': transparency});
			}
			*/
		}
	}

	public function isVideoOn():Bool { return videoImage != null; }

	/* Pen support */

	public function clearPenStrokes():Void {
		var bm:BitmapData = penLayer.bitmapData;
		bm.fillRect(bm.rect, 0);
		newPenStrokes.graphics.clear();
		penActivity = false;
		/*
		SCRATCH::allow3d { if(Scratch.app.isIn3D) Scratch.app.render3D.updateRender(penLayer); }
		*/
	}

	public function commitPenStrokes():Void {
		if (!penActivity) return;
		penLayer.bitmapData.draw(newPenStrokes);
		newPenStrokes.graphics.clear();
		penActivity = false;
		/*
		SCRATCH::allow3d { if(Scratch.app.isIn3D) Scratch.app.render3D.updateRender(penLayer); }
		*/
	}

	private var cachedBM:BitmapData;
	private var cachedBitmapIsCurrent:Bool;

	private function updateCachedBitmap():Void {
		if (cachedBitmapIsCurrent) return;
		if (cachedBM == null) cachedBM = new BitmapData(ScratchObj.STAGEW, ScratchObj.STAGEH, false);
		cachedBM.fillRect(cachedBM.rect, 0xF0F080);
		cachedBM.draw(img);
		if (penLayer != null) cachedBM.draw(penLayer);
		if (videoImage != null) cachedBM.draw(videoImage);
		cachedBitmapIsCurrent = true;
	}

	public function bitmapWithoutSprite(s:ScratchSprite):BitmapData {
		// Used by the 'touching color' primitives. Draw the background layers
		// and all sprites (but not watchers or talk bubbles) except the given
		// sprite within the bounding rectangle of the given sprite into
		// a bitmap and return it.

		var r:Rectangle = s.bounds();
		var bm:BitmapData = new BitmapData(Std.int(r.width), Std.int(r.height), false);

		if (!cachedBitmapIsCurrent) updateCachedBitmap();

		var m:Matrix = new Matrix();
		m.translate(-Math.floor(r.x), -Math.floor(r.y));
		bm.draw(cachedBM, m);

		for (i in 0...this.numChildren) {
			var o:ScratchSprite = cast(this.getChildAt(i), ScratchSprite);
			if (o != null && (o != s) && o.visible && o.bounds().intersects(r)) {
				m.identity();
				m.translate(o.img.x, o.img.y);
				m.rotate((Math.PI * o.rotation) / 180);
				m.scale(o.scaleX, o.scaleY);
				m.translate(o.x - r.x, o.y - r.y);
				m.tx = Math.floor(m.tx);
				m.ty = Math.floor(m.ty);
				var colorTransform:ColorTransform = (o.img.alpha == 1) ? null : new ColorTransform(1, 1, 1, o.img.alpha);
				bm.draw(o.img, m, colorTransform);
			}
		}

		return bm;
	}
//	private var testBM:Bitmap = new Bitmap();
//	private var dumpPixels:Bool = true;

/*
	SCRATCH::allow3d
	public function updateSpriteEffects(spr:DisplayObject, effects:Object):Void {
		if(Scratch.app.isIn3D) {
			Scratch.app.render3D.updateFilters(spr, effects);
		}
	}
*/
	public function getBitmapWithoutSpriteFilteredByColor(s:ScratchSprite, c:Int):BitmapData {
		commitPenStrokes(); // force any pen strokes to be rendered so they can be sensed

		var bm1:BitmapData;
		var mask:UInt = 0x00F8F8F0;
		if (Scratch.app.isIn3D) {
			/*
			SCRATCH::allow3d {
				bm1 = Scratch.app.render3D.getOtherRenderedChildren(s, 1);
			}
			*/
		}
		else {
			// OLD code here
			bm1 = bitmapWithoutSprite(s);
		}

		var bm2:BitmapData = new BitmapData(bm1.width, bm1.height, true, 0);
		bm2.threshold(bm1, bm1.rect, bm1.rect.topLeft, '==', c, 0xFF000000, mask); // match only top five bits of each component
//		if(!testBM.parent) {
//			testBM.filters = [new GlowFilter(0xFF00FF, 0.8)];
//			stage.addChild(testBM);
//		}
//		testBM.x = bm1.width;
//		testBM.y = 300;
//		testBM.bitmapData = bm1;
//		if(dumpPixels) {
//			var arr:Vector.<uint> = bm1.getVector(bm1.rect);
//			var pxs:String = '';
//			for(var i:Int=0; i<arr.length; ++i)
//				pxs += getNumberAsHexString(arr[i], 8) + ', ';
//			trace('Looking for '+getNumberAsHexString(c, 8)+'   bitmap pixels: '+pxs);
//			dumpPixels = false;
//		}

		return bm2;
	}

	private function getNumberAsHexString(number:UInt, minimumLength:UInt = 1, showHexDenotation:Bool = true):String {
		// The string that will be output at the end of the function.
		var string:String = number.toString(16).toUpperCase();

		// While the minimumLength argument is higher than the length of the string, add a leading zero.
		while (minimumLength > string.length) {
			string = "0" + string;
		}

		// Return the result with a "0x" in front of the result.
		if (showHexDenotation) { string = "0x" + string; }

		return string;
	}

	public function updateRender(dispObj:DisplayObject, renderID:String = null, renderOpts:Dynamic = null):Void {
		/*
		SCRATCH::allow3d {
			if (Scratch.app.isIn3D) Scratch.app.render3D.updateRender(dispObj, renderID, renderOpts);
		}
		*/
	}

	public function projectThumbnailPNG():ByteArray {
		// Generate project thumbnail.
		// Note: Do not save the video layer in the thumbnail for privacy reasons.
		var bm:BitmapData = new BitmapData(ScratchObj.STAGEW, ScratchObj.STAGEH, false);
		if (videoImage != null) videoImage.visible = false;

		// Get a screenshot of the stage
		/*
		if (SCRATCH::allow3d) {
			if(Scratch.app.isIn3D) Scratch.app.render3D.getRender(bm);
			else bm.draw(this);
		}
		else {
		*/
			bm.draw(this);
			/*
		}
*/

		if (videoImage != null) videoImage.visible = true;
		return null; // PNG24Encoder.encode(bm);
	}

	public function savePenLayer():Void {
		penLayerID = -1;
		penLayerPNG = null;// PNG24Encoder.encode(penLayer.bitmapData, PNGFilter.PAETH);
		penLayerMD5 = null; // by.blooddy.crypto.MD5.hashBytes(penLayerPNG) + '.png';
	}

	public function clearPenLayer():Void {
		penLayerPNG = null;
		penLayerMD5 = null;
	}

	public function isEmpty():Bool {
		// Return true if this project has no scripts, no variables, no lists,
		// at most one sprite, and only the default costumes and sound media.
		var defaultMedia:Array<String> = [
			'510da64cf172d53750dffd23fbf73563.png',
			'b82f959ab7fa28a70b06c8162b7fef83.svg',
			'df0e59dcdea889efae55eb77902edc1c.svg',
			'83a9787d4cb6f3b7632b4ddfebf74367.wav',
			'f9a1c175dbe2e5dee472858dd30d16bb.svg',
			'6e8bd9ae68fdb02b7e1e3df656a75635.svg',
			'0aa976d536ad6667ce05f9f2174ceb3d.svg',	// new empty backdrop
			'790f7842ea100f71b34e5b9a5bfbcaa1.svg', // even newer empty backdrop
			'c969115cb6a3b75470f8897fbda5c9c9.svg'	// new empty costume
		];
		if (sprites().length > 1) return false;
		if (scriptCount() > 0) return false;
		for (obj in allObjects()) {
			if (obj.variables.length > 0) return false;
			if (obj.lists.length > 0) return false;
			for (c in obj.costumes) {
				if (defaultMedia.indexOf(c.baseLayerMD5) < 0) return false;
			}
			for (snd in obj.sounds) {
				if (defaultMedia.indexOf(snd.md5) < 0) return false;
			}
		}
		return true;
	}

	public function updateInfo():Void {
		info.scriptCount = scriptCount();
		info.spriteCount = spriteCount();
		info.flashVersion = Capabilities.version;
		if (Scratch.app.projectID != '') info.projectID = Scratch.app.projectID;
		info.videoOn = isVideoOn();
		info.swfVersion = Scratch.versionString;

		info.loadInProgress = null;// 	delete info.loadInProgress;
		if (Scratch.app.loadInProgress) info.loadInProgress = true; // log flag for debugging

		if (this == Scratch.app.stagePane) {
			// If this is the active stage pane, record the current extensions.
			//var extensionsToSave:Array = Scratch.app.extensionManager.extensionsToSave();
			info.savedExtensions = null; //delete info.savedExtensions;
			//if (extensionsToSave.length == 0) info.savedExtensions = null; //delete info.savedExtensions;
			//else info.savedExtensions = extensionsToSave;
		}

		info.userAgent = null; //delete info.userAgent;
		if (Scratch.app.isOffline) {
			info.userAgent = 'Scratch 2.0 Offline Editor';
		}
		//else if (Scratch.app.jsEnabled) {
			//Scratch.app.externalCall('window.navigator.userAgent.toString', function(userAgent:String):Void {
				//if (userAgent != null) info.userAgent = userAgent;
			//});
		//}
	}

	public function updateListWatchers():Void {
		for (i in 0...numChildren) {
			var c:DisplayObject = getChildAt(i);
			if (Std.is(c, ListWatcher)) {
				cast(c,ListWatcher).updateContents();
			}
		}
	}

	public function scriptCount():Int {
		var scriptCount:Int;
		for (obj in allObjects()) {
			for (b in obj.scripts) {
				if (Std.is(b, Block) && b.isHat) scriptCount++;
			}
		}
		return scriptCount;
	}

	public function spriteCount():Int { return sprites().length; }

	/* Dropping */

	public function handleDrop(obj:Dynamic):Bool {
		if (Std.is(obj, ScratchSprite) || Std.is(obj, Watcher) || Std.is(obj, ListWatcher)) {
			if (scaleX != 1) {
				obj.scaleX = obj.scaleY = obj.scaleX / scaleX; // revert to original scale
			}
			var p:Point = globalToLocal(new Point(obj.x, obj.y));
			obj.x = p.x;
			obj.y = p.y;
			if (obj.parent) obj.parent.removeChild(obj); // force redisplay
			addChild(obj);
			if (Std.is(obj, ScratchSprite)) {
				cast(obj, ScratchSprite).updateCostume();
				obj.setScratchXY(p.x - 240, 180 - p.y);
				Scratch.app.selectSprite(obj);
				obj.setScratchXY(p.x - 240, 180 - p.y); // needed because selectSprite() moves sprite back if costumes tab is open
				cast(obj, ScratchObj).applyFilters();
			}
			if (!Std.is(obj, ScratchSprite) || Scratch.app.editMode) Scratch.app.setSaveNeeded();
			return true;
		}
		Scratch.app.setSaveNeeded();
		return false;
	}

	/* Saving */

	public override function writeJSON(json:util.JSON):Void {
		super.writeJSON(json);
		var children:Array<Dynamic> = [];
		var c:DisplayObject;
		for (i in 0...numChildren) {
			c = getChildAt(i);
			if ((Std.is(c, ScratchSprite) && !cast(c,ScratchSprite).isClone)
				|| Std.is(c, Watcher) || Std.is(c, ListWatcher)) {
				children.push(c);
			}
		}

		// If UI elements are on another layer (during 3d rendering), process them from there
		var uiLayer:Sprite = getUILayer();
		if(uiLayer != this) {
			for (i in 0...uiLayer.numChildren) {
				c = uiLayer.getChildAt(i);
				if ((Std.is(c, ScratchSprite) && !cast(c,ScratchSprite).isClone)
						|| Std.is(c, Watcher) || Std.is(c, ListWatcher)) {
					children.push(c);
				}
			}
		}

		json.writeKeyValue('penLayerMD5', penLayerMD5);
		json.writeKeyValue('penLayerID', penLayerID);
		json.writeKeyValue('tempoBPM', tempoBPM);
		json.writeKeyValue('videoAlpha', videoAlpha);
		json.writeKeyValue('children', children);
		json.writeKeyValue('info', info);
	}

	public override function readJSON(jsonObj:Dynamic):Void {
		var children:Array<Dynamic>, i:Int, o:Dynamic;

		// read stage fields
		super.readJSON(jsonObj);
		penLayerMD5 = jsonObj.penLayerMD5;
		tempoBPM = jsonObj.tempoBPM;
		if (jsonObj.videoAlpha) videoAlpha = jsonObj.videoAlpha;
		children = jsonObj.children;
		info = jsonObj.info;

		// instantiate sprites and record their names
		var spriteNameMap:Map<String,ScratchObj> = new Map<String,ScratchObj>();
		spriteNameMap[objName] = this; // record stage's name
		for (i in 0...children.length) {
			o = children[i];
			if (o.objName != null) { // o is a sprite record
				var s:ScratchSprite = new ScratchSprite();
				s.readJSON(o);
				spriteNameMap[s.objName] = s;
				children[i] = s;
			}
		}

		// instantiate Watchers and add all children (sprites and watchers)
		for (i in 0...children.length) {
			o = children[i];
			if (Std.is(o, ScratchSprite)) {
				addChild(cast(o,ScratchSprite));
			} else if (o.sliderMin != null) { // o is a watcher record
				o.target = spriteNameMap[o.target]; // update target before instantiating
				if (o.target) {
					if (o.cmd == "senseVideoMotion" && o.param && o.param.indexOf(',')) {
						// fix old video motion/direction watchers
						var args:Array<String> = o.param.split(',');
						if (args[1] == 'this sprite') continue;
						o.param = args[0];
					}
					var w:Watcher = new Watcher();
					w.readJSON(o);
					addChild(w);
				}
			}
		}

		// instantiate lists, variables, scripts, costumes, and sounds
		for (scratchObj in allObjects()) {
			scratchObj.instantiateFromJSON(this);
		}
	}

	public override function getSummary():String {
		var summary:String = super.getSummary();
		for (s in sprites()) {
			summary += "\n\n" + s.getSummary();
		}
		return summary;
	}

}

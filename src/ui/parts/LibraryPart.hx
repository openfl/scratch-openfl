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

// LibraryPart.as
// John Maloney, November 2011
//
// This part holds the Sprite Library and the UI elements around it.

package ui.parts;

//import ui.parts.BitmapData;
//import ui.parts.Graphics;
//import ui.parts.IconButton;
//import ui.parts.MediaLibrary;
//import ui.parts.Scratch;
//import ui.parts.ScratchCostume;
//import ui.parts.ScratchObj;
//import ui.parts.ScratchSprite;
//import ui.parts.ScrollFrame;
//import ui.parts.ScrollFrameContents;
//import ui.parts.Shape;
//import ui.parts.SpriteInfoPart;
//import ui.parts.TextField;
//import ui.parts.TextFormat;
//import ui.parts.UIPart;

import flash.display.*;
import flash.text.*;
import flash.utils.*;
import scratch.*;
import translation.Translator;
import ui.media.*;
import ui.SpriteThumbnail;
import uiwidgets.*;

class LibraryPart extends UIPart {
	
	private var smallTextFormat : TextFormat = new TextFormat(CSS.font, 10, CSS.textColor);
	
	private var bgColor : Int = CSS.tabColor;
	private inline var stageAreaWidth : Int = 77;
	private inline var updateInterval : Int = 200;  // msecs between thumbnail updates  
	
	private var lastUpdate : UInt;  // time of last thumbnail update  
	
	private var shape : Shape;
	
	private var stageThumbnail : SpriteThumbnail;
	private var spritesFrame : ScrollFrame;
	private var spritesPane : ScrollFrameContents;
	private var spriteDetails : SpriteInfoPart;
	
	private var spritesTitle : TextField;
	private var newSpriteLabel : TextField;
	private var paintButton : IconButton;
	private var libraryButton : IconButton;
	private var importButton : IconButton;
	private var photoButton : IconButton;
	
	private var newBackdropLabel : TextField;
	private var backdropLibraryButton : IconButton;
	private var backdropPaintButton : IconButton;
	private var backdropImportButton : IconButton;
	private var backdropCameraButton : IconButton;
	
	private var videoLabel : TextField;
	private var videoButton : IconButton;
	
	public function new(app : Scratch)
	{
		super();
		this.app = app;
		shape = new Shape();
		addChild(shape);
		
		spritesTitle = makeLabel(Translator.map("Sprites"), CSS.titleFormat, (app.isMicroworld) ? 10 : stageAreaWidth + 10, 5);
		addChild(spritesTitle);
		
		addChild(newSpriteLabel = makeLabel(Translator.map("New sprite:"), CSS.titleFormat, 10, 5));
		addChild(libraryButton = makeButton(spriteFromLibrary, "library"));
		addChild(paintButton = makeButton(paintSprite, "paintbrush"));
		addChild(importButton = makeButton(spriteFromComputer, "import"));
		addChild(photoButton = makeButton(spriteFromCamera, "camera"));
		
		if (!app.isMicroworld) {
			addStageArea();
			addNewBackdropButtons();
			addVideoControl();
		}
		addSpritesArea();
		
		spriteDetails = new SpriteInfoPart(app);
		addChild(spriteDetails);
		spriteDetails.visible = false;
		
		updateTranslation();
	}
	
	public static function strings() : Array<Dynamic>{
		return [
		"Sprites", "New sprite:", "New backdrop:", "Video on:", "backdrop1", "costume1", "photo1", "pop", 
		"Choose sprite from library", "Paint new sprite", "Upload sprite from file", "New sprite from camera", 
		"Choose backdrop from library", "Paint new backdrop", "Upload backdrop from file", "New backdrop from camera"];
	}
	
	public function updateTranslation() : Void{
		spritesTitle.text = Translator.map("Sprites");
		newSpriteLabel.text = Translator.map("New sprite:");
		if (newBackdropLabel != null) 			newBackdropLabel.text = Translator.map("New backdrop:");
		if (videoLabel != null) 			videoLabel.text = Translator.map("Video on:");
		if (stageThumbnail != null) 
			stageThumbnail.updateThumbnail(true);
		spriteDetails.updateTranslation();
		
		SimpleTooltips.add(libraryButton, {
					text : "Choose sprite from library",
					direction : "bottom",

				});
		SimpleTooltips.add(paintButton, {
					text : "Paint new sprite",
					direction : "bottom",

				});
		SimpleTooltips.add(importButton, {
					text : "Upload sprite from file",
					direction : "bottom",

				});
		SimpleTooltips.add(photoButton, {
					text : "New sprite from camera",
					direction : "bottom",

				});
		
		SimpleTooltips.add(backdropLibraryButton, {
					text : "Choose backdrop from library",
					direction : "bottom",

				});
		SimpleTooltips.add(backdropPaintButton, {
					text : "Paint new backdrop",
					direction : "bottom",

				});
		SimpleTooltips.add(backdropImportButton, {
					text : "Upload backdrop from file",
					direction : "bottom",

				});
		SimpleTooltips.add(backdropCameraButton, {
					text : "New backdrop from camera",
					direction : "bottom",

				});
		
		fixLayout();
	}
	
	public function setWidthHeight(w : Int, h : Int) : Void{
		this.w = w;
		this.h = h;
		var g : Graphics = shape.graphics;
		g.clear();
		drawTopBar(g, CSS.titleBarColors, getTopBarPath(w, CSS.titleBarH), w, CSS.titleBarH);
		g.lineStyle(1, CSS.borderColor, 1, true);
		g.drawRect(0, CSS.titleBarH, w, h - CSS.titleBarH);
		g.lineStyle(1, CSS.borderColor);
		if (!app.isMicroworld) {
			g.moveTo(stageAreaWidth, 0);
			g.lineTo(stageAreaWidth, h);
			g.lineStyle();
			g.beginFill(CSS.tabColor);
			g.drawRect(1, CSS.titleBarH + 1, stageAreaWidth - 1, h - CSS.titleBarH - 1);
			g.endFill();
		}
		fixLayout();
		if (app.viewedObj()) 			refresh();  // refresh, but not during initialization  ;
	}
	
	private function fixLayout() : Void{
		var buttonY : Int = 4;
		
		if (!app.isMicroworld) {
			libraryButton.x = 380;
			if (app.stageIsContracted) 				libraryButton.x = 138;
			libraryButton.y = buttonY + 0;
			paintButton.x = libraryButton.x + libraryButton.width + 3;
			paintButton.y = buttonY + 1;
			importButton.x = paintButton.x + paintButton.width + 4;
			importButton.y = buttonY + 0;
			photoButton.x = importButton.x + importButton.width + 8;
			photoButton.y = buttonY + 2;
			
			stageThumbnail.x = 2;
			stageThumbnail.y = CSS.titleBarH + 2;
			spritesFrame.x = stageAreaWidth + 1;
			
			newSpriteLabel.x = libraryButton.x - newSpriteLabel.width - 6;
			newSpriteLabel.y = 6;
		}
		else {
			libraryButton.visible = false;
			paintButton.visible = false;
			importButton.visible = false;
			photoButton.visible = false;
			newSpriteLabel.visible = false;
			spritesFrame.x = 1;
		}
		
		spritesFrame.y = CSS.titleBarH + 1;
		spritesFrame.allowHorizontalScrollbar = false;
		spritesFrame.setWidthHeight(w - spritesFrame.x, h - spritesFrame.y);
		
		spriteDetails.x = spritesFrame.x;
		spriteDetails.y = spritesFrame.y;
		spriteDetails.setWidthHeight(w - spritesFrame.x, h - spritesFrame.y);
	}
	
	public function highlight(highlightList : Array<Dynamic>) : Void{
		// Highlight each ScratchObject in the given list to show,
		// for example, broadcast senders or receivers. Passing an
		// empty list to this function clears all highlights.
		for (tn/* AS3HX WARNING could not determine type for var: tn exp: ECall(EIdent(allThumbnails),[]) type: null */ in allThumbnails()){
			tn.showHighlight(Lambda.indexOf(highlightList, tn.targetObj) >= 0);
		}
	}
	
	public function refresh() : Void{
		// Create thumbnails for all sprites. This function is called
		// after loading project, or adding or deleting a sprite.
		newSpriteLabel.visible = !app.stageIsContracted && !app.isMicroworld;
		spritesTitle.visible = !app.stageIsContracted;
		if (app.viewedObj().isStage) 			showSpriteDetails(false);
		if (spriteDetails.visible) 			spriteDetails.refresh();
		if (stageThumbnail != null) 			stageThumbnail.setTarget(app.stageObj());
		spritesPane.clear(false);
		var sortedSprites : Array<Dynamic> = app.stageObj().sprites();
		sortedSprites.sort(
				function(spr1 : ScratchSprite, spr2 : ScratchSprite) : Int{
					return spr1.indexInLibrary - spr2.indexInLibrary;
				});
		var inset : Int = 2;
		var rightEdge : Int = w - spritesFrame.x;
		var nextX : Int = inset;
		var nextY : Int = inset;
		var index : Int = 1;
		for (spr in sortedSprites){
			spr.indexInLibrary = index++;  // renumber to ensure unique indices  
			var tn : SpriteThumbnail = new SpriteThumbnail(spr, app);
			tn.x = nextX;
			tn.y = nextY;
			spritesPane.addChild(tn);
			nextX += tn.width;
			if ((nextX + tn.width) > rightEdge) {  // start new line  
				nextX = inset;
				nextY += tn.height;
			}
		}
		spritesPane.updateSize();
		scrollToSelectedSprite();
		step();
	}
	
	private function scrollToSelectedSprite() : Void{
		var viewedObj : ScratchObj = app.viewedObj();
		var sel : SpriteThumbnail;
		for (i in 0...spritesPane.numChildren){
			var tn : SpriteThumbnail = try cast(spritesPane.getChildAt(i), SpriteThumbnail) catch(e:Dynamic) null;
			if (tn != null && (tn.targetObj == viewedObj)) 				sel = tn;
		}
		if (sel != null) {
			var selTop : Int = sel.y + spritesPane.y - 1;
			var selBottom : Int = selTop + sel.height;
			spritesPane.y -= Math.max(0, selBottom - spritesFrame.visibleH());
			spritesPane.y -= Math.min(0, selTop);
			spritesFrame.updateScrollbars();
		}
	}
	
	public function showSpriteDetails(flag : Bool) : Void{
		spriteDetails.visible = flag;
		if (spriteDetails.visible) 			spriteDetails.refresh();
	}
	
	public function step() : Void{
		// Update thumbnails and sprite details.
		var viewedObj : ScratchObj = app.viewedObj();
		var updateThumbnails : Bool = ((Math.round(haxe.Timer.stamp() * 1000) - lastUpdate) > updateInterval);
		for (tn/* AS3HX WARNING could not determine type for var: tn exp: ECall(EIdent(allThumbnails),[]) type: null */ in allThumbnails()){
			if (updateThumbnails) 				tn.updateThumbnail();
			tn.select(tn.targetObj == viewedObj);
		}
		if (updateThumbnails) 			lastUpdate = Math.round(haxe.Timer.stamp() * 1000);
		if (spriteDetails.visible) 			spriteDetails.step();
		if (videoButton != null && videoButton.visible) 			updateVideoButton();
	}
	
	private function addStageArea() : Void{
		stageThumbnail = new SpriteThumbnail(app.stagePane, app);
		addChild(stageThumbnail);
	}
	
	private function addNewBackdropButtons() : Void{
		addChild(newBackdropLabel = makeLabel(
								Translator.map("New backdrop:"), smallTextFormat, 3, 126));
		
		// new backdrop buttons
		addChild(backdropLibraryButton = makeButton(backdropFromLibrary, "landscapeSmall"));
		addChild(backdropPaintButton = makeButton(paintBackdrop, "paintbrushSmall"));
		addChild(backdropImportButton = makeButton(backdropFromComputer, "importSmall"));
		addChild(backdropCameraButton = makeButton(backdropFromCamera, "cameraSmall"));
		
		var buttonY : Int = 145;
		backdropLibraryButton.x = 4;
		backdropLibraryButton.y = buttonY + 3;
		backdropPaintButton.x = backdropLibraryButton.right() + 4;
		backdropPaintButton.y = buttonY + 1;
		backdropImportButton.x = backdropPaintButton.right() + 1;
		backdropImportButton.y = buttonY + 0;
		backdropCameraButton.x = backdropImportButton.right() + 5;
		backdropCameraButton.y = buttonY + 3;
	}
	
	private function addSpritesArea() : Void{
		spritesPane = new ScrollFrameContents();
		spritesPane.color = bgColor;
		spritesPane.hExtra = spritesPane.vExtra = 0;
		spritesFrame = new ScrollFrame();
		spritesFrame.setContents(spritesPane);
		addChild(spritesFrame);
	}
	
	private function makeButton(fcn : Function, iconName : String) : IconButton{
		var b : IconButton = new IconButton(fcn, iconName);
		b.isMomentary = true;
		return b;
	}
	
	// -----------------------------
	// Video Button
	//------------------------------
	
	public function showVideoButton() : Void{
		// Show the video button. Turn on the camera the first time this is called.
		if (videoButton.visible) 			return  // already showing  ;
		videoButton.visible = true;
		videoLabel.visible = true;
		if (!app.stagePane.isVideoOn()) {
			app.stagePane.setVideoState("on");
		}
	}
	
	private function updateVideoButton() : Void{
		var isOn : Bool = app.stagePane.isVideoOn();
		if (videoButton.isOn() != isOn) 			videoButton.setOn(isOn);
	}
	
	private function addVideoControl() : Void{
		function turnVideoOn(b : IconButton) : Void{
			app.stagePane.setVideoState((b.isOn()) ? "on" : "off");
			app.setSaveNeeded();
		};
		addChild(videoLabel = makeLabel(
								Translator.map("Video on:"), smallTextFormat,
								1, backdropLibraryButton.y + 22));
		
		videoButton = makeButton(turnVideoOn, "checkbox");
		videoButton.x = videoLabel.x + videoLabel.width + 1;
		videoButton.y = videoLabel.y + 3;
		videoButton.disableMouseover();
		videoButton.isMomentary = false;
		addChild(videoButton);
		
		videoLabel.visible = videoButton.visible = false;
	}
	
	// -----------------------------
	// New Sprite Operations
	//------------------------------
	
	private function paintSprite(b : IconButton) : Void{
		var spr : ScratchSprite = new ScratchSprite();
		spr.setInitialCostume(ScratchCostume.emptyBitmapCostume(Translator.map("costume1"), false));
		app.addNewSprite(spr, true);
	}
	
	private function spriteFromCamera(b : IconButton) : Void{
		function savePhoto(photo : BitmapData) : Void{
			var s : ScratchSprite = new ScratchSprite();
			s.setInitialCostume(new ScratchCostume(Translator.map("photo1"), photo));
			app.addNewSprite(s);
			app.closeCameraDialog();
		};
		app.openCameraDialog(savePhoto);
	}
	
	private function spriteFromComputer(b : IconButton) : Void{importSprite(true);
	}
	private function spriteFromLibrary(b : IconButton) : Void{importSprite(false);
	}
	
	private function importSprite(fromComputer : Bool) : Void{
		function addSprite(costumeOrSprite : Dynamic) : Void{
			var spr : ScratchSprite;
			var c : ScratchCostume = try cast(costumeOrSprite, ScratchCostume) catch(e:Dynamic) null;
			if (c != null) {
				spr = new ScratchSprite(c.costumeName);
				spr.setInitialCostume(c);
				app.addNewSprite(spr);
				return;
			}
			spr = try cast(costumeOrSprite, ScratchSprite) catch(e:Dynamic) null;
			if (spr != null) {
				app.addNewSprite(spr);
				return;
			}
			var list : Array<Dynamic> = try cast(costumeOrSprite, Array<Dynamic>) catch(e:Dynamic) null;
			if (list != null) {
				var sprName : String = list[0].costumeName;
				if (sprName.length > 3) 					sprName = sprName.substring(0, sprName.length - 2);
				spr = new ScratchSprite(sprName);
				for (c in list)spr.costumes.push(c);
				if (spr.costumes.length > 1) 					spr.costumes.shift();  // remove default costume  ;
				spr.showCostumeNamed(list[0].costumeName);
				app.addNewSprite(spr);
			}
		};
		var lib : MediaLibrary = app.getMediaLibrary("sprite", addSprite);
		if (fromComputer) 			lib.importFromDisk();
		else lib.open();
	}
	
	// -----------------------------
	// New Backdrop Operations
	//------------------------------
	
	private function backdropFromCamera(b : IconButton) : Void{
		function savePhoto(photo : BitmapData) : Void{
			addBackdrop(new ScratchCostume(Translator.map("photo1"), photo));
			app.closeCameraDialog();
		};
		app.openCameraDialog(savePhoto);
	}
	
	private function backdropFromComputer(b : IconButton) : Void{
		var lib : MediaLibrary = app.getMediaLibrary("backdrop", addBackdrop);
		lib.importFromDisk();
	}
	
	private function backdropFromLibrary(b : IconButton) : Void{
		var lib : MediaLibrary = app.getMediaLibrary("backdrop", addBackdrop);
		lib.open();
	}
	
	private function paintBackdrop(b : IconButton) : Void{
		addBackdrop(ScratchCostume.emptyBitmapCostume(Translator.map("backdrop1"), true));
	}
	
	private function addBackdrop(costumeOrList : Dynamic) : Void{
		var c : ScratchCostume = try cast(costumeOrList, ScratchCostume) catch(e:Dynamic) null;
		if (c != null) {
			if (!c.baseLayerData) 				c.prepareToSave();
			if (!app.okayToAdd(c.baseLayerData.length)) 				return  // not enough room  ;
			c.costumeName = app.stagePane.unusedCostumeName(c.costumeName);
			app.stagePane.costumes.push(c);
			app.stagePane.showCostumeNamed(c.costumeName);
		}
		var list : Array<Dynamic> = try cast(costumeOrList, Array<Dynamic>) catch(e:Dynamic) null;
		if (list != null) {
			for (c in list){
				if (!c.baseLayerData) 					c.prepareToSave();
				if (!app.okayToAdd(c.baseLayerData.length)) 					return  // not enough room  ;
				app.stagePane.costumes.push(c);
			}
			app.stagePane.showCostumeNamed(list[0].costumeName);
		}
		app.setTab("images");
		app.selectSprite(app.stagePane);
		app.setSaveNeeded(true);
	}
	
	// -----------------------------
	// Dropping
	//------------------------------
	
	public function handleDrop(obj : Dynamic) : Bool{
		return false;
	}
	
	private function changeThumbnailOrder(dropped : ScratchSprite, dropX : Int, dropY : Int) : Void{
		// Update the order of library items based on the drop point. Update the
		// indexInLibrary field of all sprites, then refresh the library.
		dropped.indexInLibrary = -1;
		var inserted : Bool = false;
		var nextIndex : Int = 1;
		for (i in 0...spritesPane.numChildren){
			var th : SpriteThumbnail = try cast(spritesPane.getChildAt(i), SpriteThumbnail) catch(e:Dynamic) null;
			var spr : ScratchSprite = try cast(th.targetObj, ScratchSprite) catch(e:Dynamic) null;
			if (!inserted) {
				if (dropY < (th.y - (th.height / 2))) {  // insert before this row  
					dropped.indexInLibrary = nextIndex++;
					inserted = true;
				}
				else if (dropY < (th.y + (th.height / 2))) {
					if (dropX < th.x) {  // insert before the current thumbnail  
						dropped.indexInLibrary = nextIndex++;
						inserted = true;
					}
				}
			}
			if (spr != dropped) 				spr.indexInLibrary = nextIndex++;
		}
		if (dropped.indexInLibrary < 0) 			dropped.indexInLibrary = nextIndex++;
		refresh();
	}
	
	// -----------------------------
	// Misc
	//------------------------------
	
	private function allThumbnails() : Array<Dynamic>{
		// Return a list containing all thumbnails.
		var result : Array<Dynamic> = (stageThumbnail != null) ? [stageThumbnail] : [];
		for (i in 0...spritesPane.numChildren){
			result.push(spritesPane.getChildAt(i));
		}
		return result;
	}
}

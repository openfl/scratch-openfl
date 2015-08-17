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

// SpriteInfoPart.as
// John Maloney, November 2011
//
// This part shows information about the currently selected object (the stage or a sprite).

package ui.parts;

import ui.parts.Bitmap;
import ui.parts.DisplayObject;
import ui.parts.EditableLabel;
import ui.parts.Graphics;
import ui.parts.IconButton;
import ui.parts.Point;
import ui.parts.Scratch;
import ui.parts.ScratchCostume;
import ui.parts.ScratchObj;
import ui.parts.ScratchSprite;
import ui.parts.Shape;
import ui.parts.Sprite;
import ui.parts.TextField;
import ui.parts.TextFormat;
import ui.parts.UIPart;

import flash.display.*;
import flash.events.*;
import flash.geom.*;
import flash.text.*;
import scratch.*;
import translation.Translator;
import uiwidgets.*;
import util.DragClient;
import watchers.ListWatcher;

class SpriteInfoPart extends UIPart implements DragClient {
	
	private var readoutLabelFormat : TextFormat = new TextFormat(CSS.font, 12, 0xA6A8AB, true);
	private var readoutFormat : TextFormat = new TextFormat(CSS.font, 12, 0xA6A8AB);
	
	private var shape : Shape;
	
	// sprite info parts
	private var closeButton : IconButton;
	private var thumbnail : Bitmap;
	private var spriteName : EditableLabel;
	
	private var xReadoutLabel : TextField;
	private var yReadoutLabel : TextField;
	private var xReadout : TextField;
	private var yReadout : TextField;
	
	private var dirLabel : TextField;
	private var dirReadout : TextField;
	private var dirWheel : Sprite;
	
	private var rotationStyleLabel : TextField;
	private var rotationStyleButtons : Array<Dynamic>;
	
	private var draggableLabel : TextField;
	private var draggableButton : IconButton;
	
	private var showSpriteLabel : TextField;
	private var showSpriteButton : IconButton;
	
	private var lastX : Float;private var lastY : Float;private var lastDirection : Float;private var lastRotationStyle : String;
	private var lastSrcImg : DisplayObject;
	
	public function new(app : Scratch)
	{
		super();
		this.app = app;
		shape = new Shape();
		addChild(shape);
		addParts();
		updateTranslation();
	}
	
	public static function strings() : Array<Dynamic>{
		return ["direction:", "rotation style:", "can drag in player:", "show:"];
	}
	
	public function updateTranslation() : Void{
		dirLabel.text = Translator.map("direction:");
		rotationStyleLabel.text = Translator.map("rotation style:");
		draggableLabel.text = Translator.map("can drag in player:");
		showSpriteLabel.text = Translator.map("show:");
		if (app.viewedObj()) 			refresh();
	}
	
	public function setWidthHeight(w : Int, h : Int) : Void{
		this.w = w;
		this.h = h;
		var g : Graphics = shape.graphics;
		g.clear();
		g.beginFill(CSS.white);
		g.drawRect(0, 0, w, h);
		g.endFill();
	}
	
	public function step() : Void{updateSpriteInfo();
	}
	
	public function refresh() : Void{
		spriteName.setContents(app.viewedObj().objName);
		updateSpriteInfo();
		if (app.stageIsContracted) 			layoutCompact()
		else layoutFullsize();
	}
	
	private function addParts() : Void{
		addChild(closeButton = new IconButton(closeSpriteInfo, "backarrow"));
		closeButton.isMomentary = true;
		
		addChild(spriteName = new EditableLabel(nameChanged));
		spriteName.setWidth(200);
		
		addChild(thumbnail = new Bitmap());
		
		addChild(xReadoutLabel = makeLabel("x:", readoutLabelFormat));
		addChild(xReadout = makeLabel("-888", readoutFormat));
		
		addChild(yReadoutLabel = makeLabel("y:", readoutLabelFormat));
		addChild(yReadout = makeLabel("-888", readoutFormat));
		
		addChild(dirLabel = makeLabel("", readoutLabelFormat));
		addChild(dirWheel = new Sprite());
		dirWheel.addEventListener(MouseEvent.MOUSE_DOWN, dirMouseDown);
		addChild(dirReadout = makeLabel("-179", readoutFormat));
		
		addChild(rotationStyleLabel = makeLabel("", readoutLabelFormat));
		rotationStyleButtons = [
				new IconButton(rotate360, "rotate360", null, true), 
				new IconButton(rotateFlip, "flip", null, true), 
				new IconButton(rotateNone, "norotation", null, true)];
		for (b in rotationStyleButtons)addChild(b);
		
		addChild(draggableLabel = makeLabel("", readoutLabelFormat));
		addChild(draggableButton = new IconButton(toggleLock, "checkbox"));
		draggableButton.disableMouseover();
		
		addChild(showSpriteLabel = makeLabel("", readoutLabelFormat));
		addChild(showSpriteButton = new IconButton(toggleShowSprite, "checkbox"));
		showSpriteButton.disableMouseover();
	}
	
	private function layoutFullsize() : Void{
		dirLabel.visible = true;
		rotationStyleLabel.visible = true;
		
		closeButton.x = 5;
		closeButton.y = 5;
		
		thumbnail.x = 40;
		thumbnail.y = 8;
		
		var left : Int = 150;
		
		spriteName.setWidth(228);
		spriteName.x = left;
		spriteName.y = 5;
		
		var nextY : Int = spriteName.y + spriteName.height + 9;
		xReadoutLabel.x = left;
		xReadoutLabel.y = nextY;
		xReadout.x = xReadoutLabel.x + 15;
		xReadout.y = nextY;
		
		yReadoutLabel.x = left + 47;
		yReadoutLabel.y = nextY;
		yReadout.x = yReadoutLabel.x + 15;
		yReadout.y = nextY;
		
		// right aligned
		dirWheel.x = w - 38;
		dirWheel.y = nextY + 8;
		dirReadout.x = dirWheel.x - 47;
		dirReadout.y = nextY;
		dirLabel.x = dirReadout.x - dirLabel.textWidth - 5;
		dirLabel.y = nextY;
		
		nextY += 22;
		rotationStyleLabel.x = left;
		rotationStyleLabel.y = nextY;
		var buttonsX : Int = rotationStyleLabel.x + rotationStyleLabel.width + 5;
		rotationStyleButtons[0].x = buttonsX;
		rotationStyleButtons[1].x = buttonsX + 28;
		rotationStyleButtons[2].x = buttonsX + 55;
		rotationStyleButtons[0].y = rotationStyleButtons[1].y = rotationStyleButtons[2].y = nextY;
		
		nextY += 22;
		draggableLabel.x = left;
		draggableLabel.y = nextY;
		draggableButton.x = draggableLabel.x + draggableLabel.textWidth + 10;
		draggableButton.y = nextY + 4;
		
		nextY += 22;
		showSpriteLabel.x = left;
		showSpriteLabel.y = nextY;
		showSpriteButton.x = showSpriteLabel.x + showSpriteLabel.textWidth + 10;
		showSpriteButton.y = nextY + 4;
	}
	
	private function layoutCompact() : Void{
		dirLabel.visible = false;
		rotationStyleLabel.visible = false;
		
		closeButton.x = 5;
		closeButton.y = 5;
		
		spriteName.setWidth(130);
		spriteName.x = 28;
		spriteName.y = 5;
		
		var left : Int = 6;
		
		thumbnail.x = ((w - thumbnail.width) / 2) + 3;
		thumbnail.y = spriteName.y + spriteName.height + 10;
		
		var nextY : Int = 125;
		xReadoutLabel.x = left;
		xReadoutLabel.y = nextY;
		xReadout.x = left + 15;
		xReadout.y = nextY;
		
		yReadoutLabel.x = left + 47;
		yReadoutLabel.y = nextY;
		yReadout.x = yReadoutLabel.x + 15;
		yReadout.y = nextY;
		
		// right aligned
		dirWheel.x = w - 18;
		dirWheel.y = nextY + 8;
		dirReadout.x = dirWheel.x - 47;
		dirReadout.y = nextY;
		
		nextY += 22;
		rotationStyleButtons[0].x = left;
		rotationStyleButtons[1].x = left + 33;
		rotationStyleButtons[2].x = left + 64;
		rotationStyleButtons[0].y = rotationStyleButtons[1].y = rotationStyleButtons[2].y = nextY;
		
		nextY += 22;
		draggableLabel.x = left;
		draggableLabel.y = nextY;
		draggableButton.x = draggableLabel.x + draggableLabel.textWidth + 10;
		draggableButton.y = nextY + 4;
		
		nextY += 22;
		showSpriteLabel.x = left;
		showSpriteLabel.y = nextY;
		showSpriteButton.x = showSpriteLabel.x + showSpriteLabel.textWidth + 10;
		showSpriteButton.y = nextY + 4;
	}
	
	private function closeSpriteInfo(ignore : Dynamic) : Void{
		var lib : LibraryPart = try cast(parent, LibraryPart) catch(e:Dynamic) null;
		if (lib != null) 			lib.showSpriteDetails(false);
	}
	
	private function rotate360(ignore : Dynamic) : Void{
		var spr : ScratchSprite = try cast(app.viewedObj(), ScratchSprite) catch(e:Dynamic) null;
		spr.rotationStyle = "normal";
		spr.setDirection(spr.direction);
		app.setSaveNeeded();
	}
	
	private function rotateFlip(ignore : Dynamic) : Void{
		var spr : ScratchSprite = try cast(app.viewedObj(), ScratchSprite) catch(e:Dynamic) null;
		var dir : Float = spr.direction;
		spr.setDirection(90);
		spr.rotationStyle = "leftRight";
		spr.setDirection(dir);
		app.setSaveNeeded();
	}
	
	private function rotateNone(ignore : Dynamic) : Void{
		var spr : ScratchSprite = try cast(app.viewedObj(), ScratchSprite) catch(e:Dynamic) null;
		var dir : Float = spr.direction;
		spr.setDirection(90);
		spr.rotationStyle = "none";
		spr.setDirection(dir);
		app.setSaveNeeded();
	}
	
	private function toggleLock(b : IconButton) : Void{
		var spr : ScratchSprite = cast((app.viewedObj()), ScratchSprite);
		if (spr != null) {
			spr.isDraggable = b.isOn();
			app.setSaveNeeded();
		}
	}
	
	private function toggleShowSprite(b : IconButton) : Void{
		var spr : ScratchSprite = cast((app.viewedObj()), ScratchSprite);
		if (spr != null) {
			spr.visible = !spr.visible;
			spr.updateBubble();
			b.setOn(spr.visible);
			app.setSaveNeeded();
		}
	}
	
	private function updateSpriteInfo() : Void{
		// Update the sprite info. Do nothing if a field is already up to date (to minimize CPU load).
		var spr : ScratchSprite = try cast(app.viewedObj(), ScratchSprite) catch(e:Dynamic) null;
		if (spr == null) 			return;
		updateThumbnail();
		if (spr.scratchX != lastX) {
			xReadout.text = Std.string(Math.round(spr.scratchX));
			lastX = spr.scratchX;
		}
		if (spr.scratchY != lastY) {
			yReadout.text = Std.string(Math.round(spr.scratchY));
			lastY = spr.scratchY;
		}
		if (spr.direction != lastDirection) {
			dirReadout.text = Std.string(Math.round(spr.direction)) + "\u00B0";
			drawDirWheel(spr.direction);
			lastDirection = spr.direction;
		}
		if (spr.rotationStyle != lastRotationStyle) {
			updateRotationStyle();
			lastRotationStyle = spr.rotationStyle;
		}
		draggableButton.setOn(spr.isDraggable);
		showSpriteButton.setOn(spr.visible);
	}
	
	private function drawDirWheel(dir : Float) : Void{
		var DegreesToRadians : Float = (2 * Math.PI) / 360;
		var r : Float = 11;
		var g : Graphics = dirWheel.graphics;
		g.clear();
		
		// circle
		g.beginFill(0xFF, 0);
		g.drawCircle(0, 0, r + 5);
		g.endFill();
		g.lineStyle(2, 0xD0D0D0, 1, true);
		g.drawCircle(0, 0, r - 3);
		
		// direction pointer
		g.lineStyle(3, 0x006080, 1, true);
		g.moveTo(0, 0);
		var dx : Float = r * Math.sin(DegreesToRadians * (180 - dir));
		var dy : Float = r * Math.cos(DegreesToRadians * (180 - dir));
		g.lineTo(dx, dy);
	}
	
	private function nameChanged() : Void{
		app.runtime.renameSprite(spriteName.contents());
		spriteName.setContents(app.viewedObj().objName);
	}
	
	public function updateThumbnail() : Void{
		var targetObj : ScratchObj = app.viewedObj();
		if (targetObj == null) 			return;
		if (targetObj.img.numChildren == 0) 			return  // shouldn't happen  ;
		
		var src : DisplayObject = targetObj.img.getChildAt(0);
		if (src == lastSrcImg) 			return  // thumbnail is up to date  ;
		
		var c : ScratchCostume = targetObj.currentCostume();
		thumbnail.bitmapData = c.thumbnail(80, 80, targetObj.isStage);
		lastSrcImg = src;
	}
	
	private function updateRotationStyle() : Void{
		var targetObj : ScratchSprite = try cast(app.viewedObj(), ScratchSprite) catch(e:Dynamic) null;
		if (targetObj == null) 			return;
		for (i in 0...numChildren){
			var b : IconButton = try cast(getChildAt(i), IconButton) catch(e:Dynamic) null;
			if (b != null) {
				if (b.clickFunction == rotate360) 					b.setOn(targetObj.rotationStyle == "normal");
				if (b.clickFunction == rotateFlip) 					b.setOn(targetObj.rotationStyle == "leftRight");
				if (b.clickFunction == rotateNone) 					b.setOn(targetObj.rotationStyle == "none");
			}
		}
	}
	
	// -----------------------------
	// Direction Wheel Interaction
	//------------------------------
	
	private function dirMouseDown(evt : MouseEvent) : Void{app.gh.setDragClient(this, evt);
	}
	
	public function dragBegin(evt : MouseEvent) : Void{dragMove(evt);
	}
	public function dragEnd(evt : MouseEvent) : Void{dragMove(evt);
	}
	
	public function dragMove(evt : MouseEvent) : Void{
		var spr : ScratchSprite = try cast(app.viewedObj(), ScratchSprite) catch(e:Dynamic) null;
		if (spr == null) 			return;
		var p : Point = dirWheel.localToGlobal(new Point(0, 0));
		var dx : Int = evt.stageX - p.x;
		var dy : Int = evt.stageY - p.y;
		if ((dx == 0) && (dy == 0)) 			return;
		var degrees : Float = 90 + ((180 / Math.PI) * Math.atan2(dy, dx));
		spr.setDirection(degrees);
	}
}

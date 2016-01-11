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

package ui;


import flash.display.*;
import flash.events.*;
import flash.filters.GlowFilter;
import flash.text.*;
import assets.Resources;
import blocks.Block;
import scratch.*;
import translation.Translator;
import ui.media.MediaInfo;
import ui.parts.LibraryPart;
import uiwidgets.*;

class SpriteThumbnail extends Sprite
{

	private static inline var frameW : Int = 73;
	private static inline var frameH : Int = 73;
	private static inline var stageFrameH : Int = 86;

	private static inline var thumbnailW : Int = 68;
	private static inline var thumbnailH : Int = 51;

	public var targetObj : ScratchObj;

	private var app : Scratch;
	private var thumbnail : Bitmap;
	private var label : TextField;
	private var sceneInfo : TextField;
	private var selectedFrame : Shape;
	private var highlightFrame : Shape;
	private var infoSprite : Sprite;
	private var detailsButton : IconButton;

	private var lastSrcImg : DisplayObject;
	private var lastName : String = "";
	private var lastSceneCount : Int = 0;

	public function new(targetObj : ScratchObj, app : Scratch)
	{
		super();
		this.targetObj = targetObj;
		this.app = app;

		addFrame();
		addSelectedFrame();
		addHighlightFrame();

		thumbnail = new Bitmap();
		thumbnail.x = 3;
		thumbnail.y = 3;
		thumbnail.filters = [grayOutlineFilter()];
		addChild(thumbnail);

		label = Resources.makeLabel("", CSS.thumbnailFormat);
		label.width = frameW;
		addChild(label);

		if (targetObj.isStage) {
			sceneInfo = Resources.makeLabel("", CSS.thumbnailExtraInfoFormat);
			sceneInfo.width = frameW;
			addChild(sceneInfo);
		}

		addDetailsButton();
		updateThumbnail();
	}

	public static function strings() : Array<Dynamic>{
		return ["backdrop", "backdrops", "hide", "show", "Stage"];
	}

	private function addDetailsButton() : Void{
		detailsButton = new IconButton(showSpriteDetails, "spriteInfo");
		detailsButton.x = detailsButton.y = -2;
		detailsButton.isMomentary = true;
		detailsButton.visible = false;
		addChild(detailsButton);
	}

	private function addFrame() : Void{
		if (targetObj.isStage)             return;

		var frame : Shape = new Shape();
		var g : Graphics = frame.graphics;
		g.lineStyle(Math.NaN);
		g.beginFill(0xFFFFFF);
		g.drawRoundRect(0, 0, frameW, frameH, 12, 12);
		g.endFill();
		addChild(frame);
	}

	private function addSelectedFrame() : Void{
		selectedFrame = new Shape();
		var g : Graphics = selectedFrame.graphics;
		var h : Int = (targetObj.isStage) ? stageFrameH : frameH;
		g.lineStyle(3, CSS.overColor, 1, true);
		g.beginFill(CSS.itemSelectedColor);
		g.drawRoundRect(0, 0, frameW, h, 12, 12);
		g.endFill();
		selectedFrame.visible = false;
		addChild(selectedFrame);
	}

	private function addHighlightFrame() : Void{
		var highlightColor : Int = 0xE0E000;
		highlightFrame = new Shape();
		var g : Graphics = highlightFrame.graphics;
		var h : Int = (targetObj.isStage) ? stageFrameH : frameH;
		g.lineStyle(2, highlightColor, 1, true);
		g.drawRoundRect(1, 1, frameW - 1, h - 1, 12, 12);
		highlightFrame.visible = false;
		addChild(highlightFrame);
	}

	public function setTarget(obj : ScratchObj) : Void{
		targetObj = obj;
		updateThumbnail();
	}

	public function select(flag : Bool) : Void{
		if (selectedFrame.visible == flag)             return;
		selectedFrame.visible = flag;
		detailsButton.visible = flag && !targetObj.isStage;
	}

	public function showHighlight(flag : Bool) : Void{
		// Display a highlight if flag is true (e.g. to show broadcast senders/receivers).
		highlightFrame.visible = flag;
	}

	public function showInfo(flag : Bool) : Void{
		if (infoSprite != null) {
			removeChild(infoSprite);
			infoSprite = null;
		}
		if (flag) {
			infoSprite = makeInfoSprite();
			addChild(infoSprite);
		}
	}

	public function makeInfoSprite() : Sprite{
		var result : Sprite = new Sprite();
		var bm : Bitmap = Resources.createBmp("hatshape");
		bm.x = (frameW - bm.width) / 2;
		bm.y = 20;
		result.addChild(bm);
		var tf : TextField = Resources.makeLabel(Std.string(targetObj.scripts.length), CSS.normalTextFormat);
		tf.x = bm.x + 20 - (tf.textWidth / 2);
		tf.y = bm.y + 4;
		result.addChild(tf);
		return result;
	}

	public function updateThumbnail(translationChanged : Bool = false) : Void{
		if (targetObj == null)             return;
		if (translationChanged)             lastSceneCount = -1;
		updateName();
		if (targetObj.isStage)             updateSceneCount();

		if (targetObj.img.numChildren == 0)             return;  // shouldn't happen  ;
		if (targetObj.currentCostume().svgLoading)             return;  // don't update thumbnail while loading SVG bitmaps  ;
		var src : DisplayObject = targetObj.img.getChildAt(0);
		if (src == lastSrcImg)             return;  // thumbnail is up to date  ;

		var c : ScratchCostume = targetObj.currentCostume();
		thumbnail.bitmapData = c.thumbnail(thumbnailW, thumbnailH, targetObj.isStage);
		lastSrcImg = src;
	}

	private function grayOutlineFilter() : GlowFilter{
		// Filter to provide a gray outline even around totally white costumes.
		var f : GlowFilter = new GlowFilter(CSS.onColor);
		f.strength = 1;
		f.blurX = f.blurY = 2;
		f.knockout = false;
		return f;
	}

	private function updateName() : Void{
		var s : String = ((targetObj.isStage)) ? Translator.map("Stage") : targetObj.objName;
		if (s == lastName)             return;
		lastName = s;
		label.text = s;
		while ((label.textWidth > 60) && (s.length > 0)){
			s = s.substring(0, s.length - 1);
			label.text = s + "\u2026";
		}
		label.x = ((frameW - label.textWidth) / 2) - 2;
		label.y = 57;
	}

	private function updateSceneCount() : Void{
		if (targetObj.costumes.length == lastSceneCount)             return;
		var sceneCount : Int = targetObj.costumes.length;
		sceneInfo.text = sceneCount + " " + Translator.map(((sceneCount == 1)) ? "backdrop" : "backdrops");
		sceneInfo.x = ((frameW - sceneInfo.textWidth) / 2) - 2;
		sceneInfo.y = 70;
		lastSceneCount = sceneCount;
	}

	// -----------------------------
	// Grab and Drop
	//------------------------------

	public function objToGrab(evt : MouseEvent) : MediaInfo{
		if (targetObj.isStage)             return null;
		var result : MediaInfo = app.createMediaInfo(targetObj);
		result.removeDeleteButton();
		result.computeThumbnail();
		result.hideTextFields();
		return result;
	}

	public function handleDrop(obj : Dynamic) : Bool{
		function addCostume(c : ScratchCostume) : Void{app.addCostume(c, targetObj);
		};
		function addSound(snd : ScratchSound) : Void{app.addSound(snd, targetObj);
		};
		var item : MediaInfo = try cast(obj, MediaInfo) catch(e:Dynamic) null;
		if (item != null) {
			// accept dropped costumes and sounds from another sprite, but not yet from Backpack
			if (item.mycostume != null) {
				addCostume(item.mycostume.duplicate());
				return true;
			}
			if (item.mysound != null) {
				addSound(item.mysound.duplicate());
				return true;
			}
		}
		if (Std.is(obj, Block)) {
			// copy a block/stack to this sprite
			if (targetObj == app.viewedObj())                 return false;  // dropped on my own thumbnail; do nothing  ;
			var copy : Block = cast((obj), Block).duplicate(false, targetObj.isStage);
			copy.x = app.scriptsPane.padding;
			copy.y = app.scriptsPane.padding;
			targetObj.scripts.push(copy);
			return false;
		}
		return false;
	}

	// -----------------------------
	// User interaction
	//------------------------------

	public function click(evt : Event) : Void{
		if (!targetObj.isStage && Std.is(targetObj, ScratchSprite))             app.flashSprite(try cast(targetObj, ScratchSprite) catch(e:Dynamic) null);
		app.selectSprite(targetObj);
	}

	public function menu(evt : MouseEvent) : Menu{
		if (targetObj.isStage)             return null;
		var t : ScratchSprite = try cast(targetObj, ScratchSprite) catch(e:Dynamic) null;
		function hideInScene() : Void{
			t.visible = false;
			t.updateBubble();
		};
		function showInScene() : Void{
			t.visible = true;
			t.updateBubble();
		};
		var m : Menu = t.menu(evt);  // basic sprite menu  
		m.addLine();
		if (t.visible) {
			m.addItem("hide", hideInScene);
		}
		else {
			m.addItem("show", showInScene);
		}
		return m;
	}

	public function handleTool(tool : String, evt : MouseEvent) : Void{
		if (tool == "help")             Scratch.app.showTip("scratchUI");
		var spr : ScratchSprite = try cast(targetObj, ScratchSprite) catch(e:Dynamic) null;
		if (spr == null)             return;
		if (tool == "copy")             spr.duplicateSprite();
		if (tool == "cut")             spr.deleteSprite();
	}

	private function showSpriteDetails(ignore : Dynamic) : Void{
		var lib : LibraryPart = try cast(parent.parent.parent, LibraryPart) catch(e:Dynamic) null;
		if (lib != null)             lib.showSpriteDetails(true);
	}
}

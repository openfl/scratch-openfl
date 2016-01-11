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

// LooksPrims.as
// John Maloney, April 2010
//
// Looks primitives.

package primitives;

import flash.utils.Dictionary;
import blocks.*;
import interpreter.*;
import scratch.*;

class LooksPrims
{

	private var app : Scratch;
	private var interp : Interpreter;

	public function new(app : Scratch, interpreter : Interpreter)
	{
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable : Dictionary) : Void{
		Reflect.setField(primTable, "lookLike:", primShowCostume);
		Reflect.setField(primTable, "nextCostume", primNextCostume);
		Reflect.setField(primTable, "costumeIndex", primCostumeIndex);
		Reflect.setField(primTable, "costumeName", primCostumeName);

		Reflect.setField(primTable, "showBackground:", primShowCostume);  // used by Scratch 1.4 and earlier (doesn't start scene hats)  
		Reflect.setField(primTable, "nextBackground", primNextCostume);  // used by Scratch 1.4 and earlier (doesn't start scene hats)  
		Reflect.setField(primTable, "backgroundIndex", primSceneIndex);
		Reflect.setField(primTable, "sceneName", primSceneName);
		Reflect.setField(primTable, "nextScene", function(b : Dynamic) : Dynamic{startScene("next backdrop", false);
		});
		Reflect.setField(primTable, "startScene", function(b : Dynamic) : Dynamic{startScene(interp.arg(b, 0), false);
		});
		Reflect.setField(primTable, "startSceneAndWait", function(b : Dynamic) : Dynamic{startScene(interp.arg(b, 0), true);
		});

		Reflect.setField(primTable, "say:duration:elapsed:from:", function(b : Dynamic) : Dynamic{showBubbleAndWait(b, "talk");
		});
		Reflect.setField(primTable, "say:", function(b : Dynamic) : Dynamic{showBubble(b, "talk");
		});
		Reflect.setField(primTable, "think:duration:elapsed:from:", function(b : Dynamic) : Dynamic{showBubbleAndWait(b, "think");
		});
		Reflect.setField(primTable, "think:", function(b : Dynamic) : Dynamic{showBubble(b, "think");
		});

		Reflect.setField(primTable, "changeGraphicEffect:by:", primChangeEffect);
		Reflect.setField(primTable, "setGraphicEffect:to:", primSetEffect);
		Reflect.setField(primTable, "filterReset", primClearEffects);

		Reflect.setField(primTable, "changeSizeBy:", primChangeSize);
		Reflect.setField(primTable, "setSizeTo:", primSetSize);
		Reflect.setField(primTable, "scale", primSize);

		Reflect.setField(primTable, "show", primShow);
		Reflect.setField(primTable, "hide", primHide);
		//		primTable['hideAll']				= primHideAll;

		Reflect.setField(primTable, "comeToFront", primGoFront);
		Reflect.setField(primTable, "goBackByLayers:", primGoBack);

		Reflect.setField(primTable, "setVideoState", primSetVideoState);
		Reflect.setField(primTable, "setVideoTransparency", primSetVideoTransparency);

		//		primTable['scrollAlign']			= primScrollAlign;
		//		primTable['scrollRight']			= primScrollRight;
		//		primTable['scrollUp']				= primScrollUp;
		//		primTable['xScroll']				= function(b:*):* { return app.stagePane.xScroll };
		//		primTable['yScroll']				= function(b:*):* { return app.stagePane.yScroll };

		Reflect.setField(primTable, "setRotationStyle", primSetRotationStyle);
	}

	private function primNextCostume(b : Block) : Void{
		var s : ScratchObj = interp.targetObj();
		if (s != null)             s.showCostume(s.currentCostumeIndex + 1);
		if (s.visible)             interp.redraw();
	}

	private function primShowCostume(b : Block) : Void{
		var s : ScratchObj = interp.targetObj();
		if (s == null)             return;
		var arg : Dynamic = interp.arg(b, 0);
		if (Std.is(arg, Float) || Std.is(arg, Int)) {
			s.showCostume(arg - 1);
		}
		else {
			var i : Int = s.indexOfCostumeNamed(arg);
			if (i >= 0) {
				s.showCostume(i);
			}
			else if ("previous costume" == arg) {
				s.showCostume(s.currentCostumeIndex - 1);
			}
			else if ("next costume" == arg) {
				s.showCostume(s.currentCostumeIndex + 1);
			}
			else {
				var n : Float = Interpreter.asNumber(arg);
				if (!Math.isNaN(n))                     s.showCostume(n - 1)
				else return;
			}
		}
		if (s.visible)             interp.redraw();
	}

	private function primCostumeIndex(b : Block) : Float{
		var s : ScratchObj = interp.targetObj();
		return ((s == null)) ? 1 : s.costumeNumber();
	}

	private function primCostumeName(b : Block) : String{
		var s : ScratchObj = interp.targetObj();
		return ((s == null)) ? "" : s.currentCostume().costumeName;
	}

	private function primSceneIndex(b : Block) : Float{
		return app.stagePane.costumeNumber();
	}

	private function primSceneName(b : Block) : String{
		return app.stagePane.currentCostume().costumeName;
	}

	private function startScene(s : String, waitFlag : Bool) : Void{
		if ("next backdrop" == s)             s = backdropNameAt(Std.int(app.stagePane.currentCostumeIndex + 1))
		else if ("previous backdrop" == s)             s = backdropNameAt(Std.int(app.stagePane.currentCostumeIndex - 1))
		else {
			var n : Float = Interpreter.asNumber(s);
			if (!Math.isNaN(n)) {
				n = (Math.round(n) - 1) % app.stagePane.costumes.length;
				if (n < 0)                     n += app.stagePane.costumes.length;
				s = app.stagePane.costumes[Std.int(n)].costumeName;
			}
		}
		interp.startScene(s, waitFlag);
	}

	private function backdropNameAt(i : Int) : String{
		var costumes : Array<Dynamic> = app.stagePane.costumes;
		return costumes[(i + costumes.length) % costumes.length].costumeName;
	}

	private function showBubbleAndWait(b : Block, type : String) : Void{
		var text : Dynamic;
		var secs : Float;
		var s : ScratchSprite = interp.targetSprite();
		if (s == null)             return;
		if (interp.activeThread.firstTime) {
			text = interp.arg(b, 0);
			secs = interp.numarg(b, 1);
			s.showBubble(text, type, b);
			if (s.visible)                 interp.redraw();
			interp.startTimer(secs);
		}
		else {
			if (interp.checkTimer() && s.bubble != null && (s.bubble.getSource() == b)) {
				s.hideBubble();
			}
		}
	}

	private function showBubble(b : Block, type : String = null) : Void{
		var text : Dynamic;
		var secs : Float;
		var s : ScratchSprite = interp.targetSprite();
		if (s == null)             return;
		if (type == null) {  // combined talk/think/shout/whisper command  
			type = interp.arg(b, 0);
			text = interp.arg(b, 1);
		}
		else {  // talk or think command  
			text = interp.arg(b, 0);
		}
		s.showBubble(text, type, b);
		if (s.visible)             interp.redraw();
	}

	private function primChangeEffect(b : Block) : Void{
		var s : ScratchObj = interp.targetObj();
		if (s == null)             return;
		var filterName : String = interp.arg(b, 0);
		var delta : Float = interp.numarg(b, 1);
		if (delta == 0)             return;

		var newValue : Float = s.filterPack.getFilterSetting(filterName) + delta;
		s.filterPack.setFilter(filterName, newValue);
		s.applyFilters();
		if (s.visible || s == Scratch.app.stagePane)             interp.redraw();
	}

	private function primSetEffect(b : Block) : Void{
		var s : ScratchObj = interp.targetObj();
		if (s == null)             return;
		var filterName : String = interp.arg(b, 0);
		var newValue : Float = interp.numarg(b, 1);
		if (s.filterPack.setFilter(filterName, newValue)) 
			s.applyFilters();
		if (s.visible || s == Scratch.app.stagePane)             interp.redraw();
	}

	private function primClearEffects(b : Block) : Void{
		var s : ScratchObj = interp.targetObj();
		s.clearFilters();
		s.applyFilters();
		if (s.visible || s == Scratch.app.stagePane)             interp.redraw();
	}

	private function primChangeSize(b : Block) : Void{
		var s : ScratchSprite = interp.targetSprite();
		if (s == null)             return;
		var oldScale : Float = s.scaleX;
		s.setSize(s.getSize() + interp.numarg(b, 0));
		if (s.visible && (s.scaleX != oldScale))             interp.redraw();
	}

	private function primSetRotationStyle(b : Block) : Void{
		var s : ScratchSprite = interp.targetSprite();
		var newStyle : String = try cast(interp.arg(b, 0), String) catch(e:Dynamic) null;
		if ((s == null) || (newStyle == null))             return;
		s.setRotationStyle(newStyle);
	}

	private function primSetSize(b : Block) : Void{
		var s : ScratchSprite = interp.targetSprite();
		if (s == null)             return;
		s.setSize(interp.numarg(b, 0));
		if (s.visible)             interp.redraw();
	}

	private function primSize(b : Block) : Float{
		var s : ScratchSprite = interp.targetSprite();
		if (s == null)             return 100;
		return Math.round(s.getSize());
	}

	private function primShow(b : Block) : Void{
		var s : ScratchSprite = interp.targetSprite();
		if (s == null)             return;
		s.visible = true;
		if (!app.isIn3D)             s.applyFilters();
		s.updateBubble();
		if (s.visible)             interp.redraw();
	}

	private function primHide(b : Block) : Void{
		var s : ScratchSprite = interp.targetSprite();
		if ((s == null) || !s.visible)             return;
		s.visible = false;
		if (!app.isIn3D)             s.applyFilters();
		s.updateBubble();
		interp.redraw();
	}

	private function primHideAll(b : Block) : Void{
		// Hide all sprites and delete all clones. Only works from the stage.
		if (!interp.targetObj().isStage)             return;
		app.stagePane.deleteClones();
		for (i in 0...app.stagePane.numChildren){
			var o : Dynamic = app.stagePane.getChildAt(i);
			if (Std.is(o, ScratchSprite)) {
				o.visible = false;
				o.updateBubble();
			}
		}
		interp.redraw();
	}

	private function primGoFront(b : Block) : Void{
		var s : ScratchSprite = interp.targetSprite();
		if ((s == null) || (s.parent == null))             return;
		s.parent.setChildIndex(s, s.parent.numChildren - 1);
		if (s.visible)             interp.redraw();
	}

	private function primGoBack(b : Block) : Void{
		var s : ScratchSprite = interp.targetSprite();
		if ((s == null) || (s.parent == null))             return;
		var newIndex : Int = Std.int(s.parent.getChildIndex(s) - interp.numarg(b, 0));
		newIndex = Std.int(Math.max(minSpriteLayer(), Math.min(newIndex, s.parent.numChildren - 1)));

		if (newIndex > 0 && newIndex < s.parent.numChildren) {
			s.parent.setChildIndex(s, newIndex);
			if (s.visible)                 interp.redraw();
		}
	}

	private function minSpriteLayer() : Int{
		// Return the lowest sprite layer.
		var stg : ScratchStage = app.stagePane;
		return stg.getChildIndex((stg.videoImage != null) ? stg.videoImage : stg.penLayer) + 1;
	}

	private function primSetVideoState(b : Block) : Void{
		app.stagePane.setVideoState(interp.arg(b, 0));
	}

	private function primSetVideoTransparency(b : Block) : Void{
		app.stagePane.setVideoTransparency(interp.numarg(b, 0));
		app.stagePane.setVideoState("on");
	}

	private function primScrollAlign(b : Block) : Void{
		if (!interp.targetObj().isStage)             return;
		app.stagePane.scrollAlign(interp.arg(b, 0));
	}

	private function primScrollRight(b : Block) : Void{
		if (!interp.targetObj().isStage)             return;
		app.stagePane.scrollRight(interp.numarg(b, 0));
	}

	private function primScrollUp(b : Block) : Void{
		if (!interp.targetObj().isStage)             return;
		app.stagePane.scrollUp(interp.numarg(b, 0));
	}
}

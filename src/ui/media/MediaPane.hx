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


import flash.display.Sprite;
import flash.geom.Point;
import flash.text.TextField;
import assets.Resources;
import scratch.*;
import ui.parts.SoundsPart;
import uiwidgets.*;

class MediaPane extends ScrollFrameContents
{

	public var app : Scratch;

	private var isSound : Bool;
	private var lastCostume : ScratchCostume;

	public function new(app : Scratch, type : String)
	{
		super();
		this.app = app;
		isSound = (type == "sounds");
		refresh();
	}

	public function refresh() : Void{
		if (app.viewedObj() == null)             return;
		replaceContents((isSound) ? soundItems() : costumeItems());
		updateSelection();
	}

	// Returns true if we might need to save
	public function updateSelection() : Bool{
		if (isSound) {
			updateSoundSelection();
			return true;
		}

		return updateCostumeSelection();
	}

	private function replaceContents(newItems : Array<Dynamic>) : Void{
		while (numChildren > 0)removeChildAt(0);
		var nextY : Int = 3;
		var n : Int = 1;
		for (item in newItems){
			var numLabel : TextField = Resources.makeLabel("" + n++, CSS.thumbnailExtraInfoFormat);
			numLabel.x = 9;
			numLabel.y = nextY + 1;
			item.x = 7;
			item.y = nextY;
			nextY += item.height + 3;
			addChild(item);
			addChild(numLabel);
		}
		updateSize();
		lastCostume = null;
		x = y = 0;
	}

	private function costumeItems() : Array<Dynamic>{
		var result : Array<Dynamic> = [];
		var viewedObj : ScratchObj = app.viewedObj();
		for (c in viewedObj.costumes){
			result.push(Scratch.app.createMediaInfo(c, viewedObj));
		}
		return result;
	}

	private function soundItems() : Array<Dynamic>{
		var result : Array<Dynamic> = [];
		var viewedObj : ScratchObj = app.viewedObj();
		for (snd in viewedObj.sounds){
			result.push(Scratch.app.createMediaInfo(snd, viewedObj));
		}
		return result;
	}

	// Returns true if the costume changed
	private function updateCostumeSelection() : Bool{
		var viewedObj : ScratchObj = app.viewedObj();
		if ((viewedObj == null) || isSound)             return false;
		var current : ScratchCostume = viewedObj.currentCostume();
		if (current == lastCostume)             return false;
		var oldCostume : ScratchCostume = lastCostume;
		for (i in 0...numChildren) {
			var child = getChildAt(i);
			if (Std.is(getChildAt(i), MediaInfo)) {
				var ci : MediaInfo = cast(getChildAt(i), MediaInfo);
				if (ci.mycostume == current) {
					ci.highlight();
					scrollToItem(ci);
				}
				else {
					ci.unhighlight();
				}
			}
		}
		lastCostume = current;
		return (oldCostume != null);
	}

	private function scrollToItem(item : MediaInfo) : Void{
		var frame : ScrollFrame = try cast(parent, ScrollFrame) catch(e:Dynamic) null;
		if (frame == null)             return;
		var itemTop : Int = Std.int(item.y + y - 1);
		var itemBottom : Int = Std.int(itemTop + item.height);
		y -= Math.max(0, itemBottom - frame.visibleH());
		y -= Math.min(0, itemTop);
		frame.updateScrollbars();
	}

	private function updateSoundSelection() : Void{
		var viewedObj : ScratchObj = app.viewedObj();
		if ((viewedObj == null) || !isSound)             return;
		if (viewedObj.sounds.length < 1)             return;
		if (this.parent == null || this.parent.parent == null)             return;
		var sp : SoundsPart = try cast(this.parent.parent, SoundsPart) catch(e:Dynamic) null;
		if (sp == null)             return;
		sp.currentIndex = Std.int(Math.min(sp.currentIndex, viewedObj.sounds.length - 1));
		var current : ScratchSound = try cast(viewedObj.sounds[sp.currentIndex], ScratchSound) catch(e:Dynamic) null;
		for (i in 0...numChildren){
			if (Std.is(getChildAt(i), MediaInfo)) {
				var si : MediaInfo = cast(getChildAt(i), MediaInfo);
				if (si.mysound == current)                     si.highlight()
				else si.unhighlight();
			}
		}
	}

	// -----------------------------
	// Dropping
	//------------------------------

	public function handleDrop(obj : Dynamic) : Bool{
		var item : MediaInfo = try cast(obj, MediaInfo) catch(e:Dynamic) null;
		if (item != null && item.owner == app.viewedObj()) {
			changeMediaOrder(item);
			return true;
		}
		return false;
	}

	private function changeMediaOrder(dropped : MediaInfo) : Void{
		var inserted : Bool = false;
		var newItems : Array<Dynamic> = [];
		var dropY : Int = Std.int(globalToLocal(new Point(dropped.x, dropped.y)).y);
		var i: Int = 0;
		while (i < numChildren) {
			var item : MediaInfo = try cast(getChildAt(i), MediaInfo) catch(e:Dynamic) null;
			if (item == null)                 {
				i++;
				i++;
				continue;
			}  // skip item numbers  ;
			if (!inserted && (dropY < item.y)) {
				newItems.push(dropped);
				inserted = true;
			}
			if (!sameMedia(item, dropped))                 newItems.push(item);
			i++;
		}
		if (!inserted)             newItems.push(dropped);
		replacedMedia(newItems);
	}

	private function sameMedia(item1 : MediaInfo, item2 : MediaInfo) : Bool{
		if (item1.mycostume  != null&& (item1.mycostume == item2.mycostume))             return true;
		if (item1.mysound != null && (item1.mysound == item2.mysound))             return true;
		return false;
	}

	private function replacedMedia(newList : Array<Dynamic>) : Void{
		// Note: Clones can share the costume and sound arrays with their prototype,
		// so this method mutates those arrays in place rather than replacing them.
		var el : MediaInfo;
		var scratchObj : ScratchObj = app.viewedObj();
		if (isSound) {
			scratchObj.sounds.splice(0, scratchObj.sounds.length);  // remove all  
			for (el in newList){
				if (el.mysound)                     scratchObj.sounds.push(el.mysound);
			}
		}
		else {
			var oldCurrentCostume : ScratchCostume = scratchObj.currentCostume();
			scratchObj.costumes.splice(0, scratchObj.costumes.length);  // remove all  
			for (el in newList){
				if (el.mycostume)                     scratchObj.costumes.push(el.mycostume);
			}
			var cIndex : Int = scratchObj.costumes.indexOf(oldCurrentCostume);
			if (cIndex > -1)                 scratchObj.currentCostumeIndex = cIndex;
		}
		app.setSaveNeeded();
		refresh();
	}
}

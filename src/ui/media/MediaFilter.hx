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

// MediaFilter.as
// John Maloney, February 2013

package ui.media;


import flash.display.*;
import flash.text.*;
import assets.Resources;
import translation.Translator;
import flash.events.MouseEvent;

class MediaFilter extends Sprite
{
	public var currentSelection(get, set) : String;


	private var titleFormat : TextFormat = new TextFormat(CSS.font, 15, CSS.buttonLabelOverColor, false);
	private var selectorFormat : TextFormat = new TextFormat(CSS.font, 14, CSS.textColor);

	private var unselectedColor : UInt = CSS.overColor;  // 0x909090;  
	private var selectedColor : UInt = CSS.textColor;
	private var rolloverColor : UInt = CSS.buttonLabelOverColor;

	private var title : TextField;
	private var selectorNames : Array<Dynamic> = [];  // strings representing tags/themes/categories  
	private var selectors : Array<Dynamic> = [];  // TextFields (translated)  
	private var selection : String = "";
	private var whenChanged : Dynamic->Void;

	public function new(filterName : String, elements : Array<Dynamic>, whenChanged : Dynamic->Void= null)
	{
		super();
		addChild(title = Resources.makeLabel(Translator.map(filterName), titleFormat));
		this.whenChanged = whenChanged;
		for (selName in elements)addSelector(selName);
		select(0);  // select first selector by default  
		fixLayout();
	}

	private function set_currentSelection(s : String) : String{select(Lambda.indexOf(selectorNames, s));
		return s;
	}
	private function get_currentSelection() : String{return selection;
	}

	private function fixLayout() : Void{
		title.x = title.y = 0;
		var nextY : Int = Std.int(title.height + 2);
		for (sel in selectors){
			sel.x = 15;
			sel.y = nextY;
			nextY += sel.height;
		}
	}

	private function addSelectors(selList : Array<Dynamic>) : Void{
		for (selName in selList)addSelector(selName);
	}

	private function addSelector(selName : String) : Void{
		var sel : TextField = Resources.makeLabel(Translator.map(selName), selectorFormat);
		function mouseDown(ignore : Dynamic) : Void{
			select(Lambda.indexOf(selectorNames, selName));
			if (whenChanged != null)                 whenChanged(sel.parent);
		};
		sel.addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		sel.addEventListener(MouseEvent.MOUSE_OUT, mouseOver);
		sel.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		selectorNames.push(selName);
		selectors.push(sel);
		addChild(sel);
	}

	private function mouseOver(evt : MouseEvent) : Void{
		var sel : TextField = try cast(evt.target, TextField) catch(e:Dynamic) null;
		if (sel.textColor != selectedColor) {
			sel.textColor = ((evt.type == MouseEvent.MOUSE_OVER)) ? rolloverColor : unselectedColor;
		}
	}

	private function select(index : Int) : Void{
		// Highlight the new selection and unlight all others.
		selection = "";  // nothing selected  
		var fmt : TextFormat = new TextFormat();
		for (i in 0...selectors.length){
			if (i == index) {
				selection = selectorNames[i];
				fmt.bold = true;
				selectors[i].setTextFormat(fmt);
				selectors[i].textColor = selectedColor;
			}
			else {
				fmt.bold = false;
				selectors[i].setTextFormat(fmt);
				selectors[i].textColor = unselectedColor;
			}
		}
	}
}

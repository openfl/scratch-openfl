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

// IconButton.as
// John Maloney, December 2010
//
// An IconButton is a button that draws itself using an image. An optional second
// image can be used to display the on/off state of the button. If the 'isRadioButton'
// flag is set, then turning on one IconButton will turn off all other IconButton
// children of its parent that also have 'isRadioButton' set. (That is, only one of
// the radio button children of a given parent can be on.) The optional clickFunction
// is called when the user clicks on the IconButton.

package uiwidgets;

import CSS;
import openfl.display.*;
import openfl.events.MouseEvent;
import openfl.text.*;
import assets.Resources;

class IconButton extends Sprite
{

	public var clickFunction : Dynamic->Void;
	public var isRadioButton : Bool;  // if true then other button children of my parent will be turned off when I'm turned on  
	public var isMomentary : Bool;  // if true then button does not remain on when clicked  
	public var lastEvent : MouseEvent;
	public var clientData : Dynamic;

	private var buttonIsOn : Bool;
	private var mouseIsOver : Bool;
	private var onImage : DisplayObject;
	private var offImage : DisplayObject;

	public function new(clickFunction : Dynamic->Void, onImageOrName : Dynamic, offImageObj : DisplayObject = null, isRadioButton : Bool = false)
	{
		super();
		this.clickFunction = clickFunction;
		this.isRadioButton = isRadioButton;
		useDefaultImages();
		setImage(onImageOrName, offImageObj);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
		mouseChildren = false;
	}

	public function actOnMouseUp() : Void{
		removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(MouseEvent.MOUSE_UP, mouseDown);
	}

	public function disableMouseover() : Void{
		removeEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		removeEventListener(MouseEvent.MOUSE_OUT, mouseOut);
	}

	public function setImage(onImageObjOrName : Dynamic, offImageObj : DisplayObject = null) : Void{
		if (Std.is(onImageObjOrName, String)) {
			// specify on/off images by asset name
			var assetName : String = onImageObjOrName;
			onImage = Resources.createBmp(assetName + "On");
			offImage = Resources.createBmp(assetName + "Off");
		}
		else if (Std.is(onImageObjOrName, DisplayObject)) {
			// on/off images are supplied
			onImage = cast(onImageObjOrName, DisplayObject);
			offImage = ((offImageObj == null)) ? onImage : offImageObj;
		}
		redraw();
	}

	public function turnOff() : Void{
		if (!buttonIsOn)             return;
		buttonIsOn = false;
		redraw();
	}

	public function turnOn() : Void{
		if (buttonIsOn)             return;
		buttonIsOn = true;
		redraw();
	}

	public function setOn(flag : Bool) : Void{
		if (flag)             turnOn()
		else turnOff();
	}

	public function isOn() : Bool{return buttonIsOn;
	}
	public function right() : Int{return Std.int(x + width);
	}
	public function bottom() : Int{return Std.int(y + height);
	}

	public function isDisabled() : Bool{return alpha < 1;
	}
	public function setDisabled(disabledFlag : Bool, disabledAlpha : Float = 0.0) : Void{
		alpha = (disabledFlag) ? disabledAlpha : 1;
		if (disabledFlag) {mouseIsOver = false;turnOff();
		}
		mouseEnabled = !disabledFlag;
	}

	public function setLabel(s : String, onColor : Int, offColor : Int, dropDownArrow : Bool = false) : Void{
		// Set my off/on images to the given string and colors.
		// If dropDownArrow, add a drop-down arrow after the label.
		setImage(
				makeLabelSprite(s, offColor, dropDownArrow),
				makeLabelSprite(s, onColor, dropDownArrow));
		isMomentary = true;
	}

	private function makeLabelSprite(s : String, labelColor : Int, dropDownArrow : Bool) : Sprite{
		var label : TextField = Resources.makeLabel(s, CSS.topBarButtonFormat);
		label.textColor = labelColor;
		var img : Sprite = new Sprite();
		img.addChild(label);
		if (dropDownArrow)             img.addChild(menuArrow(Std.int(label.textWidth + 6), 6, labelColor));
		return img;
	}

	private function menuArrow(x : Int, y : Int, c : Int) : Shape{
		var arrow : Shape = new Shape();
		var g : Graphics = arrow.graphics;
		g.beginFill(c);
		g.lineTo(8, 0);
		g.lineTo(4, 6);
		g.lineTo(0, 0);
		g.endFill();
		arrow.x = x;
		arrow.y = y;
		return arrow;
	}

	private function redraw() : Void{
		var img : DisplayObject = (buttonIsOn) ? onImage : offImage;
		if (mouseIsOver && !buttonIsOn)             img = onImage;
		while (numChildren > 0)removeChildAt(0);
		addChild(img);
		// Make the entire button rectangle be mouse-sensitive:
		graphics.clear();
		graphics.beginFill(0xA0, 0);  // invisible but mouse-sensitive; min size 10x10  
		graphics.drawRect(0, 0, Math.max(10, img.width), Math.max(10, img.height));
		graphics.endFill();
	}

	private function mouseDown(e : MouseEvent) : Void{
		if (isDisabled())             return;
		if (CursorTool.tool == "help")             return;  // ignore mouseDown events with help tool (this doesn't apply to 'actOnMouseUp' buttons)  ;
		if (isRadioButton) {
			if (buttonIsOn)                 return;  // user must click on another radio button to turn this button off  ;
			turnOffOtherRadioButtons();
		}
		buttonIsOn = !buttonIsOn;
		redraw();
		if (clickFunction != null) {
			lastEvent = e;
			clickFunction(this);
			lastEvent = null;
		}
		if (isMomentary)             buttonIsOn = false
		else mouseIsOver = false;
		redraw();
	}

	private function mouseOver(evt : MouseEvent) : Void{if (!isDisabled()) {mouseIsOver = true;redraw();
		}
	}
	private function mouseOut(evt : MouseEvent) : Void{if (!isDisabled()) {mouseIsOver = false;redraw();
		}
	}

	private function turnOffOtherRadioButtons() : Void{
		if (parent == null)             return;
		for (i in 0...parent.numChildren){
			var b : Dynamic = parent.getChildAt(i);
			if ((Std.is(b, IconButton)) && (b.isRadioButton) && (b != this))                 b.turnOff();
		}
	}

	private function useDefaultImages() : Void{
		// Use default images (empty and filled circles, appropriate for a radio button)
		var color : Int = 0x373737;
		offImage = new Sprite();
		var g : Graphics = cast((offImage), Sprite).graphics;
		g.lineStyle(1, color);
		g.beginFill(0, 0);  // transparent fill allows button to get mouse clicks  
		g.drawCircle(6, 6, 6);
		onImage = new Sprite();
		g = cast((onImage), Sprite).graphics;
		g.lineStyle(1, color);
		g.beginFill(0, 0);  // transparent fill allows button to get mouse clicks  
		g.drawCircle(6, 6, 6);
		g.beginFill(color);
		g.drawCircle(6, 6, 4);
		g.endFill();
	}
}

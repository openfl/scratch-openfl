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

package uiwidgets;

import CSS;
import flash.display.*;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.text.*;

class Button extends Sprite
{

	private var labelOrIcon : DisplayObject;
	private var color : Dynamic = CSS.titleBarColors;
	private var minWidth : Int = 50;
	private var compact : Bool;

	private var action : Void->Void;  // takes no arguments  
	private var eventAction : Dynamic->Void;  // like action, but takes the event as an argument  
	private var tipName : String;

	public function new(label : String, action : Void->Void= null, compact : Bool = false, tipName : String = null)
	{
		super();
		this.action = action;
		this.compact = compact;
		this.tipName = tipName;
		addLabel(label);
		mouseChildren = false;
		addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		setColor(CSS.titleBarColors);
	}

	public function setLabel(s : String) : Void{
		if (Std.is(labelOrIcon, TextField)) {
			cast((labelOrIcon), TextField).text = s;
			setMinWidthHeight(0, 0);
		}
		else {
			if ((labelOrIcon != null) && (labelOrIcon.parent != null))                 labelOrIcon.parent.removeChild(labelOrIcon);
			addLabel(s);
		}
	}

	public function setIcon(icon : DisplayObject) : Void{
		if ((labelOrIcon != null) && (labelOrIcon.parent != null)) {
			labelOrIcon.parent.removeChild(labelOrIcon);
		}
		labelOrIcon = icon;
		if (icon != null)             addChild(labelOrIcon);
		setMinWidthHeight(0, 0);
	}

	public function setMinWidthHeight(minW : Int, minH : Int) : Void{
		if (labelOrIcon != null) {
			if (Std.is(labelOrIcon, TextField)) {
				minW = Std.int(Math.max(minWidth, labelOrIcon.width + 11));
				minH = (compact) ? 20 : 25;
			}
			else {
				minW = Std.int(Math.max(minWidth, labelOrIcon.width + 12));
				minH = Std.int(Math.max(minH, labelOrIcon.height + 11));
			}
			labelOrIcon.x = ((minW - labelOrIcon.width) / 2);
			labelOrIcon.y = ((minH - labelOrIcon.height) / 2);
		}  // outline  

		graphics.clear();
		graphics.lineStyle(0.5, CSS.borderColor, 1, true);
		if (Std.is(color, Array)) {
			var matr : Matrix = new Matrix();
			matr.createGradientBox(minW, minH, Math.PI / 2, 0, 0);
			graphics.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors, [100, 100], [0x00, 0xFF], matr);
		}
		else graphics.beginFill(color);
		graphics.drawRoundRect(0, 0, minW, minH, 12);
		graphics.endFill();
	}

	public function setEventAction(newEventAction : Dynamic->Void) : Dynamic->Void{
		var oldEventAction : Dynamic->Void = eventAction;
		eventAction = newEventAction;
		return oldEventAction;
	}

	private function mouseOver(evt : MouseEvent) : Void{
		setColor(CSS.overColor);
	}

	private function mouseOut(evt : MouseEvent) : Void{
		setColor(CSS.titleBarColors);
	}

	private function mouseDown(evt : MouseEvent) : Void{
		Menu.removeMenusFrom(stage);
	}

	private function mouseUp(evt : MouseEvent) : Void{
		if (action != null)             action();
		if (eventAction != null)             eventAction(evt);
		evt.stopImmediatePropagation();
	}

	public function handleTool(tool : String, evt : MouseEvent) : Void{
		if (tool == "help" && tipName != null)             Scratch.app.showTip(tipName);
	}

	private function setColor(c : Dynamic) : Void{
		color = c;
		if (Std.is(labelOrIcon, TextField)) {
			(try cast(labelOrIcon, TextField) catch(e:Dynamic) null).textColor = ((c == CSS.overColor)) ? CSS.white : CSS.buttonLabelColor;
		}
		setMinWidthHeight(5, 5);
	}

	private function addLabel(s : String) : Void{
		var label : TextField = new TextField();
		label.autoSize = TextFieldAutoSize.LEFT;
		label.selectable = false;
		label.background = false;
		label.defaultTextFormat = CSS.normalTextFormat;
		label.textColor = CSS.buttonLabelColor;
		label.text = s;
		labelOrIcon = label;
		setMinWidthHeight(0, 0);
		addChild(label);
	}
}


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


import openfl.display.*;
import openfl.text.*;
import assets.Resources;
import translation.Translator;

class VariableSettings extends Sprite
{

	public var isLocal : Bool;

	public var isList : Bool;
	private var isStage : Bool;

	private var globalButton : IconButton;
	private var globalLabel : TextField;
	private var localButton : IconButton;
	private var localLabel : TextField;

	public function new(isList : Bool, isStage : Bool)
	{
		super();
		this.isList = isList;
		this.isStage = isStage;
		addLabels();
		addButtons();
		fixLayout();
		updateButtons();
	}

	public static function strings() : Array<String>{
		return ["For this sprite only", "For all sprites", "list", "variable"];
	}

	private function addLabels() : Void{
		addChild(localLabel = Resources.makeLabel(
								Translator.map("For this sprite only"), CSS.normalTextFormat));

		addChild(globalLabel = Resources.makeLabel(
								Translator.map("For all sprites"), CSS.normalTextFormat));
	}

	private function addButtons() : Void{
		function setLocal(b : IconButton) : Void{isLocal = true;updateButtons();
		};
		function setGlobal(b : IconButton) : Void{isLocal = false;updateButtons();
		};
		addChild(localButton = new IconButton(setLocal, null));
		addChild(globalButton = new IconButton(setGlobal, null));
	}

	private function updateButtons() : Void{
		localButton.setOn(isLocal);
		localButton.setDisabled(false, 0.2);
		localLabel.alpha = 1;
		globalButton.setOn(!isLocal);
	}

	private function fixLayout() : Void{
		var nextX : Int = 0;
		var baseY : Int = 10;

		globalButton.x = nextX;
		globalButton.y = baseY + 3;
		globalLabel.x = (nextX += 16);
		globalLabel.y = baseY;

		nextX += Std.int(globalLabel.textWidth + 20);

		localButton.x = nextX;
		localButton.y = baseY + 3;
		localLabel.x = (nextX += 16);
		localLabel.y = baseY;

		nextX = 15;
		if (isStage) {
			localButton.visible = false;
			localLabel.visible = false;
			globalButton.x = nextX;
			globalLabel.x = nextX + 16;
		}
	}

	private function drawLine() : Void{
		var lineY : Int = 36;
		var w : Int = Std.int(getRect(this).width);
		if (isStage)             w += 10;
		var g : Graphics = graphics;
		g.clear();
		g.beginFill(0xD0D0D0);
		g.drawRect(0, lineY, w, 1);
		g.beginFill(0x909090);
		g.drawRect(0, lineY + 1, w, 1);
		g.endFill();
	}
}

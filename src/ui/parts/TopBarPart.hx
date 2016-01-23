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

// TopBarPart.as
// John Maloney, November 2011
//
// This part holds the Scratch Logo, cursor tools, screen mode buttons, and more.

package ui.parts;


import assets.Resources;

//import extensions.ExtensionDevManager;

import openfl.display.*;
import openfl.events.MouseEvent;
import openfl.text.*;

import translation.Translator;

import uiwidgets.*;

class TopBarPart extends UIPart
{

	private var shape : Shape;
	private var logoButton : IconButton;
	private var languageButton : IconButton;

	private var fileMenu : IconButton;
	private var editMenu : IconButton;

	private var copyTool : IconButton;
	private var cutTool : IconButton;
	private var growTool : IconButton;
	private var shrinkTool : IconButton;
	private var helpTool : IconButton;
	private var toolOnMouseDown : String;

	private var offlineNotice : TextField;
	private var offlineNoticeFormat : TextFormat = new TextFormat(CSS.font, 13, CSS.white, true);

	private var loadExperimentalButton : Button;
	private var exportButton : Button;
	private var extensionLabel : TextField;

	public function new(app : Scratch)
	{
		super();
		this.app = app;
		addButtons();
		refresh();
	}

	private function addButtons() : Void{
		addChild(shape = new Shape());
		addChild(languageButton = new IconButton(app.setLanguagePressed, "languageButton"));
		languageButton.isMomentary = true;
		addTextButtons();
		addToolButtons();
		if (Scratch.app.isExtensionDevMode) {
			addChild(logoButton = new IconButton(app.logoButtonPressed, Resources.createBmp("scratchxlogo")));
			var desiredButtonHeight : Float = 20;
			logoButton.scaleX = logoButton.scaleY = 1;
			var scale : Float = desiredButtonHeight / logoButton.height;
			logoButton.scaleX = logoButton.scaleY = scale;

			addChild(exportButton = new Button("Save Project", function() : Void{app.exportProjectToFile();
							}));
			addChild(extensionLabel = UIPart.makeLabel("My Extension", offlineNoticeFormat, 2, 2));

			//var extensionDevManager : ExtensionDevManager = try cast(Scratch.app.extensionManager, ExtensionDevManager) catch(e:Dynamic) null;
			//if (extensionDevManager != null) {
				//addChild(loadExperimentalButton = extensionDevManager.makeLoadExperimentalExtensionButton());
			//}
		}
	}

	public static function strings() : Array<String>{
		if (Scratch.app != null) {
			Scratch.app.showFileMenu(Menu.dummyButton());
			Scratch.app.showEditMenu(Menu.dummyButton());
		}
		return ["File", "Edit", "Tips", "Duplicate", "Delete", "Grow", "Shrink", "Block help", "Offline Editor"];
	}

	private function removeTextButtons() : Void{
		if (fileMenu.parent != null) {
			removeChild(fileMenu);
			removeChild(editMenu);
		}
	}

	public function updateTranslation() : Void{
		removeTextButtons();
		addTextButtons();
		if (offlineNotice != null)             offlineNotice.text = Translator.map("Offline Editor");
		refresh();
	}

	public function setWidthHeight(w : Int, h : Int) : Void{
		this.w = w;
		this.h = h;
		var g : Graphics = shape.graphics;
		g.clear();
		g.beginFill(CSS.topBarColor());
		g.drawRect(0, 0, w, h);
		g.endFill();
		fixLayout();
	}

	private function fixLogoLayout() : Int{
		var nextX : Int = 9;
		if (logoButton != null) {
			logoButton.x = nextX;
			logoButton.y = 5;
			nextX += Std.int(logoButton.width + buttonSpace);
		}
		return nextX;
	}

	private var buttonSpace : Int = 12;
	private function fixLayout() : Void{
		var buttonY : Int = 5;

		var nextX : Int = fixLogoLayout();

		languageButton.x = nextX;
		languageButton.y = buttonY - 1;
		nextX += Std.int(languageButton.width + buttonSpace);

		// new/more/tips buttons
		fileMenu.x = nextX;
		fileMenu.y = buttonY;
		nextX += Std.int(fileMenu.width + buttonSpace);

		editMenu.x = nextX;
		editMenu.y = buttonY;
		nextX += Std.int(editMenu.width + buttonSpace);

		// cursor tool buttons
		var space : Int = 3;
		copyTool.x = (app.isOffline) ? 493 : 427;
		cutTool.x = copyTool.right() + space;
		growTool.x = cutTool.right() + space;
		shrinkTool.x = growTool.right() + space;
		helpTool.x = shrinkTool.right() + space;
		copyTool.y = cutTool.y = shrinkTool.y = growTool.y = helpTool.y = buttonY - 3;

		if (offlineNotice != null) {
			offlineNotice.x = w - offlineNotice.width - 5;
			offlineNotice.y = 5;
		}  // From here down, nextX is the next item's right edge and decreases after each item  



		nextX = w - 5;

		if (loadExperimentalButton != null) {
			loadExperimentalButton.x = nextX - loadExperimentalButton.width;
			loadExperimentalButton.y = h + 5;
		}

		if (exportButton != null) {
			exportButton.x = nextX - exportButton.width;
			exportButton.y = h + 5;
			nextX = Std.int(exportButton.x - 5);
		}

		if (extensionLabel != null) {
			extensionLabel.x = nextX - extensionLabel.width;
			extensionLabel.y = h + 5;
			nextX = Std.int(extensionLabel.x - 5);
		}
	}

	public function refresh() : Void{
		if (app.isOffline) {
			helpTool.visible = app.isOffline;
		}

		if (Scratch.app.isExtensionDevMode) {
			var hasExperimental : Bool = false; // app.extensionManager.hasExperimentalExtensions();
			exportButton.visible = hasExperimental;
			extensionLabel.visible = hasExperimental;
			loadExperimentalButton.visible = !hasExperimental;

			//var extensionDevManager : ExtensionDevManager = try cast(app.extensionManager, ExtensionDevManager) catch(e:Dynamic) null;
			//if (extensionDevManager != null) {
				//extensionLabel.text = extensionDevManager.getExperimentalExtensionNames().join(", ");
			//}
		}
		fixLayout();
	}

	private function addTextButtons() : Void{
		addChild(fileMenu = UIPart.makeMenuButton("File", app.showFileMenu, true));
		addChild(editMenu = UIPart.makeMenuButton("Edit", app.showEditMenu, true));
	}

	private function addToolButtons() : Void{
		function selectTool(b : IconButton) : Void{
			var newTool : String = "";
			if (b == copyTool)                 newTool = "copy";
			if (b == cutTool)                 newTool = "cut";
			if (b == growTool)                 newTool = "grow";
			if (b == shrinkTool)                 newTool = "shrink";
			if (b == helpTool)                 newTool = "help";
			if (newTool == toolOnMouseDown) {
				clearToolButtons();
				CursorTool.setTool(null);
			}
			else {
				clearToolButtonsExcept(b);
				CursorTool.setTool(newTool);
			}
		};

		addChild(copyTool = makeToolButton("copyTool", selectTool));
		addChild(cutTool = makeToolButton("cutTool", selectTool));
		addChild(growTool = makeToolButton("growTool", selectTool));
		addChild(shrinkTool = makeToolButton("shrinkTool", selectTool));
		addChild(helpTool = makeToolButton("helpTool", selectTool));

		SimpleTooltips.add(copyTool, [
					"text" => "Duplicate",
					"direction" => "bottom",

				]);
		SimpleTooltips.add(cutTool, [
					"text" => "Delete",
					"direction" => "bottom",

				]);
		SimpleTooltips.add(growTool, [
					"text" => "Grow",
					"direction" => "bottom",

				]);
		SimpleTooltips.add(shrinkTool, [
					"text" => "Shrink",
					"direction" => "bottom",

				]);
		SimpleTooltips.add(helpTool, [
					"text" => "Block help",
					"direction" => "bottom",

				]);
	}

	public function clearToolButtons() : Void{
		clearToolButtonsExcept(null);
	}

	private function clearToolButtonsExcept(activeButton : IconButton) : Void{
		for (b in [copyTool, cutTool, growTool, shrinkTool, helpTool]){
			if (b != activeButton)                 b.turnOff();
		}
	}

	private function makeToolButton(iconName : String, fcn : Dynamic->Void) : IconButton{
		function mouseDown(evt : MouseEvent) : Void{
			toolOnMouseDown = CursorTool.tool;
		};

		var onImage : Sprite = toolButtonImage(iconName, CSS.overColor, 1);
		var offImage : Sprite = toolButtonImage(iconName, 0, 0);
		var b : IconButton = new IconButton(fcn, onImage, offImage);
		b.actOnMouseUp();
		b.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);  // capture tool on mouse down to support deselecting  
		return b;
	}

	private function toolButtonImage(iconName : String, color : Int, alpha : Float) : Sprite{
		var w : Int = 23;
		var h : Int = 24;
		var img : Bitmap;
		var result : Sprite = new Sprite();
		var g : Graphics = result.graphics;
		g.clear();
		g.beginFill(color, alpha);
		g.drawRoundRect(0, 0, w, h, 8, 8);
		g.endFill();
		result.addChild(img = Resources.createBmp(iconName));
		img.x = Math.floor((w - img.width) / 2);
		img.y = Math.floor((h - img.height) / 2);
		return result;
	}

	private function makeButtonImg(s : String, c : Int, isOn : Bool) : Sprite{
		var result : Sprite = new Sprite();

		var label : TextField = UIPart.makeLabel(Translator.map(s), CSS.topBarButtonFormat, 2, 2);
		label.textColor = CSS.white;
		label.x = 6;
		result.addChild(label);  // label disabled for now  

		var w : Int = Std.int(label.textWidth + 16);
		var h : Int = 22;
		var g : Graphics = result.graphics;
		g.clear();
		g.beginFill(c);
		g.drawRoundRect(0, 0, w, h, 8, 8);
		g.endFill();

		return result;
	}
}


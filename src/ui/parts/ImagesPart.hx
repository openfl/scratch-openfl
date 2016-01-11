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

// ImagesPart.as
// John Maloney, November 2011
//
// This part holds the Costumes/Scenes list for the current sprite (or stage),
// as well as the image editor, camera, import button and other image media tools.

package ui.parts;


import flash.display.*;
import flash.events.MouseEvent;
import flash.geom.*;
import flash.text.*;
//import flash.utils.SetTimeout;
import haxe.Timer;
import scratch.*;

//import svgeditor.*;

//import svgutils.*;

import translation.Translator;

import ui.media.*;

import uiwidgets.*;

class ImagesPart extends UIPart
{

	//public var editor : ImageEdit;

	private inline static var columnWidth : Int = 106;
	private var contentsX : Int = columnWidth + 13;
	private var topButtonSize : Point = new Point(24, 22);
	private inline static var smallSpace : Int = 3;
	private var bigSpace : Int;

	private var shape : Shape;
	private var listFrame : ScrollFrame;
	private var nameField : EditableLabel;
	private var undoButton : IconButton;
	private var redoButton : IconButton;
	private var clearButton : Button;
	private var libraryButton : Button;
	private var editorImportButton : Button;
	private var cropButton : IconButton;
	private var flipHButton : IconButton;
	private var flipVButton : IconButton;
	private var centerButton : IconButton;

	private var newCostumeLabel : TextField;
	private var backdropLibraryButton : IconButton;
	private var costumeLibraryButton : IconButton;
	private var paintButton : IconButton;
	private var importButton : IconButton;
	private var cameraButton : IconButton;

	public function new(app : Scratch)
	{
		super();
		this.app = app;
		addChild(shape = new Shape());

		addChild(newCostumeLabel = UIPart.makeLabel("", new TextFormat(CSS.font, 12, CSS.textColor, true)));
		addNewCostumeButtons();

		addListFrame();
		addChild(nameField = new EditableLabel(nameChanged));

		addEditor(true);

		addUndoButtons();
		addFlipButtons();
		addCenterButton();
		updateTranslation();
	}

	/*
	private function addEditor(isSVG : Bool) : Void{
		if (isSVG) {
			addChild(editor = new SVGEdit(app, this));
		}
		else {
			addChild(editor = new BitmapEdit(app, this));
		}
	}
	*/

	public static function strings() : Array<Dynamic>{
		return [
		"Clear", "Add", "Import", "New backdrop:", "New costume:", "photo1", "Undo", "Redo", "Flip left-right", 
		"Flip up-down", "Set costume center", "Choose backdrop from library", "Choose costume from library", 
		"Paint new backdrop", "Upload backdrop from file", "New backdrop from camera", "Paint new costume", 
		"Upload costume from file", "New costume from camera"];
	}

	public function updateTranslation() : Void{
		clearButton.setLabel(Translator.map("Clear"));
		libraryButton.setLabel(Translator.map("Add"));
		editorImportButton.setLabel(Translator.map("Import"));
		//if (editor != null)             editor.updateTranslation();
		updateLabel();
		fixlayout();
	}

	public function refresh(fromEditor : Bool = false) : Void{
		updateLabel();
		backdropLibraryButton.visible = isStage();
		costumeLibraryButton.visible = !isStage();
		(try cast(listFrame.contents, MediaPane) catch(e:Dynamic) null).refresh();
		if (!fromEditor)             selectCostume();  // this refresh is because the editor just saved the costume; do nothing  ;
	}

	private function updateLabel() : Void{
		newCostumeLabel.text = Translator.map((isStage()) ? "New backdrop:" : "New costume:");

		SimpleTooltips.add(backdropLibraryButton, {
					text : "Choose backdrop from library",
					direction : "bottom",

				});
		SimpleTooltips.add(costumeLibraryButton, {
					text : "Choose costume from library",
					direction : "bottom",

				});
		if (isStage()) {
			SimpleTooltips.add(paintButton, {
						text : "Paint new backdrop",
						direction : "bottom",

					});
			SimpleTooltips.add(importButton, {
						text : "Upload backdrop from file",
						direction : "bottom",

					});
			SimpleTooltips.add(cameraButton, {
						text : "New backdrop from camera",
						direction : "bottom",

					});
		}
		else {
			SimpleTooltips.add(paintButton, {
						text : "Paint new costume",
						direction : "bottom",

					});
			SimpleTooltips.add(importButton, {
						text : "Upload costume from file",
						direction : "bottom",

					});
			SimpleTooltips.add(cameraButton, {
						text : "New costume from camera",
						direction : "bottom",

					});
		}
	}

	private function isStage() : Bool{return app.viewedObj() != null && app.viewedObj().isStage;
	}

	public function step() : Void{
		(try cast(listFrame.contents, MediaPane) catch(e:Dynamic) null).updateSelection();
		listFrame.updateScrollbars();
	}

	public function setWidthHeight(w : Int, h : Int) : Void{
		this.w = w;
		this.h = h;
		var g : Graphics = shape.graphics;
		g.clear();

		g.lineStyle(0.5, CSS.borderColor, 1, true);
		g.beginFill(CSS.tabColor);
		g.drawRect(0, 0, w, h);
		g.endFill();

		g.lineStyle(0.5, CSS.borderColor, 1, true);
		g.beginFill(CSS.panelColor);
		g.drawRect(columnWidth + 1, 5, w - columnWidth - 6, h - 10);
		g.endFill();

		fixlayout();
	}

	private function fixlayout() : Void{
		var extraSpace : Int = Std.int(Math.max(0, (w - 590) / 3));
		bigSpace = smallSpace + extraSpace;

		newCostumeLabel.x = 7;
		newCostumeLabel.y = 7;

		listFrame.x = 1;
		listFrame.y = 58;
		listFrame.setWidthHeight(columnWidth, Std.int(h - listFrame.y));

		var contentsW : Int = w - contentsX - 15;
		nameField.setWidth(Std.int(Math.min(135, contentsW)));
		nameField.x = contentsX;
		nameField.y = 15;

		// undo buttons
		undoButton.x = nameField.x + nameField.width + bigSpace;
		redoButton.x = undoButton.right() + smallSpace;
		clearButton.x = redoButton.right() + bigSpace;
		clearButton.y = nameField.y;
		undoButton.y = redoButton.y = nameField.y - 2;

		fixEditorLayout();
		if (parent != null)             refresh();
	}

	public function selectCostume() : Void{
		var contents : MediaPane = try cast(listFrame.contents, MediaPane) catch(e:Dynamic) null;
		var changed : Bool = contents.updateSelection();
		var obj : ScratchObj = app.viewedObj();
		if (obj == null)             return;
		nameField.setContents(obj.currentCostume().costumeName);

		//var zoomAndScroll : Array<Dynamic> = editor.getZoomAndScroll();
		//editor.shutdown();
		var c : ScratchCostume = obj.currentCostume();
		useBitmapEditor(c.isBitmap() && c.text == null);
		//editor.editCostume(c, obj.isStage);
		//editor.setZoomAndScroll(zoomAndScroll);
		if (changed)             app.setSaveNeeded();
	}

	private function addListFrame() : Void{
		listFrame = new ScrollFrame();
		listFrame.setContents(app.getMediaPane(app, "costumes"));
		listFrame.contents.color = CSS.tabColor;
		listFrame.allowHorizontalScrollbar = false;
		addChild(listFrame);
	}

	private function nameChanged() : Void{
		app.runtime.renameCostume(nameField.contents());
		nameField.setContents(app.viewedObj().currentCostume().costumeName);
		(try cast(listFrame.contents, MediaPane) catch(e:Dynamic) null).refresh();
	}

	private function addNewCostumeButtons() : Void{
		var left : Int = 8;
		var buttonY : Int = 32;
		addChild(backdropLibraryButton = makeButton(costumeFromLibrary, "landscape", left, buttonY + 1));
		addChild(costumeLibraryButton = makeButton(costumeFromLibrary, "library", left + 1, buttonY - 2));
		addChild(paintButton = makeButton(paintCostume, "paintbrush", left + 23, buttonY - 1));
		addChild(importButton = makeButton(costumeFromComputer, "import", left + 44, buttonY - 2));
		addChild(cameraButton = makeButton(costumeFromCamera, "camera", left + 72, buttonY));
	}

	public function useBitmapEditor(flag : Bool) : Void{
		// Switch editors based on flag. Do nothing if editor is already of the correct type.
		// NOTE: After switching editors, the caller must install costume and other state in the new editor.
		//var oldSettings : DrawProperties;
		//var oldZoomAndScroll : Array<Dynamic>;
		/*
		if (editor != null) {
			oldSettings = editor.getShapeProps();
			oldZoomAndScroll = editor.getWorkArea().getZoomAndScroll();
		}
		if (flag) {
			if (Std.is(editor, BitmapEdit))                 return;
			if (editor != null && editor.parent)                 removeChild(editor);
			addEditor(false);
		}
		else {
			if (Std.is(editor, SVGEdit))                 return;
			if (editor != null && editor.parent)                 removeChild(editor);
			addEditor(true);
		}
		if (oldSettings != null) {
			editor.setShapeProps(oldSettings);
			editor.getWorkArea().setZoomAndScroll([oldZoomAndScroll[0], 0.5, 0.5]);
		}
		editor.registerToolButton("setCenter", centerButton);
		*/
		fixEditorLayout();
	}

	private function fixEditorLayout() : Void {
		/*
		var contentsW : Int = w - contentsX - 15;
		if (editor != null) {
			editor.x = contentsX;
			editor.y = 45;
			editor.setWidthHeight(contentsW, h - editor.y - 14);
		}

		contentsW = w - 16;
		// import button
		libraryButton.x = clearButton.x + clearButton.width + smallSpace;
		libraryButton.y = clearButton.y;
		editorImportButton.x = libraryButton.x + libraryButton.width + smallSpace;
		editorImportButton.y = clearButton.y;

		// buttons in the upper right
		centerButton.x = contentsW - centerButton.width;
		flipVButton.x = centerButton.x - flipVButton.width - smallSpace;
		flipHButton.x = flipVButton.x - flipHButton.width - smallSpace;
		cropButton.x = flipHButton.x - cropButton.width - smallSpace;
		cropButton.y = flipHButton.y = flipVButton.y = centerButton.y = nameField.y - 1;
		*/
	}

	// -----------------------------
	// Button Creation
	//------------------------------

	private function makeButton(fcn : Dynamic->Void, iconName : String, x : Int, y : Int) : IconButton{
		var b : IconButton = new IconButton(fcn, iconName);
		b.isMomentary = true;
		b.x = x;
		b.y = y;
		return b;
	}

	private function makeTopButton(fcn : Dynamic->Void, iconName : String, isRadioButton : Bool = false) : IconButton{
		return new IconButton(
		fcn, SoundsPart.makeButtonImg(iconName, true, topButtonSize), 
		SoundsPart.makeButtonImg(iconName, false, topButtonSize), isRadioButton);
	}

	// -----------------------------
	// Bitmap/Vector Conversion
	//------------------------------

	public function convertToBitmap() : Void {
		/*
		function finishConverting() : Void{
			var c : ScratchCostume = editor.targetCostume;
			var forStage : Bool = editor.isScene;
			var zoomAndScroll : Array<Dynamic> = editor.getZoomAndScroll();
			useBitmapEditor(true);

			var bm : BitmapData = c.bitmapForEditor(forStage);
			c.setBitmapData(bm, 2 * c.rotationCenterX, 2 * c.rotationCenterY);

			editor.editCostume(c, forStage, true);
			editor.setZoomAndScroll(zoomAndScroll);
			editor.saveContent();
		};
		if (Std.is(editor, BitmapEdit))             return;
		editor.shutdown();
		var timer = new Timer(300);
		timer.run = finishConverting;
//        setTimeout(finishConverting, 300);
		*/
	}

	public function convertToVector() : Void {
		/*
		if (Std.is(editor, SVGEdit))             return;
		editor.shutdown();
		editor.setToolMode("select", true);
		var c : ScratchCostume = editor.targetCostume;
		var forStage : Bool = editor.isScene;
		var zoomAndScroll : Array<Dynamic> = editor.getZoomAndScroll();
		useBitmapEditor(false);

		var svg : SVGElement = new SVGElement("svg");
		var nonTransparentBounds : Rectangle = c.baseLayerBitmap.getColorBoundsRect(0xFF000000, 0x00000000, false);
		if (nonTransparentBounds.width != 0 && nonTransparentBounds.height != 0) {
			svg.subElements.push(SVGElement.makeBitmapEl(c.baseLayerBitmap, 1 / c.bitmapResolution));
		}
		c.rotationCenterX /= c.bitmapResolution;
		c.rotationCenterY /= c.bitmapResolution;
		c.setSVGData(new SVGExport(svg).svgData(), false, false);

		editor.editCostume(c, forStage, true);
		editor.setZoomAndScroll(zoomAndScroll);
		*/
	}

	// -----------------------------
	// Undo/Redo
	//------------------------------

	private function addUndoButtons() : Void{
		addChild(undoButton = makeTopButton(undo, "undo"));
		addChild(redoButton = makeTopButton(redo, "redo"));
		addChild(clearButton = new Button(Translator.map("Clear"), clear, true));
		addChild(libraryButton = new Button(Translator.map("Add"), importFromLibrary, true));
		addChild(editorImportButton = new Button(Translator.map("Import"), importIntoEditor, true));
		undoButton.isMomentary = true;
		redoButton.isMomentary = true;
		SimpleTooltips.add(undoButton, {
					text : "Undo",
					direction : "bottom",

				});
		SimpleTooltips.add(redoButton, {
					text : "Redo",
					direction : "bottom",

				});
		SimpleTooltips.add(clearButton, {
					text : "Erase all",
					direction : "bottom",

				});
	}

	private function undo(b : Dynamic) : Void{//editor.undo(b);
	}
	private function redo(b : Dynamic) : Void{//editor.redo(b);
	}
	private function clear() : Void{//editor.clearCanvas();
	}

	private function importFromLibrary() : Void{
		var type : String = (isStage()) ? "backdrop" : "costume";
		var lib : MediaLibrary = app.getMediaLibrary(type, addCostume);
		lib.open();
	}

	private function importIntoEditor() : Void{
		var lib : MediaLibrary = app.getMediaLibrary("", addCostume);
		lib.importFromDisk();
	}

	private function addCostume(costumeOrList : Dynamic) : Void{
		var c : ScratchCostume = try cast(costumeOrList, ScratchCostume) catch(e:Dynamic) null;

		// If they imported a GIF, take the first frame only
		if (c == null && Std.is(costumeOrList, Array)) 
			c = try cast(costumeOrList[0], ScratchCostume) catch(e:Dynamic) null;

		var p : Point = new Point(240, 180);
		//editor.addCostume(c, p);
	}

	public function refreshUndoButtons() : Void{
		//undoButton.setDisabled(!editor.canUndo(), 0.5);
		//redoButton.setDisabled(!editor.canRedo(), 0.5);
		if (editor.canClearCanvas()) {
			clearButton.alpha = 1;
			clearButton.mouseEnabled = true;
		}
		else {
			clearButton.alpha = 0.5;
			clearButton.mouseEnabled = false;
		}
	}

	public function setCanCrop(enabled : Bool) : Void{
		if (enabled) {
			cropButton.alpha = 1;
			cropButton.mouseEnabled = true;
		}
		else {
			cropButton.alpha = 0.5;
			cropButton.mouseEnabled = false;
		}
	}

	// -----------------------------
	// Flip and costume center buttons
	//------------------------------

	private function addFlipButtons() : Void{
		addChild(cropButton = makeTopButton(crop, "crop"));
		addChild(flipHButton = makeTopButton(flipH, "flipH"));
		addChild(flipVButton = makeTopButton(flipV, "flipV"));
		cropButton.isMomentary = true;
		flipHButton.isMomentary = true;
		flipVButton.isMomentary = true;
		SimpleTooltips.add(cropButton, {
					text : "Crop to selection",
					direction : "bottom",

				});
		SimpleTooltips.add(flipHButton, {
					text : "Flip left-right",
					direction : "bottom",

				});
		SimpleTooltips.add(flipVButton, {
					text : "Flip up-down",
					direction : "bottom",

				});
		setCanCrop(false);
	}

	private function crop(ignore : Dynamic) : Void {
		/*
		var bitmapEditor : BitmapEdit = try cast(editor, BitmapEdit) catch(e:Dynamic) null;
		if (bitmapEditor != null) {
			bitmapEditor.cropToSelection();
		}
		*/
	}
	private function flipH(ignore : Dynamic) : Void{//editor.flipContent(false);
	}
	private function flipV(ignore : Dynamic) : Void{//editor.flipContent(true);
	}

	private function addCenterButton() : Void {
		/*
		function setCostumeCenter(b : IconButton) : Void{
			editor.setToolMode("setCenter");
			b.lastEvent.stopPropagation();
		};
		centerButton = makeTopButton(setCostumeCenter, "setCenter", true);
		SimpleTooltips.add(centerButton, {
					text : "Set costume center",
					direction : "bottom",

				});
		editor.registerToolButton("setCenter", centerButton);
		addChild(centerButton);
		*/
	}

	// -----------------------------
	// New costume/backdrop
	//------------------------------

	private function costumeFromComputer(ignore : Dynamic = null) : Void{importCostume(true);
	}
	private function costumeFromLibrary(ignore : Dynamic = null) : Void{importCostume(false);
	}

	private function importCostume(fromComputer : Bool) : Void{
		function addCostume(costumeOrSprite : Dynamic) : Void{
			var c : ScratchCostume = try cast(costumeOrSprite, ScratchCostume) catch(e:Dynamic) null;
			if (c != null) {
				addAndSelectCostume(c);
				return;
			}
			var spr : ScratchSprite = try cast(costumeOrSprite, ScratchSprite) catch(e:Dynamic) null;
			if (spr != null) {
				// If a sprite was selected, add all it's costumes to this sprite.
				for (c/* AS3HX WARNING could not determine type for var: c exp: EField(EIdent(spr),costumes) type: null */ in spr.costumes)addAndSelectCostume(c);
				return;
			}
			var costumeList : Array<Dynamic> = try cast(costumeOrSprite, Array<Dynamic/*AS3HX WARNING no type*/>) catch(e:Dynamic) null;
			if (costumeList != null) {
				for (c in costumeList){
					addAndSelectCostume(c);
				}
			}
		};
		var type : String = (isStage()) ? "backdrop" : "costume";
		var lib : MediaLibrary = app.getMediaLibrary(type, addCostume);
		if (fromComputer)             lib.importFromDisk()
		else lib.open();
	}

	private function paintCostume(ignore : Dynamic = null) : Void{
		addAndSelectCostume(ScratchCostume.emptyBitmapCostume("", isStage()));
	}

	private function savePhotoAsCostume(photo : BitmapData) : Void{
		app.closeCameraDialog();
		var obj : ScratchObj = app.viewedObj();
		if (obj == null)             return;
		if (obj.isStage) {  // resize photo to stage  
			var scale : Float = 480 / photo.width;
			var m : Matrix = new Matrix();
			m.scale(scale, scale);
			var scaledPhoto : BitmapData = new BitmapData(480, 360, true, 0);
			scaledPhoto.draw(photo, m);
			photo = scaledPhoto;
		}
		var c : ScratchCostume = new ScratchCostume(Translator.map("photo1"), photo);
		addAndSelectCostume(c);
		//editor.getWorkArea().zoom();
	}

	private function costumeFromCamera(ignore : Dynamic = null) : Void{
		app.openCameraDialog(savePhotoAsCostume);
	}

	private function addAndSelectCostume(c : ScratchCostume) : Void{
		var obj : ScratchObj = app.viewedObj();
		if (c.baseLayerData == null)             c.prepareToSave();
		if (!app.okayToAdd(c.baseLayerData.length))             return;  // not enough room  ;
		c.costumeName = obj.unusedCostumeName(c.costumeName);
		obj.costumes.push(c);
		obj.showCostume(obj.costumes.length - 1);
		app.setSaveNeeded(true);
		refresh();
	}

	// -----------------------------
	// Help tool
	//------------------------------

	public function handleTool(tool : String, evt : MouseEvent) : Void{
		var localP : Point = globalToLocal(new Point(stage.mouseX, stage.mouseY));
		if (tool == "help") {
			if (localP.x > columnWidth)                 Scratch.app.showTip("paint")
			else Scratch.app.showTip("scratchUI");
		}
	}
}


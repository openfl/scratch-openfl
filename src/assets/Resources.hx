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

package assets;


import flash.display.*;
import flash.text.*;

class Resources
{

	public static function createBmp(resourceName : String) : Bitmap{
		var resourceClass : Class<Dynamic> = Reflect.field (Resources, resourceName);  // Resources[resourceName];
		if (resourceClass == null) {
			trace("missing resource: ", resourceName);
			return new Bitmap(new BitmapData(10, 10, false, 0x808080));
		}
		return Type.createInstance(resourceClass, []);
	}

	public static function makeLabel(s : String, fmt : TextFormat, x : Int = 0, y : Int = 0) : TextField{
		// Create a non-editable text field for use as a label.
		// Note: Although labels not related to bitmaps, this was a handy
		// place to put this function.
		var tf : TextField = new TextField();
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.selectable = false;
		tf.defaultTextFormat = fmt;
		tf.text = s;
		tf.x = x;
		tf.y = y;
		return tf;
	}

	public static function chooseFont(fontList : Array<Dynamic>) : String{
		// Return the first available font in the given list or '_sans' if none of the fonts exist.
		// Font names are case sensitive.
		var availableFonts : Array<Dynamic> = [];
		for (f/* AS3HX WARNING could not determine type for var: f exp: ECall(EField(EIdent(Font),enumerateFonts),[EIdent(true)]) type: null */ in Font.enumerateFonts(true))availableFonts.push(f.fontName);

		for (fName in fontList){
			if (Lambda.indexOf(availableFonts, fName) > -1)                 return fName;
		}
		return "_sans";
	}

	// Embedded fonts
	@:meta(Embed(source="fonts/DonegalOne-Regular.ttf",fontName="Donegal",embedAsCFF="false",advancedAntiAliasing="true"))
private static var Font1 : Class<Dynamic>;
	@:meta(Embed(source="fonts/GloriaHallelujah.ttf",fontName="Gloria",embedAsCFF="false",advancedAntiAliasing="true"))
private static var Font2 : Class<Dynamic>;
	@:meta(Embed(source="fonts/Helvetica-Bold.ttf",fontName="Helvetica",embedAsCFF="false",advancedAntiAliasing="true"))
private static var Font3 : Class<Dynamic>;
	@:meta(Embed(source="fonts/MysteryQuest-Regular.ttf",fontName="Mystery",embedAsCFF="false",advancedAntiAliasing="true"))
private static var Font4 : Class<Dynamic>;
	@:meta(Embed(source="fonts/PermanentMarker.ttf",fontName="Marker",embedAsCFF="false",advancedAntiAliasing="true"))
private static var Font5 : Class<Dynamic>;
	@:meta(Embed(source="fonts/Scratch.ttf",fontName="Scratch",embedAsCFF="false",advancedAntiAliasing="true"))
private static var Font6 : Class<Dynamic>;

	// Block Icons (2x resolution to look better when scaled)
	@:meta(Embed(source="blocks/flagIcon.png"))
private static var flagIcon : Class<Dynamic>;
	@:meta(Embed(source="blocks/stopIcon.png"))
private static var stopIcon : Class<Dynamic>;
	@:meta(Embed(source="blocks/turnLeftIcon.png"))
private static var turnLeftIcon : Class<Dynamic>;
	@:meta(Embed(source="blocks/turnRightIcon.png"))
private static var turnRightIcon : Class<Dynamic>;

	// Cursors
	@:meta(Embed(source="cursors/copyCursor.png"))
private static var copyCursor : Class<Dynamic>;
	@:meta(Embed(source="cursors/crosshairCursor.gif"))
private static var crosshairCursor : Class<Dynamic>;
	@:meta(Embed(source="cursors/cutCursor.png"))
private static var cutCursor : Class<Dynamic>;
	@:meta(Embed(source="cursors/growCursor.png"))
private static var growCursor : Class<Dynamic>;
	@:meta(Embed(source="cursors/helpCursor.png"))
private static var helpCursor : Class<Dynamic>;
	@:meta(Embed(source="cursors/shrinkCursor.png"))
private static var shrinkCursor : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/zoomInCursor.png"))
private static var zoomInCursor : Class<Dynamic>;

	// Top bar
	@:meta(Embed(source="UI/topbar/scratchlogoOff.png"))
private static var scratchlogoOff : Class<Dynamic>;
	@:meta(Embed(source="UI/topbar/scratchlogoOn.png"))
private static var scratchlogoOn : Class<Dynamic>;
	@:meta(Embed(source="UI/topbar/scratchx-logo.png"))
private static var scratchxlogo : Class<Dynamic>;
	@:meta(Embed(source="UI/topbar/copyTool.png"))
private static var copyTool : Class<Dynamic>;
	@:meta(Embed(source="UI/topbar/cutTool.png"))
private static var cutTool : Class<Dynamic>;
	@:meta(Embed(source="UI/topbar/growTool.png"))
private static var growTool : Class<Dynamic>;
	@:meta(Embed(source="UI/topbar/helpTool.png"))
private static var helpTool : Class<Dynamic>;
	@:meta(Embed(source="UI/topbar/languageButtonOff.png"))
private static var languageButtonOff : Class<Dynamic>;
	@:meta(Embed(source="UI/topbar/languageButtonOn.png"))
private static var languageButtonOn : Class<Dynamic>;
	@:meta(Embed(source="UI/topbar/myStuffOff.gif"))
private static var myStuffOff : Class<Dynamic>;
	@:meta(Embed(source="UI/topbar/myStuffOn.gif"))
private static var myStuffOn : Class<Dynamic>;
	@:meta(Embed(source="UI/topbar/projectPageFlip.png"))
private static var projectPageFlip : Class<Dynamic>;
	@:meta(Embed(source="UI/topbar/shrinkTool.png"))
private static var shrinkTool : Class<Dynamic>;

	// Buttons
	@:meta(Embed(source="UI/buttons/addItemOff.gif"))
private static var addItemOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/addItemOn.gif"))
private static var addItemOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/backarrowOff.png"))
private static var backarrowOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/backarrowOn.png"))
private static var backarrowOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/checkboxOff.gif"))
private static var checkboxOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/checkboxOn.gif"))
private static var checkboxOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/closeOff.gif"))
private static var closeOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/closeOn.gif"))
private static var closeOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/deleteItemOff.png"))
private static var deleteItemOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/deleteItemOn.png"))
private static var deleteItemOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/extensionHelpOff.png"))
private static var extensionHelpOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/extensionHelpOn.png"))
private static var extensionHelpOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/flipOff.png"))
private static var flipOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/flipOn.png"))
private static var flipOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/fullScreenOff.png"))
private static var fullscreenOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/fullScreenOn.png"))
private static var fullscreenOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/greenFlagOff.png"))
private static var greenflagOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/greenFlagOn.png"))
private static var greenflagOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/norotationOff.png"))
private static var norotationOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/norotationOn.png"))
private static var norotationOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/playOff.png"))
private static var playOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/playOn.png"))
private static var playOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/redoOff.png"))
private static var redoOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/redoOn.png"))
private static var redoOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/revealOff.gif"))
private static var revealOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/revealOn.gif"))
private static var revealOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/rotate360Off.png"))
private static var rotate360Off : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/rotate360On.png"))
private static var rotate360On : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/spriteInfoOff.png"))
private static var spriteInfoOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/spriteInfoOn.png"))
private static var spriteInfoOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/stopOff.png"))
private static var stopOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/stopOn.png"))
private static var stopOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/undoOff.png"))
private static var undoOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/undoOn.png"))
private static var undoOn : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/unlockedOff.png"))
private static var unlockedOff : Class<Dynamic>;
	@:meta(Embed(source="UI/buttons/unlockedOn.png"))
private static var unlockedOn : Class<Dynamic>;

	// Misc UI Elements
	@:meta(Embed(source="UI/misc/hatshape.png"))
private static var hatshape : Class<Dynamic>;
	@:meta(Embed(source="UI/misc/playerStartFlag.png"))
private static var playerStartFlag : Class<Dynamic>;
	@:meta(Embed(source="UI/misc/promptCheckButton.png"))
private static var promptCheckButton : Class<Dynamic>;
	@:meta(Embed(source="UI/misc/questionMark.png"))
private static var questionMark : Class<Dynamic>;
	@:meta(Embed(source="UI/misc/removeItem.png"))
private static var removeItem : Class<Dynamic>;
	@:meta(Embed(source="UI/misc/speakerOff.png"))
private static var speakerOff : Class<Dynamic>;
	@:meta(Embed(source="UI/misc/speakerOn.png"))
private static var speakerOn : Class<Dynamic>;

	// New Backdrop Buttons
	@:meta(Embed(source="UI/newbackdrop/cameraSmallOff.png"))
private static var cameraSmallOff : Class<Dynamic>;
	@:meta(Embed(source="UI/newbackdrop/cameraSmallOn.png"))
private static var cameraSmallOn : Class<Dynamic>;
	@:meta(Embed(source="UI/newbackdrop/importSmallOff.png"))
private static var importSmallOff : Class<Dynamic>;
	@:meta(Embed(source="UI/newbackdrop/importSmallOn.png"))
private static var importSmallOn : Class<Dynamic>;
	@:meta(Embed(source="UI/newbackdrop/landscapeSmallOff.png"))
private static var landscapeSmallOff : Class<Dynamic>;
	@:meta(Embed(source="UI/newbackdrop/landscapeSmallOn.png"))
private static var landscapeSmallOn : Class<Dynamic>;
	@:meta(Embed(source="UI/newbackdrop/paintbrushSmallOff.png"))
private static var paintbrushSmallOff : Class<Dynamic>;
	@:meta(Embed(source="UI/newbackdrop/paintbrushSmallOn.png"))
private static var paintbrushSmallOn : Class<Dynamic>;

	// New Sprite Buttons
	@:meta(Embed(source="UI/newsprite/cameraOff.png"))
private static var cameraOff : Class<Dynamic>;
	@:meta(Embed(source="UI/newsprite/cameraOn.png"))
private static var cameraOn : Class<Dynamic>;
	@:meta(Embed(source="UI/newsprite/importOff.png"))
private static var importOff : Class<Dynamic>;
	@:meta(Embed(source="UI/newsprite/importOn.png"))
private static var importOn : Class<Dynamic>;
	@:meta(Embed(source="UI/newsprite/landscapeOff.png"))
private static var landscapeOff : Class<Dynamic>;
	@:meta(Embed(source="UI/newsprite/landscapeOn.png"))
private static var landscapeOn : Class<Dynamic>;
	@:meta(Embed(source="UI/newsprite/libraryOff.png"))
private static var libraryOff : Class<Dynamic>;
	@:meta(Embed(source="UI/newsprite/libraryOn.png"))
private static var libraryOn : Class<Dynamic>;
	@:meta(Embed(source="UI/newsprite/paintbrushOff.png"))
private static var paintbrushOff : Class<Dynamic>;
	@:meta(Embed(source="UI/newsprite/paintbrushOn.png"))
private static var paintbrushOn : Class<Dynamic>;

	// New Sound Buttons
	@:meta(Embed(source="UI/newsound/recordOff.png"))
private static var recordOff : Class<Dynamic>;
	@:meta(Embed(source="UI/newsound/recordOn.png"))
private static var recordOn : Class<Dynamic>;
	@:meta(Embed(source="UI/newsound/soundlibraryOff.png"))
private static var soundlibraryOff : Class<Dynamic>;
	@:meta(Embed(source="UI/newsound/soundlibraryOn.png"))
private static var soundlibraryOn : Class<Dynamic>;

	// Sound Editing
	@:meta(Embed(source="UI/sound/forwardOff.png"))
private static var forwardSndOff : Class<Dynamic>;
	@:meta(Embed(source="UI/sound/forwardOn.png"))
private static var forwardSndOn : Class<Dynamic>;
	@:meta(Embed(source="UI/sound/pauseOff.png"))
private static var pauseSndOff : Class<Dynamic>;
	@:meta(Embed(source="UI/sound/pauseOn.png"))
private static var pauseSndOn : Class<Dynamic>;
	@:meta(Embed(source="UI/sound/playOff.png"))
private static var playSndOff : Class<Dynamic>;
	@:meta(Embed(source="UI/sound/playOn.png"))
private static var playSndOn : Class<Dynamic>;
	@:meta(Embed(source="UI/sound/recordOff.png"))
private static var recordSndOff : Class<Dynamic>;
	@:meta(Embed(source="UI/sound/recordOn.png"))
private static var recordSndOn : Class<Dynamic>;
	@:meta(Embed(source="UI/sound/rewindOff.png"))
private static var rewindSndOff : Class<Dynamic>;
	@:meta(Embed(source="UI/sound/rewindOn.png"))
private static var rewindSndOn : Class<Dynamic>;
	@:meta(Embed(source="UI/sound/stopOff.png"))
private static var stopSndOff : Class<Dynamic>;
	@:meta(Embed(source="UI/sound/stopOn.png"))
private static var stopSndOn : Class<Dynamic>;

	// Paint
	@:meta(Embed(source="UI/paint/swatchesOff.png"))
private static var swatchesOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/swatchesOn.png"))
private static var swatchesOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/wheelOff.png"))
private static var wheelOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/wheelOn.png"))
private static var wheelOn : Class<Dynamic>;

	@:meta(Embed(source="UI/paint/noZoomOff.png"))
private static var noZoomOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/noZoomOn.png"))
private static var noZoomOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/zoomInOff.png"))
private static var zoomInOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/zoomInOn.png"))
private static var zoomInOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/zoomOutOff.png"))
private static var zoomOutOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/zoomOutOn.png"))
private static var zoomOutOn : Class<Dynamic>;

	@:meta(Embed(source="UI/paint/wicon.png"))
private static var WidthIcon : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/hicon.png"))
private static var HeightIcon : Class<Dynamic>;

	@:meta(Embed(source="UI/paint/canvasGrid.gif"))
private static var canvasGrid : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/colorWheel.png"))
private static var colorWheel : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/swatchButton.png"))
private static var swatchButton : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/rainbowButton.png"))
private static var rainbowButton : Class<Dynamic>;

	// Paint Tools
	@:meta(Embed(source="UI/paint/ellipseOff.png"))
private static var ellipseOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/ellipseOn.png"))
private static var ellipseOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/cropOff.png"))
private static var cropOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/cropOn.png"))
private static var cropOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/flipHOff.gif"))
private static var flipHOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/flipHOn.gif"))
private static var flipHOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/flipVOff.gif"))
private static var flipVOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/flipVOn.gif"))
private static var flipVOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/pathOff.png"))
private static var pathOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/pathOn.png"))
private static var pathOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/pencilCursor.gif"))
private static var pencilCursor : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/textOff.png"))
private static var textOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/textOn.png"))
private static var textOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/selectOff.png"))
private static var selectOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/selectOn.png"))
private static var selectOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/rotateCursor.png"))
private static var rotateCursor : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/eyedropperOff.png"))
private static var eyedropperOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/eyedropperOn.png"))
private static var eyedropperOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/setCenterOn.gif"))
private static var setCenterOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/setCenterOff.gif"))
private static var setCenterOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/rectSolidOn.png"))
private static var rectSolidOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/rectSolidOff.png"))
private static var rectSolidOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/rectBorderOn.png"))
private static var rectBorderOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/rectBorderOff.png"))
private static var rectBorderOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/ellipseSolidOn.png"))
private static var ellipseSolidOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/ellipseSolidOff.png"))
private static var ellipseSolidOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/ellipseBorderOn.png"))
private static var ellipseBorderOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/ellipseBorderOff.png"))
private static var ellipseBorderOff : Class<Dynamic>;

	// Vector
	@:meta(Embed(source="UI/paint/vectorRectOff.png"))
private static var vectorRectOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/vectorRectOn.png"))
private static var vectorRectOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/vectorEllipseOff.png"))
private static var vectorEllipseOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/vectorEllipseOn.png"))
private static var vectorEllipseOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/vectorLineOff.png"))
private static var vectorLineOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/vectorLineOn.png"))
private static var vectorLineOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/patheditOff.png"))
private static var patheditOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/patheditOn.png"))
private static var patheditOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/groupOff.png"))
private static var groupOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/groupOn.png"))
private static var groupOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/ungroupOff.png"))
private static var ungroupOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/ungroupOn.png"))
private static var ungroupOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/frontOff.png"))
private static var frontOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/frontOn.png"))
private static var frontOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/backOn.png"))
private static var backOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/backOff.png"))
private static var backOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/paintbrushOff.png"))
private static var vpaintbrushOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/paintbrushOn.png"))
private static var vpaintbrushOn : Class<Dynamic>;

	// Bitmap
	@:meta(Embed(source="UI/paint/rectOff.png"))
private static var rectOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/rectOn.png"))
private static var rectOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/paintbucketOn.png"))
private static var paintbucketOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/paintbucketOff.png"))
private static var paintbucketOff : Class<Dynamic>;

	@:meta(Embed(source="UI/paint/editOff.png"))
private static var editOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/editOn.png"))
private static var editOn : Class<Dynamic>;

	@:meta(Embed(source="UI/paint/sliceOn.png"))
private static var sliceOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/sliceOff.png"))
private static var sliceOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/wandOff.png"))
private static var wandOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/wandOn.png"))
private static var wandOn : Class<Dynamic>;

	@:meta(Embed(source="UI/paint/eraserOn.png"))
private static var eraserOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/eraserOff.png"))
private static var eraserOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/saveOn.png"))
private static var saveOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/saveOff.png"))
private static var saveOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/cloneOff.png"))
private static var cloneOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/cloneOn.png"))
private static var cloneOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/lassoOn.png"))
private static var lassoOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/lassoOff.png"))
private static var lassoOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/lineOn.png"))
private static var lineOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/lineOff.png"))
private static var lineOff : Class<Dynamic>;

	@:meta(Embed(source="UI/paint/bitmapBrushOff.png"))
private static var bitmapBrushOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapBrushOn.png"))
private static var bitmapBrushOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapEllipseOff.png"))
private static var bitmapEllipseOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapEllipseOn.png"))
private static var bitmapEllipseOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapPaintbucketOff.png"))
private static var bitmapPaintbucketOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapPaintbucketOn.png"))
private static var bitmapPaintbucketOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapRectOff.png"))
private static var bitmapRectOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapRectOn.png"))
private static var bitmapRectOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapSelectOff.png"))
private static var bitmapSelectOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapSelectOn.png"))
private static var bitmapSelectOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapStampOff.png"))
private static var bitmapStampOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapStampOn.png"))
private static var bitmapStampOn : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapTextOff.png"))
private static var bitmapTextOff : Class<Dynamic>;
	@:meta(Embed(source="UI/paint/bitmapTextOn.png"))
private static var bitmapTextOn : Class<Dynamic>;

	public function new()
	{
	}
}

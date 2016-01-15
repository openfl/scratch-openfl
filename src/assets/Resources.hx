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


import openfl.display.*;
import openfl.text.*;
import openfl.utils.ByteArray;

class Resources
{

	public static function createBmp(resourceName : String) : Bitmap {
		var embedded = findEmbeddedBitmap(resourceName);
		if (embedded == null) {
			trace("missing resource: ", resourceName);
			return new Bitmap(new BitmapData(10, 10, false, 0x808080));
		}
		return new Bitmap(embedded);
	}

	private static function findEmbeddedBitmap(resourceName : String) : BitmapData {
		switch(resourceName) {
			// Block Icons (2x resolution to look better when scaled)
			case "flagIcon": return new FlagIcon(0, 0);
			case "stopIcon": return new StopIcon(0, 0);
			case "turnLeftIcon": return new TurnLeftIcon(0, 0);
			case "turnRightIcon": return new TurnRightIcon(0, 0);

			// Cursors
			case "copyCursor": return new CopyCursor(0, 0);
			case "crosshairCursor": return new CrosshairCursor(0, 0);
			case "cutCursor": return new CutCursor(0, 0);
			case "growCursor": return new GrowCursor(0, 0);
			case "helpCursor": return new HelpCursor(0, 0);
			case "shrinkCursor": return new ShrinkCursor(0, 0);
			case "zoomInCursor": return new ZoomInCursor(0, 0);

			// Top bar
			case "scratchlogoOff": return new ScratchlogoOff(0, 0);
			case "scratchlogoOn": return new ScratchlogoOn(0, 0);
			case "scratchxlogo": return new Scratchxlogo(0, 0);
			case "copyTool": return new CopyTool(0, 0);
			case "cutTool": return new CutTool(0, 0);
			case "growTool": return new GrowTool(0, 0);
			case "helpTool": return new HelpTool(0, 0);
			case "languageButtonOff": return new LanguageButtonOff(0, 0);
			case "languageButtonOn": return new LanguageButtonOn(0, 0);
			case "myStuffOff": return new MyStuffOff(0, 0);
			case "myStuffOn": return new MyStuffOn(0, 0);
			case "projectPageFlip": return new ProjectPageFlip(0, 0);
			case "shrinkTool": return new ShrinkTool(0, 0);

			// Buttons
			case "addItemOff": return new AddItemOff(0, 0);
			case "addItemOn": return new AddItemOn(0, 0);
			case "backarrowOff": return new BackarrowOff(0, 0);
			case "backarrowOn": return new BackarrowOn(0, 0);
			case "checkboxOff": return new CheckboxOff(0, 0);
			case "checkboxOn": return new CheckboxOn(0, 0);
			case "closeOff": return new CloseOff(0, 0);
			case "closeOn": return new CloseOn(0, 0);
			case "deleteItemOff": return new DeleteItemOff(0, 0);
			case "deleteItemOn": return new DeleteItemOn(0, 0);
			case "extensionHelpOff": return new ExtensionHelpOff(0, 0);
			case "extensionHelpOn": return new ExtensionHelpOn(0, 0);
			case "flipOff": return new FlipOff(0, 0);
			case "flipOn": return new FlipOn(0, 0);
			case "fullscreenOff": return new FullscreenOff(0, 0);
			case "fullscreenOn": return new FullscreenOn(0, 0);
			case "greenflagOff": return new GreenflagOff(0, 0);
			case "greenflagOn": return new GreenflagOn(0, 0);
			case "norotationOff": return new NorotationOff(0, 0);
			case "norotationOn": return new NorotationOn(0, 0);
			case "playOff": return new PlayOff(0, 0);
			case "playOn": return new PlayOn(0, 0);
			case "redoOff": return new RedoOff(0, 0);
			case "redoOn": return new RedoOn(0, 0);
			case "revealOff": return new RevealOff(0, 0);
			case "revealOn": return new RevealOn(0, 0);
			case "rotate360Off": return new Rotate360Off(0, 0);
			case "rotate360On": return new Rotate360On(0, 0);
			case "spriteInfoOff": return new SpriteInfoOff(0, 0);
			case "spriteInfoOn": return new SpriteInfoOn(0, 0);
			case "stopOff": return new StopOff(0, 0);
			case "stopOn": return new StopOn(0, 0);
			case "undoOff": return new UndoOff(0, 0);
			case "undoOn": return new UndoOn(0, 0);
			case "unlockedOff": return new UnlockedOff(0, 0);
			case "unlockedOn": return new UnlockedOn(0, 0);

			// Misc UI Elements
			case "hatshape": return new Hatshape(0, 0);
			case "playerStartFlag": return new PlayerStartFlag(0, 0);
			case "promptCheckButton": return new PromptCheckButton(0, 0);
			case "questionMark": return new QuestionMark(0, 0);
			case "removeItem": return new RemoveItem(0, 0);
			case "speakerOff": return new SpeakerOff(0, 0);
			case "speakerOn": return new SpeakerOn(0, 0);

			// New Backdrop Buttons
			case "cameraSmallOff": return new CameraSmallOff(0, 0);
			case "cameraSmallOn": return new CameraSmallOn(0, 0);
			case "importSmallOff": return new ImportSmallOff(0, 0);
			case "importSmallOn": return new ImportSmallOn(0, 0);
			case "landscapeSmallOff": return new LandscapeSmallOff(0, 0);
			case "landscapeSmallOn": return new LandscapeSmallOn(0, 0);
			case "paintbrushSmallOff": return new PaintbrushSmallOff(0, 0);
			case "paintbrushSmallOn": return new PaintbrushSmallOn(0, 0);

			// New Sprite Buttons
			case "cameraOff": return new CameraOff(0, 0);
			case "cameraOn": return new CameraOn(0, 0);
			case "importOff": return new ImportOff(0, 0);
			case "importOn": return new ImportOn(0, 0);
			case "landscapeOff": return new LandscapeOff(0, 0);
			case "landscapeOn": return new LandscapeOn(0, 0);
			case "libraryOff": return new LibraryOff(0, 0);
			case "libraryOn": return new LibraryOn(0, 0);
			case "paintbrushOff": return new PaintbrushOff(0, 0);
			case "paintbrushOn": return new PaintbrushOn(0, 0);

			// New Sound Buttons
			case "recordOff": return new RecordOff(0, 0);
			case "recordOn": return new RecordOn(0, 0);
			case "soundlibraryOff": return new SoundlibraryOff(0, 0);
			case "soundlibraryOn": return new SoundlibraryOn(0, 0);

			// Sound Editing
			case "forwardSndOff": return new ForwardSndOff(0, 0);
			case "forwardSndOn": return new ForwardSndOn(0, 0);
			case "pauseSndOff": return new PauseSndOff(0, 0);
			case "pauseSndOn": return new PauseSndOn(0, 0);
			case "playSndOff": return new PlaySndOff(0, 0);
			case "playSndOn": return new PlaySndOn(0, 0);
			case "recordSndOff": return new RecordSndOff(0, 0);
			case "recordSndOn": return new RecordSndOn(0, 0);
			case "rewindSndOff": return new RewindSndOff(0, 0);
			case "rewindSndOn": return new RewindSndOn(0, 0);
			case "stopSndOff": return new StopSndOff(0, 0);
			case "stopSndOn": return new StopSndOn(0, 0);

			// Paint
			case "swatchesOff": return new SwatchesOff(0, 0);
			case "swatchesOn": return new SwatchesOn(0, 0);
			case "wheelOff": return new WheelOff(0, 0);
			case "wheelOn": return new WheelOn(0, 0);

			case "noZoomOff": return new NoZoomOff(0, 0);
			case "noZoomOn": return new NoZoomOn(0, 0);
			case "zoomInOff": return new ZoomInOff(0, 0);
			case "zoomInOn": return new ZoomInOn(0, 0);
			case "zoomOutOff": return new ZoomOutOff(0, 0);
			case "zoomOutOn": return new ZoomOutOn(0, 0);

			case "WidthIcon": return new WidthIcon(0, 0);
			case "HeightIcon": return new HeightIcon(0, 0);

			case "canvasGrid": return new CanvasGrid(0, 0);
			case "colorWheel": return new ColorWheel(0, 0);
			case "swatchButton": return new SwatchButton(0, 0);
			case "rainbowButton": return new RainbowButton(0, 0);

			// Paint Tools
			case "ellipseOff": return new EllipseOff(0, 0);
			case "ellipseOn": return new EllipseOn(0, 0);
			case "cropOff": return new CropOff(0, 0);
			case "cropOn": return new CropOn(0, 0);
			case "flipHOff": return new FlipHOff(0, 0);
			case "flipHOn": return new FlipHOn(0, 0);
			case "flipVOff": return new FlipVOff(0, 0);
			case "flipVOn": return new FlipVOn(0, 0);
			case "pathOff": return new PathOff(0, 0);
			case "pathOn": return new PathOn(0, 0);
			case "pencilCursor": return new PencilCursor(0, 0);
			case "textOff": return new TextOff(0, 0);
			case "textOn": return new TextOn(0, 0);
			case "selectOff": return new SelectOff(0, 0);
			case "selectOn": return new SelectOn(0, 0);
			case "rotateCursor": return new RotateCursor(0, 0);
			case "eyedropperOff": return new EyedropperOff(0, 0);
			case "eyedropperOn": return new EyedropperOn(0, 0);
			case "setCenterOn": return new SetCenterOn(0, 0);
			case "setCenterOff": return new SetCenterOff(0, 0);
			case "rectSolidOn": return new RectSolidOn(0, 0);
			case "rectSolidOff": return new RectSolidOff(0, 0);
			case "rectBorderOn": return new RectBorderOn(0, 0);
			case "rectBorderOff": return new RectBorderOff(0, 0);
			case "ellipseSolidOn": return new EllipseSolidOn(0, 0);
			case "ellipseSolidOff": return new EllipseSolidOff(0, 0);
			case "ellipseBorderOn": return new EllipseBorderOn(0, 0);
			case "ellipseBorderOff": return new EllipseBorderOff(0, 0);

			// Vector
			case "vectorRectOff": return new VectorRectOff(0, 0);
			case "vectorRectOn": return new VectorRectOn(0, 0);
			case "vectorEllipseOff": return new VectorEllipseOff(0, 0);
			case "vectorEllipseOn": return new VectorEllipseOn(0, 0);
			case "vectorLineOff": return new VectorLineOff(0, 0);
			case "vectorLineOn": return new VectorLineOn(0, 0);
			case "patheditOff": return new PatheditOff(0, 0);
			case "patheditOn": return new PatheditOn(0, 0);
			case "groupOff": return new GroupOff(0, 0);
			case "groupOn": return new GroupOn(0, 0);
			case "ungroupOff": return new UngroupOff(0, 0);
			case "ungroupOn": return new UngroupOn(0, 0);
			case "frontOff": return new FrontOff(0, 0);
			case "frontOn": return new FrontOn(0, 0);
			case "backOn": return new BackOn(0, 0);
			case "backOff": return new BackOff(0, 0);
			case "vpaintbrushOff": return new VpaintbrushOff(0, 0);
			case "vpaintbrushOn": return new VpaintbrushOn(0, 0);

			// Bitmap
			case "rectOff": return new RectOff(0, 0);
			case "rectOn": return new RectOn(0, 0);
			case "paintbucketOn": return new PaintbucketOn(0, 0);
			case "paintbucketOff": return new PaintbucketOff(0, 0);

			case "editOff": return new EditOff(0, 0);
			case "editOn": return new EditOn(0, 0);

			case "sliceOn": return new SliceOn(0, 0);
			case "sliceOff": return new SliceOff(0, 0);
			case "wandOff": return new WandOff(0, 0);
			case "wandOn": return new WandOn(0, 0);

			case "eraserOn": return new EraserOn(0, 0);
			case "eraserOff": return new EraserOff(0, 0);
			case "saveOn": return new SaveOn(0, 0);
			case "saveOff": return new SaveOff(0, 0);
			case "cloneOff": return new CloneOff(0, 0);
			case "cloneOn": return new CloneOn(0, 0);
			case "lassoOn": return new LassoOn(0, 0);
			case "lassoOff": return new LassoOff(0, 0);
			case "lineOn": return new LineOn(0, 0);
			case "lineOff": return new LineOff(0, 0);

			case "bitmapBrushOff": return new BitmapBrushOff(0, 0);
			case "bitmapBrushOn": return new BitmapBrushOn(0, 0);
			case "bitmapEllipseOff": return new BitmapEllipseOff(0, 0);
			case "bitmapEllipseOn": return new BitmapEllipseOn(0, 0);
			case "bitmapPaintbucketOff": return new BitmapPaintbucketOff(0, 0);
			case "bitmapPaintbucketOn": return new BitmapPaintbucketOn(0, 0);
			case "bitmapRectOff": return new BitmapRectOff(0, 0);
			case "bitmapRectOn": return new BitmapRectOn(0, 0);
			case "bitmapSelectOff": return new BitmapSelectOff(0, 0);
			case "bitmapSelectOn": return new BitmapSelectOn(0, 0);
			case "bitmapStampOff": return new BitmapStampOff(0, 0);
			case "bitmapStampOn": return new BitmapStampOn(0, 0);
			case "bitmapTextOff": return new BitmapTextOff(0, 0);
			case "bitmapTextOn": return new BitmapTextOn(0, 0);
		}
		return null;
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
		for (f in Font.enumerateFonts(true))availableFonts.push(f.fontName);

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


	public function new()
	{
	}
}

// Block Icons (2x resolution to look better when scaled)
@:bitmap("assets/blocks/flagIcon.png")
class FlagIcon extends BitmapData { }
@:bitmap("assets/blocks/stopIcon.png")
class StopIcon extends BitmapData { }
@:bitmap("assets/blocks/turnLeftIcon.png")
class TurnLeftIcon extends BitmapData { }
@:bitmap("assets/blocks/turnRightIcon.png")
class TurnRightIcon extends BitmapData { }

// Cursors
@:bitmap("assets/cursors/copyCursor.png")
class CopyCursor extends BitmapData { }
@:bitmap("assets/cursors/crosshairCursor.gif")
class CrosshairCursor extends BitmapData { }
@:bitmap("assets/cursors/cutCursor.png")
class CutCursor extends BitmapData { }
@:bitmap("assets/cursors/growCursor.png")
class GrowCursor extends BitmapData { }
@:bitmap("assets/cursors/helpCursor.png")
class HelpCursor extends BitmapData { }
@:bitmap("assets/cursors/shrinkCursor.png")
class ShrinkCursor extends BitmapData { }
@:bitmap("assets/UI/paint/zoomInCursor.png")
class ZoomInCursor extends BitmapData { }

// Top bar
@:bitmap("assets/UI/topbar/scratchlogoOff.png")
class ScratchlogoOff extends BitmapData { }
@:bitmap("assets/UI/topbar/scratchlogoOn.png")
class ScratchlogoOn extends BitmapData { }
@:bitmap("assets/UI/topbar/scratchx-logo.png")
class Scratchxlogo extends BitmapData { }
@:bitmap("assets/UI/topbar/copyTool.png")
class CopyTool extends BitmapData { }
@:bitmap("assets/UI/topbar/cutTool.png")
class CutTool extends BitmapData { }
@:bitmap("assets/UI/topbar/growTool.png")
class GrowTool extends BitmapData { }
@:bitmap("assets/UI/topbar/helpTool.png")
class HelpTool extends BitmapData { }
@:bitmap("assets/UI/topbar/languageButtonOff.png")
class LanguageButtonOff extends BitmapData { }
@:bitmap("assets/UI/topbar/languageButtonOn.png")
class LanguageButtonOn extends BitmapData { }
@:bitmap("assets/UI/topbar/myStuffOff.gif")
class MyStuffOff extends BitmapData { }
@:bitmap("assets/UI/topbar/myStuffOn.gif")
class MyStuffOn extends BitmapData { }
@:bitmap("assets/UI/topbar/projectPageFlip.png")
class ProjectPageFlip extends BitmapData { }
@:bitmap("assets/UI/topbar/shrinkTool.png")
class ShrinkTool extends BitmapData { }

// Buttons
@:bitmap("assets/UI/buttons/addItemOff.gif")
class AddItemOff extends BitmapData { }
@:bitmap("assets/UI/buttons/addItemOn.gif")
class AddItemOn extends BitmapData { }
@:bitmap("assets/UI/buttons/backarrowOff.png")
class BackarrowOff extends BitmapData { }
@:bitmap("assets/UI/buttons/backarrowOn.png")
class BackarrowOn extends BitmapData { }
@:bitmap("assets/UI/buttons/checkboxOff.gif")
class CheckboxOff extends BitmapData { }
@:bitmap("assets/UI/buttons/checkboxOn.gif")
class CheckboxOn extends BitmapData { }
@:bitmap("assets/UI/buttons/closeOff.gif")
class CloseOff extends BitmapData { }
@:bitmap("assets/UI/buttons/closeOn.gif")
class CloseOn extends BitmapData { }
@:bitmap("assets/UI/buttons/deleteItemOff.png")
class DeleteItemOff extends BitmapData { }
@:bitmap("assets/UI/buttons/deleteItemOn.png")
class DeleteItemOn extends BitmapData { }
@:bitmap("assets/UI/buttons/extensionHelpOff.png")
class ExtensionHelpOff extends BitmapData { }
@:bitmap("assets/UI/buttons/extensionHelpOn.png")
class ExtensionHelpOn extends BitmapData { }
@:bitmap("assets/UI/buttons/flipOff.png")
class FlipOff extends BitmapData { }
@:bitmap("assets/UI/buttons/flipOn.png")
class FlipOn extends BitmapData { }
@:bitmap("assets/UI/buttons/fullScreenOff.png")
class FullscreenOff extends BitmapData { }
@:bitmap("assets/UI/buttons/fullScreenOn.png")
class FullscreenOn extends BitmapData { }
@:bitmap("assets/UI/buttons/greenFlagOff.png")
class GreenflagOff extends BitmapData { }
@:bitmap("assets/UI/buttons/greenFlagOn.png")
class GreenflagOn extends BitmapData { }
@:bitmap("assets/UI/buttons/norotationOff.png")
class NorotationOff extends BitmapData { }
@:bitmap("assets/UI/buttons/norotationOn.png")
class NorotationOn extends BitmapData { }
@:bitmap("assets/UI/buttons/playOff.png")
class PlayOff extends BitmapData { }
@:bitmap("assets/UI/buttons/playOn.png")
class PlayOn extends BitmapData { }
@:bitmap("assets/UI/buttons/redoOff.png")
class RedoOff extends BitmapData { }
@:bitmap("assets/UI/buttons/redoOn.png")
class RedoOn extends BitmapData { }
@:bitmap("assets/UI/buttons/revealOff.gif")
class RevealOff extends BitmapData { }
@:bitmap("assets/UI/buttons/revealOn.gif")
class RevealOn extends BitmapData { }
@:bitmap("assets/UI/buttons/rotate360Off.png")
class Rotate360Off extends BitmapData { }
@:bitmap("assets/UI/buttons/rotate360On.png")
class Rotate360On extends BitmapData { }
@:bitmap("assets/UI/buttons/spriteInfoOff.png")
class SpriteInfoOff extends BitmapData { }
@:bitmap("assets/UI/buttons/spriteInfoOn.png")
class SpriteInfoOn extends BitmapData { }
@:bitmap("assets/UI/buttons/stopOff.png")
class StopOff extends BitmapData { }
@:bitmap("assets/UI/buttons/stopOn.png")
class StopOn extends BitmapData { }
@:bitmap("assets/UI/buttons/undoOff.png")
class UndoOff extends BitmapData { }
@:bitmap("assets/UI/buttons/undoOn.png")
class UndoOn extends BitmapData { }
@:bitmap("assets/UI/buttons/unlockedOff.png")
class UnlockedOff extends BitmapData { }
@:bitmap("assets/UI/buttons/unlockedOn.png")
class UnlockedOn extends BitmapData { }

// Misc UI Elements
@:bitmap("assets/UI/misc/hatshape.png")
class Hatshape extends BitmapData { }
@:bitmap("assets/UI/misc/playerStartFlag.png")
class PlayerStartFlag extends BitmapData { }
@:bitmap("assets/UI/misc/promptCheckButton.png")
class PromptCheckButton extends BitmapData { }
@:bitmap("assets/UI/misc/questionMark.png")
class QuestionMark extends BitmapData { }
@:bitmap("assets/UI/misc/removeItem.png")
class RemoveItem extends BitmapData { }
@:bitmap("assets/UI/misc/speakerOff.png")
class SpeakerOff extends BitmapData { }
@:bitmap("assets/UI/misc/speakerOn.png")
class SpeakerOn extends BitmapData { }

// New Backdrop Buttons
@:bitmap("assets/UI/newbackdrop/cameraSmallOff.png")
class CameraSmallOff extends BitmapData { }
@:bitmap("assets/UI/newbackdrop/cameraSmallOn.png")
class CameraSmallOn extends BitmapData { }
@:bitmap("assets/UI/newbackdrop/importSmallOff.png")
class ImportSmallOff extends BitmapData { }
@:bitmap("assets/UI/newbackdrop/importSmallOn.png")
class ImportSmallOn extends BitmapData { }
@:bitmap("assets/UI/newbackdrop/landscapeSmallOff.png")
class LandscapeSmallOff extends BitmapData { }
@:bitmap("assets/UI/newbackdrop/landscapeSmallOn.png")
class LandscapeSmallOn extends BitmapData { }
@:bitmap("assets/UI/newbackdrop/paintbrushSmallOff.png")
class PaintbrushSmallOff extends BitmapData { }
@:bitmap("assets/UI/newbackdrop/paintbrushSmallOn.png")
class PaintbrushSmallOn extends BitmapData { }

// New Sprite Buttons
@:bitmap("assets/UI/newsprite/cameraOff.png")
class CameraOff extends BitmapData { }
@:bitmap("assets/UI/newsprite/cameraOn.png")
class CameraOn extends BitmapData { }
@:bitmap("assets/UI/newsprite/importOff.png")
class ImportOff extends BitmapData { }
@:bitmap("assets/UI/newsprite/importOn.png")
class ImportOn extends BitmapData { }
@:bitmap("assets/UI/newsprite/landscapeOff.png")
class LandscapeOff extends BitmapData { }
@:bitmap("assets/UI/newsprite/landscapeOn.png")
class LandscapeOn extends BitmapData { }
@:bitmap("assets/UI/newsprite/libraryOff.png")
class LibraryOff extends BitmapData { }
@:bitmap("assets/UI/newsprite/libraryOn.png")
class LibraryOn extends BitmapData { }
@:bitmap("assets/UI/newsprite/paintbrushOff.png")
class PaintbrushOff extends BitmapData { }
@:bitmap("assets/UI/newsprite/paintbrushOn.png")
class PaintbrushOn extends BitmapData { }

// New Sound Buttons
@:bitmap("assets/UI/newsound/recordOff.png")
class RecordOff extends BitmapData { }
@:bitmap("assets/UI/newsound/recordOn.png")
class RecordOn extends BitmapData { }
@:bitmap("assets/UI/newsound/soundlibraryOff.png")
class SoundlibraryOff extends BitmapData { }
@:bitmap("assets/UI/newsound/soundlibraryOn.png")
class SoundlibraryOn extends BitmapData { }

// Sound Editing
@:bitmap("assets/UI/sound/forwardOff.png")
class ForwardSndOff extends BitmapData { }
@:bitmap("assets/UI/sound/forwardOn.png")
class ForwardSndOn extends BitmapData { }
@:bitmap("assets/UI/sound/pauseOff.png")
class PauseSndOff extends BitmapData { }
@:bitmap("assets/UI/sound/pauseOn.png")
class PauseSndOn extends BitmapData { }
@:bitmap("assets/UI/sound/playOff.png")
class PlaySndOff extends BitmapData { }
@:bitmap("assets/UI/sound/playOn.png")
class PlaySndOn extends BitmapData { }
@:bitmap("assets/UI/sound/recordOff.png")
class RecordSndOff extends BitmapData { }
@:bitmap("assets/UI/sound/recordOn.png")
class RecordSndOn extends BitmapData { }
@:bitmap("assets/UI/sound/rewindOff.png")
class RewindSndOff extends BitmapData { }
@:bitmap("assets/UI/sound/rewindOn.png")
class RewindSndOn extends BitmapData { }
@:bitmap("assets/UI/sound/stopOff.png")
class StopSndOff extends BitmapData { }
@:bitmap("assets/UI/sound/stopOn.png")
class StopSndOn extends BitmapData { }

// Paint
@:bitmap("assets/UI/paint/swatchesOff.png")
class SwatchesOff extends BitmapData { }
@:bitmap("assets/UI/paint/swatchesOn.png")
class SwatchesOn extends BitmapData { }
@:bitmap("assets/UI/paint/wheelOff.png")
class WheelOff extends BitmapData { }
@:bitmap("assets/UI/paint/wheelOn.png")
class WheelOn extends BitmapData { }

@:bitmap("assets/UI/paint/noZoomOff.png")
class NoZoomOff extends BitmapData { }
@:bitmap("assets/UI/paint/noZoomOn.png")
class NoZoomOn extends BitmapData { }
@:bitmap("assets/UI/paint/zoomInOff.png")
class ZoomInOff extends BitmapData { }
@:bitmap("assets/UI/paint/zoomInOn.png")
class ZoomInOn extends BitmapData { }
@:bitmap("assets/UI/paint/zoomOutOff.png")
class ZoomOutOff extends BitmapData { }
@:bitmap("assets/UI/paint/zoomOutOn.png")
class ZoomOutOn extends BitmapData { }

@:bitmap("assets/UI/paint/wicon.png")
class WidthIcon extends BitmapData { }
@:bitmap("assets/UI/paint/hicon.png")
class HeightIcon extends BitmapData { }

@:bitmap("assets/UI/paint/canvasGrid.gif")
class CanvasGrid extends BitmapData { }
@:bitmap("assets/UI/paint/colorWheel.png")
class ColorWheel extends BitmapData { }
@:bitmap("assets/UI/paint/swatchButton.png")
class SwatchButton extends BitmapData { }
@:bitmap("assets/UI/paint/rainbowButton.png")
class RainbowButton extends BitmapData { }

// Paint Tools
@:bitmap("assets/UI/paint/ellipseOff.png")
class EllipseOff extends BitmapData { }
@:bitmap("assets/UI/paint/ellipseOn.png")
class EllipseOn extends BitmapData { }
@:bitmap("assets/UI/paint/cropOff.png")
class CropOff extends BitmapData { }
@:bitmap("assets/UI/paint/cropOn.png")
class CropOn extends BitmapData { }
@:bitmap("assets/UI/paint/flipHOff.gif")
class FlipHOff extends BitmapData { }
@:bitmap("assets/UI/paint/flipHOn.gif")
class FlipHOn extends BitmapData { }
@:bitmap("assets/UI/paint/flipVOff.gif")
class FlipVOff extends BitmapData { }
@:bitmap("assets/UI/paint/flipVOn.gif")
class FlipVOn extends BitmapData { }
@:bitmap("assets/UI/paint/pathOff.png")
class PathOff extends BitmapData { }
@:bitmap("assets/UI/paint/pathOn.png")
class PathOn extends BitmapData { }
@:bitmap("assets/UI/paint/pencilCursor.gif")
class PencilCursor extends BitmapData { }
@:bitmap("assets/UI/paint/textOff.png")
class TextOff extends BitmapData { }
@:bitmap("assets/UI/paint/textOn.png")
class TextOn extends BitmapData { }
@:bitmap("assets/UI/paint/selectOff.png")
class SelectOff extends BitmapData { }
@:bitmap("assets/UI/paint/selectOn.png")
class SelectOn extends BitmapData { }
@:bitmap("assets/UI/paint/rotateCursor.png")
class RotateCursor extends BitmapData { }
@:bitmap("assets/UI/paint/eyedropperOff.png")
class EyedropperOff extends BitmapData { }
@:bitmap("assets/UI/paint/eyedropperOn.png")
class EyedropperOn extends BitmapData { }
@:bitmap("assets/UI/paint/setCenterOn.gif")
class SetCenterOn extends BitmapData { }
@:bitmap("assets/UI/paint/setCenterOff.gif")
class SetCenterOff extends BitmapData { }
@:bitmap("assets/UI/paint/rectSolidOn.png")
class RectSolidOn extends BitmapData { }
@:bitmap("assets/UI/paint/rectSolidOff.png")
class RectSolidOff extends BitmapData { }
@:bitmap("assets/UI/paint/rectBorderOn.png")
class RectBorderOn extends BitmapData { }
@:bitmap("assets/UI/paint/rectBorderOff.png")
class RectBorderOff extends BitmapData { }
@:bitmap("assets/UI/paint/ellipseSolidOn.png")
class EllipseSolidOn extends BitmapData { }
@:bitmap("assets/UI/paint/ellipseSolidOff.png")
class EllipseSolidOff extends BitmapData { }
@:bitmap("assets/UI/paint/ellipseBorderOn.png")
class EllipseBorderOn extends BitmapData { }
@:bitmap("assets/UI/paint/ellipseBorderOff.png")
class EllipseBorderOff extends BitmapData { }

// Vector
@:bitmap("assets/UI/paint/vectorRectOff.png")
class VectorRectOff extends BitmapData { }
@:bitmap("assets/UI/paint/vectorRectOn.png")
class VectorRectOn extends BitmapData { }
@:bitmap("assets/UI/paint/vectorEllipseOff.png")
class VectorEllipseOff extends BitmapData { }
@:bitmap("assets/UI/paint/vectorEllipseOn.png")
class VectorEllipseOn extends BitmapData { }
@:bitmap("assets/UI/paint/vectorLineOff.png")
class VectorLineOff extends BitmapData { }
@:bitmap("assets/UI/paint/vectorLineOn.png")
class VectorLineOn extends BitmapData { }
@:bitmap("assets/UI/paint/patheditOff.png")
class PatheditOff extends BitmapData { }
@:bitmap("assets/UI/paint/patheditOn.png")
class PatheditOn extends BitmapData { }
@:bitmap("assets/UI/paint/groupOff.png")
class GroupOff extends BitmapData { }
@:bitmap("assets/UI/paint/groupOn.png")
class GroupOn extends BitmapData { }
@:bitmap("assets/UI/paint/ungroupOff.png")
class UngroupOff extends BitmapData { }
@:bitmap("assets/UI/paint/ungroupOn.png")
class UngroupOn extends BitmapData { }
@:bitmap("assets/UI/paint/frontOff.png")
class FrontOff extends BitmapData { }
@:bitmap("assets/UI/paint/frontOn.png")
class FrontOn extends BitmapData { }
@:bitmap("assets/UI/paint/backOn.png")
class BackOn extends BitmapData { }
@:bitmap("assets/UI/paint/backOff.png")
class BackOff extends BitmapData { }
@:bitmap("assets/UI/paint/paintbrushOff.png")
class VpaintbrushOff extends BitmapData { }
@:bitmap("assets/UI/paint/paintbrushOn.png")
class VpaintbrushOn extends BitmapData { }

// Bitmap
@:bitmap("assets/UI/paint/rectOff.png")
class RectOff extends BitmapData { }
@:bitmap("assets/UI/paint/rectOn.png")
class RectOn extends BitmapData { }
@:bitmap("assets/UI/paint/paintbucketOn.png")
class PaintbucketOn extends BitmapData { }
@:bitmap("assets/UI/paint/paintbucketOff.png")
class PaintbucketOff extends BitmapData { }

@:bitmap("assets/UI/paint/editOff.png")
class EditOff extends BitmapData { }
@:bitmap("assets/UI/paint/editOn.png")
class EditOn extends BitmapData { }

@:bitmap("assets/UI/paint/sliceOn.png")
class SliceOn extends BitmapData { }
@:bitmap("assets/UI/paint/sliceOff.png")
class SliceOff extends BitmapData { }
@:bitmap("assets/UI/paint/wandOff.png")
class WandOff extends BitmapData { }
@:bitmap("assets/UI/paint/wandOn.png")
class WandOn extends BitmapData { }

@:bitmap("assets/UI/paint/eraserOn.png")
class EraserOn extends BitmapData { }
@:bitmap("assets/UI/paint/eraserOff.png")
class EraserOff extends BitmapData { }
@:bitmap("assets/UI/paint/saveOn.png")
class SaveOn extends BitmapData { }
@:bitmap("assets/UI/paint/saveOff.png")
class SaveOff extends BitmapData { }
@:bitmap("assets/UI/paint/cloneOff.png")
class CloneOff extends BitmapData { }
@:bitmap("assets/UI/paint/cloneOn.png")
class CloneOn extends BitmapData { }
@:bitmap("assets/UI/paint/lassoOn.png")
class LassoOn extends BitmapData { }
@:bitmap("assets/UI/paint/lassoOff.png")
class LassoOff extends BitmapData { }
@:bitmap("assets/UI/paint/lineOn.png")
class LineOn extends BitmapData { }
@:bitmap("assets/UI/paint/lineOff.png")
class LineOff extends BitmapData { }

@:bitmap("assets/UI/paint/bitmapBrushOff.png")
class BitmapBrushOff extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapBrushOn.png")
class BitmapBrushOn extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapEllipseOff.png")
class BitmapEllipseOff extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapEllipseOn.png")
class BitmapEllipseOn extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapPaintbucketOff.png")
class BitmapPaintbucketOff extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapPaintbucketOn.png")
class BitmapPaintbucketOn extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapRectOff.png")
class BitmapRectOff extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapRectOn.png")
class BitmapRectOn extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapSelectOff.png")
class BitmapSelectOff extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapSelectOn.png")
class BitmapSelectOn extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapStampOff.png")
class BitmapStampOff extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapStampOn.png")
class BitmapStampOn extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapTextOff.png")
class BitmapTextOff extends BitmapData { }
@:bitmap("assets/UI/paint/bitmapTextOn.png")
class BitmapTextOn extends BitmapData { }

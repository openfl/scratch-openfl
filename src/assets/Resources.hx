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


import openfl.Assets;
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
		return Assets.getBitmapData(resourceName);
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

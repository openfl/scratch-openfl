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

// CSS.as
// Paula Bonta, November 2011
//
// Styles for Scratch Editor based on the Upstatement design.


import openfl.text.*;
import assets.Resources;

class CSS
{

	public static function topBarColor() : Int{return (Scratch.app.isExtensionDevMode) ? topBarColor_ScratchX : topBarColor_default;
	}
	public static function backgroundColor() : Int{return (Scratch.app.isExtensionDevMode) ? backgroundColor_ScratchX : backgroundColor_default;
	}

	// ScratchX
	public static inline var topBarColor_ScratchX : Int = 0x30485f;
	public static inline var backgroundColor_ScratchX : Int = 0x3f5975;

	// Colors
	public static inline var white : Int = 0xFFFFFF;
	public static var backgroundColor_default : Int = white;
	public static inline var topBarColor_default : Int = 0x9C9EA2;
	public static inline var tabColor : Int = 0xE6E8E8;
	public static inline var panelColor : Int = 0xF2F2F2;
	public static inline var itemSelectedColor : Int = 0xD0D0D0;
	public static inline var borderColor : Int = 0xD0D1D2;
	public static inline var textColor : Int = 0x5C5D5F;  // 0x6C6D6F  
	public static var buttonLabelColor : Int = textColor;
	public static inline var buttonLabelOverColor : Int = 0xFBA939;
	public static inline var offColor : Int = 0x8F9193;  // 0x9FA1A3  
	public static var onColor : Int = textColor;  // 0x4C4D4F  
	public static inline var overColor : Int = 0x179FD7;
	public static inline var arrowColor : Int = 0xA6A8AC;

	// Fonts
	public static var font : String = Resources.chooseFont(["Arial", "Verdana", "DejaVu Sans"]);
	public static inline var menuFontSize : Int = 12;
	public static var normalTextFormat : TextFormat = new TextFormat(font, 12, textColor);
	public static var topBarButtonFormat : TextFormat = new TextFormat(font, 12, white, true);
	public static var titleFormat : TextFormat = new TextFormat(font, 14, textColor);
	public static var thumbnailFormat : TextFormat = new TextFormat(font, 11, textColor);
	public static var thumbnailExtraInfoFormat : TextFormat = new TextFormat(font, 9, textColor);
	public static var projectTitleFormat : TextFormat = new TextFormat(font, 13, textColor);
	public static var projectInfoFormat : TextFormat = new TextFormat(font, 12, textColor);

	// Section title bars
	public static var titleBarColors : Array<UInt> = [white, tabColor];
	public static inline var titleBarH : Int = 30;

	public function new()
	{
	}
}

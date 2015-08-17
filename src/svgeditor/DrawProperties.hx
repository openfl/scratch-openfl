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

package svgeditor;


class DrawProperties {
	public var color(get, set) : UInt;
	public var alpha(get, never) : Float;
	public var secondColor(get, set) : UInt;
	public var secondAlpha(get, never) : Float;
	public var strokeWidth(get, set) : Int;
	public var eraserWidth(get, set) : Int;

	
	// colors
	public var rawColor : UInt = 0xFF000000;
	public var rawSecondColor : UInt = 0xFFFFFFFF;
	
	private function set_Color(c : UInt) : UInt{rawColor = c;
		return c;
	}
	private function get_Color() : UInt{return rawColor & 0xFFFFFF;
	}
	private function get_Alpha() : Float{return ((rawColor >> 24) & 0xFF) / 0xFF;
	}
	
	private function set_SecondColor(c : UInt) : UInt{rawSecondColor = c;
		return c;
	}
	private function get_SecondColor() : UInt{return rawSecondColor & 0xFFFFFF;
	}
	private function get_SecondAlpha() : Float{return ((rawSecondColor >> 24) & 0xFF) / 0xFF;
	}
	
	// stroke
	public var smoothness : Float = 1;
	private var rawStrokeWidth : Float = 1;
	private var rawEraserWidth : Float = 4;
	
	private function set_StrokeWidth(w : Int) : Int{rawStrokeWidth = w;
		return w;
	}
	private function set_EraserWidth(w : Int) : Int{rawEraserWidth = w;
		return w;
	}
	
	private function get_StrokeWidth() : Int{
		return adjustWidth(rawStrokeWidth);
	}
	
	private function get_EraserWidth() : Int{
		return adjustWidth(rawEraserWidth);
	}
	
	private static function adjustWidth(raw : Int) : Int{
		if (Scratch.app.imagesPart && (Std.is(Scratch.app.imagesPart.editor, SVGEdit))) 			return raw  // above 10, use Squeak brush sizes  ;
		
		
		
		var n : Float = Math.max(1, Math.round(raw));
		switch (n) {
			case 11:return 13;
			case 12:return 19;
			case 13:return 29;
			case 14:return 47;
			case 15:return 75;
			default:return n;
		}
	}
	
	// fill
	public var fillType : String = "solid";  // solid, linearHorizontal, linearVertical, radial  
	public var filledShape : Bool = false;
	
	// font
	public var fontName : String = "Helvetica";

	public function new()
	{
	}
}

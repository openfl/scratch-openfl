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

// Color.as
// John Maloney, August 2009
//
// Color utility methods, such as HSV/RGB conversions.

package util;


class Color
{

	// Convert hue (0-360), saturation (0-1), and brightness (0-1) to RGB.
	public static function fromHSV(h : Float, s : Float, v : Float) : Int{
		var r : Float;
		var g : Float;
		var b : Float;
		h = h % 360;
		if (h < 0)             h += 360;
		s = Math.max(0, Math.min(s, 1));
		v = Math.max(0, Math.min(v, 1));

		var i : Float = Math.floor(h / 60);
		var f : Float = (h / 60) - i;
		var p : Float = v * (1 - s);
		var q : Float = v * (1 - (s * f));
		var t : Float = v * (1 - (s * (1 - f)));
		if (i == 0) {r = v;g = t;b = p;
		}
		else if (i == 1) {r = q;g = v;b = p;
		}
		else if (i == 2) {r = p;g = v;b = t;
		}
		else if (i == 3) {r = p;g = q;b = v;
		}
		else if (i == 4) {r = t;g = p;b = v;
		}
		else if (i == 5) {r = v;g = p;b = q;
		}
		r = Math.floor(r * 255);
		g = Math.floor(g * 255);
		b = Math.floor(b * 255);
		return (Std.int(r) << 16) | (Std.int(g) << 8) | Std.int(b);
	}

	// Convert RGB to an array containing the hue, saturation, and brightness.
	public static function rgb2hsv(rgb : Float) : Array<Float>{
		var h : Float;
		var s : Float;
		var v : Float;
		var x : Float;
		var f : Float;
		var i : Float;
		var r : Float = ((Std.int(rgb) >> 16) & 255) / 255;
		var g : Float = ((Std.int(rgb) >> 8) & 255) / 255;
		var b : Float = (Std.int(rgb) & 255) / 255;
		x = Math.min(Math.min(r, g), b);
		v = Math.max(Math.max(r, g), b);
		if (x == v)             return [0, 0, v];  // gray; hue arbitrarily reported as zero  ;
		f = ((r == x)) ? g - b : (((g == x)) ? b - r : r - g);
		i = ((r == x)) ? 3 : (((g == x)) ? 5 : 1);
		h = ((i - (f / (v - x))) * 60) % 360;
		s = (v - x) / v;
		return [h, s, v];
	}

	public static function scaleBrightness(rgb : Float, scale : Float) : Int{
		var hsv : Array<Dynamic> = rgb2hsv(rgb);
		var val : Float = Math.max(0, Math.min(scale * hsv[2], 1));
		return fromHSV(hsv[0], hsv[1], val);
	}

	public static function mixRGB(rgb1 : Int, rgb2 : Int, fraction : Float) : Int{
		// Mix rgb1 with rgb2. 0 gives all rgb1, 1 gives rbg2, .5 mixes them 50/50.
		if (fraction <= 0)             return rgb1;
		if (fraction >= 1)             return rgb2;
		var r1 : Int = (rgb1 >> 16) & 255;
		var g1 : Int = (rgb1 >> 8) & 255;
		var b1 : Int = rgb1 & 255;
		var r2 : Int = (rgb2 >> 16) & 255;
		var g2 : Int = (rgb2 >> 8) & 255;
		var b2 : Int = rgb2 & 255;
		var r : Int = Std.int(((fraction * r2) + ((1.0 - fraction) * r1))) & 255;
		var g : Int = Std.int(((fraction * g2) + ((1.0 - fraction) * g1))) & 255;
		var b : Int = Std.int(((fraction * b2) + ((1.0 - fraction) * b1))) & 255;
		return (r << 16) | (g << 8) | b;
	}

	public static function random() : Int{
		// return a random color
		var h : Float = 360 * Math.random();
		var s : Float = 0.7 + (0.3 * Math.random());
		var v : Float = 0.6 + (0.4 * Math.random());
		return fromHSV(h, s, v);
	}

	public function new()
	{
	}
}

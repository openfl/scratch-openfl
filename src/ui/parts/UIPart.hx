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

// UIPart.as
// John Maloney, November 2011
//
// This is the superclass for the main parts of the Scratch UI.
// It holds drawing style constants and code shared by all parts.
// Subclasses often implement one or more of the following:
//
//		refresh() - update this part after a change (e.g. changing the selected object)
//		step() - do background tasks

package ui.parts;


import openfl.display.GradientType;
import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.text.*;
import translation.Translator;
import uiwidgets.IconButton;
import util.DrawPath;

class UIPart extends Sprite
{

	private static inline var cornerRadius : Int = 8;

	public var app : Scratch;
	public var w : Int;public var h : Int;

	public function right() : Int{return Std.int(x + w);
	}
	public function bottom() : Int{return Std.int(y + h);
	}

	public static function makeLabel(s : String, fmt : TextFormat, x : Int = 0, y : Int = 0) : TextField{
		// Create a non-editable text field for use as a label.
		var tf : TextField = new TextField();
		tf.autoSize = TextFieldAutoSize.LEFT;
		tf.selectable = false;
		tf.defaultTextFormat = fmt;
		tf.text = s;
		tf.x = x;
		tf.y = y;
		return tf;
	}

	public static function drawTopBar(g : Graphics, colors : Array<UInt>, path : Array<Dynamic>, w : Int, h : Int, borderColor : Int = -1) : Void{
		if (borderColor < 0)             borderColor = CSS.borderColor;
		g.clear();
		drawBoxBkgGradientShape(g, Math.PI / 2, colors, [0x00, 0xFF], path, w, h);
		g.lineStyle(0.5, borderColor, 1, true);
		DrawPath.drawPath(path, g);
	}

	private static function drawSelected(g : Graphics, colors : Array<UInt>, path : Array<Dynamic>, w : Int, h : Int) : Void{
		g.clear();
		drawBoxBkgGradientShape(g, Math.PI / 2, colors, [0xDC, 0xFF], path, w, h);
		g.lineStyle(0.5, CSS.borderColor, 1, true);
		DrawPath.drawPath(path, g);
	}

	private function curve(g : Graphics, p1x : Int, p1y : Int, p2x : Int, p2y : Int, roundness : Float = 0.42) : Void{
		// Compute the Bezier control point by following an orthogal vector from the midpoint
		// of the line between p1 and p2 scaled by roundness * dist(p1, p2). The default roundness
		// approximates a circular arc. Negative roundness gives a concave curve.

		var midX : Float = (p1x + p2x) / 2.0;
		var midY : Float = (p1y + p2y) / 2.0;
		var cx : Float = midX + (roundness * (p2y - p1y));
		var cy : Float = midY - (roundness * (p2x - p1x));
		g.curveTo(cx, cy, p2x, p2y);
	}

	private static function drawBoxBkgGradientShape(g : Graphics, angle : Float, colors : Array<UInt>, ratios : Array<Int>, path : Array<Dynamic>, w : Float, h : Float) : Void{
		var m : Matrix = new Matrix();
		m.createGradientBox(w, h, angle, 0, 0);
		g.beginGradientFill(GradientType.LINEAR, colors, [100, 100], ratios, m);
		DrawPath.drawPath(path, g);
		g.endFill();
	}

	public static function getTopBarPath(w : Int, h : Int) : Array<Dynamic>{
		return [["m", 0, h], ["v", -h + cornerRadius], ["c", 0, -cornerRadius, cornerRadius, -cornerRadius], 
		["h", w - cornerRadius * 2], ["c", cornerRadius, 0, cornerRadius, cornerRadius], 
		["v", h - cornerRadius]];
	}

	/* Text Menu Buttons */

	public static function makeMenuButton(s : String, fcn : Dynamic->Void, hasArrow : Bool = false, labelColor : Int = 0xFFFFFF) : IconButton{
		var onImg : Sprite = makeButtonLabel(Translator.map(s), CSS.buttonLabelOverColor, hasArrow);
		var offImg : Sprite = makeButtonLabel(Translator.map(s), labelColor, hasArrow);
		var btn : IconButton = new IconButton(fcn, onImg, offImg);
		btn.isMomentary = true;
		return btn;
	}

	public static function makeButtonLabel(s : String, labelColor : Int, hasArrow : Bool) : Sprite{
		var label : TextField = makeLabel(s, CSS.topBarButtonFormat);
		label.textColor = labelColor;
		var img : Sprite = new Sprite();
		img.addChild(label);
		if (hasArrow)             img.addChild(menuArrow(Std.int(label.textWidth + 5), 6, labelColor));
		return img;
	}

	private static function menuArrow(x : Int, y : Int, c : Int) : Shape{
		var arrow : Shape = new Shape();
		var g : Graphics = arrow.graphics;
		g.beginFill(c);
		g.lineTo(8, 0);
		g.lineTo(4, 6);
		g.lineTo(0, 0);
		g.endFill();
		arrow.x = x;
		arrow.y = y;
		return arrow;
	}

	public function new()
	{
		super();
	}
}

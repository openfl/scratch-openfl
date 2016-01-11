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

// BlockShape.as
// John Maloney, August 2009
//
// BlockShape handles drawing and resizing of a block shape.

package blocks;


import flash.display.*;
import flash.filters.*;

class BlockShape extends Shape
{

	// Shapes
	public static inline var RectShape : Int = 1;
	public static inline var BooleanShape : Int = 2;
	public static inline var NumberShape : Int = 3;
	public static inline var CmdShape : Int = 4;
	public static inline var FinalCmdShape : Int = 5;
	public static inline var CmdOutlineShape : Int = 6;
	public static inline var HatShape : Int = 7;
	public static inline var ProcHatShape : Int = 8;
	// C-shaped blocks
	public static inline var LoopShape : Int = 9;
	public static inline var FinalLoopShape : Int = 10;
	// E-shaped blocks
	public static inline var IfElseShape : Int = 11;

	// Geometry
	public static inline var NotchDepth : Int = 3;
	public static inline var EmptySubstackH : Int = 12;
	public static inline var SubstackInset : Int = 15;

	private static inline var CornerInset : Int = 3;
	private static inline var InnerCornerInset : Int = 2;
	private static inline var BottomBarH : Int = 16;  // height of the bottom bar of a C or E block  
	private static inline var DividerH : Int = 18;  // height of the divider bar in an E block  
	private static inline var NotchL1 : Int = 13;
	private static inline var NotchL2 : Int = NotchL1 + NotchDepth;
	private static inline var NotchR1 : Int = NotchL1 + NotchDepth + 8;
	private static inline var NotchR2 : Int = NotchL1 + NotchDepth + 8 + NotchDepth;

	// Variables
	public var color : Int;
	public var hasLoopArrow : Bool;

	private var shape : Int;
	private var w : Int;
	private var topH : Int;
	private var substack1H : Int = EmptySubstackH;
	private var substack2H : Int = EmptySubstackH;
	private var drawFunction : Graphics->Void = drawRectShape;
	private var redrawNeeded : Bool = true;

	public function new(shape : Int = 1, color : Int = 0xFFFFFF)
	{
		super();
		this.color = color;
		this.shape = shape;
		setShape(shape);
		filters = blockShapeFilters();
	}

	public function setWidthAndTopHeight(newW : Int, newTopH : Int, doRedraw : Bool = false) : Void{
		// Set the width and 'top' height of this block. For normal command
		// and reporter blocks, the top height is the height of the block.
		// For C and E shaped blocks (conditionals and loops), the top height
		// is the height of the top bar, which contains block labels and arguments.
		if ((newW == w) && (newTopH == topH))             return;
		w = newW;
		topH = newTopH;
		redrawNeeded = true;
		if (doRedraw)             redraw();
	}

	public function setWidth(newW : Int) : Void{
		if (newW == w)             return;
		w = newW;
		redrawNeeded = true;
	}

	public function copyFeedbackShapeFrom(b : Dynamic, reporterFlag : Bool, isInsertion : Bool = false, targetHeight : Int = 0) : Void{
		// Set my shape from b, which is a Block or BlockArg.
		var s : BlockShape = b.base;
		color = 0x0093ff;
		setShape(s.shape);
		w = s.w;
		topH = s.topH;
		substack1H = s.substack1H;
		substack2H = s.substack2H;
		if (!reporterFlag) {
			if (isInsertion) {
				// inserting in middle or at end of stack (i.e. not above or wrapping around)
				setShape(CmdShape);
				topH = 6;
			}
			else {
				if (!canHaveSubstack1() && !b.isHat)                     topH = b.height;  // normal command block (not hat, C, or E)  ;
				if (targetHeight != 0)                     substack1H = targetHeight - NotchDepth;  // wrapping a C or E block  ;
			}
		}
		filters = dropFeedbackFilters(reporterFlag);
		redrawNeeded = true;
		redraw();
	}

	public function setColor(color : Int) : Void{this.color = color;redrawNeeded = true;
	}

	public function nextBlockY() : Int{
		if (ProcHatShape == shape)             return topH;
		return Std.int(height - NotchDepth);
	}

	public function setSubstack1Height(h : Int) : Void{
		h = Std.int(Math.max(h, EmptySubstackH));
		if (h != substack1H) {substack1H = h;redrawNeeded = true;
		}
	}

	public function setSubstack2Height(h : Int) : Void{
		h = Std.int(Math.max(h, EmptySubstackH));
		if (h != substack2H) {substack2H = h;redrawNeeded = true;
		}
	}

	public function canHaveSubstack1() : Bool{return shape >= LoopShape;
	}
	public function canHaveSubstack2() : Bool{return shape == IfElseShape;
	}

	public function substack1y() : Int{return topH;
	}
	public function substack2y() : Int{return topH + substack1H + DividerH - NotchDepth;
	}

	public function redraw() : Void{
		if (!redrawNeeded)             return;
		var g : Graphics = this.graphics;
		g.clear();
		g.beginFill(color);
		drawFunction(g);
		g.endFill();
		redrawNeeded = false;
	}

	private function blockShapeFilters() : Array<BitmapFilter>{
		// filters for command and reporter Block outlines
		var f : BevelFilter = new BevelFilter(1);
		f.blurX = f.blurY = 3;
		f.highlightAlpha = 0.3;
		f.shadowAlpha = 0.6;
		return [f];
	}

	private function dropFeedbackFilters(forReporter : Bool) : Array<flash.filters.BitmapFilter>{
		// filters for command/reporter block drop feedback
		var f : GlowFilter;
		if (forReporter) {
			f = new GlowFilter(0xFFFFFF);
			f.strength = 5;
			f.blurX = f.blurY = 8;
			f.quality = 2;
		}
		else {
			f = new GlowFilter(0xFFFFFF);
			f.strength = 12;
			f.blurX = f.blurY = 6;
			f.inner = true;
		}
		f.knockout = true;
		return [f];
	}

	private function setShape(shape : Int) : Void{
		this.shape = shape;
		switch (shape)
		{
			case RectShape:drawFunction = drawRectShape;
			case BooleanShape:drawFunction = drawBooleanShape;
			case NumberShape:drawFunction = drawNumberShape;
			case CmdShape, FinalCmdShape:drawFunction = drawCmdShape;
			case CmdOutlineShape:drawFunction = drawCmdOutlineShape;
			case LoopShape, FinalLoopShape:drawFunction = drawLoopShape;
			case IfElseShape:drawFunction = drawIfElseShape;
			case HatShape:drawFunction = drawHatShape;
			case ProcHatShape:drawFunction = drawProcHatShape;
		}
	}

	private function drawRectShape(g : Graphics) : Void{g.drawRect(0, 0, w, topH);
	}

	private function drawBooleanShape(g : Graphics) : Void{
		var centerY : Int = Std.int(topH / 2);
		g.moveTo(centerY, topH);
		g.lineTo(0, centerY);
		g.lineTo(centerY, 0);
		g.lineTo(w - centerY, 0);
		g.lineTo(w, centerY);
		g.lineTo(w - centerY, topH);
	}

	private function drawNumberShape(g : Graphics) : Void{
		var centerY : Int = Std.int(topH / 2);
		g.moveTo(centerY, topH);
		curve(centerY, topH, 0, centerY);
		curve(0, centerY, centerY, 0);
		g.lineTo(w - centerY, 0);
		curve(w - centerY, 0, w, centerY);
		curve(w, centerY, w - centerY, topH);
	}

	private function drawCmdShape(g : Graphics) : Void{
		drawTop(g);
		drawRightAndBottom(g, topH, (shape != FinalCmdShape));
	}

	private function drawCmdOutlineShape(g : Graphics) : Void{
		g.endFill();  // do not fill  
		g.lineStyle(2, 0xFFFFFF, 0.2);
		drawTop(g);
		drawRightAndBottom(g, topH, (shape != FinalCmdShape));
		g.lineTo(0, CornerInset);
	}

	private function drawTop(g : Graphics) : Void{
		g.moveTo(0, CornerInset);
		g.lineTo(CornerInset, 0);
		g.lineTo(NotchL1, 0);
		g.lineTo(NotchL2, NotchDepth);
		g.lineTo(NotchR1, NotchDepth);
		g.lineTo(NotchR2, 0);
		g.lineTo(w - CornerInset, 0);
		g.lineTo(w, CornerInset);
	}

	private function drawRightAndBottom(g : Graphics, bottomY : Int, hasNotch : Bool, inset : Int = 0) : Void{
		g.lineTo(w, bottomY - CornerInset);
		g.lineTo(w - CornerInset, bottomY);
		if (hasNotch) {
			g.lineTo(inset + NotchR2, bottomY);
			g.lineTo(inset + NotchR1, bottomY + NotchDepth);
			g.lineTo(inset + NotchL2, bottomY + NotchDepth);
			g.lineTo(inset + NotchL1, bottomY);
		}
		if (inset > 0) {  // bottom of control structure arm  
			g.lineTo(inset + InnerCornerInset, bottomY);
			g.lineTo(inset, bottomY + InnerCornerInset);
		}
		else {  // bottom of entire block  
			g.lineTo(inset + CornerInset, bottomY);
			g.lineTo(0, bottomY - CornerInset);
		}
	}

	private function drawHatShape(g : Graphics) : Void{
		g.moveTo(0, 12);
		curve(0, 12, 40, 0, 0.15);
		curve(40, 0, 80, 10, 0.12);
		g.lineTo(w - CornerInset, 10);
		g.lineTo(w, 10 + CornerInset);
		drawRightAndBottom(g, topH, true);
	}

	private function drawProcHatShape(g : Graphics) : Void{
		var trimColor : Int = 0x8E2EC2;  // 0xcf4ad9;  
		var archRoundness : Float = Math.min(0.2, 35 / w);
		g.beginFill(Specs.procedureColor);
		g.moveTo(0, 15);
		curve(0, 15, w, 15, archRoundness);
		drawRightAndBottom(g, topH, true);
		g.beginFill(trimColor);
		g.lineStyle(1, Specs.procedureColor);
		g.moveTo(-1, 13);
		curve(-1, 13, w + 1, 13, archRoundness);
		curve(w + 1, 13, w, 16, 0.6);
		curve(w, 16, 0, 16, -archRoundness);
		curve(0, 16, -1, 13, 0.6);
	}

	private function drawLoopShape(g : Graphics) : Void{
		var h1 : Int = topH + substack1H - NotchDepth;
		drawTop(g);
		drawRightAndBottom(g, topH, true, SubstackInset);
		drawArm(g, h1);
		drawRightAndBottom(g, h1 + BottomBarH, (shape == LoopShape));
		if (hasLoopArrow)             drawLoopArrow(g, h1 + BottomBarH);
	}

	private function drawLoopArrow(g : Graphics, h : Int) : Void{
		// Draw the arrow on loop blocks.
		var arrow : Array<Dynamic> = [
		[8, 0], [2, -2], [0, -3], 
		[3, 0], [-4, -5], [-4, 5], [3, 0], 
		[0, 3], [-8, 0], [0, 2]];
		g.beginFill(0, 0.3);
		drawPath(g, w - 15, h - 3, arrow);  // shadow  
		g.beginFill(0xFFFFFF, 0.9);
		drawPath(g, w - 16, h - 4, arrow);  // white arrow  
		g.endFill();
	}

	private function drawPath(g : Graphics, startX : Float, startY : Float, deltas : Array<Dynamic>) : Void{
		// Starting at startX, startY, draw a sequence of lines following the given position deltas.
		var nextX : Float = startX;
		var nextY : Float = startY;
		g.moveTo(nextX, nextY);
		for (d in deltas){
			g.lineTo(nextX += d[0], nextY += d[1]);
		}
	}

	private function drawIfElseShape(g : Graphics) : Void{
		var h1 : Int = topH + substack1H - NotchDepth;
		var h2 : Int = h1 + DividerH + substack2H - NotchDepth;
		drawTop(g);
		drawRightAndBottom(g, topH, true, SubstackInset);
		drawArm(g, h1);
		drawRightAndBottom(g, h1 + DividerH, true, SubstackInset);
		drawArm(g, h2);
		drawRightAndBottom(g, h2 + BottomBarH, true);
	}

	private function drawArm(g : Graphics, armTop : Int) : Void{
		g.lineTo(SubstackInset, armTop - InnerCornerInset);
		g.lineTo(SubstackInset + InnerCornerInset, armTop);
		g.lineTo(w - CornerInset, armTop);
		g.lineTo(w, armTop + CornerInset);
	}

	private function curve(p1x : Int, p1y : Int, p2x : Int, p2y : Int, roundness : Float = 0.42) : Void{
		// Compute the Bezier control point by following an orthogonal vector from the midpoint
		// of the line between p1 and p2 scaled by roundness * dist(p1, p2). The default roundness
		// approximates a circular arc. Negative roundness gives a concave curve.

		var midX : Float = (p1x + p2x) / 2.0;
		var midY : Float = (p1y + p2y) / 2.0;
		var cx : Float = midX + (roundness * (p2y - p1y));
		var cy : Float = midY - (roundness * (p2x - p1x));
		graphics.curveTo(cx, cy, p2x, p2y);
	}
}

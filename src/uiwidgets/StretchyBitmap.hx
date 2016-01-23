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

package uiwidgets;

import uiwidgets.Bitmap;
import uiwidgets.BitmapData;

import openfl.display.*;
import openfl.geom.*;

class StretchyBitmap extends Sprite
{

	private var srcBM : BitmapData;
	private var cachedBM : Bitmap;

	public function new(bm : BitmapData = null, w : Int = 100, h : Int = 75)
	{
		super();
		srcBM = bm;
		if (srcBM == null)             srcBM = new BitmapData(1, 1, false, 0x808080);
		cachedBM = new Bitmap(srcBM);
		addChild(cachedBM);
		setWidthHeight(w, h);
	}

	public function setWidthHeight(w : Int, h : Int) : Void{
		var srcW : Int = srcBM.width;
		var srcH : Int = srcBM.height;
		w = Math.max(w, srcW);
		h = Math.max(h, srcH);
		var halfSrc : Int;

		// adjust width
		var newBM : BitmapData = new BitmapData(w, h, true, 0xFF000000);
		halfSrc = srcW / 2;
		newBM.copyPixels(srcBM, new Rectangle(0, 0, halfSrc, srcH), new Point(0, 0));
		newBM.copyPixels(srcBM, new Rectangle(srcW - halfSrc, 0, halfSrc, srcH), new Point(w - halfSrc, 0));
		for (dstX in halfSrc...(w - halfSrc)){
			newBM.copyPixels(srcBM, new Rectangle(halfSrc, 0, 1, srcH), new Point(dstX, 0));
		}  // adjust height  



		halfSrc = srcH / 2;
		newBM.copyPixels(newBM, new Rectangle(0, (srcH - halfSrc), w, halfSrc), new Point(0, h - halfSrc));
		for (dstY in halfSrc + 1...(h - halfSrc)){
			newBM.copyPixels(newBM, new Rectangle(0, halfSrc, w, 1), new Point(0, dstY));
		}  // install new bitmap  



		cachedBM.bitmapData = newBM;
	}
}

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

package util;


import flash.display.Graphics;

class DrawPath {
	
	public static function drawPath(path : Array<Dynamic>, g : Graphics) : Void{
		var startx : Float = 0;
		var starty : Float = 0;
		var pathx : Float = 0;
		var pathy : Float = 0;
		for (item in path){
			switch (item[0].toLowerCase()) {
				case "m":
					startx = item[1];
					starty = item[2];
					g.moveTo(pathx = startx, pathy = starty);
				case "l":g.lineTo(pathx += item[1], pathy += item[2]);
				case "h":g.lineTo(pathx += item[1], pathy);
				case "v":g.lineTo(pathx, pathy += item[1]);
				case "c":
					var cx : Float = pathx + item[1];
					var cy : Float = pathy + item[2];
					var px : Float = pathx + item[3];
					var py : Float = pathy + item[4];
					g.curveTo(cx, cy, px, py);
					pathx += item[3];
					pathy += item[4];
				case "z":
					g.lineTo(pathx = startx, pathy = starty);
				default:
					trace("DrawPath command not implemented", item[0]);
			}
		}
	}

	public function new()
	{
	}
}

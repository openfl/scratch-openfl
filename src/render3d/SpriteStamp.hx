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

package render3d;


import flash.display.BitmapData;

class SpriteStamp extends BitmapData
{
	public var effects(get, set) : Dynamic;

	private var fx : Dynamic;
	public function new(width : Int, height : Int, fx : Dynamic)
	{
		super(width, height, true, 0);
		effects = fx;
	}

	private function set_effects(o : Dynamic) : Dynamic{
		fx = null;

		if (o != null) {
			fx = { };
			for (prop in Reflect.fields(o))
			Reflect.setField(fx, prop, Reflect.field(o, prop));
		}
		return o;
	}

	private function get_effects() : Dynamic{
		return fx;
	}
}


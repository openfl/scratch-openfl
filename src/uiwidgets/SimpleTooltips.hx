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

import openfl.display.DisplayObject;
import openfl.display.*;
import openfl.events.*;
import openfl.filters.DropShadowFilter;
import openfl.geom.*;
import openfl.text.*;
import openfl.utils.Timer;

import translation.Translator;











class SimpleTooltips
{
	private static var instance : SimpleTooltip = null;
	/**
		 * Add a tooltip to a DisplayObject
		 * @param dObj Attach the tooltip to this
		 * @param opts Options (just 'text' and 'direction' right now)
		 *
		 */
	public static function add(dObj : DisplayObject, opts : Map<String, String>) : Void{
		if (instance == null)             instance = new SimpleTooltip();
		if (dObj == null)             return;
		instance.addTooltip(dObj, opts);
	}

	public static function hideAll() : Void{
		if (instance != null)             instance.forceHide();
	}

	public static function showOnce(dObj : DisplayObject, opts : Dynamic) : Void{
		if (instance == null)             instance = new SimpleTooltip();
		instance.showOnce(dObj, opts);
	}

	public function new()
	{
	}
}

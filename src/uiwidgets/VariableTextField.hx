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


import openfl.text.TextField;
import openfl.text.TextFormat;

import util.StringUtils;

class VariableTextField extends TextField
{
	private var originalText : String;

	//override private function set_text(value : String) : String{
		//throw cast(("Call setText() instead"), Error);
		//return value;
	//}

	public function setText(t : String, context : Map<String,String> = null) : Void{
		originalText = t;
		applyContext(context);
	}

	// Re-substitutes values from this new context into the original text.
	// This context must be a complete context, not just the fields that have changed.
	public function applyContext(context : Map<String,String>) : Void{
		// Assume that the whole text field uses the same format since there's no guarantee how indices will map.
		var oldFormat : TextFormat = this.getTextFormat();
		super.text = (context != null) ? StringUtils.substitute(originalText, context) : originalText;
		setTextFormat(oldFormat);
	}

	public function new()
	{
		super();
	}
}


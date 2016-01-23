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

// TranslatableStrings.as
// John Maloney, August 2012
//
// This class is used to collect strings for translation.
// Call collectAndExport() to write a file of translation strings.
//
// Several techniques are used to collection UI strings:
//	1. a UI class can provide the function strings() that returns an array of the strings it uses
//	2. menu strings are collected by putting Menu into string collection mode and creating menus.
//	3. in some cases (e.g., BlockPalette), strings may be added to the collection at initialization time.
// In any case, the collectAndExport() method is extended with the appropriate calls to UI modules.
// This task could be automated, of course, but this way gives the programmer precise control over
// what strings are collected (for example, it can collect strings that are constructed dynamically).

package translation;


import openfl.net.FileReference;
import scratch.*;
//import soundedit.SoundEditor;
import svgeditor.*;
import ui.*;
import ui.media.*;
import ui.parts.*;
import uiwidgets.*;
import util.*;
import watchers.*;

class TranslatableStrings
{

	private static var exclude : Array<Dynamic> = [
		"1", 
		"%n * %n", "%n + %n", "%n - %n", "%n / %n", 
		"%s < %s", "%s = %s", "%s > %s"];
	private static var uiExtras : Array<String> = ["Backpack"];
	private static var commandExtras : Array<String> = ["define", "else"];

	private static var strings : Array<String> = [];

	public static function exportCommands() : Void{
		strings = commandExtras.copy();
		for (r/* AS3HX WARNING could not determine type for var: r exp: EField(EIdent(Specs),commands) type: null */ in Specs.commands){
			if ((r[2] < 90) || (r[2] > 100)) {  // ignore obsolete and experiment specs (categories 90-100)  
				var spec : String = r[0];
				if ((spec.length > 0) && (spec.charAt(0) != "-"))                     add(spec, true);
			}
		}
		addAll(Specs.extensionSpecs);
		addAll(PaletteSelector.strings());
		export("commands");
	}

	public static function exportHelpScreenNames() : Void{
		// Generate a file mapping block specs to ops, used as keys for help screens.
		var dict : Dynamic = { };
		var keys : Array<String> = [];
		Reflect.setField(dict, "variable reporter", "readVariable");
		Reflect.setField(dict, "set variable to", "setVar:to:");
		Reflect.setField(dict, "change variable by", "changeVar:by:");
		Reflect.setField(dict, "list reporter", "contentsOfList:");
		Reflect.setField(dict, "procedure definition hat", "procDef");
		Reflect.setField(dict, "procedure call block", "call");
		for (r/* AS3HX WARNING could not determine type for var: r exp: EField(EIdent(Specs),commands) type: null */ in Specs.commands){
			if ((r.length > 3) && (r[2] < 90) || (r[2] > 100)) {  // ignore obsolete and experiment specs (categories 90-100)  
				var spec : String = r[0];
				var op : String = r[3];
				if (Lambda.indexOf(keys, spec) < 0) {
					Reflect.setField(dict, spec, op);
					keys.push(spec);
				}
			}
		}
		var data : String = "";
		keys.sort(function(a, b) {
			if (a.toLowerCase() < b.toLowerCase()) return -1;
			if (a.toLowerCase() > b.toLowerCase()) return 1;
			return 0;
		});
//
		//keys.sort(Array.CASEINSENSITIVE);
		for (k in keys){
			data += "\t  '" + Reflect.field(dict, Std.string(k)) + "': '/help/studio/tips/blocks/FILENAME',\n";
		}
		new FileReference().save(data, "helpScreens.txt");
	}

	public static function exportUIStrings() : Void{
		strings = uiExtras.copy();

		// collect strings from various UI classes
		Menu.stringCollectionMode = true;
		//addAll(BackpackPart.strings());
		addAll(BlockMenus.strings());
		addAll(BlockPalette.strings());
		//addAll(ColorPicker.strings());
		//addAll(DrawPropertyUI.strings());
		//addAll(ImageEdit.strings());
		addAll(ImagesPart.strings());
		addAll(LibraryPart.strings());
		addAll(ListWatcher.strings());
		addAll(MediaInfo.strings());
		addAll(MediaLibrary.strings());
		addAll(PaletteBuilder.strings());
		addAll(ProcedureSpecEditor.strings());
		addAll(ProjectIO.strings());
		// Get the strings from the Scratch app instance so that the offline version can add strings
		addAll(Scratch.app.strings());
		addAll(ScriptsPane.strings());
//        addAll(SoundEditor.strings());
		addAll(SoundsPart.strings());
		addAll(SpriteInfoPart.strings());
		addAll(SpriteThumbnail.strings());
		addAll(StagePart.strings());
		addAll(TabsPart.strings());
		addAll(TopBarPart.strings());
		addAll(VariableSettings.strings());
		addAll(Watcher.strings());
		addAll(CameraDialog.strings());
		Menu.stringCollectionMode = false;

		export("uiStrings");
	}

	public static function addAll(list : Array<Dynamic>, removeParens : Bool = true) : Void{
		for (s in list)add(s, removeParens);
	}

	public static function add(s : String, removeParens : Bool = true) : Void{
		if (removeParens)             s = removeParentheticals(s);
		s = removeWhitespace(s);
		if ((s.length < 2) || (Lambda.indexOf(exclude, s) > -1))             return;
		if (Lambda.indexOf(strings, s) > -1)             return ; // already added  ;
		strings.push(s);
	}

	public static function has(s : String) : Bool{return Lambda.indexOf(strings, s) > -1;
	}

	private static function export(defaultName : String) : Void{
		// Save the collected strings to a file, one string per line.
		var data : String = "";
		strings.sort(function(a, b) {
			if (a.toLowerCase() < b.toLowerCase()) return -1;
			if (a.toLowerCase() > b.toLowerCase()) return 1;
			return 0;
		});
		for (s in strings)data += s + "\n";
		data += "\n";
		new FileReference().save(data, defaultName + ".txt");
		Scratch.app.translationChanged();
	}

	private static function removeParentheticals(s : String) : String{
		// Remove substrings of the form (*).
		var i : Int;
		var j : Int;
		while (((i = s.indexOf("(")) > -1) && ((j = s.indexOf(")")) > -1)){
			s = s.substring(0, i) + s.substring(j + 1);
		}
		return s;
	}

	private static function removeWhitespace(s : String) : String{
		// Remove leading and trailing whitespace characters.
		if (s.length == 0)             return "";
		var i : Int = 0;
		while ((i < s.length) && (s.charCodeAt(i) <= 32))i++;
		if (i == s.length)             return "";
		var j : Int = s.length - 1;
		while ((j > i) && (s.charCodeAt(j) <= 32))j--;
		return s.substring(i, j + 1);
	}

	public function new()
	{
	}
}

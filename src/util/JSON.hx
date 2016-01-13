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

// JSON.as
// John Maloney, September 2010
//
// Convert between objects and their JSON string representation.
// Usage:
//	var s:String, obj:Object;
//	s = JSON.stringify(obj)
//  obj = JSON.parse(s)

package util;

import flash.errors.Error;
import util.ReadStream;

import flash.display.BitmapData;
import flash.utils.*;

class JSON
{

	private var src : ReadStream;
	private var buf : String = "";
	private var tabs : String = "";
	private var needsComma : Bool = false;
	private var doFormatting : Bool;

	public static function stringify(obj : Dynamic, doFormatting : Bool = true) : String{
		// Return the JSON string representation for the given object.
		var json : util.JSON = new util.JSON();
		json.doFormatting = doFormatting;
		json.write(obj);
		return json.buf;
	}

	public static function parse(s : String) : Dynamic{
		// Parse the JSON string and return the resulting object.
		var json : util.JSON = new util.JSON();
		json.buf = s;
		json.src = new ReadStream(s);
		return json.readValue();
	}

	public static function escapeForJS(s : String) : String{
		var ch : String;
		var result : String = "";
		for (i in 0 ...s.length){
			result += (ch = s.charAt(i));
			if ("\\" == ch)                 result += "\\";
		}
		return result;
	}

	//----------------------------
	// JSON to string support
	//----------------------------

	private function readValue() : Dynamic{
		skipWhiteSpaceAndComments();
		var ch : String = src.peek();
		if (("0" <= ch) && (ch <= "9"))             return readNumber();  // common case  ;

		switch (ch)
		{
			case "\"":return readString();
			case "[":return readArray();
			case "{":return readObject();
			case "t", "f", "n", "-", "I", "N", "":

				switch (ch)
				{case "t":
						if (src.nextString(4) == "true")                             return true;
						else error("Expected 'true'");
				}

				switch (ch)
				{case "f":
						if (src.nextString(5) == "false")                             return false;
						else error("Expected 'false'");
				}

				switch (ch)
				{case "n":
						if (src.nextString(4) == "null")                             return null;
						else error("Expected 'null'");
				}

				switch (ch)
				{case "-":
						if (src.peekString(9) == "-Infinity") {
							src.skip(9);
							return Math.NEGATIVE_INFINITY;
						}
						else return readNumber();
				}

				switch (ch)
				{case "I":
						if (src.nextString(8) == "Infinity")                             return Math.POSITIVE_INFINITY
						else error("Expected 'Infinity'");
				}

				switch (ch)
				{case "N":
						if (src.nextString(3) == "NaN")                             return Math.NaN;
						else error("Expected 'NaN'");
				}
				error("Incomplete JSON data");
				error("Bad character: " + ch);
			default:
				error("Bad character: " + ch);
		}
		return null;
	}

	private function readArray() : Array<Dynamic>{
		var result : Array<Dynamic> = [];
		src.skip(1);  // skip "["  
		while (true){
			if (src.atEnd())                 return error("Incomplete array");
			skipWhiteSpaceAndComments();
			if (src.peek() == "]")                 break;
			result.push(readValue());
			skipWhiteSpaceAndComments();
			if (src.peek() == ",") {
				src.skip(1);
				continue;
			}
			if (src.peek() == "]")                 break
			else error("Bad array syntax");
		}
		src.skip(1);  // skip "]"  
		return result;
	}

	private function readObject() : Dynamic{
		var result : Dynamic = { };
		src.skip(1);  // skip "{"  
		while (true){
			if (src.atEnd())                 return error("Incomplete object");
			skipWhiteSpaceAndComments();
			if (src.peek() == "}")                 break;
			if (src.peek() != "\"")                 error("Bad object syntax");
			var key : String = readString();
			skipWhiteSpaceAndComments();
			if (src.next() != ":")                 error("Bad object syntax");
			skipWhiteSpaceAndComments();
			var value : Dynamic = readValue();
			Reflect.setField(result, key, value);
			skipWhiteSpaceAndComments();
			if (src.peek() == ",") {
				src.skip(1);
				continue;
			}
			if (src.peek() == "}")                 break
			else error("Bad object syntax");
		}
		src.skip(1);  // skip "}"  
		return result;
	}

	private function readNumber() : Float{
		var numStr : String = "";
		var ch : String = src.peek();

		if ((ch == "0") && (src.peek2() == "x")) {  // hex number  
			numStr = src.nextString(2) + readHexDigits();
			return Std.parseFloat(numStr);
		}

		if (ch == "-")             numStr += src.next();
		numStr += readDigits();
		if ((numStr == "") || (numStr == "-"))             error("At least one digit expected");
		if (src.peek() == ".")             numStr += src.next() + readDigits();
		ch = src.peek();
		if ((ch == "e") || (ch == "E")) {
			numStr += src.next();
			ch = src.peek();
			if ((ch == "+") || (ch == "-"))                 numStr += src.next();
			numStr += readDigits();
		}
		return Std.parseFloat(numStr);
	}

	private function readDigits() : String{
		var result : String = "";
		while (true){
			var ch : String = src.next();
			if (("0" <= ch) && (ch <= "9"))                 result += ch
			else {
				if (ch != "")                     src.skip(-1);
				break;
			}
		}
		return result;
	}

	private function readHexDigits() : String{
		var result : String = "";
		while (true){
			var ch : String = src.next();
			if (("0" <= ch) && (ch <= "9"))                 result += ch
			else if (("a" <= ch) && (ch <= "f"))                 result += ch
			else if (("A" <= ch) && (ch <= "F"))                 result += ch
			else {
				if (!src.atEnd())                     src.skip(-1);
				break;
			}
		}
		return result;
	}

	private function readString() : String{
		var result : String = "";
		src.skip(1);  // skip opening quote  
		var ch : String;
		while ((ch = src.next()) != "\""){
			if (ch == "")                 return error("Incomplete string");
			if (ch == "\\")                 result += readEscapedChar()
			else result += ch;
		}
		return result;
	}

	private function readEscapedChar() : String{
		var ch : String = src.next();
		switch (ch)
		{
			//case "b":return "\b";
			//case "f":return "\f";
			case "n":return "\n";
			case "r":return "\r";
			case "t":return "\t";
			case "u":return String.fromCharCode(Std.parseInt("0x" + src.nextString(4)));
		}
		return ch;
	}

	private function skipWhiteSpaceAndComments() : Void{
		while (true){
			// skip comments and white space until the stream position does not change
			var lastPos : Int = src.pos();
			src.skipWhiteSpace();
			skipComment();
			if (src.pos() == lastPos)                 break;  // done  ;
		}
	}

	private function skipComment() : Void{
		var ch : String;
		if ((src.peek() == "/") && (src.peek2() == "/")) {
			src.skip(2);
			while ((ch = src.next()) != "\n"){  // comments goes until the end of the line  
				if (ch == "")                     return;  // end of stream  ;
			}
		}
		if ((src.peek() == "/") && (src.peek2() == "*")) {
			src.skip(2);
			var lastWasAsterisk : Bool = false;
			while (true){
				ch = src.next();
				if (ch == "")                     return;  // end of stream  ;
				if (lastWasAsterisk && (ch == "/"))                     return;  // end of comment  ;
				if (ch == "*")                     lastWasAsterisk = true;
			}
		}
	}

	private function error(msg : String) : Dynamic{
		throw new Error(msg + " [pos=" + src.pos()) + "] in " + buf;
	}

	//----------------------------
	// Object to JSON support
	//----------------------------

	public function writeKeyValue(key : String, value : Dynamic) : Void{
		// This method is called by custom writeJSON() methods.
		if (needsComma)             buf += (doFormatting) ? ",\n" : ", ";
		buf += tabs + "\"" + key + "\": ";
		write(value);
		needsComma = true;
	}

	private function write(value : Dynamic) : Void{
		// Write a value in JSON format. The argument of the top-level call is usually an object or array.
		if (Std.is(value, Float))             buf += (Math.isFinite(value)) ? value : "0"
		else if (Std.is(value, Bool))             buf += value
		else if (Std.is(value, String))             buf += "\"" + encodeString(value) + "\""
		else if (value == null)             buf += "null"
		else if (Std.is(value, Array))             writeArray(value)
		else if (Std.is(value, BitmapData))             buf += "null"
		// bitmaps sometimes appear in old project info objects
		else writeObject(value);
	}

	private function writeObject(obj : Dynamic) : Void{
		var savedNeedsComma : Bool = needsComma;
		needsComma = false;
		buf += "{";
		if (doFormatting)             buf += "\n";
		indent();
		if (isClass(obj, "Object") || isClass(obj, "Dictonary")) {
			for (k in Reflect.fields(obj))writeKeyValue(k, Reflect.field(obj, k));
		}
		else {
			obj.writeJSON(this);
		}
		if (doFormatting && needsComma)             buf += "\n";
		outdent();
		buf += tabs + "}";
		needsComma = savedNeedsComma;
	}

	private function isClass(obj : Dynamic, className : String) : Bool{
		var fullName : String = Type.getClassName(obj);
		var i : Int = fullName.lastIndexOf(className);
		return i == (fullName.length - className.length);
	}

	private function writeArray(a : Array<Dynamic>) : Void{
		var separator : String = ", ";
		var indented : Bool = doFormatting && ((a.length > 13) || needsMultipleLines(a, 13));
		buf += "[";
		indent();
		if (indented)             separator = ",\n" + tabs;
		for (i in 0...a.length){
			write(a[i]);
			if (i < (a.length - 1))                 buf += separator;
		}
		outdent();
		buf += "]";
	}

	private function needsMultipleLines(arrayValue : Array<Dynamic>, limit : Int) : Bool{
		// Return true if this array is short enough to fit on one line.
		// (This is simply to make the JSON representation of stacks more readable.)
		var count : Int = 0;
		var toDo : Array<Dynamic> = [arrayValue];
		while (toDo.length > 0){
			var a : Array<Dynamic> = toDo.pop();
			count += a.length;
			if (count > limit)                 return true;
			var i : Int = 0;
			while (i < a.length) {
				var item : Dynamic = a[i];
				if ((Std.is(item, Float)) || (Std.is(item, Bool)) || (Std.is(item, String)) || (item == null))                     { i++; i++; continue;
				}  // atomic value  ;
				if (Std.is(item, Array))                     toDo.push(item)
				else return true;
				i++;
			}
		}
		return false;
	}

	private function encodeString(s : String) : String{
		var result : String = "";
		var i: Int = 0;
		while (i < s.length){
			var ch : String = s.charAt(i);
			var code : Int = s.charCodeAt(i);
			if (code < 32) {
				if (code == 9)                     result += "\\t"
				else if (code == 10)                     result += "\\n"
				else if (code == 13)                     result += "\\r"
				else {
					var hex : String = Std.string(code);
					while (hex.length < 4)hex = "0" + hex;
					result += "\\u" + hex;
				}
				{i++; i++; continue;
				}
			}
			else if (ch == "\\")                 result += "\\\\"
			else if (ch == "\"")                 result += "\\\""
			else if (ch == "/")                 result += "\\/"
			else result += ch;
			i++;
		}
		return result;
	}

	private function indent() : Void{if (doFormatting)             tabs += "\t";
	}

	private function outdent() : Void{
		if (tabs.length == 0)             return;
		tabs = tabs.substring(0, tabs.length - 1);
	}

	public function new()
	{
	}
}

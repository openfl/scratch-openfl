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

// ReadStream.as
// John Maloney, October 2009
//
// A simple character stream with two character look-ahead and tokenization.

package util;


class ReadStream {
	
	private var src : String;private var i : Int;
	
	public function new(s : String)
	{
		src = s;
		i = 0;
	}
	
	public function atEnd() : Bool{
		return i >= src.length;
	}
	
	public function next() : String{
		if (i >= src.length) 			return "";
		return src.charAt(i++);
	}
	
	public function peek() : String{
		return ((i < src.length)) ? src.charAt(i) : "";
	}
	
	public function peek2() : String{
		return (((i + 1) < src.length)) ? src.charAt(i + 1) : "";
	}
	
	public function peekString(n : Int) : String{return src.substring(i, i + n);
	}
	
	public function nextString(n : Int) : String{
		i += n;
		return src.substring(i - n, i);
	}
	
	public function pos() : Int{return i;
	}
	
	public function setPos(newPos : Int) : Void{i = newPos;
	}
	
	public function skip(count : Int) : Void{i += count;
	}
	
	public function skipWhiteSpace() : Void{
		while ((i < src.length) && (src.charCodeAt(i) <= 32))i++;
	}
	
	public function upToEnd() : String{
		var result : String = ((i < src.length)) ? src.substring(i, src.length) : "";
		i = src.length;
		return result;
	}
	
	public static function tokenize(s : String) : Array<Dynamic>{
		var stream : ReadStream = new ReadStream(s);
		var result : Array<Dynamic> = [];
		while (!stream.atEnd()){
			var token : String = stream.nextToken();
			if (token.length > 0) 				result.push(token);
		}
		return result;
	}
	
	public function nextToken() : String{
		skipWhiteSpace();
		if (atEnd()) 			return "";
		var token : String = "";
		var isArg : Bool;
		var start : Int = i;
		while (i < src.length){
			if (src.charCodeAt(i) <= 32) 				break;
			var ch : String = src.charAt(i);
			if (ch == "\\") {
				token += ch + src.charAt(i + 1);
				i += 2;
				continue;
			}
			if (ch == "%") {
				if (i > start) 					break;  // percent sign starts new token  ;
				isArg = true;
			}  // example: 'touching %m?' (question mark after arg starts a new token) vs. 'loud?' (doesn't)    // certain punctuation marks following an argument start a new token  
			
			
			
			if (isArg && (ch == "?" || ch == "-")) 				break;
			token += ch;
			i++;
		}
		return token;
	}
	
	public static function escape(s : String) : String{
		return s.replace(new EReg('[\\\\%@]', "g"), "\\$&");
	}
	
	public static function unescape(s : String) : String{
		var result : String = "";
		for (i in 0...s.length){
			var ch : String = s.charAt(i);
			if (ch == "\\") {
				result += s.charAt(i + 1);
				i++;
			}
			else {
				result += ch;
			}
		}
		return result;
	}
}

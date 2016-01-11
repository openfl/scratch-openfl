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




class Perf
{

	private static var totalStart : Int;
	private static var lapStart : Int;
	private static var lapTotal : Int;

	public static function start(msg : String = null) : Void{
		if (msg == null)             msg = "Perf.start";
		Scratch.app.log(msg);
		totalStart = lapStart = Math.round(haxe.Timer.stamp() * 1000);
		lapTotal = 0;
	}

	public static function clearLap() : Void{
		lapStart = Math.round(haxe.Timer.stamp() * 1000);
	}

	public static function lap(msg : String = "") : Void{
		if (totalStart == 0)             return  // not monitoring performance  ;
		var lapMSecs : Int = Math.round(haxe.Timer.stamp() * 1000) - lapStart;
		Scratch.app.log("  " + msg + ": " + lapMSecs + " msecs");
		lapTotal += lapMSecs;
		lapStart = Math.round(haxe.Timer.stamp() * 1000);
	}

	public static function end() : Void{
		if (totalStart == 0)             return  // not monitoring performance  ;
		var totalMSecs : Int = Math.round(haxe.Timer.stamp() * 1000) - totalStart;
		var unaccountedFor : Int = totalMSecs - lapTotal;
		Scratch.app.log("Total: " + totalMSecs + " msecs; unaccounted for: " + unaccountedFor + " msecs (" + Std.parseInt((100 * unaccountedFor) / totalMSecs) + "%)");
		totalStart = lapStart = lapTotal = 0;
	}

	public function new()
	{
	}
}

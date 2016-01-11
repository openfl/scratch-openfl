/*
 * Scratch Project Editor and Player
 * Copyright (C) 2015 Massachusetts Institute of Technology
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

package logging;




class LogEntry
{
	public var timeStamp : Float;
	public var severity : Int;
	public var messageKey : String;
	public var extraData : Dynamic;

	public function new(severity : String, messageKey : String, extraData : Dynamic = null)
	{
		setAll(severity, messageKey, extraData);
	}

	// Set all fields of this event
	public function setAll(severity : String, messageKey : String, extraData : Dynamic = null) : Void{
		this.timeStamp = getCurrentTime();
		this.severity = LogLevel.LEVEL.indexOf(severity);
		this.messageKey = messageKey;
		this.extraData = extraData;
	}

	private static var tempDate : Date = Date.now();
	private function makeTimeStampString() : String{
		tempDate.time = timeStamp;
		return tempDate.toLocaleTimeString();
	}

	// Generate a string representing this event. Does not include extraData.
	public function toString() : String{
		return [makeTimeStampString(), LogLevel.LEVEL[severity], messageKey].join(" | ");
	}

	private static var timerOffset : Float = Date.now().getTime() - Math.round(haxe.Timer.stamp() * 1000);

	// Returns approximately the same value as "new Date().time" without GC impact
	public static function getCurrentTime() : Float{
		return Math.round(haxe.Timer.stamp() * 1000) + timerOffset;
	}
}


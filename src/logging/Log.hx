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

import logging.LogEntry;

import openfl.system.Capabilities;

import util.JSON;

class Log
{

	// Should the logger echo log entries to JavaScript?
	public var echoToJS : Bool = true;

	public var logBuffer : Array<LogEntry> = [];

	private var fixedBuffer : Bool;
	private var nextIndex : Int;

	// If messageCount is 0, keep all logged messages. Otherwise throw out old messages once `messageCount` is reached.
	public function new(messageCount : Int)
	{
		fixedBuffer = (messageCount > 0);
		if (fixedBuffer) {
			logBuffer.splice(messageCount, logBuffer.length - messageCount);
		}
		nextIndex = 0;
	}

	// Add a new entry to the log.
	public function log(severity : String, messageKey : String, extraData : Dynamic = null) : LogEntry{
		var entry : LogEntry = logBuffer[nextIndex];
		if (entry != null) {
			// Reduce GC impact by replacing the contents of existing entries
			entry.setAll(severity, messageKey, extraData);
		}
		else {
			// Either we're not in fixedBufer mode or we haven't yet filled the buffer.
			entry = new LogEntry(severity, messageKey, extraData);
			logBuffer[nextIndex] = entry;
		}
		++nextIndex;
		if (fixedBuffer) {
			nextIndex %= logBuffer.length;
		}

		var entryString : String = null;
		function getEntryString() : String {
			if (entryString == null)
				entryString = Std.string(entry);
			return entryString;
		};

		var extraString : String = null;
		function getExtraString() : String {
			if (extraString == null)
				extraString = util.JSON.stringify(extraData);
			return extraString;
		};

		if (Capabilities.isDebugger) {
			trace(getEntryString());
		}
		//if (Scratch.app.jsEnabled) {
			//if (echoToJS) {
				//Scratch.app.externalCall(
						//"console.log", null, getEntryString() + ((extraData != null) ? "\n" + getExtraString() : ""));
			//}
			//if (LogLevel.TRACK == severity) {
				//Scratch.app.externalCall(
						//"JStrackEvent", null, messageKey, (extraData != null) ? getExtraString() : null);
			//}
		//}
		return entry;
	}

	// Generate a JSON-compatible object representing the contents of the log in a human- and machine-readable way.
	public function report(severityLimit : String = LogLevel.DEBUG) : Dynamic{
		var maxSeverity : Int = LogLevel.LEVEL.indexOf(severityLimit);
		var baseIndex : Int = (fixedBuffer) ? nextIndex : 0;
		var count : Int = logBuffer.length;
		var jsonArray : Array<Dynamic> = [];
		for (index in 0...count){
			var entry : LogEntry = logBuffer[(baseIndex + index) % count];
			// If we're in fixedBuffer mode and nextIndex hasn't yet wrapped then there will be null entries
			if (entry != null && (entry.severity <= maxSeverity)) {
				jsonArray.push(Std.string(entry));
				if (entry.extraData) {
					jsonArray.push(entry.extraData);
				}
			}
		}
		return jsonArray;
	}
}


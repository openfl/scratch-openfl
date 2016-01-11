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



class LogLevel
{
	// Use this for problems that should be in our control
	public static inline var ERROR : String = "err";

	// Use this for unexpected conditions and problems outside our control (network, user data, etc.)
	public static inline var WARNING : String = "wrn";

	// These events will be communicated to JS so they can be handled by web UI, sent to GA, etc.
	public static inline var TRACK : String = "trk";

	// Use this to report status information
	public static inline var INFO : String = "inf";

	// Use this to report information useful for debugging
	public static inline var DEBUG : String = "dbg";

	public static var LEVEL : Array<Dynamic> = [
		ERROR, WARNING, TRACK, INFO, DEBUG];

	public function new()
	{
	}
}


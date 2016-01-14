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

// IServer.as
// Shane Clements, March 2014
//
// Interface to the Scratch website API's
//
// Note: All operations call the callback function with the result
// if the operation succeeded or null if it failed.

package util;


import flash.net.URLLoader;
import openfl.utils.ByteArray;

interface IServer
{

	// -----------------------------
	// Asset API
	//------------------------------
	function getAsset(md5 : String, callback : ByteArray->Void) : URLLoader;
	function getMediaLibrary(type : String, callback : Dynamic->Void) : URLLoader;
	function getThumbnail(md5 : String, w : Int, h : Int, callback : Dynamic->Void) : URLLoader;

	// -----------------------------
	// Translation Support
	//------------------------------
	function getLanguageList(callback : Dynamic->Void) : Void;
	function getPOFile(lang : String, callback : Dynamic->Void) : Void;
	function getSelectedLang(callback : Dynamic->Void) : Void;
	function setSelectedLang(lang : String) : Void;
}

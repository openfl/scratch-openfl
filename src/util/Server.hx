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

// ServerOffline.as
// John Maloney, June 2013
//
// Interface to the Scratch website API's for Offline Editor.
//
// Note: All operations call the whenDone function with the result
// if the operation succeeded or null if it failed.

package util;


//import by.blooddy.crypto.serialization.JSON;

import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.geom.Matrix;
import flash.net.SharedObject;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.net.URLRequestMethod;
import flash.system.Capabilities;
import flash.system.Security;
import flash.utils.ByteArray;

import logging.LogLevel;

import mx.utils.URLUtil;

class Server implements IServer
{

	private var URLs : Dynamic = { };

	public function new()
	{
		setDefaultURLs();

		// Accept URL overrides from the flash variables
		//try{
			//var urlOverrides : String = Scratch.app.loaderInfo.parameters["urlOverrides"];
			//if (urlOverrides != null)                 overrideURLs(by.blooddy.crypto.serialization.JSON.decode(urlOverrides));
		//}        catch (e : Dynamic){
//
		//}
	}

	// No default URLs
	private function setDefaultURLs() : Void{
	}

	public function overrideURLs(overrides : Dynamic) : Void{
		var forceProtocol : String;
		var swfURL : String = Scratch.app.loaderInfo.url;
		if (swfURL != null && URLUtil.isHttpURL(swfURL)) {  // "isHttpURL" is true if the protocol is either HTTP or HTTPS  
			forceProtocol = URLUtil.getProtocol(swfURL);
		}
		for (name in Reflect.fields(overrides)){
			if (overrides.exists(name)) {
				var url : String = Reflect.field(overrides, name);

				if (forceProtocol != null && URLUtil.isHttpURL(url)) {
					url = URLUtil.replaceProtocol(url, forceProtocol);
				}

				Reflect.setField(URLs, name, url);
			}
		}
	}

	private function getCdnStaticSiteURL() : String{
		return URLs.siteCdnPrefix + URLs.staticFiles;
	}

	// Returns a URL for downloading the JS for an official extension given input like 'myExtension.js'
	public function getOfficialExtensionURL(extensionName : String) : String{
		var path : String;

		if (Scratch.app.isOffline) {
			path = "static/js/scratch_extensions/";
		}
		else if (Scratch.app.isExtensionDevMode) {
			path = "scratch_extensions/";
		}
		else {
			// Skip the CDN when debugging to make iteration easier
			var extensionSite : String = (Capabilities.isDebugger) ? URLs.sitePrefix : URLs.siteCdnPrefix;
			path = extensionSite + URLs.staticFiles + "js/scratch_extensions/";
		}

		path += extensionName;

		return path;
	}

	// -----------------------------
	// Server GET/POST
	//------------------------------

	// This will be called with the HTTP status result from any callServer() that receives one, even when successful.
	// The url and data parameters match those passed to callServer.
	private function onCallServerHttpStatus(url : String, data : Dynamic, event : HTTPStatusEvent) : Void{
		if (event.status < 200 || event.status > 299) {
			if (event.status != 0)                   // Happens when reading local files  
			Scratch.app.logMessage(url + " -- " + Std.string(event));
		}
	}

	// This will be called if callServer encounters an error, before whenDone(null) is called.
	// The url and data parameters match those passed to callServer.
	private function onCallServerError(url : String, data : Dynamic, event : ErrorEvent) : Void{
		//			if(err.type != IOErrorEvent.IO_ERROR || url.indexOf('/backpack/') == -1) {
		//				if(data)
		//					Scratch.app.logMessage('Failed server request for '+url+' with data ['+data+']');
		//				else
		//					Scratch.app.logMessage('Failed server request for '+url);
		//			}
		// We shouldn't have SecurityErrorEvents unless the crossdomain file failed to load
		// Re-trying here should help project save failures but we'll need to add more code to re-try loading projects
		if (Std.is(event, SecurityErrorEvent)) {
			var urlPathStart : Int = url.indexOf("/", 10);
			var policyFileURL : String = url.substr(0, urlPathStart) + "/crossdomain.xml?cb=" + Math.random();
			Security.loadPolicyFile(policyFileURL);
			Scratch.app.log(LogLevel.WARNING, "Reloading policy file", {
						url : policyFileURL

					});
		}
		if (data != null || url.indexOf("/set/") > -1) {
			// TEMPORARY HOTFIX: Don't send this message since it seems to saturate our logging backend.
			//Scratch.app.logMessage('Failed server request for '+url+' with data ['+data+']');
			trace("Failed server request for " + url + " with data [" + data + "]");
		}
	}

	// This will be called if callServer encounters an exception, before whenDone(null) is called.
	// The url and data parameters match those passed to callServer.
	private function onCallServerException(url : String, data : Dynamic, exception : Dynamic) : Void{
		if (Std.is(exception, Error)) {
			Scratch.app.logException(exception);
		}
	}

	// TODO: Maybe should have this or onCallServerError() but not both
	public var callServerErrorInfo : Dynamic;  // only valid during a whenDone() call reporting failure.  

	// Make a GET or POST request to the given URL (do a POST if the data is not null).
	// The whenDone() function is called when the request is done, either with the
	// data returned by the server or with a null argument if the request failed.
	// The request includes site and session authentication headers.
	private function callServer(url : String, data : Dynamic, mimeType : String, whenDone : Function,
			queryParams : Dynamic = null) : URLLoader{
		function addListeners() : Void{
			loader.addEventListener(Event.COMPLETE, completeHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, statusHandler);
		};

		function removeListeners() : Void{
			loader.removeEventListener(Event.COMPLETE, completeHandler);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, statusHandler);
		};

		function completeHandler(event : Event) : Void{
			removeListeners();
			callServerErrorInfo = null;
			whenDone(loader.data);
		};

		var httpStatus : Int = 0;

		function errorHandler(event : ErrorEvent) : Void{
			removeListeners();
			onCallServerError(url, data, event);
			callServerErrorInfo = {
						url : url,
						httpStatus : httpStatus,
						errorEvent : event,

					};
			whenDone(null);
			callServerErrorInfo = null;
		};

		function exceptionHandler(exception : Dynamic) : Void{
			removeListeners();
			onCallServerException(url, data, exception);
			whenDone(null);
		};

		function statusHandler(e : HTTPStatusEvent) : Void{
			httpStatus = e.status;
			onCallServerHttpStatus(url, data, e);
		};

		var loader : URLLoader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.BINARY;
		addListeners();

		// Add a cache breaker if we're sending data and the url has no query string.
		var nextSeparator : String = "?";
		if (data != null && url.indexOf("?") == -1) {
			url += "?v=" + Scratch.versionString + "&_rnd=" + Math.random();
			nextSeparator = "&";
		}
		for (key in Reflect.fields(queryParams)){
			if (queryParams.exists(key)) {
				url += nextSeparator + encodeURIComponent(key) + "=" + encodeURIComponent(Reflect.field(queryParams, key));
				nextSeparator = "&";
			}
		}
		var request : URLRequest = new URLRequest(url);
		if (data != null) {
			request.method = URLRequestMethod.POST;
			request.data = data;

			if (mimeType != null)                 request.requestHeaders.push(new URLRequestHeader("Content-type", mimeType));  // header for CSRF authentication when sending data  ;



			var csrfCookie : String = getCSRF();
			if (csrfCookie != null && (csrfCookie.length > 0)) {
				request.requestHeaders.push(new URLRequestHeader("X-CSRFToken", csrfCookie));
			}
		}

		try{
			loader.load(request);
		}        catch (e : Dynamic){
			// Local sandbox exception?
			exceptionHandler(e);
		}
		return loader;
	}

	public function getCSRF() : String{
		return null;
	}

	// Make a simple GET. Uses the same callbacks as callServer().
	public function serverGet(url : String, whenDone : Function) : URLLoader{
		return callServer(url, null, null, whenDone);
	}

	// -----------------------------
	// Asset API
	//------------------------------
	public function getAsset(md5 : String, whenDone : Function) : URLLoader{
		//		if (BackpackPart.localAssets[md5] && BackpackPart.localAssets[md5].length > 0) {
		//			whenDone(BackpackPart.localAssets[md5]);
		//			return null;
		//		}
		var url : String = URLs.assetCdnPrefix + URLs.internalAPI + "asset/" + md5 + "/get/";
		return serverGet(url, whenDone);
	}

	public function getMediaLibrary(libraryType : String, whenDone : Function) : URLLoader{
		var url : String = getCdnStaticSiteURL() + "medialibraries/" + libraryType + "Library.json";
		return serverGet(url, whenDone);
	}

	private function downloadThumbnail(url : String, w : Int, h : Int, whenDone : Function) : URLLoader{
		function decodeImage(data : ByteArray) : Void{
			if (data == null || data.length == 0)                 return  // no data  ;
			var decoder : Loader = new Loader();
			decoder.contentLoaderInfo.addEventListener(Event.COMPLETE, imageDecoded);
			decoder.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, imageError);
			try{
				decoder.loadBytes(data);
			}            catch (e : Dynamic){
				if (Std.is(e, Error)) {
					Scratch.app.logException(e);
				}
				else {
					Scratch.app.logMessage("Server caught exception decoding image: " + url);
				}
			}
		};

		function imageError(e : IOErrorEvent) : Void{
			Scratch.app.log(LogLevel.WARNING, "ServerOnline failed to decode image", {
						url : url

					});
		};

		function imageDecoded(e : Event) : Void{
			whenDone(makeThumbnail(e.target.content.bitmapData));
		};

		return serverGet(url, decodeImage);
	}

	private static function makeThumbnail(bm : BitmapData) : BitmapData{
		var tnWidth : Int = 120;
		var tnHeight : Int = 90;
		var result : BitmapData = new BitmapData(tnWidth, tnHeight, true, 0);
		if ((bm.width == 0) || (bm.height == 0))             return result;
		var scale : Float = Math.min(tnWidth / bm.width, tnHeight / bm.height);
		var m : Matrix = new Matrix();
		m.scale(scale, scale);
		m.translate((tnWidth - (scale * bm.width)) / 2, (tnHeight - (scale * bm.height)) / 2);
		result.draw(bm, m);
		return result;
	}

	public function getThumbnail(idAndExt : String, w : Int, h : Int, whenDone : Function) : URLLoader{
		var url : String = getCdnStaticSiteURL() + "medialibrarythumbnails/" + idAndExt;
		return downloadThumbnail(url, w, h, whenDone);
	}

	// -----------------------------
	// Translation Support
	//------------------------------

	public function getLanguageList(whenDone : Function) : Void{
		serverGet("locale/lang_list.txt", whenDone);
	}

	public function getPOFile(lang : String, whenDone : Function) : Void{
		serverGet("locale/" + lang + ".po", whenDone);
	}

	public function getSelectedLang(whenDone : Function) : Void{
		// Get the language setting.
		var sharedObj : SharedObject = SharedObject.getLocal("Scratch");
		if (sharedObj.data.lang)             whenDone(sharedObj.data.lang);
	}

	public function setSelectedLang(lang : String) : Void{
		// Record the language setting.
		var sharedObj : SharedObject = SharedObject.getLocal("Scratch");
		if (lang == "")             lang = "en";
		sharedObj.data.lang = lang;
		sharedObj.flush();
	}
}


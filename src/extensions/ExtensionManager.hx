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

// ExtensionManager.as
// John Maloney, September 2011
//
// Scratch extension manager. Maintains a dictionary of all extensions in use and manages
// socket-based communications with local and server-based extension helper applications.

package extensions;

import extensions.Event;
import extensions.Scratch;
import extensions.ScratchExtension;
import extensions.Thread;
import extensions.URLLoader;
import extensions.URLRequest;

import blocks.Block;

import com.adobe.utils.StringUtil;

import flash.errors.IllegalOperationError;
import flash.events.*;
import flash.net.*;
import flash.utils.Dictionary;


import interpreter.*;

import mx.utils.URLUtil;

import uiwidgets.DialogBox;
import uiwidgets.IndicatorLight;

import util.*;

class ExtensionManager {
	
	private var app : Scratch;
	private var extensionDict : Dynamic = new Dynamic();  // extension name -> extension record  
	private var justStartedWait : Bool;
	private var pollInProgress : Dictionary = new Dictionary(true);
	public static inline var wedoExt : String = "LEGO WeDo";
	
	public function new(app : Scratch)
	{
		this.app = app;
		clearImportedExtensions();
	}
	
	public function extensionActive(extName : String) : Bool{
		return extensionDict.exists(extName);
	}
	
	public function isInternal(extName : String) : Bool{
		return (extensionDict.exists(extName) && Reflect.field(extensionDict, extName).isInternal);
	}
	
	public function clearImportedExtensions() : Void{
		for (ext/* AS3HX WARNING could not determine type for var: ext exp: EIdent(extensionDict) type: Dynamic */ in extensionDict){
			if (ext.showBlocks) 
				setEnabled(ext.name, false);
		}  // Clear imported extensions before loading a new project.  
		
		
		
		extensionDict = { };
		Reflect.setField(extensionDict, "PicoBoard", ScratchExtension.PicoBoard());
		Reflect.setField(extensionDict, wedoExt, ScratchExtension.WeDo());
	}
	
	// -----------------------------
	// Block Specifications
	//------------------------------
	
	public function specForCmd(op : String) : Array<Dynamic>{
		// Return a command spec array for the given operation or null.
		for (ext/* AS3HX WARNING could not determine type for var: ext exp: EIdent(extensionDict) type: Dynamic */ in extensionDict){
			var prefix : String = (ext.useScratchPrimitives) ? "" : (ext.name + ".");
			for (spec/* AS3HX WARNING could not determine type for var: spec exp: EField(EIdent(ext),blockSpecs) type: null */ in ext.blockSpecs){
				if ((spec.length > 2) && ((prefix + spec[2]) == op)) {
					return [spec[1], spec[0], Specs.extensionsCategory, op, spec.substring(3)];
				}
			}
		}
		return null;
	}
	
	// -----------------------------
	// Enable/disable/reset
	//------------------------------
	
	public function setEnabled(extName : String, flag : Bool) : Void{
		var ext : ScratchExtension = Reflect.field(extensionDict, extName);
		if (ext != null && ext.showBlocks != flag) {
			ext.showBlocks = flag;
			if (app.jsEnabled && ext.javascriptURL) {
				if (flag) {
					var javascriptURL : String = (ext.isInternal) ? Scratch.app.fixExtensionURL(ext.javascriptURL) : ext.javascriptURL;
					app.externalCall("ScratchExtensions.loadExternalJS", null, javascriptURL);
					ext.showBlocks = false;
				}
				else {
					app.externalCall("ScratchExtensions.unregister", null, extName);
					if (!ext.isInternal) 						;
					app.updateTopBar();
				}
			}
		}
	}
	
	public function isEnabled(extName : String) : Bool{
		var ext : ScratchExtension = Reflect.field(extensionDict, extName);
		return (ext != null) ? ext.showBlocks : false;
	}
	
	public function enabledExtensions() : Array<Dynamic>{
		// Answer an array of enabled extensions, sorted alphabetically.
		var result : Array<Dynamic> = [];
		for (ext/* AS3HX WARNING could not determine type for var: ext exp: EIdent(extensionDict) type: Dynamic */ in extensionDict){
			if (ext.showBlocks) 				result.push(ext);
		}
		result.sortOn("name");
		return result;
	}
	
	public function stopButtonPressed() : Dynamic{
		// Send a reset_all command to all active extensions.
		for (ext/* AS3HX WARNING could not determine type for var: ext exp: ECall(EIdent(enabledExtensions),[]) type: null */ in enabledExtensions()){
			call(ext.name, "reset_all", []);
		}
	}
	
	public function extensionsToSave() : Array<Dynamic>{
		// Answer an array of extension descriptor objects for imported extensions to be saved with the project.
		var result : Array<Dynamic> = [];
		for (ext/* AS3HX WARNING could not determine type for var: ext exp: EIdent(extensionDict) type: Dynamic */ in extensionDict){
			if (!ext.showBlocks) 				continue;
			
			var descriptor : Dynamic = { };
			descriptor.extensionName = ext.name;
			descriptor.blockSpecs = ext.blockSpecs;
			descriptor.menus = ext.menus;
			if (ext.port) 				descriptor.extensionPort = ext.port
			else if (ext.javascriptURL) 				descriptor.javascriptURL = ext.javascriptURL;
			result.push(descriptor);
		}
		return result;
	}
	
	// -----------------------------
	// Communications
	//------------------------------
	
	public function callCompleted(extensionName : String, id : Float) : Void{
		var ext : ScratchExtension = Reflect.field(extensionDict, extensionName);
		if (ext == null) 			return  // unknown extension  ;
		
		var index : Int = ext.busy.indexOf(id);
		if (index > -1) 			ext.busy.splice(index, 1);
	}
	
	public function reporterCompleted(extensionName : String, id : Float, retval : Dynamic) : Void{
		var ext : ScratchExtension = Reflect.field(extensionDict, extensionName);
		if (ext == null) 			return  // unknown extension  ;
		
		app.updateTopBar();
		
		var index : Int = ext.busy.indexOf(id);
		if (index > -1) {
			ext.busy.splice(index, 1);
			for (b in Reflect.fields(ext.waiting)){
				if (ext.waiting[b] == id) {
					(try cast(b, Block) catch(e:Dynamic) null).response = retval;
					(try cast(b, Block) catch(e:Dynamic) null).requestState = 2;
				}
			}
		}
	}
	
	// -----------------------------
	// Loading
	//------------------------------
	
	public function loadCustom(ext : ScratchExtension) : Void{
		if (!extensionDict[ext.name] && ext.javascriptURL) {
			extensionDict[ext.name] = ext;
			ext.showBlocks = false;
			setEnabled(ext.name, true);
		}
	}
	
	public function loadRawExtension(extObj : Dynamic) : ScratchExtension{
		var ext : ScratchExtension = extensionDict[extObj.extensionName];
		if (ext == null) 
			ext = new ScratchExtension(extObj.extensionName, extObj.extensionPort);
		ext.port = extObj.extensionPort;
		ext.blockSpecs = extObj.blockSpecs;
		if (app.isOffline && (ext.port == 0)) {
			// Fix up block specs to force reporters to be treated as requesters.
			// This is because the offline JS interface doesn't support returning values directly.
			for (spec/* AS3HX WARNING could not determine type for var: spec exp: EField(EIdent(ext),blockSpecs) type: null */ in ext.blockSpecs){
				if (spec[0] == "r") {
					// 'r' is reporter, 'R' is requester, and 'rR' is a reporter forced to act as a requester.
					spec[0] = "rR";
				}
			}
		}
		if (extObj.url) 			ext.url = extObj.url;
		ext.showBlocks = true;
		ext.menus = extObj.menus;
		ext.javascriptURL = extObj.javascriptURL;
		if (extObj.host) 			ext.host = extObj.host  // non-local host allowed but not saved in project  ;
		extensionDict[extObj.extensionName] = ext;
		Scratch.app.translationChanged();
		Scratch.app.updatePalette();
		
		// Update the indicator
		for (i in 0...app.palette.numChildren){
			var indicator : IndicatorLight = try cast(app.palette.getChildAt(i), IndicatorLight) catch(e:Dynamic) null;
			if (indicator != null && indicator.target == ext) {
				updateIndicator(indicator, indicator.target, true);
				break;
			}
		}
		
		return ext;
	}
	
	public function loadSavedExtensions(savedExtensions : Array<Dynamic>) : Void{
		function extensionRefused(extObj : Dynamic, reason : String) : Void{
			Scratch.app.jsThrowError("Refusing to load project extension \"" + extObj.extensionName + "\": " + reason);
		}  // Reset the system extensions and load the given array of saved extensions.  ;
		
		
		
		if (savedExtensions == null) 			return  // no saved extensions  ;
		for (extObj in savedExtensions){
			if (isInternal(extObj.extensionName)) {
				setEnabled(extObj.extensionName, true);
				continue;
			}
			
			if (!(Lambda.has(extObj, "extensionName"))) {
				Scratch.app.jsThrowError("Refusing to load project extension without a name.");
				continue;
			}
			
			if (!(Lambda.has(extObj, "extensionPort")) && !(Lambda.has(extObj, "javascriptURL"))) {
				extensionRefused(extObj, "No location specified.");
				continue;
			}
			
			if (!(Lambda.has(extObj, "blockSpecs"))) {
				// TODO: resolve potential confusion when the project blockSpecs don't match those in the JS.
				extensionRefused(extObj, "No blockSpecs.");
				continue;
			}
			
			var ext : ScratchExtension = new ScratchExtension(extObj.extensionName, extObj.extensionPort || 0);
			ext.blockSpecs = extObj.blockSpecs;
			ext.showBlocks = true;
			ext.isInternal = false;
			ext.menus = extObj.menus;
			if (extObj.javascriptURL) {
				if (!Scratch.app.isExtensionDevMode) {
					extensionRefused(extObj, "Experimental extensions are only supported on ScratchX.");
					continue;
				}
				if (!StringTools.endsWith(URLUtil.getServerName(extObj.javascriptURL).toLowerCase(), ".github.io")) {
					extensionRefused(extObj, "Experimental extensions must be hosted on GitHub Pages.");
					continue;
				}
				ext.javascriptURL = extObj.javascriptURL;
				ext.showBlocks = false;
				if (extObj.id) 					ext.id = extObj.id;
			}
			
			extensionDict[extObj.extensionName] = ext;
			setEnabled(extObj.extensionName, true);
		}
		Scratch.app.updatePalette();
	}
	
	// -----------------------------
	// Menu Support
	//------------------------------
	
	public function menuItemsFor(op : String, menuName : String) : Array<Dynamic>{
		// Return a list of menu items for the given menu of the extension associated with op or null.
		var i : Int = op.indexOf(".");
		if (i < 0) 			return null;
		var ext : ScratchExtension = extensionDict[op.substring(0, i)];
		if (ext == null || !ext.menus) 			return null  // unknown extension  ;
		return ext.menus[menuName];
	}
	
	// -----------------------------
	// Status Indicator
	//------------------------------
	
	public function updateIndicator(indicator : IndicatorLight, ext : ScratchExtension, firstTime : Bool = false) : Void{
		if (ext.port > 0) {
			var msecsSinceLastResponse : UInt = Math.round(haxe.Timer.stamp() * 1000) - ext.lastPollResponseTime;
			if (msecsSinceLastResponse > 500) 				indicator.setColorAndMsg(0xE00000, "Cannot find helper app")
			else if (ext.problem != "") 				indicator.setColorAndMsg(0xE0E000, ext.problem)
			else indicator.setColorAndMsg(0x00C000, ext.success);
		}
		else if (app.jsEnabled) {
			function statusCallback(retval : Dynamic) : Void{
				if (retval == null) 					retval = {
							status : 0,
							msg : "Cannot communicate with extension.",

						};
				
				var color : UInt;
				if (retval.status == 2) 					color = 0x00C000
				else if (retval.status == 1) 					color = 0xE0E000
				else {
					color = 0xE00000;
					if (firstTime) {
						Scratch.app.showTip("extensions");
						//					DialogBox.notify('Extension Problem', 'It looks like the '+ext.name+' is not working properly.' +
						//							'Please read the extensions help in the tips window.', Scratch.app.stage);
						DialogBox.notify("Extension Problem", "See the Tips window (on the right) to install the plug-in and get the extension working.");
					}
				}
				
				indicator.setColorAndMsg(color, retval.msg);
			};
			
			app.externalCall("ScratchExtensions.getStatus", statusCallback, ext.name);
		}
	}
	
	// -----------------------------
	// Execution
	//------------------------------
	
	public function primExtensionOp(b : Block) : Dynamic{
		var i : Int = b.op.indexOf(".");
		var extName : String = b.op.substring(0, i);
		var ext : ScratchExtension = Reflect.field(extensionDict, extName);
		if (ext == null) 			return 0  // unknown extension  ;
		var primOrVarName : String = b.op.substring(i + 1);
		var args : Array<Dynamic> = [];
		for (i in 0...b.args.length){
			args.push(app.interp.arg(b, i));
		}
		
		var value : Dynamic;
		if (b.isReporter) {
			if (b.isRequester) {
				if (b.requestState == 2) {
					b.requestState = 0;
					return b.response;
				}
				// Returns null if we just made a request or we're still waiting
				else if (b.requestState == 0) {
					request(extName, primOrVarName, args, b);
				}
				
				
				
				return null;
			}
			else {
				var sensorName : String = primOrVarName;
				if (ext.port > 0) {  // we were checking ext.isInternal before, should we?  
					sensorName = encodeURIComponent(sensorName);
					for (a in args)sensorName += "/" + encodeURIComponent(a);  // append menu args  
					value = ext.stateVars[sensorName];
				}
				else if (Scratch.app.jsEnabled) {
					// JavaScript
					if (Scratch.app.isOffline) {
						throw new IllegalOperationError("JS reporters must be requesters in Offline.");
					}
					app.externalCall("ScratchExtensions.getReporter", function(v : Dynamic) : Void{
								value = v;
							}, ext.name, sensorName, args);
				}
				if (value == null) 					value = 0  // default to zero if missing  ;
				if ("b" == b.type) 					value = (ext.port > (0) ? "true" == value : true == value)  // coerce value to a boolean  ;
				return value;
			}
		}
		else {
			if ("w" == b.type) {
				var activeThread : Thread = app.interp.activeThread;
				if (activeThread.firstTime) {
					var id : Int = ++ext.nextID;  // assign a unique ID for this call  
					ext.busy.push(id);
					activeThread.tmp = id;
					app.interp.doYield();
					justStartedWait = true;
					
					if (ext.port == 0) {
						activeThread.firstTime = false;
						if (app.jsEnabled) 
							app.externalCall("ScratchExtensions.runAsync", null, ext.name, primOrVarName, args, id)
						else 
						ext.busy.pop();
						
						return;
					}
					
					args.unshift(id);
				}
				else {
					if (ext.busy.indexOf(activeThread.tmp) > -1) {
						app.interp.doYield();
					}
					else {
						activeThread.tmp = 0;
						activeThread.firstTime = true;
					}
					return;
				}
			}
			call(extName, primOrVarName, args);
		}
	}
	
	public function call(extensionName : String, op : String, args : Array<Dynamic>) : Void{
		var ext : ScratchExtension = Reflect.field(extensionDict, extensionName);
		if (ext == null) 			return  // unknown extension  ;
		if (ext.port > 0) {
			var activeThread : Thread = app.interp.activeThread;
			if (activeThread != null && op != "reset_all") {
				if (activeThread.firstTime) {
					httpCall(ext, op, args);
					activeThread.firstTime = false;
					app.interp.doYield();
				}
				else {
					activeThread.firstTime = true;
				}
			}
			else 
			httpCall(ext, op, args);
		}
		else {
			if (op == "reset_all") 				op = "resetAll"  // call a JavaScript extension function with the given arguments  ;
			
			
			
			if (Scratch.app.jsEnabled) 				app.externalCall("ScratchExtensions.runCommand", null, ext.name, op, args);
			app.interp.redraw();
		}
	}
	
	public function request(extensionName : String, op : String, args : Array<Dynamic>, b : Block) : Void{
		var ext : ScratchExtension = Reflect.field(extensionDict, extensionName);
		if (ext == null) {
			// unknown extension, skip the block
			b.requestState = 2;
			return;
		}
		
		if (ext.port > 0) {
			httpRequest(ext, op, args, b);
		}
		else if (Scratch.app.jsEnabled) {
			// call a JavaScript extension function with the given arguments
			b.requestState = 1;
			++ext.nextID;
			ext.busy.push(ext.nextID);
			ext.waiting[b] = ext.nextID;
			
			if (b.forcedRequester) {
				// We're forcing a non-requester to be treated as a requester
				app.externalCall("ScratchExtensions.getReporterForceAsync", null, ext.name, op, args, ext.nextID);
			}
			else {
				// Normal request
				app.externalCall("ScratchExtensions.getReporterAsync", null, ext.name, op, args, ext.nextID);
			}
		}
	}
	
	private function httpRequest(ext : ScratchExtension, op : String, args : Array<Dynamic>, b : Block) : Void{
		function responseHandler(e : Event) : Void{
			if (e.type == Event.COMPLETE) 
				b.response = loader.data
			else 
			b.response = "";
			
			b.requestState = 2;
			b.requestLoader = null;
		};
		
		var loader : URLLoader = new URLLoader();
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, responseHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, responseHandler);
		loader.addEventListener(Event.COMPLETE, responseHandler);
		
		b.requestState = 1;
		b.requestLoader = loader;
		
		var url : String = "http://" + ext.host + ":" + ext.port + "/" + encodeURIComponent(op);
		for (arg in args){
			url += "/" + (((Std.is(arg, String))) ? encodeURIComponent(arg) : arg);
		}
		loader.load(new URLRequest(url));
	}
	
	private function httpCall(ext : ScratchExtension, op : String, args : Array<Dynamic>) : Void{
		function errorHandler(e : Event) : Void{
		}  // ignore errors  ;
		var url : String = "http://" + ext.host + ":" + ext.port + "/" + encodeURIComponent(op);
		for (arg in args){
			url += "/" + (((Std.is(arg, String))) ? encodeURIComponent(arg) : arg);
		}
		var loader : URLLoader = new URLLoader();
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		loader.load(new URLRequest(url));
	}
	
	public function getStateVar(extensionName : String, varName : String, defaultValue : Dynamic) : Dynamic{
		var ext : ScratchExtension = Reflect.field(extensionDict, extensionName);
		if (ext == null) 			return defaultValue  // unknown extension  ;
		var value : Dynamic = ext.stateVars[encodeURIComponent(varName)];
		return ((value == null)) ? defaultValue : value;
	}
	
	// -----------------------------
	// Polling
	//------------------------------
	
	public function step() : Void{
		// Poll all extensions.
		for (ext/* AS3HX WARNING could not determine type for var: ext exp: EIdent(extensionDict) type: Dynamic */ in extensionDict){
			if (ext.showBlocks) {
				if (!ext.isInternal && ext.port > 0) {
					if (ext.blockSpecs.length == 0) 						httpGetSpecs(ext);
					httpPoll(ext);
				}
			}
		}
	}
	
	private function httpGetSpecs(ext : ScratchExtension) : Void{
		// Fetch the block specs (and optional menu specs) from the helper app.
		function completeHandler(e : Event) : Void{
			var specsObj : Dynamic;
			try{
				specsObj = util.JSON.parse(loader.data);
			}			catch (e : Dynamic){ };
			if (specsObj == null) 				return  // use the block specs and (optionally) menu returned by the helper app  ;
			
			if (specsObj.blockSpecs) 				ext.blockSpecs = specsObj.blockSpecs;
			if (specsObj.menus) 				ext.menus = specsObj.menus;
		};
		function errorHandler(e : Event) : Void{
		}  // ignore errors  ;
		var url : String = "http://" + ext.host + ":" + ext.port + "/get_specs";
		var loader : URLLoader = new URLLoader();
		loader.addEventListener(Event.COMPLETE, completeHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		loader.load(new URLRequest(url));
	}
	
	private function httpPoll(ext : ScratchExtension) : Void{
		
		if (Reflect.field(pollInProgress, Std.string(ext))) {
			// Don't poll again if there's already one in progress.
			// This can happen a lot if the connection is timing out.
			return;
		}  // Poll via HTTP.  
		
		
		
		function completeHandler(e : Event) : Void{
			;
			processPollResponse(ext, loader.data);
		};
		function errorHandler(e : Event) : Void{
			// ignore errors
			;
		};
		var url : String = "http://" + ext.host + ":" + ext.port + "/poll";
		var loader : URLLoader = new URLLoader();
		loader.addEventListener(Event.COMPLETE, completeHandler);
		loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
		loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
		Reflect.setField(pollInProgress, Std.string(ext), true);
		loader.load(new URLRequest(url));
	}
	
	private function processPollResponse(ext : ScratchExtension, response : String) : Void{
		if (response == null) 			return;
		ext.lastPollResponseTime = Math.round(haxe.Timer.stamp() * 1000);
		ext.problem = "";
		
		// clear the busy list unless we just started a command that waits
		if (justStartedWait) 			justStartedWait = false
		else ext.busy = [];
		
		var i : Int;
		var lines : Array<Dynamic> = response.split("\n");
		for (line in lines){
			i = line.indexOf(" ");
			if (i == -1) 				i = line.length;
			var key : String = line.substring(0, i);
			var value : String = decodeURIComponent(line.substring(i + 1));
			switch (key) {
				case "_busy":
					for (token/* AS3HX WARNING could not determine type for var: token exp: ECall(EField(EIdent(value),split),[EConst(CString( ))]) type: null */ in value.split(" ")){
						var id : Int = parseInt(token);
						if (ext.busy.indexOf(id) == -1) 							ext.busy.push(id);
					}
				case "_problem":
					ext.problem = value;
				case "_success":
					ext.success = value;
				default:
					var n : Float = Interpreter.asNumber(value);
					var path : Array<Dynamic> = key.split("/");
					for (i in 0...path.length){
						// normalize URL encoding for each path segment
						path[i] = encodeURIComponent(decodeURIComponent(path[i]));
					}
					ext.stateVars[path.join("/")] = n == (n != 0) ? n : value;
			}
		}
	}
	
	public function hasExperimentalExtensions() : Bool{
		for (ext/* AS3HX WARNING could not determine type for var: ext exp: EIdent(extensionDict) type: Dynamic */ in extensionDict){
			if (!ext.isInternal && ext.javascriptURL) {
				return true;
			}
		}
		return false;
	}
}

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

// Scratch.as
// John Maloney, September 2009
//
// This is the top-level application.

package;
import blocks.*;
import flash.Lib;

//import com.adobe.utils.StringUtil;

//import extensions.ExtensionDevManager;
//import extensions.ExtensionManager;

import flash.errors.Error;
import flash.display.*;
import flash.events.*;
import flash.external.ExternalInterface;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.net.FileFilter;
import flash.net.FileReference;
import flash.net.FileReferenceList;
import flash.net.LocalConnection;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.system.*;
import flash.text.*;
import flash.utils.*;

import interpreter.*;

import logging.Log;
import logging.LogEntry;
import logging.LogLevel;

import mx.utils.URLUtil;

//import render3d.DisplayObjectContainerIn3D;

import scratch.*;
import scratch.PaletteBuilder;

//import svgeditor.tools.SVGTool;

import translation.*;

import ui.*;
import ui.media.*;
import ui.parts.*;

import uiwidgets.*;

import util.*;

import watchers.ListWatcher;

class Scratch extends Sprite {
	// Version
	public static inline var versionString/*:String*/ = 'v440.1';
	public static var app:Scratch; // static reference to the app, used for debugging

	// Display modes
	public var hostProtocol:String = 'http';
	public var editMode:Bool; // true when project editor showing, false when only the player is showing
	public var isOffline:Bool; // true when running as an offline (i.e. stand-alone) app
	public var isSmallPlayer:Bool; // true when displaying as a scaled-down player (e.g. in search results)
	public var stageIsContracted:Bool; // true when the stage is half size to give more space on small screens
	public var isIn3D:Bool;
//	public var render3D:DisplayObjectContainerIn3D;
	public var isArmCPU:Bool;
	public var jsEnabled:Bool = false; // true when the SWF can talk to the webpage
	public var ignoreResize:Bool = false; // If true, temporarily ignore resize events.
	public var isExtensionDevMode:Bool = false; // If true, run in extension development mode (as on ScratchX)
	public var isMicroworld:Bool = false;

	// Runtime
	public var runtime:ScratchRuntime;
	public var interp:Interpreter;
	//public var extensionManager:ExtensionManager;
	public var server:IServer;
	public var gh:GestureHandler;
	public var projectID:String = '';
	public var projectOwner:String = '';
	public var projectIsPrivate:Bool;
	public var oldWebsiteURL:String = '';
	public var loadInProgress:Bool;
	public var debugOps:Bool = false;
	public var debugOpCmd:String = '';

	private var autostart:Bool;
	private var viewedObject:ScratchObj;
	private var lastTab:String = 'scripts';
	private var wasEdited:Bool; // true if the project was edited and autosaved
	private var _usesUserNameBlock:Bool = false;
	private var languageChanged:Bool; // set when language changed

	// UI Elements
	public var playerBG:Shape;
	public var palette:BlockPalette;
	public var scriptsPane:ScriptsPane;
	public var stagePane:ScratchStage;
	public var mediaLibrary:MediaLibrary;
	public var lp:LoadProgress;
	public var cameraDialog:CameraDialog;

	// UI Parts
	public var libraryPart:LibraryPart;
	private var topBarPart:TopBarPart;
	private var stagePart:StagePart;
	private var tabsPart:TabsPart;
	private var scriptsPart:ScriptsPart;
	public var imagesPart:ImagesPart;
	public var soundsPart:SoundsPart;
	public static inline var tipsBarClosedWidth = 17;

	public var logger:Log = new Log(16);

	public function new() {
		super();
		//SVGTool.setStage(stage);
		loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);
		app = this;

		// This one must finish before most other queries can start, so do it separately
		determineJSAccess();
	}

	private function determineJSAccess():Void {
		//if (externalInterfaceAvailable()) {
			//try {
				//externalCall('function(){return true;}', jsAccessDetermined);
				//return; // wait for callback
			//}
			//catch (e:Error) {
			//}
		//}
		jsAccessDetermined(false);
	}

	private function jsAccessDetermined(result:Bool):Void {
		jsEnabled = result;
		initialize();
	}

	private function initialize():Void {
		isOffline = !URLUtil.isHttpURL(loaderInfo.url);
		hostProtocol = URLUtil.getProtocol(loaderInfo.url);

		isExtensionDevMode = false; // (loaderInfo.parameters['extensionDevMode'] == 'true');
		isMicroworld = false; //  (loaderInfo.parameters['microworldMode'] == 'true');

		checkFlashVersion();
		initServer();

		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.frameRate = 30;

		//if (stage.hasOwnProperty('color')) {
			//// Stage doesn't have a color property on Air 2.6, and Linux throws if you try to set it anyway.
			//stage['color'] = CSS.backgroundColor();
		//}

		Block.setFonts(10, 9, true, 0); // default font sizes
		Block.MenuHandlerFunction = BlockMenus.BlockMenuHandler;
		CursorTool.init(this);
		app = this;

		stagePane = getScratchStage();
		gh = new GestureHandler(this, false); // (loaderInfo.parameters['inIE'] == 'true'));
		initInterpreter();
		initRuntime();
		initExtensionManager();
		Translator.initializeLanguageList();

		playerBG = new Shape(); // create, but don't add
		addParts();

		server.getSelectedLang(Translator.setLanguageValue);


		stage.addEventListener(MouseEvent.MOUSE_DOWN, gh.mouseDown);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, gh.mouseMove);
		stage.addEventListener(MouseEvent.MOUSE_UP, gh.mouseUp);
		stage.addEventListener(MouseEvent.MOUSE_WHEEL, gh.mouseWheel);
		stage.addEventListener('rightClick', gh.rightMouseClick);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, function(evt:KeyboardEvent): Void {
			if (!evt.shiftKey && evt.charCode == 27) gh.escKeyDown();
			else runtime.keyDown(evt);
		});

		stage.addEventListener(KeyboardEvent.KEY_UP, runtime.keyUp);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown); // to handle escape key
		stage.addEventListener(Event.ENTER_FRAME, step);
		stage.addEventListener(Event.RESIZE, onResize);

		setEditMode(startInEditMode());

		// install project before calling fixLayout()
		if (editMode) runtime.installNewProject();
		else runtime.installEmptyProject();

		fixLayout();
		//Analyze.collectAssets(0, 119110);
		//Analyze.checkProjects(56086, 64220);
		//Analyze.countMissingAssets();

		handleStartupParameters();
	}

	private function handleStartupParameters():Void {
		setupExternalInterface(false);
		jsEditorReady();
	}

	private function setupExternalInterface(oldWebsitePlayer:Bool):Void {
		if (!jsEnabled) return;

		//addExternalCallback('ASloadExtension', extensionManager.loadRawExtension);
		//addExternalCallback('ASextensionCallDone', extensionManager.callCompleted);
		//addExternalCallback('ASextensionReporterDone', extensionManager.reporterCompleted);
		//addExternalCallback('AScreateNewProject', createNewProjectScratchX);

		//if (isExtensionDevMode) {
			//addExternalCallback('ASloadGithubURL', loadGithubURL);
			//addExternalCallback('ASloadBase64SBX', loadBase64SBX);
			//addExternalCallback('ASsetModalOverlay', setModalOverlay);
		//}
	}

	private function jsEditorReady():Void {
		//if (jsEnabled) {
			//externalCall('JSeditorReady', function (success:Bool):Void {
				//if (!success) jsThrowError('Calling JSeditorReady() failed.');
			//});
		//}
	}

	//private function loadSingleGithubURL(url:String):Void {
		//url = StringTools.trim(unescape(url));
//
		//function handleComplete(e:Event):Void {
			//runtime.installProjectFromData(sbxLoader.data);
			//if (StringTools.trim(projectName()).length == 0) {
				//var newProjectName:String = url;
				//var index = Std.int(newProjectName.indexOf('?'));
				//if (index > 0) newProjectName = newProjectName.slice(0, index);
				//index = newProjectName.lastIndexOf('/');
				//if (index > 0) newProjectName = newProjectName.substr(index + 1);
				//index = newProjectName.lastIndexOf('.sbx');
				//if (index > 0) newProjectName = newProjectName.slice(0, index);
				//setProjectName(newProjectName);
			//}
		//}
//
		//function handleError(e:ErrorEvent):Void {
			//jsThrowError('Failed to load SBX: ' + e.toString());
		//}
//
		//var fileExtension:String = url.substr(url.lastIndexOf('.')).toLowerCase();
		//if (fileExtension == '.js') {
			//externalCall('ScratchExtensions.loadExternalJS', null, url);
			//return;
		//}
//
		//// Otherwise assume it's a project (SB2, SBX, etc.)
		//loadInProgress = true;
		//var request:URLRequest = new URLRequest(url);
		//var sbxLoader:URLLoader = new URLLoader(request);
		//sbxLoader.dataFormat = URLLoaderDataFormat.BINARY;
		//sbxLoader.addEventListener(Event.COMPLETE, handleComplete);
		//sbxLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, handleError);
		//sbxLoader.addEventListener(IOErrorEvent.IO_ERROR, handleError);
		//sbxLoader.load(request);
	//}

	private var pendingExtensionURLs:Array<Dynamic>;
	/*
	private function loadGithubURL(urlOrArray:*):Void {
		if (!isExtensionDevMode) return;

		var url:String;
		var urlArray:Array = urlOrArray as Array;
		if (urlArray) {
			var urlCount:Int = urlArray.length;
			var extensionURLs:Array = [];
			var projectURL:String;
			var index:Int;

			// Filter URLs: allow at most one project file, and wait until it loads before loading extensions.
			for (index = 0; index < urlCount; ++index) {
				url = StringUtil.trim(unescape(urlArray[index]));
				if (StringUtil.endsWith(url.toLowerCase(), '.js')) {
					extensionURLs.push(url);
				}
				else if (url.length > 0) {
					if (projectURL) {
						jsThrowError("Ignoring extra project URL: " + projectURL);
					}
					projectURL = StringUtil.trim(url);
				}
			}
			if (projectURL) {
				pendingExtensionURLs = extensionURLs;
				loadSingleGithubURL(projectURL);
				// warning will be shown later
			}
			else {
				urlCount = extensionURLs.length;
				for (index = 0; index < urlCount; ++index) {
					loadSingleGithubURL(extensionURLs[index]);
				}
				externalCall('JSshowWarning');
			}
		}
		else {
			url = urlOrArray as String;
			loadSingleGithubURL(url);
			externalCall('JSshowWarning');
		}
	}
*/
	private function loadBase64SBX(base64:String):Void {
		var sbxData:ByteArray = Base64Encoder.decode(base64);
		app.setProjectName('');
		runtime.installProjectFromData(sbxData);
	}

	private function initTopBarPart():Void {
		topBarPart = new TopBarPart(this);
	}

	private function initScriptsPart():Void {
		scriptsPart = new ScriptsPart(this);
	}

	private function initImagesPart():Void {
		imagesPart = new ImagesPart(this);
	}

	private function initInterpreter():Void {
		interp = new Interpreter(this);
	}

	private function initRuntime():Void {
		runtime = new ScratchRuntime(this, interp);
	}

	private function initExtensionManager():Void {
		//if (isExtensionDevMode) {
			//extensionManager = new ExtensionDevManager(this);
		//}
		//else {
			//extensionManager = new ExtensionManager(this);
		//}
	}

	private function initServer():Void {
		server = new Server();
	}

	public function showTip(tipName:String):Void {
	}

	public function closeTips():Void {
	}

	public function reopenTips():Void {
	}

	public function tipsWidth():Int {
		return 0;
	}

	private function startInEditMode():Bool {
		return isOffline || isExtensionDevMode;
	}

	public function getMediaLibrary(type:String, whenDone:Function):MediaLibrary {
		return new MediaLibrary(this, type, whenDone);
	}

	public function getMediaPane(app:Scratch, type:String):MediaPane {
		return new MediaPane(app, type);
	}

	public function getScratchStage():ScratchStage {
		return new ScratchStage();
	}

	public function getPaletteBuilder():PaletteBuilder {
		return new PaletteBuilder(this);
	}

	private function uncaughtErrorHandler(event:UncaughtErrorEvent):Void {
		if (Std.is (event.error, Error)) {
			var error:Error = cast(event.error, Error);
			logException(error);
		}
		else if (Std.is(event.error, ErrorEvent)) {
			var errorEvent:ErrorEvent = cast(event.error, ErrorEvent);
			log(LogLevel.ERROR, errorEvent.toString());
		}
	}

	// All other log...() methods funnel to this one
	public function log(severity:String, messageKey:String, extraData:Object = null):LogEntry {
		return logger.log(severity, messageKey, extraData);
	}

	// Log an Error object generated by an exception
	public function logException(e:Error):Void {
		log(LogLevel.ERROR, e.toString());
	}

	// Shorthand for log(LogLevel.ERROR, ...)
	public function logMessage(msg:String, extra_data:Object = null):Void {
		log(LogLevel.ERROR, msg, extra_data);
	}

	public function loadProjectFailed():Void {
		loadInProgress = false;
	}

	public function jsThrowError(s:String):Void {
		// Throw the given string as an error in the browser. Errors on the production site are logged.
		var errorString:String = 'SWF Error: ' + s;
		log(LogLevel.ERROR, errorString);
		//if (jsEnabled) {
			//externalCall('JSthrowError', null, errorString);
		//}
	}

	private function checkFlashVersion():Void {
		/*
		SCRATCH::allow3d {
			if (Capabilities.playerType != "Desktop" || Capabilities.version.indexOf('IOS') === 0) {
				var versionString:String = Capabilities.version.substr(Capabilities.version.indexOf(' ') + 1);
				var versionParts:Array = versionString.split(',');
				var majorVersion:Int = parseInt(versionParts[0]);
				var minorVersion:Int = parseInt(versionParts[1]);
				if ((majorVersion > 11 || (majorVersion == 11 && minorVersion >= 7)) && !isArmCPU && Capabilities.cpuArchitecture == 'x86') {
					render3D = new DisplayObjectContainerIn3D();
					render3D.setStatusCallback(handleRenderCallback);
					return;
				}
			}
		}
*/
		//render3D = null;
	}

	/*
	SCRATCH::allow3d
	protected function handleRenderCallback(enabled:Bool):Void {
		if (!enabled) {
			go2D();
			render3D = null;
		}
		else {
			for (var i:Int = 0; i < stagePane.numChildren; ++i) {
				var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
				if (spr) {
					spr.clearCachedBitmap();
					spr.updateCostume();
					spr.applyFilters();
				}
			}
			stagePane.clearCachedBitmap();
			stagePane.updateCostume();
			stagePane.applyFilters();
		}
	}
*/
	public function clearCachedBitmaps():Void {
		for (i in 0...stagePane.numChildren) {
			var spr:ScratchSprite = cast(stagePane.getChildAt(i), ScratchSprite);
			if (spr != null) spr.clearCachedBitmap();
		}
		stagePane.clearCachedBitmap();

		// unsupported technique that seems to force garbage collection
		try {
			new LocalConnection().connect('foo');
			new LocalConnection().connect('foo');
		} catch (e:Error) {
		}
	}
/*
	SCRATCH::allow3d
	public function go3D():Void {
		if (!render3D || isIn3D) return;

		var i:Int = stagePart.getChildIndex(stagePane);
		stagePart.removeChild(stagePane);
		render3D.setStage(stagePane, stagePane.penLayer);
		stagePart.addChildAt(stagePane, i);
		isIn3D = true;
	}

	SCRATCH::allow3d
	public function go2D():Void {
		if (!render3D || !isIn3D) return;

		var i:Int = stagePart.getChildIndex(stagePane);
		stagePart.removeChild(stagePane);
		render3D.setStage(null, null);
		stagePart.addChildAt(stagePane, i);
		isIn3D = false;
		for (i = 0; i < stagePane.numChildren; ++i) {
			var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
			if (spr) {
				spr.clearCachedBitmap();
				spr.updateCostume();
				spr.applyFilters();
			}
		}
		stagePane.clearCachedBitmap();
		stagePane.updateCostume();
		stagePane.applyFilters();
	}
*/
	private var debugRect:Shape;

	public function showDebugRect(r:Rectangle):Void {
		// Used during debugging...
		var p:Point = stagePane.localToGlobal(new Point(0, 0));
		if (debugRect == null) debugRect = new Shape();
		var g:Graphics = debugRect.graphics;
		g.clear();
		if (r != null) {
			g.lineStyle(2, 0xFFFF00);
			g.drawRect(p.x + r.x, p.y + r.y, r.width, r.height);
			addChild(debugRect);
		}
	}

	public function strings():Array<String> {
		return [
			'a copy of the project file on your computer.',
			'Project not saved!', 'Save now', 'Not saved; project did not load.',
			'Save project?', 'Don\'t save',
			'Save now', 'Saved',
			'Revert', 'Undo Revert', 'Reverting...',
			'Throw away all changes since opening this project?',
		];
	}

	public function viewedObj():ScratchObj {
		return viewedObject;
	}

	public function stageObj():ScratchStage {
		return stagePane;
	}

	public function projectName():String {
		return stagePart.projectName();
	}

	public function highlightSprites(sprites:Array<Dynamic>):Void {
		libraryPart.highlight(sprites);
	}

	public function refreshImageTab(fromEditor:Bool):Void {
		imagesPart.refresh(fromEditor);
	}

	public function refreshSoundTab():Void {
		soundsPart.refresh();
	}

	public function selectCostume():Void {
		imagesPart.selectCostume();
	}

	public function selectSound(snd:ScratchSound):Void {
		soundsPart.selectSound(snd);
	}

	public function clearTool():Void {
		CursorTool.setTool(null);
		topBarPart.clearToolButtons();
	}

	public function tabsRight():Int {
		return Std.int(tabsPart.x + tabsPart.w);
	}

	public function enableEditorTools(flag:Bool):Void {
		//imagesPart.editor.enableTools(flag);
	}

	public var usesUserNameBlock (get, set): Bool;
	public function get_usesUserNameBlock():Bool {
		return _usesUserNameBlock;
	}

	public function set_usesUserNameBlock(value:Bool):Bool {
		_usesUserNameBlock = value;
		stagePart.refresh();
		return value;
	}

	public function updatePalette(clearCaches:Bool = true):Void {
		// Note: updatePalette() is called after changing variable, list, or procedure
		// definitions, so this is a convenient place to clear the interpreter's caches.
		if (isShowing(scriptsPart)) scriptsPart.updatePalette();
		if (clearCaches) runtime.clearAllCaches();
	}

	public function setProjectName(s:String):Void {
		if (s.substr(-3) == '.sb') s = s.substr(0, s.length-3);
		if (s.substr(-4) == '.sb2') s = s.substr(0, s.length-4);
		stagePart.setProjectName(s);
	}

	private var wasEditing:Bool;

	public function setPresentationMode(enterPresentation:Bool):Void {
		if (enterPresentation) {
			wasEditing = editMode;
			if (wasEditing) {
				setEditMode(false);
				//if (jsEnabled) externalCall('tip_bar_api.hide');
			}
		} else {
			if (wasEditing) {
				setEditMode(true);
				//if (jsEnabled) externalCall('tip_bar_api.show');
			}
		}
		if (isOffline) {
			stage.displayState = enterPresentation ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
		}
		for (o in stagePane.allObjects()) o.applyFilters();

		if (lp != null) fixLoadProgressLayout();
		stagePane.updateCostume();
/*
		SCRATCH::allow3d {
			if (isIn3D) render3D.onStageResize();
		}
*/		
	}

	private function keyDown(evt:KeyboardEvent):Void {
		// Escape exists presentation mode.
		if ((evt.charCode == 27) && stagePart.isInPresentationMode()) {
			setPresentationMode(false);
			stagePart.exitPresentationMode();
		}
		// Handle enter key
//		else if(evt.keyCode == 13 && !stage.focus) {
//			stagePart.playButtonPressed(null);
//			evt.preventDefault();
//			evt.stopImmediatePropagation();
//		}
		// Handle ctrl-m and toggle 2d/3d mode
		else if (evt.ctrlKey && evt.charCode == 109) {
			/*
			SCRATCH::allow3d {
				isIn3D ? go2D() : go3D();
			}
			*/
			evt.preventDefault();
			evt.stopImmediatePropagation();
		}
	}

	private function setSmallStageMode(flag:Bool):Void {
		stageIsContracted = flag;
		stagePart.refresh();
		fixLayout();
		libraryPart.refresh();
		tabsPart.refresh();
		stagePane.applyFilters();
		stagePane.updateCostume();
	}

	public function projectLoaded():Void {
		removeLoadProgressBox();
		System.gc();
		if (autostart) runtime.startGreenFlags(true);
		loadInProgress = false;
		saveNeeded = false;

		// translate the blocks of the newly loaded project
		for (o in stagePane.allObjects()) {
			o.updateScriptsAfterTranslation();
		}

		//if (jsEnabled && isExtensionDevMode) {
			//if (pendingExtensionURLs) {
				//loadGithubURL(pendingExtensionURLs);
				//pendingExtensionURLs = null;
			//}
			//externalCall('JSprojectLoaded');
		//}
	}

	public function resetPlugin():Void {
		//if (jsEnabled)
			//externalCall('ScratchExtensions.resetPlugin');
	}

	private function step(e:Event):Void {
		// Step the runtime system and all UI components.
		gh.step();
		runtime.stepRuntime();
		Transition.step(null);
		stagePart.step();
		libraryPart.step();
		scriptsPart.step();
		imagesPart.step();
	}

	public function updateSpriteLibrary(sortByIndex:Bool = false):Void {
		libraryPart.refresh();
	}

	public function updateTopBar():Void {
		topBarPart.refresh();
	}

	public function threadStarted():Void {
		stagePart.threadStarted();
	}

	public function selectSprite(obj:ScratchObj):Void {
		//if (isShowing(imagesPart)) imagesPart.editor.shutdown();
		//if (isShowing(soundsPart)) soundsPart.editor.shutdown();
		viewedObject = obj;
		libraryPart.refresh();
		tabsPart.refresh();
		if (isShowing(imagesPart)) {
			imagesPart.refresh();
		}
		if (isShowing(soundsPart)) {
			soundsPart.currentIndex = 0;
			soundsPart.refresh();
		}
		if (isShowing(scriptsPart)) {
			scriptsPart.updatePalette();
			scriptsPane.viewScriptsFor(obj);
			scriptsPart.updateSpriteWatermark();
		}
	}

	public function setTab(tabName:String):Void {
		//if (isShowing(imagesPart)) imagesPart.editor.shutdown();
		//if (isShowing(soundsPart)) soundsPart.editor.shutdown();
		hide(scriptsPart);
		hide(imagesPart);
		hide(soundsPart);
		if (!editMode) return;
		if (tabName == 'images') {
			show(imagesPart);
			imagesPart.refresh();
		} else if (tabName == 'sounds') {
			soundsPart.refresh();
			show(soundsPart);
		} else if (tabName != null && (tabName.length > 0)) {
			tabName = 'scripts';
			scriptsPart.updatePalette();
			scriptsPane.viewScriptsFor(viewedObject);
			scriptsPart.updateSpriteWatermark();
			show(scriptsPart);
		}
		show(tabsPart);
		show(stagePart); // put stage in front
		tabsPart.selectTab(tabName);
		lastTab = tabName;
		if (saveNeeded) setSaveNeeded(true); // save project when switching tabs, if needed (but NOT while loading!)
	}

	public function installStage(newStage:ScratchStage):Void {
		var showGreenflagOverlay:Bool = shouldShowGreenFlag();
		stagePart.installStage(newStage, showGreenflagOverlay);
		selectSprite(newStage);
		libraryPart.refresh();
		setTab('scripts');
		scriptsPart.resetCategory();
		wasEdited = false;
	}

	private function shouldShowGreenFlag():Bool {
		return !(autostart || editMode);
	}

	private function addParts():Void {
		initTopBarPart();
		stagePart = getStagePart();
		libraryPart = getLibraryPart();
		tabsPart = new TabsPart(this);
		initScriptsPart();
		initImagesPart();
		soundsPart = new SoundsPart(this);
		addChild(topBarPart);
		addChild(stagePart);
		addChild(libraryPart);
		addChild(tabsPart);
	}

	private function getStagePart():StagePart {
		return new StagePart(this);
	}

	private function getLibraryPart():LibraryPart {
		return new LibraryPart(this);
	}

	public function fixExtensionURL(javascriptURL:String):String {
		return javascriptURL;
	}

	// -----------------------------
	// UI Modes and Resizing
	//------------------------------

	public function setEditMode(newMode:Bool):Void {
		Menu.removeMenusFrom(stage);
		editMode = newMode;
		if (editMode) {
			interp.showAllRunFeedback();
			hide(playerBG);
			show(topBarPart);
			show(libraryPart);
			show(tabsPart);
			setTab(lastTab);
			stagePart.hidePlayButton();
			runtime.edgeTriggersEnabled = true;
		} else {
			addChildAt(playerBG, 0); // behind everything
			playerBG.visible = false;
			hide(topBarPart);
			hide(libraryPart);
			hide(tabsPart);
			setTab(null); // hides scripts, images, and sounds
		}
		stagePane.updateListWatchers();
		show(stagePart); // put stage in front
		fixLayout();
		stagePart.refresh();
	}

	private function hide(obj:DisplayObject):Void {
		if (obj.parent != null) obj.parent.removeChild(obj);
	}

	private function show(obj:DisplayObject):Void {
		addChild(obj);
	}

	private function isShowing(obj:DisplayObject):Bool {
		return obj.parent != null;
	}

	public function onResize(e:Event):Void {
		if (!ignoreResize) fixLayout();
	}

	public function fixLayout():Void {
		var w:Int = stage.stageWidth;
		var h:Int = stage.stageHeight - 1; // fix to show bottom border...

		w = Math.ceil(w / scaleX);
		h = Math.ceil(h / scaleY);

		updateLayout(w, h);
	}

	private function updateLayout(w:Int, h:Int):Void {
		if (!isMicroworld) {
			topBarPart.x = 0;
			topBarPart.y = 0;
			topBarPart.setWidthHeight(w, 28);
		}

		var extraW:Int = 2;
		var extraH:Int = stagePart.computeTopBarHeight() + 1;
		if (editMode) {
			// adjust for global scale (from browser zoom)

			if (stageIsContracted) {
				stagePart.setWidthHeight(240 + extraW, 180 + extraH, 0.5);
			} else {
				stagePart.setWidthHeight(480 + extraW, 360 + extraH, 1);
			}
			stagePart.x = 5;
			stagePart.y = isMicroworld ? 5 : topBarPart.bottom() + 5;
			fixLoadProgressLayout();
		} else {
			drawBG();
			var pad:Int = (w > 550) ? 16 : 0; // add padding for full-screen mode
			var scale:Float = Math.min((w - extraW - pad) / 480, (h - extraH - pad) / 360);
			scale = Math.max(0.01, scale);
			var scaledW:Int = Math.floor((scale * 480) / 4) * 4; // round down to a multiple of 4
			scale = scaledW / 480;
			var playerW:Float = (scale * 480) + extraW;
			var playerH:Float = (scale * 360) + extraH;
			stagePart.setWidthHeight(Std.int(playerW), Std.int(playerH), scale);
			stagePart.x = Std.int((w - playerW) / 2);
			stagePart.y = Std.int((h - playerH) / 2);
			fixLoadProgressLayout();
			return;
		}
		libraryPart.x = stagePart.x;
		libraryPart.y = stagePart.bottom() + 18;
		libraryPart.setWidthHeight(Std.int(stagePart.w), Std.int(h - libraryPart.y));

		tabsPart.x = stagePart.right() + 5;
		if (!isMicroworld) {
			tabsPart.y = topBarPart.bottom() + 5;
			tabsPart.fixLayout();
		}
		else
			tabsPart.visible = false;

		// the content area shows the part associated with the currently selected tab:
		var contentY:Int = Std.int(tabsPart.y + 27);
		if (!isMicroworld)
			w -= tipsWidth();
		updateContentArea(Std.int(tabsPart.x), Std.int(contentY), Std.int(w - tabsPart.x - 6), Std.int(h - contentY - 5), Std.int(h));
	}

	private function updateContentArea(contentX:Int, contentY:Int, contentW:Int, contentH:Int, fullH:Int):Void {
		imagesPart.x = soundsPart.x = scriptsPart.x = contentX;
		imagesPart.y = soundsPart.y = scriptsPart.y = contentY;
		imagesPart.setWidthHeight(contentW, contentH);
		soundsPart.setWidthHeight(contentW, contentH);
		scriptsPart.setWidthHeight(contentW, contentH);

		if (mediaLibrary != null) mediaLibrary.setWidthHeight(topBarPart.w, fullH);
		if (frameRateGraph != null) {
			frameRateGraph.y = stage.stageHeight - frameRateGraphH;
			addChild(frameRateGraph); // put in front
		}
/*
		SCRATCH::allow3d {
			if (isIn3D) render3D.onStageResize();
		}
*/		
	}

	private function drawBG():Void {
		var g:Graphics = playerBG.graphics;
		g.clear();
		g.beginFill(0);
		g.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
	}

	private var modalOverlay:Sprite;

	public function setModalOverlay(enableOverlay:Bool):Void {
		var currentlyEnabled:Bool = (modalOverlay != null);
		if (enableOverlay != currentlyEnabled) {
			if (enableOverlay) {
				function eatEvent(event:MouseEvent):Void {
					event.stopImmediatePropagation();
					event.stopPropagation();
				}

				modalOverlay = new Sprite();
				modalOverlay.graphics.beginFill(CSS.backgroundColor_ScratchX, 0.8);
				modalOverlay.graphics.drawRect(0, 0, stage.width, stage.height);
				modalOverlay.addEventListener(MouseEvent.CLICK, eatEvent);
				modalOverlay.addEventListener(MouseEvent.MOUSE_DOWN, eatEvent);
/*				
				if (SCRATCH::allow3d) { // TODO: use a better flag or rename this one
					// These events are only available in flash 11.2 and above.
					modalOverlay.addEventListener(MouseEvent.RIGHT_CLICK, eatEvent);
					modalOverlay.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, eatEvent);
					modalOverlay.addEventListener(MouseEvent.MIDDLE_CLICK, eatEvent);
					modalOverlay.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, eatEvent);
				}
*/				
				stage.addChild(modalOverlay);
			}
			else {
				stage.removeChild(modalOverlay);
				modalOverlay = null;
			}
		}
	}

	public function logoButtonPressed(b:IconButton):Void {
		//if (isExtensionDevMode) {
			//externalCall('showPage', null, 'home');
		//}
	}

	// -----------------------------
	// Translations utilities
	//------------------------------

	public function translationChanged():Void {
		// The translation has changed. Fix scripts and update the UI.
		// directionChanged is true if the writing direction (e.g. left-to-right) has changed.
		for (o in stagePane.allObjects()) {
			o.updateScriptsAfterTranslation();
		}
		var uiLayer:Sprite = app.stagePane.getUILayer();
		for (i in 0...uiLayer.numChildren) {
			var lw:ListWatcher = cast(uiLayer.getChildAt(i), ListWatcher);
			if (lw != null) lw.updateTranslation();
		}
		topBarPart.updateTranslation();
		stagePart.updateTranslation();
		libraryPart.updateTranslation();
		tabsPart.updateTranslation();
		updatePalette(false);
		imagesPart.updateTranslation();
		soundsPart.updateTranslation();
	}

	// -----------------------------
	// Menus
	//------------------------------
	public function showFileMenu(b:Dynamic):Void {
		var m:Menu = new Menu(null, 'File', CSS.topBarColor(), 28);
		m.addItem('New', createNewProject);
		m.addLine();

		// Derived class will handle this
		addFileMenuItems(b, m);

		m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
	}

	private function addFileMenuItems(b:Dynamic, m:Menu):Void {
		m.addItem('Load Project', runtime.selectProjectFile);
		m.addItem('Save Project', exportProjectToFile);
		if (canUndoRevert()) {
			m.addLine();
			m.addItem('Undo Revert', undoRevert);
		} else if (canRevert()) {
			m.addLine();
			m.addItem('Revert', revertToOriginalProject);
		}

		if (b.lastEvent.shiftKey) {
			m.addLine();
			m.addItem('Save Project Summary', saveSummary);
		}
		//if (b.lastEvent.shiftKey && jsEnabled) {
			//m.addLine();
			//m.addItem('Import experimental extension', function ():Void {
				//function loadJSExtension(dialog:DialogBox):Void {
					//var url:String = dialog.getField('URL').replace(~/^\s+|\s+$/g, '');
					//if (url.length == 0) return;
					//externalCall('ScratchExtensions.loadExternalJS', null, url);
				//}
//
				//var d:DialogBox = new DialogBox(loadJSExtension);
				//d.addTitle('Load Javascript Scratch Extension');
				//d.addField('URL', 120);
				//d.addAcceptCancelButtons('Load');
				//d.showOnStage(app.stage);
			//});
		//}
	}

	public function showEditMenu(b:Dynamic):Void {
		var m:Menu = new Menu(null, 'More', CSS.topBarColor(), 28);
		m.addItem('Undelete', runtime.undelete, runtime.canUndelete());
		m.addLine();
		m.addItem('Small stage layout', toggleSmallStage, true, stageIsContracted);
		m.addItem('Turbo mode', toggleTurboMode, true, interp.turboMode);
		addEditMenuItems(b, m);
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
	}

	private function addEditMenuItems(b:Dynamic, m:Menu):Void {
		m.addLine();
		m.addItem('Edit block colors', editBlockColors);
	}

	private function editBlockColors():Void {
		var d:DialogBox = new DialogBox();
		d.addTitle('Edit Block Colors');
		d.addWidget(new BlockColorEditor());
		d.addButton('Close', d.cancel);
		d.showOnStage(stage, true);
	}

	private function canExportInternals():Bool {
		return false;
	}

	private function showAboutDialog():Void {
		DialogBox.notify(
				'Scratch 2.0 ' + versionString,
				'\n\nCopyright © 2012 MIT Media Laboratory' +
				'\nAll rights reserved.' +
				'\n\nPlease do not distribute!', stage);
	}

	private function createNewProjectAndThen(callback:Function = null):Void {
		function clearProject():Void {
			startNewProject('', '');
			setProjectName('Untitled');
			topBarPart.refresh();
			stagePart.refresh();
			if (callback != null) callback();
		}

		saveProjectAndThen(clearProject);
	}

	private function createNewProject(ignore:Dynamic = null):Void {
		createNewProjectAndThen();
	}

	//private function createNewProjectScratchX(jsCallback:Array<Dynamic>):Void {
		//createNewProjectAndThen(function():Void {
			//externalCallArray(jsCallback);
		//});
	//}

	private function saveProjectAndThen(postSaveAction:Function = null):Void {
		var d:DialogBox = new DialogBox();
		// Give the user a chance to save their project, if needed, then call postSaveAction.
		function doNothing():Void {
		}

		function cancel():Void {
			d.cancel();
		}

		function proceedWithoutSaving():Void {
			d.cancel();
			postSaveAction();
		}

		function save():Void {
			d.cancel();
			exportProjectToFile(false, postSaveAction);
		}

		if (postSaveAction == null) postSaveAction = doNothing;
		if (!saveNeeded) {
			postSaveAction();
			return;
		}
		d.addTitle('Save project?');
		d.addButton('Save', save);
		d.addButton('Don\'t save', proceedWithoutSaving);
		d.addButton('Cancel', cancel);
		d.showOnStage(stage);
	}

	public function exportProjectToFile(fromJS:Bool = false, saveCallback:Function = null):Void {
		if (loadInProgress) return;
		var projIO:ProjectIO = new ProjectIO(this);
		function fileSaved(e:Event):Void {
			if (!fromJS) setProjectName(e.target.name);
			if (isExtensionDevMode) {
				// Some versions of the editor think of this as an "export" and some think of it as a "save"
				saveNeeded = false;
			}
			if (saveCallback != null) saveCallback();
		}
		function squeakSoundsConverted():Void {
			scriptsPane.saveScripts(false);
			var projectType:String = /*extensionManager.hasExperimentalExtensions() ? '.sbx' : */'.sb2';
			var defaultName:String = StringTools.trim(projectName());
			defaultName = ((defaultName.length > 0) ? defaultName : 'project') + projectType;
			var zipData:ByteArray = projIO.encodeProjectAsZipFile(stagePane);
			var file:FileReference = new FileReference();
			file.addEventListener(Event.COMPLETE, fileSaved);
			file.save(zipData, fixFileName(defaultName));
		}


		projIO.convertSqueakSounds(stagePane, squeakSoundsConverted);
	}

	public static function fixFileName(s:String):String {
		// Replace illegal characters in the given string with dashes.
		var illegal:String = '\\/:*?"<>|%';
		var result:String = '';
		for (i in 0...s.length) {
			var ch:String = s.charAt(i);
			if ((i == 0) && ('.' == ch)) ch = '-'; // don't allow leading period
			result += (illegal.indexOf(ch) > -1) ? '-' : ch;
		}
		return result;
	}

	public function saveSummary():Void {
		var name:String = (projectName() != null ? projectName() : "project") + ".txt";
		var file:FileReference = new FileReference();
		file.save(stagePane.getSummary(), fixFileName(name));
	}

	public function toggleSmallStage():Void {
		setSmallStageMode(!stageIsContracted);
	}

	public function toggleTurboMode():Void {
		interp.turboMode = !interp.turboMode;
		stagePart.refresh();
	}

	public function handleTool(tool:String, evt:MouseEvent):Void {
	}

	public function showBubble(text:String, x:Dynamic = null, y:Dynamic = null, width:Float = 0):Void {
		if (x == null) x = stage.mouseX;
		if (y == null) y = stage.mouseY;
		gh.showBubble(text, cast(x, Float), cast(y, Float), width);
	}

	// -----------------------------
	// Project Management and Sign in
	//------------------------------

	public function setLanguagePressed(b:IconButton):Void {
		function setLanguage(lang:String):Void {
			Translator.setLanguage(lang);
			languageChanged = true;
		}

		if (Translator.languages.length == 0) return; // empty language list
		var m:Menu = new Menu(setLanguage, 'Language', CSS.topBarColor(), 28);
		if (b.lastEvent.shiftKey) {
			m.addItem('import translation file');
			m.addItem('set font size');
			m.addLine();
		}
		for (entry in Translator.languages) {
			m.addItem(entry[1], entry[0]);
		}
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, Std.int(b.x), Std.int(topBarPart.bottom() - 1));
	}

	public function startNewProject(newOwner:String, newID:String):Void {
		runtime.installNewProject();
		projectOwner = newOwner;
		projectID = newID;
		projectIsPrivate = true;
	}

	// -----------------------------
	// Save status
	//------------------------------

	public var saveNeeded:Bool;

	public function setSaveNeeded(saveNow:Bool = false):Void {
		saveNow = false;
		// Set saveNeeded flag and update the status string.
		saveNeeded = true;
		if (!wasEdited) saveNow = true; // force a save on first change
		clearRevertUndo();
	}

	private function clearSaveNeeded():Void {
		// Clear saveNeeded flag and update the status string.
		function twoDigits(n:Int):String {
			return ((n < 10) ? '0' : '') + n;
		}

		saveNeeded = false;
		wasEdited = true;
	}

	// -----------------------------
	// Project Reverting
	//------------------------------

	private var originalProj:ByteArray;
	private var revertUndo:ByteArray;

	public function saveForRevert(projData:ByteArray, isNew:Bool, onServer:Bool = false):Void {
		originalProj = projData;
		revertUndo = null;
	}

	private function doRevert():Void {
		runtime.installProjectFromData(originalProj, false);
	}

	private function revertToOriginalProject():Void {
		function preDoRevert(param:Dynamic):Void {
			revertUndo = new ProjectIO(Scratch.app).encodeProjectAsZipFile(stagePane);
			doRevert();
		}

		if (originalProj == null) return;
		DialogBox.confirm('Throw away all changes since opening this project?', stage, preDoRevert);
	}

	private function undoRevert():Void {
		if (revertUndo == null) return;
		runtime.installProjectFromData(revertUndo, false);
		revertUndo = null;
	}

	private function canRevert():Bool {
		return originalProj != null;
	}

	private function canUndoRevert():Bool {
		return revertUndo != null;
	}

	private function clearRevertUndo():Void {
		revertUndo = null;
	}

	public function addNewSprite(spr:ScratchSprite, showImages:Bool = false, atMouse:Bool = false):Void {
		var c:ScratchCostume, byteCount:Int = 0;
		for (c in spr.costumes) {
			if (!c.baseLayerData) c.prepareToSave();
			byteCount += c.baseLayerData.length;
		}
		if (!okayToAdd(byteCount)) return; // not enough room
		spr.objName = stagePane.unusedSpriteName(spr.objName);
		spr.indexInLibrary = 1000000; // add at end of library
		spr.setScratchXY(Std.int(200 * Math.random() - 100), Std.int(100 * Math.random() - 50));
		if (atMouse) spr.setScratchXY(stagePane.scratchMouseX(), stagePane.scratchMouseY());
		stagePane.addChild(spr);
		spr.updateCostume();
		selectSprite(spr);
		setTab(showImages ? 'images' : 'scripts');
		setSaveNeeded(true);
		libraryPart.refresh();
		for (c in spr.costumes) {
			if (ScratchCostume.isSVGData(c.baseLayerData)) c.setSVGData(c.baseLayerData, false);
		}
	}

	public function addSound(snd:ScratchSound, targetObj:ScratchObj = null):Void {
		if (snd.soundData != null && !okayToAdd(snd.soundData.length)) return; // not enough room
		if (targetObj == null) targetObj = viewedObj();
		snd.soundName = targetObj.unusedSoundName(snd.soundName);
		targetObj.sounds.push(snd);
		setSaveNeeded(true);
		if (targetObj == viewedObj()) {
			soundsPart.selectSound(snd);
			setTab('sounds');
		}
	}

	public function addCostume(c:ScratchCostume, targetObj:ScratchObj = null):Void {
		if (c.baseLayerData == null) c.prepareToSave();
		if (!okayToAdd(c.baseLayerData.length)) return; // not enough room
		if (targetObj == null) targetObj = viewedObj();
		c.costumeName = targetObj.unusedCostumeName(c.costumeName);
		targetObj.costumes.push(c);
		targetObj.showCostumeNamed(c.costumeName);
		setSaveNeeded(true);
		if (targetObj == viewedObj()) setTab('images');
	}

	public function okayToAdd(newAssetBytes:Int):Bool {
		// Return true if there is room to add an asset of the given size.
		// Otherwise, return false and display a warning dialog.
		var assetByteLimit:Int = 50 * 1024 * 1024; // 50 megabytes
		var assetByteCount:Int = newAssetBytes;
		for (obj in stagePane.allObjects()) {
			for (c in obj.costumes) {
				if (!c.baseLayerData) c.prepareToSave();
				assetByteCount += Std.int(c.baseLayerData.length);
			}
			for (snd in obj.sounds) assetByteCount += snd.soundData.length;
		}
		if (assetByteCount > assetByteLimit) {
			var overBy:Int = Std.int(Math.max(1, (assetByteCount - assetByteLimit) / 1024));
			DialogBox.notify(
					'Sorry!',
					'Adding that media asset would put this project over the size limit by ' + overBy + ' KB\n' +
					'Please remove some costumes, backdrops, or sounds before adding additional media.',
					stage);
			return false;
		}
		return true;
	}

	// -----------------------------
	// Flash sprite (helps connect a sprite on the stage with a sprite library entry)
	//------------------------------

	public function flashSprite(spr:ScratchSprite):Void {
		var box:Shape = new Shape();
		function doFade(alpha:Float):Void {
			box.alpha = alpha;
		}

		function deleteBox():Void {
			if (box.parent != null) {
				box.parent.removeChild(box);
			}
		}

		var r:Rectangle = spr.getVisibleBounds(this);
		box.graphics.lineStyle(3, CSS.overColor, 1, true);
		box.graphics.beginFill(0x808080);
		box.graphics.drawRoundRect(0, 0, r.width, r.height, 12, 12);
		box.x = r.x;
		box.y = r.y;
		addChild(box);
		Transition.cubic(doFade, 1, 0, 0.5, deleteBox);
	}

	// -----------------------------
	// Download Progress
	//------------------------------

	public function addLoadProgressBox(title:String):Void {
		removeLoadProgressBox();
		lp = new LoadProgress();
		lp.setTitle(title);
		stage.addChild(lp);
		fixLoadProgressLayout();
	}

	public function removeLoadProgressBox():Void {
		if (lp != null && lp.parent != null) lp.parent.removeChild(lp);
		lp = null;
	}

	private function fixLoadProgressLayout():Void {
		if (lp == null) return;
		var p:Point = stagePane.localToGlobal(new Point(0, 0));
		lp.scaleX = stagePane.scaleX;
		lp.scaleY = stagePane.scaleY;
		lp.x = Std.int(p.x + ((stagePane.width - lp.width) / 2));
		lp.y = Std.int(p.y + ((stagePane.height - lp.height) / 2));
	}

	// -----------------------------
	// Frame rate readout (for use during development)
	//------------------------------

	private var frameRateReadout:TextField;
	private var firstFrameTime:Int;
	private var frameCount:Int;

	private function addFrameRateReadout(x:Int, y:Int, color:UInt = 0):Void {
		frameRateReadout = new TextField();
		frameRateReadout.autoSize = TextFieldAutoSize.LEFT;
		frameRateReadout.selectable = false;
		frameRateReadout.background = false;
		frameRateReadout.defaultTextFormat = new TextFormat(CSS.font, 12, color);
		frameRateReadout.x = x;
		frameRateReadout.y = y;
		addChild(frameRateReadout);
		frameRateReadout.addEventListener(Event.ENTER_FRAME, updateFrameRate);
	}

	private function updateFrameRate(e:Event):Void {
		frameCount++;
		if (frameRateReadout == null) return;
		var now:Int = Lib.getTimer();
		var msecs:Int = now - firstFrameTime;
		if (msecs > 500) {
			var fps:Float = Math.round((1000 * frameCount) / msecs);
			frameRateReadout.text = fps + ' fps (' + Math.round(msecs / frameCount) + ' msecs)';
			firstFrameTime = now;
			frameCount = 0;
		}
	}

	// TODO: Remove / no longer used
	private static inline var frameRateGraphH:Int = 150;
	private var frameRateGraph:Shape;
	private var nextFrameRateX:Int;
	private var lastFrameTime:Int;

	private function addFrameRateGraph():Void {
		addChild(frameRateGraph = new Shape());
		frameRateGraph.y = stage.stageHeight - frameRateGraphH;
		clearFrameRateGraph();
		stage.addEventListener(Event.ENTER_FRAME, updateFrameRateGraph);
	}

	public function clearFrameRateGraph():Void {
		var g:Graphics = frameRateGraph.graphics;
		g.clear();
		g.beginFill(0xFFFFFF);
		g.drawRect(0, 0, stage.stageWidth, frameRateGraphH);
		nextFrameRateX = 0;
	}

	private function updateFrameRateGraph(evt:Dynamic):Void {
		var now:Int = Lib.getTimer();
		var msecs:Int = now - lastFrameTime;
		lastFrameTime = now;
		var c:Int = 0x505050;
		if (msecs > 40) c = 0xE0E020;
		if (msecs > 50) c = 0xA02020;

		if (nextFrameRateX > stage.stageWidth) clearFrameRateGraph();
		var g:Graphics = frameRateGraph.graphics;
		g.beginFill(c);
		var barH:Int = Std.int(Math.min(frameRateGraphH, msecs / 2));
		g.drawRect(nextFrameRateX, frameRateGraphH - barH, 1, barH);
		nextFrameRateX++;
	}

	// -----------------------------
	// Camera Dialog
	//------------------------------

	public function openCameraDialog(savePhoto:Function):Void {
		closeCameraDialog();
		cameraDialog = new CameraDialog(savePhoto);
		cameraDialog.fixLayout();
		cameraDialog.x = (stage.stageWidth - cameraDialog.width) / 2;
		cameraDialog.y = (stage.stageHeight - cameraDialog.height) / 2;
		addChild(cameraDialog);
	}

	public function closeCameraDialog():Void {
		if (cameraDialog != null) {
			cameraDialog.closeDialog();
			cameraDialog = null;
		}
	}

	// Misc.
	public function createMediaInfo(obj:Dynamic, owningObj:ScratchObj = null):MediaInfo {
		return new MediaInfo(obj, owningObj);
	}

	static public function loadSingleFile(fileLoaded:Function, filter:FileFilter = null):Void {
		var fileList:FileReferenceList = new FileReferenceList();
		function fileSelected(event:Event):Void {
			if (fileList.fileList.length > 0) {
				var file:FileReference = fileList.fileList[0];
				file.addEventListener(Event.COMPLETE, fileLoaded);
				file.load();
			}
		}

		fileList.addEventListener(Event.SELECT, fileSelected);
		try {
			// Ignore the exception that happens when you call browse() with the file browser open
			fileList.browse(filter != null ? [filter] : null);
		} catch (e:Dynamic) {
		}
	}

	// -----------------------------
	// External Interface abstraction
	//------------------------------

	//public function externalInterfaceAvailable():Bool {
		//return ExternalInterface.available;
	//}
//
	//public function externalCall(functionName:String, returnValueCallback:Function = null, args:Array<Dynamic>):Void {
		//args.unshift(functionName);
		//var retVal:Dynamic = ExternalInterface.call.apply(ExternalInterface, args);
		//if (returnValueCallback != null) {
			//returnValueCallback(retVal);
		//}
	//}
//
	//public function addExternalCallback(functionName:String, closure:Function):Void {
		//ExternalInterface.addCallback(functionName, closure);
	//}
//
	//// jsCallbackArray is: [functionName, arg1, arg2...] where args are optional.
	//// TODO: rewrite all versions of externalCall in terms of this
	//public function externalCallArray(jsCallbackArray:Array<Dynamic>, returnValueCallback:Dynamic->Void = null):Void {
		//var args:Array<Dynamic> = jsCallbackArray.concat(); // clone
		//args.splice(1, 0, returnValueCallback);
		//externalCall.apply(this, args);
	//}
}


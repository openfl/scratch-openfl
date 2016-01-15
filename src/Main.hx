package;

import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.Lib;
import assets.Resources;
import js.Browser;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import openfl.events.Event;

/**
 * ...
 * @author 
 */
class Main 
{
	
	static function main() 
	{
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		// Entry point
		Browser.document.oncontextmenu = function(evt) { evt.preventDefault(); };  // disable default right-click menus
		Resources.preload(function() {
			var scratch = new ScratchEasyStarter();
			
			// Just a little hack to get Scratch to load a basic project from a URL at startup
			if (Browser.location.hash.length > 1) {
				var url = Browser.location.hash.substring(1);
				var request = new URLRequest(url);
				var loader = new URLLoader(request);
				loader.dataFormat = URLLoaderDataFormat.BINARY;
				loader.addEventListener(Event.COMPLETE, function(evt) { 
					scratch.runtime.installProjectFromFile(url, loader.data);
				});
				loader.load(request);
			}
		});
	}
	
}
package;

import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.Lib;
import assets.Resources;
import js.Browser;

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
		Browser.document.oncontextmenu = function(evt) { trace('hi');  evt.preventDefault(); };  // disable default right-click menus
		Resources.preload(function() {
			trace(Resources.createBmp("flagIcon").bitmapData.width);
			new ScratchEasyStarter();
		});
	}
	
}
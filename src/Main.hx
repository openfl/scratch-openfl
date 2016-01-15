package;

import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.Lib;
import assets.Resources;

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
		Resources.preload(function() {
			trace(Resources.createBmp("flagIcon").bitmapData.width);
			new ScratchEasyStarter();
		});
	}
	
}
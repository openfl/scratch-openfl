package;

import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.Lib;

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
		new ScratchEasyStarter();
	}
	
}
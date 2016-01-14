import Scratch;

import util.ServerEasyStarter;
//import openfl.external.ExternalInterface;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.Lib;

class ScratchEasyStarter extends Scratch
{

	public function new()
	{
		super();
	}

	override private function initServer() : Void{
		var cdnPrefix : String = Reflect.field(openfl.Lib.current.root.loaderInfo.parameters, "cdnPrefix");
		//ExternalInterface.call("console.log", cdnPrefix);
		if (cdnPrefix != null) 
			server = new ServerEasyStarter(cdnPrefix)
		else 
		server = new ServerEasyStarter();
	}

	override private function determineJSAccess() : Void{
		// I don't think JS support is needed for Scratch to work,
		// but when JS support exists, Scratch seems to expect certain
		// JS functions to exist when the Scratch SWF is embedded in a
		// web page. So it seems easier for setup to simply disable it.
		initialize();
	}
	
	static function main() 
	{
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		// Entry point
		new ScratchEasyStarter();
	}
}







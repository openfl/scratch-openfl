package 
{
	import util.ServerEasyStarter;
	//import flash.external.ExternalInterface;
	
	public class ScratchEasyStarter extends Scratch
	{
		
		public function ScratchEasyStarter() 
		{
			super();
		}
		
		protected override function initServer():void {
			var cdnPrefix:String = loaderInfo.parameters['cdnPrefix'];
			//ExternalInterface.call("console.log", cdnPrefix);
			if (cdnPrefix != null)
				server = new ServerEasyStarter(cdnPrefix);
			else
				server = new ServerEasyStarter();
		}
		
		protected override function determineJSAccess():void {
			// I don't think JS support is needed for Scratch to work,
			// but when JS support exists, Scratch seems to expect certain
			// JS functions to exist when the Scratch SWF is embedded in a
			// web page. So it seems easier for setup to simply disable it.
			initialize();
		}
		
				
		protected override function startInEditMode():Boolean {
			return true;
		}

	}
	


}



package 
{
	import util.ServerEasyStarter;
	
	public class ScratchEasyStarter extends Scratch
	{
		
		public function ScratchEasyStarter() 
		{
			super();
		}
		
		protected override function initServer():void {
			server = new ServerEasyStarter();
		}
	}
	

}



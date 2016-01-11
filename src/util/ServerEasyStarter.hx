package util 
{
	import flash.net.URLLoader;

	public class ServerEasyStarter extends Server
	{
		public var resourcePrefix:String;

		public function ServerEasyStarter(resourceUrlPrefix:String = '../') {
			resourcePrefix = resourceUrlPrefix;
		}
		
		protected override function getCdnStaticSiteURL():String {
			return resourcePrefix;
		}

		public override function getAsset(md5:String, whenDone:Function):URLLoader {
//		if (BackpackPart.localAssets[md5] && BackpackPart.localAssets[md5].length > 0) {
//			whenDone(BackpackPart.localAssets[md5]);
//			return null;
//		}
			var url:String = URLs.assetCdnPrefix + URLs.internalAPI + 'asset/' + md5 + '/get/';
			url = resourcePrefix + 'medialibraries/' + md5;
			return serverGet(url, whenDone);
		}
	}
}
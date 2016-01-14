package util;


import flash.net.URLLoader;
import openfl.utils.ByteArray;

class ServerEasyStarter extends Server
{
	public var resourcePrefix : String;

	public function new(resourceUrlPrefix : String = "../")
	{
		super();
		resourcePrefix = resourceUrlPrefix;
	}

	override private function getCdnStaticSiteURL() : String{
		return resourcePrefix;
	}

	override public function getAsset(md5 : String, whenDone : ByteArray->Void) : URLLoader{
		//		if (BackpackPart.localAssets[md5] && BackpackPart.localAssets[md5].length > 0) {
		//			whenDone(BackpackPart.localAssets[md5]);
		//			return null;
		//		}
		var url : String = URLs.assetCdnPrefix + URLs.internalAPI + "asset/" + md5 + "/get/";
		url = resourcePrefix + "medialibraries/" + md5;
		return serverGet(url, whenDone);
	}
}

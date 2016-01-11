package util 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;

	/**
	 * Variant of the server which returns resources that are embedded in the
	 * SWF itself. (This is needed because the Chrome version of Flash does
	 * not allow local file access.)
	 * 
	 * Actually, this still doesn't work. Apparently, the Chrome sandbox doesn't
	 * let you decode byte arrays to png files when using local file access.
	 */
	SCRATCH::allEmbed public class ServerAllEmbedded extends Server
	{
		public function ServerAllEmbedded() {
			
		}
		
		// Overall resource lists
		[Embed(source='../../medialibraries/spriteLibrary.json', mimeType='application/octet-stream')] private static const spriteLibraryJson:Class;
		[Embed(source='../../medialibraries/backdropLibrary.json', mimeType='application/octet-stream')] private static const backdropLibraryJson:Class;
		
		// Descriptions of individual sprites
		[Embed(source='../../medialibraries/blueellipsesprite.json', mimeType='application/octet-stream')] private static const blueEllipseSpriteJson:Class;
		[Embed(source='../../medialibraries/dogsprite.json', mimeType='application/octet-stream')] private static const dogSpriteJson:Class;

		// Actual images
		[Embed(source='../../medialibraries/blueellipse.svg', mimeType='application/octet-stream')] private static const blueEllipseSvg:Class;
		[Embed(source='../../medialibraries/dog.png', mimeType='application/octet-stream')] private static const dogPng:Class;
		[Embed(source='../../medialibraries/earthrise.jpg', mimeType='application/octet-stream')] private static const earthriseJpg:Class;
		
		// Dictionary containing all the files
		private var embeddedFiles:Object = {
			'spriteLibrary.json' : spriteLibraryJson,
			'backdropLibrary.json' : backdropLibraryJson,
			'blueellipsesprite.json' : blueEllipseSpriteJson,
			'dogsprite.json' : dogSpriteJson,
			'blueellipse.svg' : blueEllipseSvg,
			'dog.png' : dogPng,
			'earthrise.jpg' : earthriseJpg
		};
		
		protected override function getCdnStaticSiteURL():String {
			return "../";
		}

		public override function getAsset(md5:String, whenDone:Function):URLLoader {
			if (embeddedFiles[md5] == null)
				whenDone(null);
			else
				whenDone(new (embeddedFiles[md5])() as ByteArray);
			return getDummyUrlLoader();
		}
		
		public override function getMediaLibrary(type:String, callback:Function):URLLoader {
			var file:String = type + 'Library.json';
			if (embeddedFiles[file] == null)
				callback(null);
			else
				callback(new (embeddedFiles[file])() as ByteArray);
			return getDummyUrlLoader();
		}
		
		public override function getThumbnail(md5:String, w:int, h:int, callback:Function):URLLoader {
			function imageLoaded(e:Event):void {
				// Scale down the bitmap to a thumbnail
				var image:BitmapData = e.target.content.bitmapData;
				var thumb:BitmapData = new BitmapData(w, h, true, 0);
				var m:Matrix = new Matrix();
				m.scale(Math.min(w / image.width, h / image.height), Math.min(w / image.width, h / image.height));
				thumb.draw(image, m);
				callback(thumb);
			}
			
			// Convert the raw image data to a bitmap
			var loader:Loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
			if (embeddedFiles[md5] == null)
				callback(null);
			else
				loader.loadBytes(new (embeddedFiles[md5])() as ByteArray, loaderContext);
			
			return new DummyURLLoader();
		}
		
		// The Scratch server API expects a URLLoader to be returned, but we don't use
		// any because we're simply accessing resources embedded in the SWF file. So we
		// create a URLLoader that accesses some random data so that we have something to return.
		protected function getDummyUrlLoader():URLLoader {
			return new DummyURLLoader();
		}
	}
}

class DummyURLLoader extends flash.net.URLLoader {
	public override function close():void { }
}

/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// FilterPack.as
// John Maloney, July 2010
//
// Scratch image filters. Uses compiled "pixel-bender" shaders for performance.
// Use setFilter() to set filter parameters. buildFilters() returns a list of filters
// to be assigned to the filters property of s DisplayObject (e.g. a sprite).

package filters;

/*
import filters.FisheyeKernel;
import filters.HSVKernel;
import filters.MosaicKernel;
import filters.PixelateKernel;
import filters.ScratchObj;
import filters.Shader;
import filters.ShaderFilter;
import filters.WhirlKernel;
*/

import flash.display.*;
import flash.filters.*;
import flash.geom.ColorTransform;
import flash.system.Capabilities;
import scratch.*;
import util.*;

class FilterPack
{
	public static var filterNames : Array<Dynamic> = [
		"color", "fisheye", "whirl", "pixelate", "mosaic", "brightness", "ghost"];

	public var targetObj : ScratchObj;
	private var filterDict : Dynamic;
/*    
	@:meta(Embed(source="kernels/fisheye.pbj",mimeType="application/octet-stream"))

	private var FisheyeKernel : Class<Dynamic>;
	private var fisheyeShader : Shader = new Shader(Type.createInstance(FisheyeKernel, []));

	@:meta(Embed(source="kernels/hsv.pbj",mimeType="application/octet-stream"))

	private var HSVKernel : Class<Dynamic>;
	private var hsvShader : Shader = new Shader(Type.createInstance(HSVKernel, []));

	@:meta(Embed(source="kernels/mosaic.pbj",mimeType="application/octet-stream"))

	private var MosaicKernel : Class<Dynamic>;
	private var mosaicShader : Shader = new Shader(Type.createInstance(MosaicKernel, []));

	@:meta(Embed(source="kernels/pixelate.pbj",mimeType="application/octet-stream"))

	private var PixelateKernel : Class<Dynamic>;
	private var pixelateShader : Shader = new Shader(Type.createInstance(PixelateKernel, []));

	@:meta(Embed(source="kernels/whirl.pbj",mimeType="application/octet-stream"))

	private var WhirlKernel : Class<Dynamic>;
	private var whirlShader : Shader = new Shader(Type.createInstance(WhirlKernel, []));
*/    
	public function new(targetObj : ScratchObj)
	{
		this.targetObj = targetObj;
		this.filterDict = {};
		resetAllFilters();
	}

	public function getAllSettings() : Dynamic{
		return filterDict;
	}

	public function resetAllFilters() : Void{
		for (i in 0...filterNames.length){
			Reflect.setField(filterDict, Std.string(filterNames[i]), 0);
		}
	}

	public function getFilterSetting(filterName : String) : Float{
		var v : Dynamic = Reflect.field(filterDict, filterName);
		if (!(Std.is(v, Float)))             return 0;
		return v;
	}

	public function setFilter(filterName : String, newValue : Float) : Bool{
		if (newValue != newValue)             return false;
		if (filterName == "brightness")             newValue = Math.max(-100, Math.min(newValue, 100));
		if (filterName == "color")             newValue = newValue % 200;
		if (filterName == "ghost")             newValue = Math.max(0, Math.min(newValue, 100));

		var oldValue : Float = Reflect.field(filterDict, filterName);
		Reflect.setField(filterDict, filterName, newValue);

		return (newValue != oldValue);
	}

	public function duplicateFor(target : ScratchObj) : FilterPack{
		var result : FilterPack = new FilterPack(target);
		for (i in 0...filterNames.length){
			var fName : String = filterNames[i];
			result.setFilter(fName, Reflect.field(filterDict, fName));
		}
		return result;
	}

	private static var emptyArray : Array<flash.filters.BitmapFilter> = [];
	private var newFilters : Array<flash.filters.BitmapFilter> = [];
	public function buildFilters(force : Bool = false) : Array<flash.filters.BitmapFilter>{
		// disable filters not running on x86 because PixelBender is really slow
		if ((Scratch.app.isIn3D || Capabilities.cpuArchitecture != "x86") && !force)             return emptyArray;

		var scale : Float = (targetObj.isStage) ? 1 : Scratch.app.stagePane.scaleX;
		var srcWidth : Float = targetObj.width * scale;
		var srcHeight : Float = targetObj.height * scale;
		var n : Float;
		newFilters = [];
		/*
		if (Reflect.field(filterDict, "whirl") != 0) {
			// range: -infinity..infinity
			var radians : Float = (Math.PI * Reflect.field(filterDict, "whirl")) / 180;
			var scaleX : Float;
			var scaleY : Float;
			if (srcWidth > srcHeight) {
				scaleX = srcHeight / srcWidth;
				scaleY = 1;
			}
			else {
				scaleX = 1;
				scaleY = srcWidth / srcHeight;
			}
			whirlShader.data.whirlRadians.value = [radians];
			whirlShader.data.center.value = [srcWidth / 2, srcHeight / 2];
			whirlShader.data.radius.value = [Math.min(srcWidth, srcHeight) / 2];
			whirlShader.data.scale.value = [scaleX, scaleY];
			newFilters.push(new ShaderFilter(whirlShader));
		}
		if (Reflect.field(filterDict, "fisheye") != 0) {
			// range: -100..infinity
			n = Math.max(0, (Reflect.field(filterDict, "fisheye") + 100) / 100);
			fisheyeShader.data.scaledPower.value = [n];
			fisheyeShader.data.center.value = [srcWidth / 2, srcHeight / 2];
			newFilters.push(new ShaderFilter(fisheyeShader));
		}
		if (Reflect.field(filterDict, "pixelate") != 0) {
			// range of absolute value: 0..(10 * min(w, h))
			n = (Math.abs(Reflect.field(filterDict, "pixelate")) / 10) + 1;
			if (targetObj == Scratch.app.stagePane)                 n *= Scratch.app.stagePane.scaleX;
			n = Math.min(n, Math.min(srcWidth, srcHeight));
			pixelateShader.data.pixelSize.value = [n];
			newFilters.push(new ShaderFilter(pixelateShader));
		}
		if (Reflect.field(filterDict, "mosaic") != 0) {
			// range of absolute value: 0..(10 * min(w, h))
			n = Math.round((Math.abs(Reflect.field(filterDict, "mosaic")) + 10) / 10);
			n = Math.max(1, Math.min(n, Math.min(srcWidth, srcHeight)));
			mosaicShader.data.count.value = [n];
			mosaicShader.data.widthAndHeight.value = [srcWidth, srcHeight];
			newFilters.push(new ShaderFilter(mosaicShader));
		}
		if (Reflect.field(filterDict, "color") != 0) {
			// brightness range is -100..100
			//			n = Math.max(-100, Math.min(filterDict["brightness"], 100));
			//			hsvShader.data.brightnessShift.value = [n];
			hsvShader.data.brightnessShift.value = [0];

			// hue range: -infinity..infinity
			n = ((360.0 * Reflect.field(filterDict, "color")) / 200.0) % 360.0;
			hsvShader.data.hueShift.value = [n];
			newFilters.push(new ShaderFilter(hsvShader));
		}
		*/
		return newFilters;
	}
}

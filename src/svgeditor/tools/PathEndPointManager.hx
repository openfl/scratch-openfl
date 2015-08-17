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

package svgeditor.tools;


import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.geom.Point;

import svgeditor.ImageEdit;
import svgeditor.objs.ISVGEditable;
import svgeditor.objs.SVGGroup;
import svgeditor.objs.SVGShape;
import svgeditor.tools.PathAnchorPoint;

import svgutils.SVGPath;

@:final class PathEndPointManager {
	private static var orb : Sprite;
	private static var endPoints : Array<Dynamic>;
	private static var editor : ImageEdit;
	private static var toolsLayer : Sprite;
	
	public static function init(ed : ImageEdit) : Void{
		editor = ed;
		orb = new Sprite();
		orb.visible = false;
		orb.mouseEnabled = false;
		orb.mouseChildren = false;
		PathAnchorPoint.render(orb.graphics);
	}
	
	public static function updateOrb(highlight : Bool, p : Point = null) : Void{
		orb.visible = true;
		if (p != null) {
			orb.x = p.x;
			orb.y = p.y;
		}
		PathAnchorPoint.render(orb.graphics, highlight);
	}
	
	public static function toggleEndPoint(vis : Bool, pt : Point = null) : Void{
		orb.visible = vis;
		
		if (vis) {
			orb.x = pt.x;
			orb.y = pt.y;
			PathAnchorPoint.render(orb.graphics, false);
		}
		
		if (vis && !orb.parent) 
			toolsLayer.addChildAt(orb, 0)
		else if (!vis && orb.parent) 
			toolsLayer.removeChild(orb);
	}
	
	public static function makeEndPoints(obj : DisplayObject = null) : Void{
		toolsLayer = editor.getToolsLayer();
		removeEndPoints();
		
		endPoints = [];
		editor.getToolsLayer().mouseEnabled = false;
		var layer : Sprite;
		var skipObj : DisplayObject = null;
		if (Std.is(obj, Sprite)) 
			layer = try cast(obj, Sprite) catch(e:Dynamic) null
		else {
			if (Std.is(obj, ISVGEditable)) {
				layer = try cast(obj.parent, Sprite) catch(e:Dynamic) null;
				skipObj = obj;
			}
			else 
			layer = editor.getContentLayer();
		}
		findEndPoints(layer, skipObj);
	}
	
	public static function removeEndPoints() : Void{
		for (endPoint in endPoints){
			if (endPoint.parent == toolsLayer) 				toolsLayer.removeChild(endPoint);
		}
		endPoints = null;
		editor.getToolsLayer().mouseEnabled = true;
	}
	
	private static function findEndPoints(layer : Sprite, skipObj : DisplayObject = null) : Void{
		for (i in 0...layer.numChildren){
			var c : Dynamic = layer.getChildAt(i);
			if (Std.is(c, SVGGroup)) {
				findEndPoints(try cast(c, Sprite) catch(e:Dynamic) null);
			}
			else if (Std.is(c, SVGShape) && c != skipObj) {
				var s : SVGShape = try cast(c, SVGShape) catch(e:Dynamic) null;
				if (s.getElement().tag == "path" && s.getElement().path && !s.getElement().path.isClosed()) {
					// TODO: Handle nested paths too
					var path : SVGPath = s.getElement().path;
					var ends : Array<Dynamic> = path.getSegmentEndPoints(0);
					if (!ends[2]) {
						var p : Point = toolsLayer.globalToLocal(s.localToGlobal(path.getPos(ends[0])));
						endPoints.push(toolsLayer.addChild(new PathEndPoint(editor, s, p)));
						p = toolsLayer.globalToLocal(s.localToGlobal(path.getPos(ends[1])));
						endPoints.push(toolsLayer.addChild(new PathEndPoint(editor, s, p)));
					}
				}
			}
		}
	}

	public function new()
	{
	}
}


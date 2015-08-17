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

import svgeditor.tools.SVGEditTool;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.CapsStyle;
import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.JointStyle;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;

import svgeditor.ImageEdit;
import svgeditor.objs.ISVGEditable;
import svgeditor.objs.PathDrawContext;
import svgeditor.objs.SVGShape;

import svgutils.SVGElement;
import svgutils.SVGPath;

@:final class PathEditTool extends SVGEditTool {
	private var pathElem : SVGElement;
	private var controlPoints : Array<Dynamic>;
	private var toolsLayer : Sprite;
	private var currentEndPoints : Array<Dynamic>;
	
	public function new(ed : ImageEdit)
	{
		super(ed, ["path", "rect", "ellipse", "circle"]);
		reset();
	}
	
	override private function init() : Void{
		super.init();
		showPathPoints();
	}
	
	override private function shutdown() : Void{
		super.shutdown();
		PathEndPointManager.removeEndPoints();
	}
	
	private function reset() : Void{
		pathElem = null;
		controlPoints = null;
	}
	
	override public function refresh() : Void{
		if (!object) 			return;
		
		var obj : ISVGEditable = object;
		edit(null, currentEvent);
		edit(obj, currentEvent);
	}
	
	////////////////////////////////////////
	// UI Path editing Adding Points
	///////////////////////////////////////
	override private function edit(obj : ISVGEditable, event : MouseEvent) : Void{
		// Select a new object?  or add a point
		if (obj != object) {
			PathEndPointManager.removeEndPoints();
			currentEndPoints = null;
			if (object) {
				for (i in 0...controlPoints.length){removeChild(controlPoints[i]);
				}
				
				reset();
			}
			
			super.edit(obj, event);
			if (object) {
				pathElem = object.getElement();
				
				// Convert non-path elements to path elements
				if (pathElem.tag != "path") {
					pathElem.convertToPath();
					object.redraw();
				}
				
				showPathPoints();
			}
			return;
		}
		
		if (object) {
			var indx : Int = (try cast(object, SVGShape) catch(e:Dynamic) null).getPathCmdIndexUnderMouse();
			if (indx < 0) 				return  // Add the new point  ;
			
			
			
			var dObj : DisplayObject = (try cast(object, DisplayObject) catch(e:Dynamic) null);
			addPoint(indx, new Point(dObj.mouseX, dObj.mouseY));
		}
	}
	
	// SVG Element access
	private function getAttribute(attr : String) : Dynamic{
		return pathElem.getAttribute(attr);
	}
	
	/////////////////////////////////////////////////////////////
	//  Path editing
	////////////////////////////////////////////////////////////
	private function showPathPoints() : Void{
		if (controlPoints != null && controlPoints.length) {
			for (cp in controlPoints){
				removeChild(cp);
			}
		}
		controlPoints = [];
		if (!object || !parent) 			return;
		
		var len : Int = pathElem.path.length;
		var i : Int = 0;
		var endPoints : Array<Dynamic> = pathElem.path.getSegmentEndPoints(0);
		for (j in 0...len){
			if (j > endPoints[1]) 				endPoints = pathElem.path.getSegmentEndPoints(j);
			if (!validAnchorIndex(j)) 				{++j;continue;
			};
			var ep : Bool = !endPoints[2] && (j == endPoints[0] || j == endPoints[1]);
			controlPoints.push(
					getAnchorPoint(j, ep)
					);
			++i;
		}
	}
	
	private function resetControlPointIndices() : Void{
		var len : Int = pathElem.path.length;
		var i : Int = 0;
		var endPoints : Array<Dynamic> = pathElem.path.getSegmentEndPoints(0);
		for (j in 0...len){
			if (j > endPoints[1]) 				endPoints = pathElem.path.getSegmentEndPoints(j);
			if (!validAnchorIndex(j)) 				{++j;continue;
			};
			controlPoints[i].index = j;
			controlPoints[i].endPoint = !endPoints[2] && (j == endPoints[0] || j == endPoints[1]);
			++i;
		}
	}
	
	private function redrawObj(bSkipSave : Bool = false) : Void{
		object.redraw();
		
		// The object changed!
		if (!bSkipSave) 
			dispatchEvent(new Event(Event.CHANGE));
	}
	
	public function moveControlPoint(index : UInt, bFirst : Bool, p : Point, bDone : Bool = false) : Void{
		if (index < pathElem.path.length && pathElem.path[index][0] == "C") {
			p = (try cast(object, DisplayObject) catch(e:Dynamic) null).globalToLocal(p);
			var cmd : Array<Dynamic> = pathElem.path[index];
			if (bFirst) {
				cmd[1] = p.x;
				cmd[2] = p.y;
			}
			else {
				cmd[3] = p.x;
				cmd[4] = p.y;
			}
			redrawObj(!bDone);
		}
	}
	
	private var movingPoint : Bool;
	public function movePoint(index : UInt, p : Point, bDone : Bool = false) : Void{
		var dObj : DisplayObject = try cast(object, DisplayObject) catch(e:Dynamic) null;
		p = dObj.globalToLocal(p);
		pathElem.path.move(index, p);
		redrawObj(!bDone);
		
		if (bDone) {
			currentEndPoints = pathElem.path.getSegmentEndPoints(index);
			if (!currentEndPoints[2]) {
				// TODO: Make a generic way to test whether it's close enough to the other end-point
				// TODO: Add a visual effect for before the stop moving the point to show that it
				// is going to close the path
				var w : Float = 2 * (getAttribute("stroke-width") || 1);
				if ((currentEndPoints[0] == index &&
					pathElem.path.getPos(index).subtract(pathElem.path.getPos(currentEndPoints[1])).length < w) ||
					(currentEndPoints[1] == index &&
					pathElem.path.getPos(index).subtract(pathElem.path.getPos(currentEndPoints[0])).length < w)) {
					
					// Close the path and refresh the anchor points
					pathElem.path.splice(currentEndPoints[1] + 1, 0, ["Z"]);
					pathElem.path.adjustPathAroundAnchor(currentEndPoints[1], 1, 1);
					pathElem.path.adjustPathAroundAnchor(currentEndPoints[1], 1, 1);
					redrawObj(!bDone);
					refresh();
				}
				else {
					dObj.visible = false;
					var retval : Dynamic = getContinuableShapeUnderMouse(getAttribute("stroke-width") || 1);
					dObj.visible = true;
					if (retval != null && (try cast(object, SVGShape) catch(e:Dynamic) null).connectPaths(retval.shape)) {
						(try cast(retval.shape, DisplayObject) catch(e:Dynamic) null).parent.removeChild((try cast(retval.shape, DisplayObject) catch(e:Dynamic) null));
						(try cast(object, SVGShape) catch(e:Dynamic) null).redraw();
						refresh();
					}
				}
			}
			movingPoint = false;
			PathEndPointManager.removeEndPoints();
		}
		// TODO: enable this when the user is altering control points
		else if (!movingPoint) {
			currentEndPoints = pathElem.path.getSegmentEndPoints(index);
			if (!currentEndPoints[2] && (index == currentEndPoints[0] || index == currentEndPoints[1])) 
				PathEndPointManager.makeEndPoints(dObj);
			movingPoint = true;
		}
		
		
		
		for (i in 0...numChildren){
			dObj = getChildAt(i);
			if (Std.is(dObj, PathControlPoint)) {
				(try cast(dObj, PathControlPoint) catch(e:Dynamic) null).refresh();
			}
		}
	}
	
	public function removePoint(index : UInt, event : MouseEvent) : Void{
		var endPoints : Array<Dynamic> = pathElem.path.getSegmentEndPoints(index);
		
		// Get the control point index
		var len : Int = pathElem.path.length;
		var cp_idx : Int = 0;
		for (j in 0...len){
			if (!validAnchorIndex(j)) 				{++j;continue;
			};
			if (j == index) {
				break;
			}++;cp_idx;
		}  // Cut the path here if the shift key was down and the point is not an end-point    //if(endPoints[1] - endPoints[0] < 2) return;    // then uncomment this code:    // If we want to prevent removing 2-point paths by removing a point,  
		
		
		
		
		
		
		
		
		
		
		var pos : Point;
		if ((index < endPoints[1] || (endPoints[2] && index == endPoints[1])) && index > endPoints[0] && event.shiftKey) {
			var intersections : Array<Dynamic> = (try cast(object, SVGShape) catch(e:Dynamic) null).getAllIntersectionsWithShape(controlPoints[cp_idx], true);
			var pos1 : Point = pathElem.path.getPos(intersections[0].start.index, intersections[0].start.time);
			var pos2 : Point = pathElem.path.getPos(intersections[0].end.index, intersections[0].end.time);
			pathElem.path.move(index, pos1, SVGPath.ADJUST.NONE);
			pathElem.path.splice(index + 1, 0, ["M", pos2.x, pos2.y]);
			
			if (endPoints[2]) {
				// Bind a segment which had closed the path to the beginning of the path
				// Copy the commands but not the ending 'Z' command
				var indices : Array<Dynamic> = pathElem.path.getSegmentEndPoints(index + 1);
				var cmds : Array<Dynamic> = pathElem.path.splice(indices[0], indices[1] + 1);
				cmds.length--;
				var stitchIndex : Int = cmds.length - 1;
				
				// Re-insert the commands at the beginning
				cmds.unshift(1);
				cmds.unshift(0);
				pathElem.path.splice.apply(pathElem.path, cmds);
				
				pathElem.path.adjustPathAroundAnchor(stitchIndex, 2);
				pathElem.path.adjustPathAroundAnchor(0, 2);
				endPoints = pathElem.path.getSegmentEndPoints(0);
				
				var fill : Dynamic = pathElem.getAttribute("fill");
				if (fill != "none" && pathElem.getAttribute("stroke") == "none") {
					pathElem.setAttribute("stroke", fill);
				}
				pathElem.setAttribute("fill", "none");
			}
			// Reset everything
			else if (index <= endPoints[1]) {
				// Make a copy to hold the path after the point
				var newPath : SVGShape = try cast((try cast(object, SVGShape) catch(e:Dynamic) null).clone(), SVGShape) catch(e:Dynamic) null;
				(try cast(object, SVGShape) catch(e:Dynamic) null).parent.addChildAt(newPath, (try cast(object, SVGShape) catch(e:Dynamic) null).parent.getChildIndex(try cast(object, DisplayObject) catch(e:Dynamic) null));
				
				// TODO: Make work with inner paths???
				// TODO: Handle closed paths!
				newPath.getElement().path.splice(0, index + 1);
				newPath.redraw();
				
				// Now truncate the existing path
				pathElem.path.length = index + 1;
			}
			
			
			
			refresh();
		}
		else {
			removeChild(controlPoints[cp_idx]);
			controlPoints.splice(cp_idx, 1);
			
			pathElem.path.remove(index);
			if (index == endPoints[1] && endPoints[2]) {
				// If we just removed the end point of a closed path then move the
				// first command, a move command, to the last point on the path
				pos = pathElem.path.getPos(index - 1);
				pathElem.path[endPoints[0]][1] = pos.x;
				pathElem.path[endPoints[0]][2] = pos.y;
			}  // Shift the indices of the control points after the deleted point  
			
			
			
			resetControlPointIndices();
		}
		
		if (controlPoints.length == 1) {
			var dObj : DisplayObject = try cast(object, DisplayObject) catch(e:Dynamic) null;
			dObj.parent.removeChild(dObj);
			setObject(null);
			dispatchEvent(new Event(Event.CHANGE));
		}
		else {
			redrawObj();
		}
	}
	
	// TODO: Make it so that we can add points AT the Z command when it's preceded by an L command
	private function validAnchorIndex(index : UInt) : Bool{
		var ends : Array<Dynamic> = pathElem.path.getSegmentEndPoints(index);
		if (pathElem.path[index][0] == "Z" || (ends[2] && index == ends[0])) 
			return false;
		return true;
	}
	
	private function addPoint(index : UInt, pt : Point, isLine : Bool = false) : Void{
		var dObj : DisplayObject = (try cast(object, DisplayObject) catch(e:Dynamic) null);
		var len : Int = pathElem.path.length;
		var i : Int = 0;
		var cp : PathAnchorPoint;
		for (j in 0...len){
			if (!validAnchorIndex(j)) 				{++j;continue;
			};
			if (j == index) {
				pathElem.path.add(j, pt, !currentEvent.shiftKey);
				cp = getAnchorPoint(j, false);
				controlPoints.splice(i, 0, cp);
				break;
			}++;i;
		}  // Shift the indices of the control points after the inserted point  
		
		
		
		resetControlPointIndices();
		redrawObj();
		
		// Allow the user to drag the new control point
		if (cp != null) {
			cp.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
			cp.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
		}
	}
	
	private function getAnchorPoint(idx : UInt, endPoint : Bool) : PathAnchorPoint{
		var pt : Point = globalToLocal((try cast(object, DisplayObject) catch(e:Dynamic) null).localToGlobal(pathElem.path.getPos(idx)));
		var pap : PathAnchorPoint = new PathAnchorPoint(this, idx, endPoint);
		pap.x = pt.x;
		pap.y = pt.y;
		addChild(pap);
		return pap;
	}
	
	public function getControlPoint(idx : UInt, first : Bool) : PathControlPoint{
		var pcp : PathControlPoint = null;
		if (pathElem.path[idx][0] == "C") {
			var cmd : Array<Dynamic> = pathElem.path[idx];
			var pt : Point = getControlPos(idx, first);
			pcp = new PathControlPoint(this, idx, first);
			pcp.x = pt.x;
			pcp.y = pt.y;
			addChild(pcp);
		}
		return pcp;
	}
	
	public function getControlPos(idx : UInt, first : Bool) : Point{
		var pt : Point = null;
		if (pathElem.path[idx][0] == "C") {
			var cmd : Array<Dynamic> = pathElem.path[idx];
			pt = new Point((first) ? cmd[1] : cmd[3], (first) ? cmd[2] : cmd[4]);
			pt = globalToLocal((try cast(object, DisplayObject) catch(e:Dynamic) null).localToGlobal(pt));
		}
		
		return pt;
	}
}


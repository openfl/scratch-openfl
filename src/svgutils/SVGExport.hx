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

// SVGExport.as
// John Maloney, June 2012.
//
// Convert an SVGElement tree into SVG file data (string or ByteArray).
//
// The client must be sure that the following are correct:
//	* 'text' field of text elements
//	* 'bitmap' field of image elements
//	* 'path' field of shape elements (the 'd' attribute is ignored)
//	* 'subElements' field of group elements
//	* 'transform' field (null if element is not transformed)
//	* gradient fills: an SVGElement with a 'stop' subElement for each color

package svgutils;

import svgutils.Matrix;
import svgutils.SVGElement;

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.geom.*;
import flash.utils.ByteArray;
import util.Base64Encoder;
import by.blooddy.crypto.image.PNG24Encoder;
import by.blooddy.crypto.image.PNGFilter;

class SVGExport {
	
	private var rootEl : SVGElement;
	private var rootNode : FastXML;
	private var defsNode : FastXML;
	private var nextID : Int;
	
	public function new(svgRoot : SVGElement)
	{
		// Create an instance on the given SVG element, assumed to be an <svg> or <g> element.
		rootEl = svgRoot;
	}
	
	public function svgData() : ByteArray{
		// Return the exported SVG file as a byte array.
		var s : String = svgString();
		var data : ByteArray = new ByteArray();
		data.writeUTFBytes(s);
		return data;
	}
	
	public function svgString() : String{
		// Return the exported SVG file as a string.
		defsNode = null;
		nextID = 1;
		FastXML.ignoreComments = false;
		rootNode = new FastXML("<svg xmlns='http://www.w3.org/2000/svg' version='1.1' " +
				"xmlns:xlink='http://www.w3.org/1999/xlink'>\n" +
				"<!-- Exported by Scratch - http://scratch.mit.edu/ -->\n" +
				"</svg>");
		setSVGWidthAndHeight();
		for (subEl/* AS3HX WARNING could not determine type for var: subEl exp: EField(EIdent(rootEl),subElements) type: null */ in rootEl.subElements){
			addNodeTo(subEl, rootNode);
		}
		if (defsNode != null) 			rootNode.node.prependChild.innerData(defsNode)  // add defs node, if needed  ;
		return rootNode.node.toXMLString.innerData();
	}
	
	private function setSVGWidthAndHeight() : Void{
		// Set the attributes of the top-level <svg> element.
		var svgSprite : Sprite = new SVGDisplayRender().renderAsSprite(rootEl);
		var r : Rectangle = svgSprite.getBounds(svgSprite);
		
		var m : Matrix = new Matrix();
		var bmd : BitmapData = new BitmapData(Math.max(as3hx.Compat.parseInt(r.width), 1), Math.max(as3hx.Compat.parseInt(r.height), 1), true, 0);
		m.translate(-r.left, -r.top);
		bmd.draw(svgSprite, m);
		
		// Get an accurate viewbox
		var cropR : Rectangle = bmd.getColorBoundsRect(0xFF000000, 0, false);
		bmd.dispose();
		
		var w : Int = Math.ceil(cropR.width + 2);
		var h : Int = Math.ceil(cropR.height + 2);
		rootNode.setAttribute("width", w);
		rootNode.setAttribute("height", h);
		rootNode.setAttribute("viewBox", "" + Math.floor(cropR.x - 1) + " " + Math.floor(cropR.y - 1) + " " + w + " " + h) = "" + Math.floor(cropR.x - 1) + " " + Math.floor(cropR.y - 1) + " " + w + " " + h;
	}
	
	private function addNodeTo(el : SVGElement, xml : FastXML) : Void{
		if ("g" == el.tag) 			addGroupNodeTo(el, xml)
		else if ("image" == el.tag) 			addImageNodeTo(el, xml)
		else if ("text" == el.tag) 			addTextNodeTo(el, xml)
		else if (el.path) 			addPathNodeTo(el, xml)
		else trace("SVGExport unhandled: " + el.tag);
	}
	
	private function addGroupNodeTo(el : SVGElement, xml : FastXML) : Void{
		if (el.subElements.length == 0) 			return;
		var node : FastXML = createNode(el, []);
		for (subEl/* AS3HX WARNING could not determine type for var: subEl exp: EField(EIdent(el),subElements) type: null */ in el.subElements){
			addNodeTo(subEl, node);
		}
		setTransform(el, node);
		xml.node.appendChild.innerData(node);
	}
	
	private function addImageNodeTo(el : SVGElement, xml : FastXML) : Void{
		if (el.bitmap == null) 			return;
		var attrList : Array<Dynamic> = ["x", "y", "width", "height", "opacity", "scratch-type"];
		var node : FastXML = createNode(el, attrList);
		var pixels : ByteArray = PNG24Encoder.encode(el.bitmap, PNGFilter.PAETH);
		node.setAttribute("xlink:href", "data:image/png;base64," + Base64Encoder.encode(pixels)) = "data:image/png;base64," + Base64Encoder.encode(pixels);
		setTransform(el, node);
		xml.node.appendChild.innerData(node);
	}
	
	private function addPathNodeTo(el : SVGElement, xml : FastXML) : Void{
		if (el.path == null) 			return;
		var attrList : Array<Dynamic> = ["fill", "stroke", "stroke-width", "stroke-linecap", "stroke-linejoin", "opacity", "scratch-type"];
		var node : FastXML = createNode(el, attrList);
		node.node.setName.innerData("path");
		node.setAttribute("d", pathCmds(el.path));
		setTransform(el, node);
		xml.node.appendChild.innerData(node);
	}
	
	public static function pathCmds(cmdList : Array<Dynamic>) : String{
		// Convert an array of path commands into a 'd' attribute string.
		var result : String = "";
		for (cmd in cmdList){
			var args : Array<Dynamic> = cmd.substring(1);
			var argsString : String = "";
			for (i in 0...args.length){
				var n : Float = args[i];
				argsString += " " + (n == (as3hx.Compat.parseInt(n)) ? n : Std.parseFloat(n).toFixed(3));
			}
			result += cmd[0] + argsString + " ";
		}
		return result;
	}
	
	private function addTextNodeTo(el : SVGElement, xml : FastXML) : Void{
		if (!el.text) 			return;
		var s : String = el.text.replace(new EReg('\\s+$', "g"), "");  // remove trailing whitespace  
		if (s.length == 0) 			return  // don't save empty text element  ;
		var stroke : Dynamic = el.getAttribute("stroke", null);
		if (stroke != null) 			el.setAttribute("fill", stroke);
		var attrList : Array<Dynamic> = [
		"fill", "stroke", "opacity", "x", "y", "dx", "dy", "text-anchor", 
		"font-family", "font-size", "font-style", "font-weight"];
		var node : FastXML = createNode(el, attrList);
		node.nodes.text()[0] = s;
		setTransform(el, node);
		xml.node.appendChild.innerData(node);
	}
	
	private function createNode(el : SVGElement, attrList : Array<Dynamic> = null) : FastXML{
		// Return a new XML node for the given element. Set the node type
		// from the element tag and copy the given attributes from the
		// element attributes into the new node, skipping any that are
		// not defined and converting any numeric color attributes into
		// SVG hex strings of the form #HHHHHH. Attributes who values are
		// SVGElement (e.g. gradients) are skipped here and handled elsewhere.
		var colorAttributes : Array<Dynamic> = ["fill", "stroke"];
		var node : FastXML = new FastXML("<placeholder> </placeholder>");
		node.node.setName.innerData(el.tag);
		node.setAttribute("id", el.id);
		for (k in attrList){
			// Save attributes that are defined but not SVGElements (e.g. gradients).
			var val : Dynamic = el.getAttribute(k);
			if (Std.is(val, Float) && (Lambda.indexOf(colorAttributes, k) > -1)) 				val = SVGElement.colorToHex(val);
			if (Std.is(val, SVGElement)) {
				if ("fill" == k || "stroke" == k) 					val = defineGradient(val)
				else val = null;
			}
			if (val != null) 				node.setAttribute("k", val);
		}
		return node;
	}
	
	// Transforms
	
	private function setTransform(el : SVGElement, node : FastXML) : Void{
		// If this element has a non-null transform, set the transform
		// attribute of the given node.
		// Note: This currently outputs a general matrix transform. To make the
		// exported SVG file more human-readable, this could output a simpler
		// transform (e.g. 'rotate(...)' when possible.
		if (!el.transform) 			return;
		var m : Matrix = el.transform;
		if ((m.a == 1) && (m.b == 0) && (m.c == 0) && (m.d == 1) && (m.tx == 0) && (m.ty == 0)) 			return  // identity  ;
		node.setAttribute("transform", "matrix(" + m.a + ", " + m.b + ", " + m.c + ", " + m.d + ", " + m.tx + ", " + m.ty + ")") = "matrix(" + m.a + ", " + m.b + ", " + m.c + ", " + m.d + ", " + m.tx + ", " + m.ty + ")";
	}
	
	// Gradients
	
	private function defineGradient(gradEl : SVGElement) : String{
		// Create a definition for the given gradient element and
		// return an internal URL reference to it. Return null if
		// the element is not a gradient.
		var node : FastXML;
		if (gradEl.tag == "linearGradient") {
			node = createNode(gradEl, ["x1", "y1", "x2", "y2", "gradientUnits"]);
		}
		else if (gradEl.tag == "radialGradient") {
			node = createNode(gradEl, ["cx", "cy", "r", "fx", "fy", "gradientUnits"]);
		}
		else {
			return null;
		}
		node.setAttribute("id", "grad_" + nextID++) = "grad_" + nextID++;
		
		for (subEl/* AS3HX WARNING could not determine type for var: subEl exp: EField(EIdent(gradEl),subElements) type: null */ in gradEl.subElements){
			var stopNode : FastXML = new FastXML("<stop> </stop>");
			stopNode.setAttribute("offset", subEl.getAttribute("offset", 0));
			stopNode.setAttribute("stop-color", subEl.getAttribute("stop-color", 0));
			var opacity : Dynamic = subEl.getAttribute("stop-opacity");
			if (as3hx.Compat.typeof(opacity) != "undefined" && opacity != null) 				stopNode.setAttribute("stop-opacity", opacity);
			node.node.appendChild.innerData(stopNode);
		}
		addDefinition(node);
		return "url(#" + node.att.id + ")";
	}
	
	private function addDefinition(node : FastXML) : Void{
		// Add the given node to the defs node, creating the defs node if necessary.
		if (defsNode == null) 			defsNode = new FastXML("<defs> </defs>");
		defsNode.node.appendChild.innerData(node);
	}
}

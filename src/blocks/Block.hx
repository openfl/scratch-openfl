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

// Block.as
// John Maloney, August 2009
//
// A Block is a graphical object representing a program statement (command)
// or function (reporter). A stack is a sequence of command blocks, where
// the following command and any nested commands (e.g. within a loop) are
// children. Blocks come in a variety of shapes and usually have some
// combination of label strings and arguments (also children).
//
// The Block class manages block shape, labels, arguments, layout, and
// block sequence. It also supports generation of the labels and argument
// sequence from a specification string (e.g. "%n + %n") and type (e.g. reporter).

package blocks;

//import blocks.BlockArg;
//import blocks.BlockShape;
//import blocks.DisplayObject;
//import blocks.DisplayObjectContainer;
//import blocks.FocusEvent;
//import blocks.MouseEvent;
//import blocks.Point;
//import blocks.Scratch;
//import blocks.ScratchComment;
//import blocks.ScriptsPane;
//import blocks.Sprite;
//import blocks.TextField;
//import blocks.TextFormat;
//import blocks.TextLineMetrics;

import extensions.ExtensionManager;

import flash.display.*;
import flash.events.*;
import flash.filters.GlowFilter;
import flash.geom.*;
import flash.net.URLLoader;
import flash.text.*;
import assets.Resources;
import translation.Translator;
import util.*;
import uiwidgets.*;
import scratch.*;

class Block extends Sprite {
	public var broadcastMsg(get, set) : String;

	
	private inline var minCommandWidth : Int = 36;
	private inline var minHatWidth : Int = 80;
	private inline var minLoopWidth : Int = 80;
	
	public static var argTextFormat : TextFormat;
	public static var blockLabelFormat : TextFormat;
	private static var vOffset : Int;
	
	//	private static const blockLabelFormat:TextFormat = new TextFormat('LucidaBoldEmbedded', 10, 0xFFFFFF, true);
	private static var useEmbeddedFont : Bool = false;
	
	public static var MenuHandlerFunction : Function;  // optional function to handle block and blockArg menus  
	
	public var spec : String;
	public var type : String;
	public var op : String = "";
	public var opFunction : Function;
	public var args : Array<Dynamic> = [];
	public var defaultArgValues : Array<Dynamic> = [];
	public var parameterIndex : Int = -1;  // cache of parameter index, used by GET_PARAM block  
	public var parameterNames : Array<Dynamic>;  // used by procedure definition hats; null for other blocks  
	public var warpProcFlag : Bool;  // used by procedure definition hats to indicate warp speed  
	public var rightToLeft : Bool;
	
	public var isHat : Bool = false;
	public var isReporter : Bool = false;
	public var isTerminal : Bool = false;  // blocks that end a stack like "stop" or "forever"  
	
	// Blocking operations
	public var isRequester : Bool = false;
	public var forcedRequester : Bool = false;  // We've forced requester-like treatment on a non-requester block.  
	public var requestState : Int = 0;  // 0 - no request made, 1 - awaiting response, 2 - data ready  
	public var response : Dynamic = null;
	public var requestLoader : URLLoader = null;
	
	public var nextBlock : Block;
	public var subStack1 : Block;
	public var subStack2 : Block;
	
	public var base : BlockShape;
	
	private var suppressLayout : Bool;  // used to avoid extra layouts during block initialization  
	private var labelsAndArgs : Array<Dynamic> = [];
	private var argTypes : Array<Dynamic> = [];
	private var elseLabel : TextField;
	
	private var indentTop : Int = 2;private var indentBottom : Int = 3;
	private var indentLeft : Int = 4;private var indentRight : Int = 3;
	
	private static var ROLE_NONE : Int = 0;
	private static var ROLE_ABSOLUTE : Int = 1;
	private static var ROLE_EMBEDDED : Int = 2;
	private static var ROLE_NEXT : Int = 3;
	private static var ROLE_SUBSTACK1 : Int = 4;
	private static var ROLE_SUBSTACK2 : Int = 5;
	
	private var originalParent : DisplayObjectContainer;private var originalRole : Int;private var originalIndex : Int;private var originalPosition : Point;
	
	public function new(spec : String, type : String = " ", color : Int = 0xD00000, op : Dynamic = 0, defaultArgs : Array<Dynamic> = null)
	{
		super();
		this.spec = Translator.map(spec);
		this.type = type;
		this.op = op;
		
		if ((Specs.CALL == op) ||
			(Specs.GET_LIST == op) ||
			(Specs.GET_PARAM == op) ||
			(Specs.GET_VAR == op) ||
			(Specs.PROCEDURE_DEF == op) ||
			("proc_declaration" == op)) {
			this.spec = spec;
		}
		
		if (color == -1) 			return  // copy for clone; omit graphics  ;
		
		var shape : Int;
		if ((type == " ") || (type == "") || (type == "w")) {
			base = new BlockShape(BlockShape.CmdShape, color);
			indentTop = 3;
		}
		else if (type == "b") {
			base = new BlockShape(BlockShape.BooleanShape, color);
			isReporter = true;
			indentLeft = 9;
			indentRight = 7;
		}
		else if (type == "r" || type == "R" || type == "rR") {
			this.type = "r";
			base = new BlockShape(BlockShape.NumberShape, color);
			isReporter = true;
			isRequester = ((type == "R") || (type == "rR"));
			forcedRequester = (type == "rR");
			indentTop = 2;
			indentBottom = 2;
			indentLeft = 6;
			indentRight = 4;
		}
		else if (type == "h") {
			base = new BlockShape(BlockShape.HatShape, color);
			isHat = true;
			indentTop = 12;
		}
		else if (type == "c") {
			base = new BlockShape(BlockShape.LoopShape, color);
		}
		else if (type == "cf") {
			base = new BlockShape(BlockShape.FinalLoopShape, color);
			isTerminal = true;
		}
		else if (type == "e") {
			base = new BlockShape(BlockShape.IfElseShape, color);
			addChild(elseLabel = makeLabel(Translator.map("else")));
		}
		else if (type == "f") {
			base = new BlockShape(BlockShape.FinalCmdShape, color);
			isTerminal = true;
			indentTop = 5;
		}
		else if (type == "o") {  // cmd outline for proc definition  
			base = new BlockShape(BlockShape.CmdOutlineShape, color);
			base.filters = [];  // no bezel  
			indentTop = 3;
		}
		else if (type == "p") {
			base = new BlockShape(BlockShape.ProcHatShape, color);
			isHat = true;
		}
		else {
			base = new BlockShape(BlockShape.RectShape, color);
		}
		addChildAt(base, 0);
		setSpec(this.spec, defaultArgs);
		
		addEventListener(FocusEvent.KEY_FOCUS_CHANGE, focusChange);
	}
	
	public function setSpec(newSpec : String, defaultArgs : Array<Dynamic> = null) : Void{
		for (o in labelsAndArgs){
			if (o.parent != null) 				o.parent.removeChild(o);
		}
		spec = newSpec;
		if (op == Specs.PROCEDURE_DEF) {
			// procedure hat: make an icon from my spec and use that as the label
			indentTop = 20;
			indentBottom = 5;
			indentLeft = 5;
			indentRight = 5;
			
			labelsAndArgs = [];
			argTypes = [];
			var label : TextField = makeLabel(Translator.map("define"));
			labelsAndArgs.push(label);
			var b : Block;
			labelsAndArgs.push(b = declarationBlock());
		}
		else if (op == Specs.GET_VAR || op == Specs.GET_LIST) {
			labelsAndArgs = [makeLabel(spec)];
		}
		else {
			var loopBlocks : Array<Dynamic> = ["doForever", "doForeverIf", "doRepeat", "doUntil"];
			base.hasLoopArrow = (Lambda.indexOf(loopBlocks, op) >= 0);
			addLabelsAndArgs(spec, base.color);
		}
		rightToLeft = Translator.rightToLeft;
		if (rightToLeft) {
			if (["+", "-", "*", "/", "%"].indexOf(op) > -1) 				rightToLeft = Translator.rightToLeftMath;
			if ([">", "<"].indexOf(op) > -1) 				rightToLeft = false;  // never change order of comparison ops  ;
		}
		if (rightToLeft) {
			// reverse specs that don't start with arg specifier or an ASCII character
			labelsAndArgs.reverse();
			argTypes.reverse();
			if (defaultArgs != null) 				defaultArgs.reverse();
		}
		for (item in labelsAndArgs)addChild(item);
		if (defaultArgs != null) 			setDefaultArgs(defaultArgs);
		fixArgLayout();
	}
	
	private function get_BroadcastMsg() : String{
		for (arg in args){
			if (arg.menuName == "broadcast") {
				return arg.argValue;
			}
		}
		
		return null;
	}
	
	private function set_BroadcastMsg(listName : String) : String{
		for (arg in args){
			if (arg.menuName == "broadcast") {
				arg.setArgValue(listName);
			}
		}
		return listName;
	}
	
	public function normalizedArgs() : Array<Dynamic>{
		return (rightToLeft) ? args.concat().reverse() : args;
	}
	
	public function changeOperator(newOp : String) : Void{
		// Used to switch among a family of related operators (e.g. +, -, *, and /).
		// Note: This does not deal with translation, so it only works for symbolic operators.
		for (item in labelsAndArgs){
			if ((Std.is(item, TextField)) && (item.text == op)) 				item.text = newOp;
		}
		op = newOp;
		opFunction = null;
		fixArgLayout();
	}
	
	public static function setFonts(labelSize : Int, argSize : Int, boldFlag : Bool, vOffset : Int) : Void{
		var font : String = Resources.chooseFont([
				"Lucida Grande", "Verdana", "Arial", "DejaVu Sans"]);
		blockLabelFormat = new TextFormat(font, labelSize, 0xFFFFFF, boldFlag);
		argTextFormat = new TextFormat(font, argSize, 0x505050, false);
		Block.vOffset = vOffset;
	}
	
	private function declarationBlock() : Block{
		// Create a block representing a procedure declaration to be embedded in a
		// procedure definition header block. For each formal parameter, embed a
		// reporter for that parameter.
		var b : Block = new Block(spec, "o", Specs.procedureColor, "proc_declaration");
		if (parameterNames == null) 			parameterNames = [];
		for (i in 0...parameterNames.length){
			var argType : String = ((as3hx.Compat.typeof((defaultArgValues[i])) == "boolean")) ? "b" : "r";
			var pBlock : Block = new Block(parameterNames[i], argType, Specs.parameterColor, Specs.GET_PARAM);
			pBlock.parameterIndex = i;
			b.setArg(i, pBlock);
		}
		b.fixArgLayout();
		return b;
	}
	
	public function isProcDef() : Bool{return op == Specs.PROCEDURE_DEF;
	}
	
	public function isEmbeddedInProcHat() : Bool{
		return (Std.is(parent, Block)) &&
		(cast((parent), Block).op == Specs.PROCEDURE_DEF) &&
		(this != cast((parent), Block).nextBlock);
	}
	
	public function isEmbeddedParameter() : Bool{
		if ((op != Specs.GET_PARAM) || !(Std.is(parent, Block))) 			return false;
		return cast((parent), Block).op == "proc_declaration";
	}
	
	public function isInPalette() : Bool{
		var o : DisplayObject = parent;
		while (o){
			if (Lambda.has(o, "isBlockPalette")) 				return true;
			o = o.parent;
		}
		return false;
	}
	
	public function setTerminal(flag : Bool) : Void{
		// Used to change the "stop" block shape.
		removeChild(base);
		isTerminal = flag;
		var newShape : Int = (isTerminal) ? BlockShape.FinalCmdShape : BlockShape.CmdShape;
		base = new BlockShape(newShape, base.color);
		addChildAt(base, 0);
		fixArgLayout();
	}
	
	private function addLabelsAndArgs(spec : String, c : Int) : Void{
		var specParts : Array<Dynamic> = ReadStream.tokenize(spec);
		var i : Int;
		labelsAndArgs = [];
		argTypes = [];
		for (i in 0...specParts.length){
			var o : DisplayObject = argOrLabelFor(specParts[i], c);
			labelsAndArgs.push(o);
			var argType : String = "icon";
			if (Std.is(o, BlockArg)) 				argType = specParts[i];
			if (Std.is(o, TextField)) 				argType = "label";
			argTypes.push(argType);
		}
	}
	
	public function argType(arg : DisplayObject) : String{
		var i : Int = Lambda.indexOf(labelsAndArgs, arg);
		return i == -(1) ? "" : argTypes[i];
	}
	
	public function allBlocksDo(f : Function) : Void{
		f(this);
		for (arg in args){
			if (Std.is(arg, Block)) 				arg.allBlocksDo(f);
		}
		if (subStack1 != null) 			subStack1.allBlocksDo(f);
		if (subStack2 != null) 			subStack2.allBlocksDo(f);
		if (nextBlock != null) 			nextBlock.allBlocksDo(f);
	}
	
	public function showRunFeedback() : Void{
		if (filters && filters.length > 0) {
			for (f/* AS3HX WARNING could not determine type for var: f exp: EIdent(filters) type: null */ in filters){
				if (Std.is(f, GlowFilter)) 					return;
			}
		}
		filters = runFeedbackFilters().concat(filters || []);
	}
	
	public function hideRunFeedback() : Void{
		if (filters && filters.length > 0) {
			var newFilters : Array<Dynamic> = [];
			for (f/* AS3HX WARNING could not determine type for var: f exp: EIdent(filters) type: null */ in filters){
				if (!(Std.is(f, GlowFilter))) 					newFilters.push(f);
			}
			filters = newFilters;
		}
	}
	
	private function runFeedbackFilters() : Array<Dynamic>{
		// filters for showing that a stack is running
		var f : GlowFilter = new GlowFilter(0xfeffa0);
		f.strength = 2;
		f.blurX = f.blurY = 12;
		f.quality = 3;
		return [f];
	}
	
	public function saveOriginalState() : Void{
		originalParent = parent;
		if (parent) {
			var b : Block = try cast(parent, Block) catch(e:Dynamic) null;
			if (b == null) {
				originalRole = ROLE_ABSOLUTE;
			}
			else if (isReporter) {
				originalRole = ROLE_EMBEDDED;
				originalIndex = b.args.indexOf(this);
			}
			else if (b.nextBlock == this) {
				originalRole = ROLE_NEXT;
			}
			else if (b.subStack1 == this) {
				originalRole = ROLE_SUBSTACK1;
			}
			else if (b.subStack2 == this) {
				originalRole = ROLE_SUBSTACK2;
			}
			originalPosition = localToGlobal(new Point(0, 0));
		}
		else {
			originalRole = ROLE_NONE;
			originalPosition = null;
		}
	}
	
	public function restoreOriginalState() : Void{
		var b : Block = try cast(originalParent, Block) catch(e:Dynamic) null;
		scaleX = scaleY = 1;
		switch (originalRole) {
			case ROLE_NONE:
				if (parent) 					parent.removeChild(this);
			case ROLE_ABSOLUTE:
				originalParent.addChild(this);
				var p : Point = originalParent.globalToLocal(originalPosition);
				x = p.x;
				y = p.y;
			case ROLE_EMBEDDED:
				b.replaceArgWithBlock(b.args[originalIndex], this, Scratch.app.scriptsPane);
			case ROLE_NEXT:
				b.insertBlock(this);
			case ROLE_SUBSTACK1:
				b.insertBlockSub1(this);
			case ROLE_SUBSTACK2:
				b.insertBlockSub2(this);
		}
	}
	
	public function originalPositionIn(p : DisplayObject) : Point{
		return originalPosition && p.globalToLocal(originalPosition);
	}
	
	private function setDefaultArgs(defaults : Array<Dynamic>) : Void{
		collectArgs();
		for (i in 0...Math.min(args.length, defaults.length)){
			var argLabel : String = null;
			var v : Dynamic = defaults[i];
			if (Std.is(v, BlockArg)) 				v = cast((v), BlockArg).argValue;
			if ("_edge_" == v) 				argLabel = Translator.map("edge");
			if ("_mouse_" == v) 				argLabel = Translator.map("mouse-pointer");
			if ("_myself_" == v) 				argLabel = Translator.map("myself");
			if ("_stage_" == v) 				argLabel = Translator.map("Stage");
			if (Std.is(args[i], BlockArg)) 				args[i].setArgValue(v, argLabel);
		}
		defaultArgValues = defaults;
	}
	
	public function setArg(i : Int, newArg : Dynamic) : Void{
		// called on newly-created block (assumes argument being set is a BlockArg)
		// newArg can be either a reporter block or a literal value (string, number, etc.)
		collectArgs();
		if (i >= args.length) 			return;
		var oldArg : BlockArg = args[i];
		if (Std.is(newArg, Block)) {
			labelsAndArgs[Lambda.indexOf(labelsAndArgs, oldArg)] = newArg;
			args[i] = newArg;
			removeChild(oldArg);
			addChild(newArg);
		}
		else {
			oldArg.setArgValue(newArg);
		}
	}
	
	public function fixExpressionLayout() : Void{
		// fix expression layout up to the enclosing command block
		var b : Block = this;
		while (b.isReporter){
			b.fixArgLayout();
			if (Std.is(b.parent, Block)) 				b = cast((b.parent), Block)
			else return;
		}
		if (Std.is(b, Block)) 			b.fixArgLayout();
	}
	
	public function fixArgLayout() : Void{
		var item : DisplayObject;
		var i : Int;
		if (suppressLayout) 			return;
		var x : Int = indentLeft - indentAjustmentFor(labelsAndArgs[0]);
		var maxH : Int = 0;
		for (i in 0...labelsAndArgs.length){
			item = labelsAndArgs[i];
			// Next line moves the argument of if and if-else blocks right slightly:
			if ((i == 1) && !(argTypes[i] == "label")) 				x = Math.max(x, 30);
			item.x = x;
			maxH = Math.max(maxH, item.height);
			x += item.width + 2;
			if (argTypes[i] == "icon") 				x += 3;
		}
		x -= indentAjustmentFor(labelsAndArgs[labelsAndArgs.length - 1]);
		
		for (i in 0...labelsAndArgs.length){
			item = labelsAndArgs[i];
			item.y = indentTop + ((maxH - item.height) / 2) + vOffset;
			if ((Std.is(item, BlockArg)) && (!cast((item), BlockArg).numberType)) 				item.y += 1;
		}
		
		if ([" ", "", "o"].indexOf(type) >= 0) 			x = Math.max(x, minCommandWidth);  // minimum width for command blocks  ;
		if (["c", "cf", "e"].indexOf(type) >= 0) 			x = Math.max(x, minLoopWidth);  // minimum width for C and E blocks  ;
		if (["h"].indexOf(type) >= 0) 			x = Math.max(x, minHatWidth);  // minimum width for hat blocks  ;
		if (elseLabel != null) 			x = Math.max(x, indentLeft + elseLabel.width + 2);
		
		base.setWidthAndTopHeight(x + indentRight, indentTop + maxH + indentBottom);
		if ((type == "c") || (type == "e")) 			fixStackLayout();
		base.redraw();
		fixElseLabel();
		collectArgs();
	}
	
	private function indentAjustmentFor(item : Dynamic) : Int{
		var itemType : String = "";
		if (Std.is(item, Block)) 			itemType = cast((item), Block).type;
		if (Std.is(item, BlockArg)) 			itemType = cast((item), BlockArg).type;
		if ((type == "b") && (itemType == "b")) 			return 4;
		if ((type == "r") && ((itemType == "r") || (itemType == "d") || (itemType == "n"))) 			return 2;
		return 0;
	}
	
	public function fixStackLayout() : Void{
		var b : Block = this;
		while (b != null){
			if (b.base.canHaveSubstack1()) {
				var substackH : Int = BlockShape.EmptySubstackH;
				if (b.subStack1) {
					b.subStack1.fixStackLayout();
					b.subStack1.x = BlockShape.SubstackInset;
					b.subStack1.y = b.base.substack1y();
					substackH = b.subStack1.getRect(b).height;
					if (b.subStack1.bottomBlock().isTerminal) 						substackH += BlockShape.NotchDepth;
				}
				b.base.setSubstack1Height(substackH);
				substackH = BlockShape.EmptySubstackH;
				if (b.subStack2) {
					b.subStack2.fixStackLayout();
					b.subStack2.x = BlockShape.SubstackInset;
					b.subStack2.y = b.base.substack2y();
					substackH = b.subStack2.getRect(b).height;
					if (b.subStack2.bottomBlock().isTerminal) 						substackH += BlockShape.NotchDepth;
				}
				b.base.setSubstack2Height(substackH);
				b.base.redraw();
				b.fixElseLabel();
			}
			if (b.nextBlock != null) {
				b.nextBlock.x = 0;
				b.nextBlock.y = b.base.nextBlockY();
			}
			b = b.nextBlock;
		}
	}
	
	private function fixElseLabel() : Void{
		if (elseLabel != null) {
			var metrics : TextLineMetrics = elseLabel.getLineMetrics(0);
			var dy : Int = (metrics.ascent + metrics.descent) / 2;
			elseLabel.x = 4;
			elseLabel.y = base.substack2y() - 11 - dy + vOffset;
		}
	}
	
	public function previewSubstack1Height(h : Int) : Void{
		base.setSubstack1Height(h);
		base.redraw();
		fixElseLabel();
		if (nextBlock != null) 			nextBlock.y = base.nextBlockY();
	}
	
	public function duplicate(forClone : Bool, forStage : Bool = false) : Block{
		var newSpec : String = spec;
		if (op == "whenClicked") 			newSpec = (forStage) ? "when Stage clicked" : "when this sprite clicked";
		var dup : Block = new Block(newSpec, type, (Int)((forClone) ? -1 : base.color), op);
		dup.isRequester = isRequester;
		dup.forcedRequester = forcedRequester;
		dup.parameterNames = parameterNames;
		dup.defaultArgValues = defaultArgValues;
		dup.warpProcFlag = warpProcFlag;
		if (forClone) {
			dup.copyArgsForClone(args);
		}
		else {
			dup.copyArgs(args);
			if (op == "stopScripts" && Std.is(args[0], BlockArg)) {
				if (args[0].argValue.indexOf("other scripts") == 0) {
					if (forStage) 						dup.args[0].setArgValue("other scripts in stage")
					else dup.args[0].setArgValue("other scripts in sprite");
				}
			}
		}
		if (nextBlock != null) 			dup.addChild(dup.nextBlock = nextBlock.duplicate(forClone, forStage));
		if (subStack1 != null) 			dup.addChild(dup.subStack1 = subStack1.duplicate(forClone, forStage));
		if (subStack2 != null) 			dup.addChild(dup.subStack2 = subStack2.duplicate(forClone, forStage));
		if (!forClone) {
			dup.x = x;
			dup.y = y;
			dup.fixExpressionLayout();
			dup.fixStackLayout();
		}
		return dup;
	}
	
	private function copyArgs(srcArgs : Array<Dynamic>) : Void{
		// called on a newly created block that is being duplicated to copy the
		// argument values and/or expressions from the source block's arguments
		var i : Int;
		collectArgs();
		for (i in 0...srcArgs.length){
			var argToCopy : Dynamic = srcArgs[i];
			if (Std.is(argToCopy, BlockArg)) {
				var arg : BlockArg = argToCopy;
				cast((args[i]), BlockArg).setArgValue(arg.argValue, arg.labelOrNull());
			}
			if (Std.is(argToCopy, Block)) {
				var newArg : Block = cast((argToCopy), Block).duplicate(false);
				var oldArg : Dynamic = args[i];
				labelsAndArgs[Lambda.indexOf(labelsAndArgs, oldArg)] = newArg;
				args[i] = newArg;
				removeChild(oldArg);
				addChild(newArg);
			}
		}
	}
	
	private function copyArgsForClone(srcArgs : Array<Dynamic>) : Void{
		// called on a block that is being cloned.
		args = [];
		for (i in 0...srcArgs.length){
			var argToCopy : Dynamic = srcArgs[i];
			if (Std.is(argToCopy, BlockArg)) {
				var a : BlockArg = new BlockArg(argToCopy.type, -1);
				a.argValue = argToCopy.argValue;
				args.push(a);
			}
			if (Std.is(argToCopy, Block)) {
				args.push(cast((argToCopy), Block).duplicate(true));
			}
		}
		for (arg in args)addChild(arg);
	}
	
	private function collectArgs() : Void{
		var i : Int;
		args = [];
		for (i in 0...labelsAndArgs.length){
			var a : Dynamic = labelsAndArgs[i];
			if ((Std.is(a, Block)) || (Std.is(a, BlockArg))) 				args.push(a);
		}
	}
	
	public function removeBlock(b : Block) : Void{
		if (b.parent == this) 			removeChild(b);
		if (b == nextBlock) {
			nextBlock = null;
		}
		if (b == subStack1) 			subStack1 = null;
		if (b == subStack2) 			subStack2 = null;
		if (b.isReporter) {
			var i : Int = Lambda.indexOf(labelsAndArgs, b);
			if (i < 0) 				return;
			var newArg : DisplayObject = argOrLabelFor(argTypes[i], base.color);
			labelsAndArgs[i] = newArg;
			addChild(newArg);
			fixExpressionLayout();
			
			// Cancel any outstanding requests (for blocking reporters, isRequester=true)
			if (b.requestLoader) 
				b.requestLoader.close();
		}
		topBlock().fixStackLayout();
		/* AS3HX WARNING namespace modifier SCRATCH::allow3d */{Scratch.app.runtime.checkForGraphicEffects();
		}
	}
	
	public function insertBlock(b : Block) : Void{
		var oldNext : Block = nextBlock;
		
		if (oldNext != null) 			removeChild(oldNext);
		
		addChild(b);
		nextBlock = b;
		if (oldNext != null) 			b.appendBlock(oldNext);
		
		topBlock().fixStackLayout();
	}
	
	public function insertBlockAbove(b : Block) : Void{
		b.x = this.x;
		b.y = this.y - b.height + BlockShape.NotchDepth;
		parent.addChild(b);
		b.bottomBlock().insertBlock(this);
	}
	
	public function insertBlockAround(b : Block) : Void{
		b.x = this.x - BlockShape.SubstackInset;
		b.y = this.y - b.base.substack1y();  //  + BlockShape.NotchDepth;  
		parent.addChild(b);
		parent.removeChild(this);
		b.addChild(this);
		b.subStack1 = this;
		b.fixStackLayout();
	}
	
	public function insertBlockSub1(b : Block) : Void{
		var old : Block = subStack1;
		if (old != null) 			old.parent.removeChild(old);
		
		addChild(b);
		subStack1 = b;
		if (old != null) 			b.appendBlock(old);
		topBlock().fixStackLayout();
	}
	
	public function insertBlockSub2(b : Block) : Void{
		var old : Block = subStack2;
		if (old != null) 			removeChild(old);
		
		addChild(b);
		subStack2 = b;
		if (old != null) 			b.appendBlock(old);
		topBlock().fixStackLayout();
	}
	
	public function replaceArgWithBlock(oldArg : DisplayObject, b : Block, pane : DisplayObjectContainer) : Void{
		var i : Int = Lambda.indexOf(labelsAndArgs, oldArg);
		if (i < 0) 			return  // remove the old argument  ;
		
		
		
		removeChild(oldArg);
		labelsAndArgs[i] = b;
		addChild(b);
		fixExpressionLayout();
		
		if (Std.is(oldArg, Block)) {
			// leave old block in pane
			var o : Block = owningBlock();
			var p : Point = pane.globalToLocal(o.localToGlobal(new Point(o.width + 5, (o.height - oldArg.height) / 2)));
			oldArg.x = p.x;
			oldArg.y = p.y;
			pane.addChild(oldArg);
		}
		topBlock().fixStackLayout();
	}
	
	private function appendBlock(b : Block) : Void{
		if (base.canHaveSubstack1() && subStack1 == null) {
			insertBlockSub1(b);
		}
		else {
			var bottom : Block = bottomBlock();
			bottom.addChild(b);
			bottom.nextBlock = b;
		}
	}
	
	private function owningBlock() : Block{
		var b : Block = this;
		while (true){
			if (Std.is(b.parent, Block)) {
				b = cast((b.parent), Block);
				if (!b.isReporter) 					return b;  // owning command block  ;
			}
			else {
				return b;
			}
		}
		return b;
	}
	
	public function topBlock() : Block{
		var result : DisplayObject = this;
		while (Std.is(result.parent, Block))result = result.parent;
		return cast((result), Block);
	}
	
	public function bottomBlock() : Block{
		var result : Block = this;
		while (result.nextBlock != null)result = result.nextBlock;
		return result;
	}
	
	private function argOrLabelFor(s : String, c : Int) : DisplayObject{
		// Possible token formats:
		//	%<single letter>
		//	%m.<menuName>
		//	@<iconName>
		//	label (any string with no embedded white space that does not start with % or @)
		//	a token consisting of a single % or @ character is also a label
		if (s.length >= 2 && s.charAt(0) == "%") {  // argument spec  
			var argSpec : String = s.charAt(1);
			if (argSpec == "b") 				return new BlockArg("b", c);
			if (argSpec == "c") 				return new BlockArg("c", c);
			if (argSpec == "d") 				return new BlockArg("d", c, true, s.substring(3));
			if (argSpec == "m") 				return new BlockArg("m", c, false, s.substring(3));
			if (argSpec == "n") 				return new BlockArg("n", c, true);
			if (argSpec == "s") 				return new BlockArg("s", c, true);
		}
		else if (s.length >= 2 && s.charAt(0) == "@") {  // icon spec  
			var icon : Dynamic = Specs.IconNamed(s.substring(1));
			return ((icon != null)) ? icon : makeLabel(s);
		}
		return makeLabel(ReadStream.unescape(s));
	}
	
	private function makeLabel(label : String) : TextField{
		var text : TextField = new TextField();
		text.autoSize = TextFieldAutoSize.LEFT;
		text.selectable = false;
		text.background = false;
		text.defaultTextFormat = blockLabelFormat;
		text.text = label;
		if (useEmbeddedFont) {
			text.antiAliasType = AntiAliasType.ADVANCED;
			text.embedFonts = true;
		}
		text.mouseEnabled = false;
		return text;
	}
	
	/* Menu */
	
	public function menu(evt : MouseEvent) : Void{
		// Note: Unlike most menu() methods, this method invokes
		// the menu itself rather than returning a menu to the caller.
		if (MenuHandlerFunction == null) 			return;
		if (isEmbeddedInProcHat()) 			MenuHandlerFunction(null, parent)
		else MenuHandlerFunction(null, this);
	}
	
	public function handleTool(tool : String, evt : MouseEvent) : Void{
		if (isEmbeddedParameter()) 			return;
		if (!isInPalette()) {
			if ("copy" == tool) 				duplicateStack(10, 5);
			if ("cut" == tool) 				deleteStack();
		}
		if (tool == "help") 			showHelp();
	}
	
	public function showHelp() : Void{
		var i : Int = -1;
		if ((i = op.indexOf(".")) > -1) {
			var extName : String = op.substr(0, i);
			if (Scratch.app.extensionManager.isInternal(extName)) 
				Scratch.app.showTip("ext:" + extName)
			else 
			DialogBox.notify("Help Missing", "There is no documentation available for experimental extension \"" + extName + "\".", Scratch.app.stage);
		}
		else {
			Scratch.app.showTip(op);
		}
	}
	
	public function duplicateStack(deltaX : Float, deltaY : Float) : Void{
		if (isProcDef() || op == "proc_declaration") 			return  // don't duplicate procedure definition  ;
		var forStage : Bool = Scratch.app.viewedObj() && Scratch.app.viewedObj().isStage;
		var newStack : Block = BlockIO.stringToStack(BlockIO.stackToString(this), forStage);
		var p : Point = localToGlobal(new Point(0, 0));
		newStack.x = p.x + deltaX;
		newStack.y = p.y + deltaY;
		Scratch.app.gh.grabOnMouseUp(newStack);
	}
	
	public function deleteStack() : Bool{
		if (op == "proc_declaration") {
			return (try cast(parent, Block) catch(e:Dynamic) null).deleteStack();
		}
		var app : Scratch = Scratch.app;
		var top : Block = topBlock();
		if (op == Specs.PROCEDURE_DEF && app.runtime.allCallsOf(spec, app.viewedObj(), false).length) {
			DialogBox.notify("Cannot Delete", "To delete a block definition, first remove all uses of the block.", stage);
			return false;
		}
		if (top == this && app.interp.isRunning(top, app.viewedObj())) {
			app.interp.toggleThread(top, app.viewedObj());
		}  // TODO: Remove any waiting reporter data in the Scratch.app.extensionManager  
		
		if (Std.is(parent, Block)) 			cast((parent), Block).removeBlock(this)
		else if (parent) 			parent.removeChild(this);
		this.cacheAsBitmap = false;
		// set position for undelete
		x = top.x;
		y = top.y;
		if (top != this) 			x += top.width + 5;
		app.runtime.recordForUndelete(this, x, y, 0, app.viewedObj());
		app.scriptsPane.saveScripts();
		/* AS3HX WARNING namespace modifier SCRATCH::allow3d */{app.runtime.checkForGraphicEffects();
		}
		app.updatePalette();
		return true;
	}
	
	public function attachedCommentsIn(scriptsPane : ScriptsPane) : Array<Dynamic>{
		var allBlocks : Array<Dynamic> = [];
		allBlocksDo(function(b : Block) : Void{
					allBlocks.push(b);
				});
		var result : Array<Dynamic> = [];
		if (scriptsPane == null) 			return result;
		for (i in 0...scriptsPane.numChildren){
			var c : ScratchComment = try cast(scriptsPane.getChildAt(i), ScratchComment) catch(e:Dynamic) null;
			if (c != null && c.blockRef && Lambda.indexOf(allBlocks, c.blockRef) != -1) {
				result.push(c);
			}
		}
		return result;
	}
	
	public function addComment() : Void{
		var scriptsPane : ScriptsPane = try cast(topBlock().parent, ScriptsPane) catch(e:Dynamic) null;
		if (scriptsPane != null) 			scriptsPane.addComment(this);
	}
	
	/* Dragging */
	
	public function objToGrab(evt : MouseEvent) : Block{
		if (isEmbeddedParameter() || isInPalette()) 			return duplicate(false, Std.is(Scratch.app.viewedObj(), ScratchStage));
		return this;
	}
	
	/* Events */
	
	public function click(evt : MouseEvent) : Void{
		if (editArg(evt)) 			return;
		Scratch.app.runtime.interp.toggleThread(topBlock(), Scratch.app.viewedObj(), 1);
	}
	
	public function doubleClick(evt : MouseEvent) : Void{
		if (editArg(evt)) 			return;
		Scratch.app.runtime.interp.toggleThread(topBlock(), Scratch.app.viewedObj(), 1);
	}
	
	private function editArg(evt : MouseEvent) : Bool{
		var arg : BlockArg = try cast(evt.target, BlockArg) catch(e:Dynamic) null;
		if (arg == null) 			arg = try cast(evt.target.parent, BlockArg) catch(e:Dynamic) null;
		if (arg != null && arg.isEditable && (arg.parent == this)) {
			arg.startEditing();
			return true;
		}
		return false;
	}
	
	private function focusChange(evt : FocusEvent) : Void{
		evt.preventDefault();
		if (evt.target.parent.parent != this) 			return  // make sure the target TextField is in this block, not a child block  ;
		if (args.length == 0) 			return;
		var i : Int;
		var focusIndex : Int = -1;
		for (i in 0...args.length){
			if (Std.is(args[i], BlockArg) && stage.focus == args[i].field) 				focusIndex = i;
		}
		var target : Block = this;
		var delta : Int = (evt.shiftKey) ? -1 : 1;
		i = focusIndex + delta;
				while (true){
			if (i >= target.args.length) {
				var p : Block = try cast(target.parent, Block) catch(e:Dynamic) null;
				if (p != null) {
					i = p.args.indexOf(target);
					if (i != -1) {
						i += delta;
						target = p;
						continue;
					}
				}
				if (target.subStack1) {
					target = target.subStack1;
				}
				else if (target.subStack2) {
					target = target.subStack2;
				}
				else {
					var t : Block = target;
					target = t.nextBlock;
					while (!target){
						var tp : Block = try cast(t.parent, Block) catch(e:Dynamic) null;
						var b : Block = t;
						while (tp && tp.nextBlock == b){
							b = tp;
							tp = try cast(tp.parent, Block) catch(e:Dynamic) null;
						}
						if (tp == null) 							return;
						target = tp.subStack1 == b && (tp.subStack2) ? tp.subStack2 : tp.nextBlock;
						t = tp;
					}
				}
				i = 0;
			}
			else if (i < 0) {
				p = try cast(target.parent, Block) catch(e:Dynamic) null;
				if (p == null) 					return;
				i = p.args.indexOf(target);
				if (i != -1) {
					i += delta;
					target = p;
					continue;
				}
				var nested : Block = p.nextBlock == (target != null) ? p.subStack2 || p.subStack1 : p.subStack2 == (target != null) ? p.subStack1 : null;
				if (nested != null) {
										while (true){
						nested = nested.bottomBlock();
						var n2 : Block = nested.subStack1 || nested.subStack2;
						if (n2 == null) 							break;
						nested = n2;
					}
					target = nested;
				}
				else {
					target = p;
				}
				i = target.args.length - 1;
			}
			else {
				if (Std.is(target.args[i], Block)) {
					target = target.args[i];
					i = (evt.shiftKey) ? target.args.length - 1 : 0;
				}
				else {
					var a : BlockArg = try cast(target.args[i], BlockArg) catch(e:Dynamic) null;
					if (a != null && a.field && a.isEditable) {
						a.startEditing();
						return;
					}
					i += delta;
				}
			}
		}
	}
	
	public function getSummary() : String{
		var s : String = type == ("r") ? "(" : type == ("b") ? "<" : "";
		var space : Bool = false;
		for (x in labelsAndArgs){
			if (space) {
				s += " ";
			}
			space = true;
			var ba : BlockArg;
			var b : Block;
			var tf : TextField;
			if ((ba != null = try cast(x, BlockArg) catch(e:Dynamic) null)) {
				s += (ba.numberType) ? "(" : "[";
				s += ba.argValue;
				if (!ba.isEditable) 					s += " v";
				s += (ba.numberType) ? ")" : "]";
			}
			else if ((b != null = try cast(x, Block) catch(e:Dynamic) null)) {
				s += b.getSummary();
			}
			else if ((tf != null = try cast(x, TextField) catch(e:Dynamic) null)) {
				s += cast((x), TextField).text;
			}
			else {
				s += "@";
			}
		}
		if (base.canHaveSubstack1()) {
			s += "\n" + ((subStack1 != null) ? indent(subStack1.getSummary()) : "");
			if (base.canHaveSubstack2()) {
				s += "\n" + elseLabel.text;
				s += "\n" + ((subStack2 != null) ? indent(subStack2.getSummary()) : "");
			}
			s += "\n" + Translator.map("end");
		}
		if (nextBlock != null) {
			s += "\n" + nextBlock.getSummary();
		}
		s += type == ("r") ? ")" : type == ("b") ? ">" : "";
		return s;
	}
	
	private static function indent(s : String) : String{
		return s.replace(new EReg('^', "gm"), "    ");
	}
}

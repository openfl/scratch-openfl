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

// Interpreter.as
// John Maloney, August 2009
// Revised, March 2010
//
// A simple yet efficient interpreter for blocks.
//
// Interpreters may seem mysterious, but this one is quite straightforward. Since every
// block knows which block (if any) follows it in a sequence of blocks, the interpreter
// simply executes the current block, then asks that block for the next block. The heart
// of the interpreter is the evalCmd() function, which looks up the opcode string in a
// dictionary (initialized by initPrims()) then calls the primitive function for that opcode.
// Control structures are handled by pushing the current state onto the active thread's
// execution stack and continuing with the first block of the substack. When the end of a
// substack is reached, the previous execution state is popped. If the substack was a loop
// body, control yields to the next thread. Otherwise, execution continues with the next
// block. If there is no next block, and no state to pop, the thread terminates.
//
// The interpreter does as much as it can within workTime milliseconds, then returns
// control. It returns control earlier if either (a) there are are no more threads to run
// or (b) some thread does a command that has a visible effect (e.g. "move 10 steps").
//
// To add a command to the interpreter, just add a new case to initPrims(). Command blocks
// usually perform some operation and return null, while reporters must return a value.
// Control structures are a little tricky; look at some of the existing control structure
// commands to get a sense of what to do.
//
// Clocks and time:
//
// The millisecond clock starts at zero when Flash is started and, since the clock is
// a 32-bit integer, it wraps after 24.86 days. Since it seems unlikely that one Scratch
// session would run that long, this code doesn't deal with clock wrapping.
// Since Scratch only runs at discrete intervals, timed commands may be resumed a few
// milliseconds late. These small errors accumulate, causing threads to slip out of
// synchronization with each other, a problem especially noticeable in music projects.
// This problem is addressed by recording the amount of time slippage and shortening
// subsequent timed commands slightly to "catch up".
// Delay times are rounded to milliseconds, and the minimum delay is a millisecond.

package interpreter;


import flash.utils.Dictionary;

import flash.geom.Point;
import blocks.*;
import primitives.*;
import scratch.*;
import sound.*;

class Interpreter
{

	public var activeThread : Thread;  // current thread  
	public var currentMSecs : Int = Math.round(haxe.Timer.stamp() * 1000);  // millisecond clock for the current step  
	public var turboMode : Bool = false;

	private var app : Scratch;
	private var primTable : Map<String,Block->Dynamic>;  // maps opcodes to functions  
	private var threads : Array<Dynamic> = [];  // all threads  
	private var yield : Bool;  // set true to indicate that active thread should yield control  
	private var startTime : Int;  // start time for stepThreads()  
	private var doRedraw : Bool;
	private var isWaiting : Bool;

	private static inline var warpMSecs : Int = 500;  // max time to run during warp  
	private var warpThread : Thread;  // thread that is in warp mode  
	private var warpBlock : Block;  // proc call block that entered warp mode  

	private var bubbleThread : Thread;  // thread for reporter bubble  
	public var askThread : Thread;  // thread that opened the ask prompt  

	private var debugFunc : Dynamic->Void;

	public function new(app : Scratch)
	{
		this.app = app;
		initPrims();
	}

	public function targetObj() : ScratchObj{return cast((activeThread.target), ScratchObj);
	}
	public function targetSprite() : ScratchSprite{return try cast(activeThread.target, ScratchSprite) catch(e:Dynamic) null;
	}

	/* Threads */

	public function doYield() : Void{isWaiting = true;yield = true;
	}
	public function redraw() : Void{if (!turboMode)             doRedraw = true;
	}

	public function yieldOneCycle() : Void{
		// Yield control but proceed to the next block. Do nothing in warp mode.
		// Used to ensure proper ordering of HTTP extension commands.
		if (activeThread == warpThread)             return;
		if (activeThread.firstTime) {
			redraw();
			yield = true;
			activeThread.firstTime = false;
		}
	}

	public function threadCount() : Int{return threads.length;
	}

	public function toggleThread(b : Block, targetObj : Dynamic, startupDelay : Int = 0) : Void{
		var i : Int;
		var newThreads : Array<Dynamic> = [];
		var wasRunning : Bool = false;
		for (i in 0...threads.length){
			if ((threads[i].topBlock == b) && (threads[i].target == targetObj)) {
				wasRunning = true;
			}
			else {
				newThreads.push(threads[i]);
			}
		}
		threads = newThreads;
		if (wasRunning) {
			if (app.editMode)                 b.hideRunFeedback();
			clearWarpBlock();
		}
		else {
			var topBlock : Block = b;
			if (b.isReporter) {
				// click on reporter shows value in bubble
				if (bubbleThread != null) {
					toggleThread(bubbleThread.topBlock, bubbleThread.target);
				}
				var reporter : Block = b;
				var interp : Interpreter = this;
				b = new Block("%s", "", -1);
				b.opFunction = function(b : Block) : Dynamic{
							var p : Point = reporter.localToGlobal(new Point(0, 0));
							app.showBubble(Std.string(interp.arg(b, 0)), p.x, p.y, reporter.getRect(app.stage).width);
							return null;
						};
				b.args[0] = reporter;
			}
			if (app.editMode)                 topBlock.showRunFeedback();
			var t : Thread = new Thread(b, targetObj, startupDelay);
			if (topBlock.isReporter)                 bubbleThread = t;
			t.topBlock = topBlock;
			threads.push(t);
			app.threadStarted();
		}
	}

	public function showAllRunFeedback() : Void{
		for (t in threads){
			t.topBlock.showRunFeedback();
		}
	}

	public function isRunning(b : Block, targetObj : ScratchObj) : Bool{
		for (t in threads){
			if ((t.topBlock == b) && (t.target == targetObj))                 return true;
		}
		return false;
	}

	public function startThreadForClone(b : Block, clone : Dynamic) : Void{
		threads.push(new Thread(b, clone));
	}

	public function stopThreadsFor(target : Dynamic, skipActiveThread : Bool = false) : Void {
		var i = 0;
		while (i < threads.length) {
			var t : Thread = threads[i];
			if (skipActiveThread && (t == activeThread))                 {
				i++;
				i++;
				continue;
			};
			if (t.target == target) {
				//if (Std.is(t.tmpObj, ScratchSoundPlayer)) {
					//(try cast(t.tmpObj, ScratchSoundPlayer) catch(e:Dynamic) null).stopPlaying();
				//}
				t.stop();
			}
			i++;
		}
		if ((activeThread.target == target) && !skipActiveThread)             yield = true;
	}

	public function restartThread(b : Block, targetObj : Dynamic) : Thread{
		// used by broadcast, click hats, and when key pressed hats
		// stop any thread running on b, then start a new thread on b
		var newThread : Thread = new Thread(b, targetObj);
		var wasRunning : Bool = false;
		for (i in 0...threads.length){
			if ((threads[i].topBlock == b) && (threads[i].target == targetObj)) {
				if (askThread == threads[i])                     app.runtime.clearAskPrompts();
				threads[i] = newThread;
				wasRunning = true;
			}
		}
		if (!wasRunning) {
			threads.push(newThread);
			if (app.editMode)                 b.showRunFeedback();
			app.threadStarted();
		}
		return newThread;
	}

	public function stopAllThreads() : Void{
		threads = [];
		if (activeThread != null)             activeThread.stop();
		clearWarpBlock();
		app.runtime.clearRunFeedback();
		doRedraw = true;
	}

	public function stepThreads() : Void{
		startTime = Math.round(haxe.Timer.stamp() * 1000);
		var workTime : Int = Std.int((0.75 * 1000) / app.stage.frameRate);  // work for up to 75% of one frame time  
		doRedraw = false;
		currentMSecs = Math.round(haxe.Timer.stamp() * 1000);
		if (threads.length == 0)             return;
		while ((currentMSecs - startTime) < workTime){
			if (warpThread != null && (warpThread.block == null))                 clearWarpBlock();
			var threadStopped : Bool = false;
			var runnableCount : Int = 0;
			for (activeThread in threads){
				isWaiting = false;
				stepActiveThread();
				if (activeThread.block == null)                     threadStopped = true;
				if (!isWaiting)                     runnableCount++;
			}
			if (threadStopped) {
				var newThreads : Array<Dynamic> = [];
				for (t in threads){
					if (t.block != null)                         newThreads.push(t)
					else if (app.editMode) {
						if (t == bubbleThread)                             bubbleThread = null;
						t.topBlock.hideRunFeedback();
					}
				}
				threads = newThreads;
				if (threads.length == 0)                     return;
			}
			currentMSecs = Math.round(haxe.Timer.stamp() * 1000);
			if (doRedraw || (runnableCount == 0))                 return;
		}
	}

	private function stepActiveThread() : Void{
		if (activeThread.block == null)             return;
		if (activeThread.startDelayCount > 0) {activeThread.startDelayCount--;doRedraw = true;return;
		}
		if (!(activeThread.target.isStage || (Std.is(activeThread.target.parent, ScratchStage)))) {
			// sprite is being dragged
			if (app.editMode) {
				// don't run scripts of a sprite that is being dragged in edit mode, but do update the screen
				doRedraw = true;
				return;
			}
		}
		yield = false;
		while (true){
			if (activeThread == warpThread)                 currentMSecs = Math.round(haxe.Timer.stamp() * 1000);
			evalCmd(activeThread.block);
			if (yield) {
				if (activeThread == warpThread) {
					if ((currentMSecs - startTime) > warpMSecs)                         return;
					yield = false;
					continue;
				}
				else return;
			}

			if (activeThread.block != null) 
				activeThread.block = activeThread.block.nextBlock;

			while (activeThread.block == null){  // end of block sequence  
				if (!activeThread.popState())                     return  // end of script  ;
				if ((activeThread.block == warpBlock) && activeThread.firstTime) {  // end of outer warp block  
					clearWarpBlock();
					activeThread.block = activeThread.block.nextBlock;
					continue;
				}
				if (activeThread.isLoop) {
					if (activeThread == warpThread) {
						if ((currentMSecs - startTime) > warpMSecs)                             return;
					}
					else return;
				}
				else {
					if (activeThread.block.op == Specs.CALL)                         activeThread.firstTime = true;  // in case set false by call  ;
					activeThread.block = activeThread.block.nextBlock;
				}
			}
		}
	}

	private function clearWarpBlock() : Void{
		warpThread = null;
		warpBlock = null;
	}

	/* Evaluation */
	public function evalCmd(b : Block) : Dynamic{
		if (b == null)             return 0;  // arg() and friends can pass null if arg index is out of range  ;
		var op : String = b.op;
		if (b.opFunction == null) {
			//if (op.indexOf(".") > -1)                 
				//b.opFunction = app.extensionManager.primExtensionOp;
			//else 
			b.opFunction = (!primTable.exists(op)) ? primNoop : primTable[op];
		}  // TODO: Optimize this into a cached check if the args *could* block at all  



		if (b.args.length > 0 && checkBlockingArgs(b)) {
			doYield();
			return null;
		}  // Debug code  



		if (debugFunc != null) 
			debugFunc(b);

		return b.opFunction(b);
	}

	// Returns true if the thread needs to yield while data is requested
	public function checkBlockingArgs(b : Block) : Bool{
		// Do any of the arguments request data?  If so, start any requests and yield.
		var shouldYield : Bool = false;
		var args : Array<Dynamic> = b.args;
		for (i in 0...args.length){
			var barg : Block = try cast(args[i], Block) catch(e:Dynamic) null;
			if (barg != null) {
				if (checkBlockingArgs(barg)) 
					shouldYield = true
				// Don't start a request if the arguments for it are blocking
				else if (barg.isRequester && barg.requestState < 2) {
					if (barg.requestState == 0)                         evalCmd(barg);
					shouldYield = true;
				}
			}
		}

		return shouldYield;
	}

	public function arg(b : Block, i : Int) : Dynamic{
		var args : Array<Dynamic> = b.args;
		if (b.rightToLeft) {i = args.length - i - 1;
		}
		return ((Std.is(b.args[i], BlockArg))) ? 
		cast((args[i]), BlockArg).argValue : evalCmd(cast((args[i]), Block));
	}

	public function numarg(b : Block, i : Int) : Float{
		var args : Array<Dynamic> = b.args;
		if (b.rightToLeft) {i = args.length - i - 1;
		}
		var n : Float = ((Std.is(args[i], BlockArg))) ? 
		Std.parseFloat(cast((args[i]), BlockArg).argValue) : Std.parseFloat(evalCmd(cast((args[i]), Block)));

		if (n != n)             return 0;  // return 0 if NaN (uses fast, inline test for NaN)  ;
		return n;
	}

	public function boolarg(b : Block, i : Int) : Bool{
		if (b.rightToLeft) {i = b.args.length - i - 1;
		}
		var o : Dynamic = ((Std.is(b.args[i], BlockArg))) ? cast((b.args[i]), BlockArg).argValue : evalCmd(cast((b.args[i]), Block));
		if (Std.is(o, Bool))             return o;
		if (Std.is(o, String)) {
			var s : String = o;
			if ((s == "") || (s == "0") || (s.toLowerCase() == "false"))                 return false;
			return true;
		}
		return cast(o, Bool);
	}

	public static function asNumber(n : Dynamic) : Float{
		// Convert n to a number if possible. If n is a string, it must contain
		// at least one digit to be treated as a number (otherwise a string
		// containing only whitespace would be consider equal to zero.)
		if (Std.is(n,String)) {
			var s : String = try cast(n, String) catch(e:Dynamic) null;
			var len : Int = s.length;
			for (i in 0...len){
				var code : Int = s.charCodeAt(i);
				if (code >= 48 && code <= 57)                     return Std.parseFloat(s);
			}
			return Math.NaN;
		}
		return Std.parseFloat(n);
	}

	private function startCmdList(b : Block, isLoop : Bool = false, argList : Array<Dynamic> = null) : Void{
		if (b == null) {
			if (isLoop)                 yield = true;
			return;
		}
		activeThread.isLoop = isLoop;
		activeThread.pushStateForBlock(b);
		if (argList != null)             activeThread.args = argList;
		evalCmd(activeThread.block);
	}

	/* Timer */

	public function startTimer(secs : Float) : Void{
		var waitMSecs : Int = Std.int(1000 * secs);
		if (waitMSecs < 0)             waitMSecs = 0;
		activeThread.tmp = currentMSecs + waitMSecs;  // end time in milliseconds  
		activeThread.firstTime = false;
		doYield();
	}

	public function checkTimer() : Bool{
		// check for timer expiration and clean up if expired. return true when expired
		if (currentMSecs >= activeThread.tmp) {
			// time expired
			activeThread.tmp = 0;
			activeThread.tmpObj = null;
			activeThread.firstTime = true;
			return true;
		}
		else {
			// time not yet expired
			doYield();
			return false;
		}
	}

	/* Primitives */

	public function isImplemented(op : String) : Bool{
		return primTable.exists(op);
	}

	public function getPrim(op : String) : Block->Dynamic {return primTable[op];
	}

	private function initPrims() : Void{
		primTable = new Map<String, Block->Dynamic>();
		// control
		primTable[ "whenGreenFlag"] = primNoop;
		primTable[ "whenKeyPressed"] = primNoop;
		primTable[ "whenClicked"] = primNoop;
		primTable[ "whenSceneStarts"] = primNoop;
		primTable[ "wait:elapsed:from:"] = primWait;
		primTable[ "doForever"] = function(b : Dynamic) : Dynamic {
			startCmdList(b.subStack1, true);
			return null;
		};
		primTable[ "doRepeat"] = primRepeat;
		primTable[ "broadcast:"] = function(b : Dynamic) : Dynamic {
			broadcast(arg(b, 0), false);
			return null;
		};
		primTable[ "doBroadcastAndWait"] = function(b : Dynamic) : Dynamic {
			broadcast(arg(b, 0), true);
			return null;
		};
		primTable[ "whenIReceive"] = primNoop;
		primTable[ "doForeverIf"] = function(b : Dynamic) : Dynamic {
			if (arg(b, 0))                 startCmdList(b.subStack1, true);
			else yield = true;
			return null;
		};
		primTable[ "doForLoop"] = primForLoop;
		primTable[ "doIf"] = function(b : Dynamic) : Dynamic {
			if (arg(b, 0))                 startCmdList(b.subStack1);
			return null;
		};
		primTable[ "doIfElse"] = function(b : Dynamic) : Dynamic {
			if (arg(b, 0))                 startCmdList(b.subStack1);
			else startCmdList(b.subStack2);
			return null;
		};
		primTable[ "doWaitUntil"] = function(b : Dynamic) : Dynamic {
			if (!arg(b, 0))                 yield = true;
			return null;
		};
		primTable[ "doWhile"] = function(b : Dynamic) : Dynamic {
			if (arg(b, 0))                 startCmdList(b.subStack1, true);
			return null;
		};
		primTable[ "doUntil"] = function(b : Dynamic) : Dynamic {
			if (!arg(b, 0))                 startCmdList(b.subStack1, true);
			return null;
		};
		primTable[ "doReturn"] = primReturn;
		primTable[ "stopAll"] = function(b : Dynamic) : Dynamic { app.runtime.stopAll(); yield = true;
			return null;
		};
		primTable[ "stopScripts"] = primStop;
		primTable[ "warpSpeed"] = primOldWarpSpeed;

		// procedures
		primTable[Specs.CALL] = primCall;

		// variables
		primTable[Specs.GET_VAR] = primVarGet;
		primTable[Specs.SET_VAR] = primVarSet;
		primTable[Specs.CHANGE_VAR] = primVarChange;
		primTable[Specs.GET_PARAM] = primGetParam;

		// edge-trigger hat blocks
		primTable[ "whenDistanceLessThan"] = primNoop;
		primTable[ "whenSensorConnected"] = primNoop;
		primTable[ "whenSensorGreaterThan"] = primNoop;
		primTable[ "whenTiltIs"] = primNoop;

		addOtherPrims(primTable);
	}

	private function addOtherPrims(primTable : Map<String,Block->Dynamic>) : Void{
		// other primitives
		new Primitives(app, this).addPrimsTo(primTable);
	}

	private function checkPrims() : Void{
		var op : String;
		var allOps : Array<Dynamic> = ["CALL", "GET_VAR", "NOOP"];
		for (spec/* AS3HX WARNING could not determine type for var: spec exp: EField(EIdent(Specs),commands) type: null */ in Specs.commands){
			if (spec.length > 3) {
				op = spec[3];
				allOps.push(op);
				if (!primTable.exists(op))                     trace("Unimplemented: " + op);
			}
		}
		for (op in primTable.keys()){
			if (Lambda.indexOf(allOps, op) < 0)                 trace("Not in specs: " + op);
		}
	}

	public function primNoop(b : Block) : Dynamic { return null;
	}

	private function primForLoop(b : Block) : Dynamic {
		var list : Array<Dynamic> = [];
		var loopVar : Variable;

		if (activeThread.firstTime) {
			if (!(Std.is(arg(b, 0), String)))                 return null;
			var listArg : Dynamic = arg(b, 1);
			if (Std.is(listArg, Array)) {
				list = try cast(listArg, Array<Dynamic/*AS3HX WARNING no type*/>) catch(e:Dynamic) null;
			}
			if (Std.is(listArg, String)) {
				var n : Float = Std.parseFloat(listArg);
				if (!Math.isNaN(n))                     listArg = n;
			}
			if ((Std.is(listArg, Float)) && !Math.isNaN(listArg)) {
				var last : Int = Std.parseInt(listArg);
				if (last >= 1) {
					list = new Array<Dynamic>();
					for (i in 0...last){list.push(i + 1);
					}
				}
			}
			loopVar = activeThread.target.lookupOrCreateVar(arg(b, 0));
			activeThread.args = [list, loopVar];
			activeThread.tmp = 0;
			activeThread.firstTime = false;
		}

		list = activeThread.args[0];
		loopVar = activeThread.args[1];
		if (activeThread.tmp < list.length) {
			loopVar.value = list[activeThread.tmp++];
			startCmdList(b.subStack1, true);
		}
		else {
			activeThread.args = null;
			activeThread.tmp = 0;
			activeThread.firstTime = true;
		}
		return null;
	}

	private function primOldWarpSpeed(b : Block) : Dynamic{
		// Semi-support for old warp block: run substack at normal speed.
		if (b.subStack1 == null)             return null;
		startCmdList(b.subStack1);
		return null;
	}

	private function primRepeat(b : Block) : Dynamic{
		if (activeThread.firstTime) {
			var repeatCount : Float = Math.max(0, Math.min(Math.round(numarg(b, 0)), 2147483647));  // clip to range: 0 to 2^31-1  
			activeThread.tmp = Std.int(repeatCount);
			activeThread.firstTime = false;
		}
		if (activeThread.tmp > 0) {
			activeThread.tmp--;  // decrement count  
			startCmdList(b.subStack1, true);
		}
		else {
			activeThread.firstTime = true;
		}
		return null;
	}

	private function primStop(b : Block) : Dynamic {
		var type : String = arg(b, 0);
		if (type == "all") {app.runtime.stopAll();yield = true;
		}
		if (type == "this script")             primReturn(b);
		if (type == "other scripts in sprite")             stopThreadsFor(activeThread.target, true);
		if (type == "other scripts in stage")             stopThreadsFor(activeThread.target, true);
		return null;
	}

	private function primWait(b : Block) : Dynamic{
		if (activeThread.firstTime) {
			startTimer(numarg(b, 0));
			redraw();
		}
		else checkTimer();
		return null;
	}

	// Broadcast and scene starting

	public function broadcast(msg : String, waitFlag : Bool) : Void{
		var pair : Array<Dynamic>;
		if (activeThread.firstTime) {
			var receivers : Array<Dynamic> = [];
			var newThreads : Array<Dynamic> = [];
			msg = msg.toLowerCase();
			var findReceivers : Block->ScratchObj->Void = function(stack : Block, target : ScratchObj) : Void{
				if ((stack.op == "whenIReceive") && (stack.args[0].argValue.toLowerCase() == msg)) {
					receivers.push([stack, target]);
				}
			};
			app.runtime.allStacksAndOwnersDo(findReceivers);
			// (re)start all receivers
			for (pair in receivers)newThreads.push(restartThread(pair[0], pair[1]));
			if (!waitFlag)                 return;
			activeThread.tmpObj = newThreads;
			activeThread.firstTime = false;
		}
		var done : Bool = true;
		for (t  in cast(activeThread.tmpObj, Array<Dynamic>)){if (Lambda.indexOf(threads, t) >= 0)                 done = false;
		}
		if (done) {
			activeThread.tmpObj = null;
			activeThread.firstTime = true;
		}
		else {
			yield = true;
		}
	}

	public function startScene(sceneName : String, waitFlag : Bool) : Void{
		var pair : Array<Dynamic>;
		if (activeThread.firstTime) {
			var receivers : Array<Dynamic> = [];
			function findSceneHats(stack : Block, target : ScratchObj) : Void{
				if ((stack.op == "whenSceneStarts") && (stack.args[0].argValue == sceneName)) {
					receivers.push([stack, target]);
				}
			};
			app.stagePane.showCostumeNamed(sceneName);
			redraw();
			app.runtime.allStacksAndOwnersDo(findSceneHats);
			// (re)start all receivers
			var newThreads : Array<Dynamic> = [];
			for (pair in receivers)newThreads.push(restartThread(pair[0], pair[1]));
			if (!waitFlag)                 return;
			activeThread.tmpObj = newThreads;
			activeThread.firstTime = false;
		}
		var done : Bool = true;
		for (t/* AS3HX WARNING could not determine type for var: t exp: EField(EIdent(activeThread),tmpObj) type: null */ in cast(activeThread.tmpObj, Array<Dynamic>)){if (Lambda.indexOf(threads, t) >= 0)                 done = false;
		}
		if (done) {
			activeThread.tmpObj = null;
			activeThread.firstTime = true;
		}
		else {
			yield = true;
		}
	}

	// Procedure call/return

	private function primCall(b : Block) : Dynamic{
		// Call a procedure. Handle recursive calls and "warp" procedures.
		// The activeThread.firstTime flag is used to mark the first call
		// to a procedure running in warp mode. activeThread.firstTime is
		// false for subsequent calls to warp mode procedures.

		// Lookup the procedure and cache for future use
		var obj : ScratchObj = activeThread.target;
		var spec : String = b.spec;
		var proc : Block = obj.procCache[spec];
		if (proc == null) {
			proc = obj.lookupProcedure(spec);
			obj.procCache[spec] = proc;
		}
		if (proc == null)             return null;

		if (warpThread != null) {
			activeThread.firstTime = false;
			if ((currentMSecs - startTime) > warpMSecs)                 yield = true;
		}
		else {
			if (proc.warpProcFlag) {
				// Start running in warp mode.
				warpBlock = b;
				warpThread = activeThread;
				activeThread.firstTime = true;
			}
			else if (activeThread.isRecursiveCall(b, proc)) {
				yield = true;
			}
		}
		var argCount : Int = proc.parameterNames.length;
		var argList : Array<Dynamic> = [];
		for (i in 0...argCount){argList.push(arg(b, i));
		}
		startCmdList(proc, false, argList);
		return null;
	}

	private function primReturn(b : Block) : Dynamic{
		// Return from the innermost procedure. If not in a procedure, stop the thread.
		var didReturn : Bool = activeThread.returnFromProcedure();
		if (!didReturn) {
			activeThread.stop();
			yield = true;
		}
		return null;
	}

	// Variable Primitives
	// Optimization: to avoid the cost of looking up the variable every time,
	// a reference to the Variable object is cached in the target object.

	private function primVarGet(b : Block) : Dynamic{
		if (activeThread == null)             return 0;

		var v : Variable = activeThread.target.varCache[b.spec];
		if (v == null) {
			v = activeThread.target.varCache[b.spec] = activeThread.target.lookupOrCreateVar(b.spec);
			if (v == null)                 return 0;
		}  // XXX: Do we need a get() for persistent variables here ?  

		return v.value;
	}

	private function primVarSet(b : Block) : Variable{
		var name : String = arg(b, 0);
		var v : Variable = activeThread.target.varCache[name];
		if (v == null) {
			v = activeThread.target.varCache[name] = activeThread.target.lookupOrCreateVar(name);
			if (v == null)                 return null;
		}
		var oldvalue : Dynamic = v.value;
		v.value = arg(b, 1);
		return v;
	}

	private function primVarChange(b : Block) : Variable{
		var name : String = arg(b, 0);
		var v : Variable = activeThread.target.varCache[name];
		if (v == null) {
			v = activeThread.target.varCache[name] = activeThread.target.lookupOrCreateVar(name);
			if (v == null)                 return null;
		}
		v.value = Std.parseFloat(v.value) + numarg(b, 1);
		return v;
	}

	private function primGetParam(b : Block) : Dynamic{
		if (b.parameterIndex < 0) {
			var proc : Block = b.topBlock();
			if (proc.parameterNames != null)                 b.parameterIndex = proc.parameterNames.indexOf(b.spec);
			if (b.parameterIndex < 0)                 return 0;
		}
		if ((activeThread.args == null) || (b.parameterIndex >= activeThread.args.length))             return 0;
		return activeThread.args[b.parameterIndex];
	}
}

package uiwidgets;


import flash.display.*;
import flash.events.*;
import flash.filters.*;
import flash.geom.*;
import flash.text.*;

import sound.*;
import translation.*;



import uiwidgets.*;

class Piano extends Sprite
{

	private var color : Int;
	private var instrument : Int;
	private var callback : Function;

	private var selectedKey : PianoKey;
	private var selectedNote : Int;
	private var hasSelection : Bool;

	private var keys : Array<Dynamic> = [];
	private var shape : Shape;
	private var label : TextField;

	private var mousePressed : Bool;
	private var notePlayer : NotePlayer;

	public function new(color : Int, instrument : Int = 0, callback : Function = null, firstKey : Int = 48, lastKey : Int = 72)
	{
		super();
		this.color = color;
		this.instrument = instrument;
		this.callback = callback;
		addShape();
		addLabel();
		addKeys(firstKey, lastKey);
		addEventListeners();
		fixLayout();
	}

	private function addShape() : Void{
		addChild(shape = new Shape());
	}

	private function addLabel() : Void{
		addChild(label = new TextField());
		label.selectable = false;
		label.defaultTextFormat = new TextFormat(CSS.font, 12, 0xFFFFFF);
	}

	private function addKeys(firstKey : Int, lastKey : Int) : Void{
		for (n in firstKey...lastKey + 1){
			addKey(n);
		}
		for (k in keys){
			if (k.isBlack)                 addChild(k);
		}
	}

	private function addKey(n : Int) : Void{
		var key : PianoKey = new PianoKey(n);
		addChild(key);
		keys.push(key);
	}

	private function addEventListeners() : Void{
		addEventListener(MouseEvent.MOUSE_DOWN, pianoMouseDown);
	}

	private function addStageEventListeners() : Void{
		stage.addEventListener(MouseEvent.MOUSE_MOVE, stageMouseMove);
		stage.addEventListener(MouseEvent.MOUSE_UP, stageMouseUp);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, stageMouseDown, true);
	}

	private function removeStageEventListeners() : Void{
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, stageMouseMove);
		stage.removeEventListener(MouseEvent.MOUSE_UP, stageMouseUp);
		stage.removeEventListener(MouseEvent.MOUSE_DOWN, stageMouseDown, true);
	}

	private function pianoMouseDown(e : MouseEvent) : Void{
		mousePressed = true;
		deselect();
		updateKey(e);
	}

	private function stageMouseDown(e : MouseEvent) : Void{
		var t : DisplayObject = try cast(e.target, DisplayObject) catch(e:Dynamic) null;
		while (t){
			if (Std.is(t, Piano))                 return;
			t = t.parent;
		}
		hide();
	}

	private function stageMouseMove(e : MouseEvent) : Void{
		updateKey(e);
	}

	private function stageMouseUp(e : MouseEvent) : Void{
		if (mousePressed) {
			if (callback != null && hasSelection)                 callback(selectedNote);
			hide();
		}
	}

	private function updateKey(e : MouseEvent) : Void{
		var objects : Array<Dynamic> = getObjectsUnderPoint(new Point(e.stageX, e.stageY));
		for (o/* AS3HX WARNING could not determine type for var: o exp: ECall(EField(EIdent(objects),reverse),[]) type: null */ in objects.reverse()){
			if (Std.is(o, PianoKey)) {
				var n : Int = cast((o), PianoKey).note;
				if (!mousePressed) {
					setLabel(getNoteLabel(n));
					return;
				}
				if (isNoteSelected(n))                     return;
				selectNote(n);
				playSoundForNote(n);
				return;
			}
		}
		if (mousePressed)             deselect();
	}

	public function selectNote(n : Int) : Void{
		if (isNoteSelected(n))             return;
		deselect();
		hasSelection = true;
		selectedNote = n;
		setLabel(getNoteLabel(n));
		selectKeyForNote(n);
	}

	public function deselect() : Void{
		hasSelection = false;
		deselectKey();
	}

	public function isNoteSelected(n : Int) : Bool{
		return hasSelection && selectedNote == n;
	}

	private function deselectKey() : Void{
		if (selectedKey != null) {
			selectedKey.deselect();
			selectedKey = null;
		}
	}

	private function selectKeyForNote(n : Int) : Void{
		for (k in keys){
			if (k.note == n) {
				selectedKey = k;
				k.select();
				return;
			}
		}
	}

	private function stopPlaying() : Void{
		if (notePlayer != null) {
			notePlayer.stopPlaying();
			notePlayer = null;
		}
	}

	private function playSoundForNote(n : Int) : Void{
		stopPlaying();
		notePlayer = SoundBank.getNotePlayer(instrument, n);
		if (notePlayer == null)             return;
		notePlayer.setNoteAndDuration(n, 3);
		notePlayer.startPlaying();
	}

	public function showOnStage(s : Stage, x : Float = NaN, y : Float = NaN) : Void{
		addShadowFilter();
		this.x = as3hx.Compat.parseInt(x == (x != 0) ? x : s.mouseX);
		this.y = as3hx.Compat.parseInt(y == (y != 0) ? y : s.mouseY);
		s.addChild(this);
		addStageEventListeners();
	}

	public function hide() : Void{
		if (stage == null)             return;
		removeStageEventListeners();
		stage.removeChild(this);
	}

	private function addShadowFilter() : Void{
		var f : DropShadowFilter = new DropShadowFilter();
		f.blurX = f.blurY = 5;
		f.distance = 3;
		f.color = 0x333333;
		filters = [f];
	}

	private function fixLayout() : Void{
		fixKeyLayout();
		fixLabelLayout();
		redraw();
	}

	private function fixKeyLayout() : Void{
		var x : Int = 1;
		for (k in keys){
			if (k.isBlack) {
				k.x = as3hx.Compat.parseInt(x - k.width / 2);
				k.y = 0;
			}
			else {
				k.x = x;
				k.y = 1;
				x += k.width;
			}
		}
	}

	private function redraw() : Void{
		var g : Graphics = shape.graphics;
		g.beginFill(color, 1);
		g.drawRect(0, 0, width + 1, 64);
		g.endFill();
	}

	private function setLabel(s : String) : Void{
		label.text = s;
		fixLabelLayout();
	}

	private function fixLabelLayout() : Void{
		label.x = as3hx.Compat.parseInt((width - label.textWidth) / 2);
		label.y = as3hx.Compat.parseInt(52 - label.textHeight / 2);
	}

	public static function isBlack(n : Int) : Bool{
		n = getNoteOffset(n);
		return n < 4 && n % 2 == 1 || n > 4 && n % 2 == 0;
	}

	private static function getNoteLabel(n : Int) : String{
		return getNoteName(n) + " (" + n + ")";
	}

	private static var noteNames : Array<Dynamic> = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "G#", "A", "Bb", "B"];
	private static function getNoteName(n : Int) : String{
		var o : Int = getNoteOffset(n);
		return (o != 0) ? noteNames[o] : getOctaveName(n / 12);
	}

	private static var octaveNames : Array<Dynamic> = ["Low C", "Middle C", "High C"];
	private static function getOctaveName(n : Int) : String{
		return n >= 4 && n <= (6) ? Translator.map(octaveNames[n - 4]) : "C";
	}

	private static function getNoteOffset(n : Int) : Int{
		n = n % 12;
		if (n < 0)             n += 12;
		return n;
	}
}


class PianoKey extends Sprite
{

	public var keyHeight : Int = 44;
	public var blackKeyHeight : Int = 26;
	public var keyWidth : Int = 14;
	public var blackKeyWidth : Int = 7;

	public var note : Int;
	public var isBlack : Bool;
	public var isSelected : Bool;

	public function new(n : Int)
	{
		super();
		note = n;
		isBlack = Piano.isBlack(n);
		redraw();
	}

	public function select() : Void{
		setSelected(true);
	}

	public function deselect() : Void{
		setSelected(false);
	}

	public function setSelected(flag : Bool) : Void{
		isSelected = flag;
		redraw();
	}

	private function redraw() : Void{
		var h : Int = (isBlack) ? blackKeyHeight : keyHeight;
		var w : Int = (isBlack) ? blackKeyWidth : keyWidth;
		graphics.beginFill((isSelected) ? 0xFFFF00 : (isBlack) ? 0 : 0xFFFFFF);
		if (isSelected && isBlack)             graphics.lineStyle(1, 0, 1, true);
		graphics.drawRect(0, 0, w, h);
		graphics.endFill();
		if (!isBlack) {
			graphics.beginFill(0, 0);
			graphics.drawRect(w, 0, 1, h);
			graphics.endFill();
		}
	}
}

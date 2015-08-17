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

// SoundEditor.as
// John Maloney, June 2012

package soundedit;

import soundedit.Graphics;
import soundedit.IconButton;
import soundedit.Menu;
import soundedit.Point;
import soundedit.Scratch;
import soundedit.Scrollbar;
import soundedit.Shape;
import soundedit.Slider;
import soundedit.SoundLevelMeter;
import soundedit.SoundsPart;
import soundedit.Sprite;
import soundedit.TextField;
import soundedit.WaveformView;

import flash.display.*;
import flash.events.KeyboardEvent;
import flash.geom.*;
import flash.media.Microphone;
import flash.text.*;
import assets.Resources;
import translation.*;
import ui.parts.*;
import uiwidgets.*;

class SoundEditor extends Sprite {
	
	private inline var waveHeight : Int = 170;
	private inline var borderColor : Int = 0x606060;
	private inline var bgColor : Int = 0xF0F0F0;
	private inline var cornerRadius : Int = 20;
	
	public var app : Scratch;
	
	private static var microphone : Microphone = Microphone.getMicrophone();
	
	public var waveform : WaveformView;
	public var levelMeter : SoundLevelMeter;
	public var scrollbar : Scrollbar;
	
	private var buttons : Array<Dynamic> = [];
	private var playButton : IconButton;
	private var stopButton : IconButton;
	private var recordButton : IconButton;
	
	private var editButton : IconButton;
	private var effectsButton : IconButton;
	
	private var recordIndicator : Shape;
	private var playIndicator : Shape;
	
	private var micVolumeLabel : TextField;
	private var micVolumeSlider : Slider;
	
	public function new(app : Scratch, soundsPart : SoundsPart)
	{
		super();
		this.app = app;
		addChild(levelMeter = new SoundLevelMeter(12, waveHeight));
		addChild(waveform = new WaveformView(this, soundsPart));
		addChild(scrollbar = new Scrollbar(10, 10, waveform.setScroll));
		addControls();
		addIndicators();
		addEditAndEffectsButtons();
		addMicVolumeSlider();
		updateIndicators();
	}
	
	public static function strings() : Array<Dynamic>{
		var editor : SoundEditor = new SoundEditor(null, null);
		editor.editMenu(Menu.dummyButton());
		editor.effectsMenu(Menu.dummyButton());
		return ["Edit", "Effects", "Microphone volume:"];
	}
	
	public function updateTranslation() : Void{
		if (editButton.parent) {
			removeChild(editButton);
			removeChild(effectsButton);
		}
		micVolumeLabel.text = Translator.map("Microphone volume:");
		addEditAndEffectsButtons();
		setWidthHeight(width, height);
	}
	
	public function shutdown() : Void{waveform.stopAll();
	}
	
	public function setWidthHeight(w : Int, h : Int) : Void{
		levelMeter.x = 0;
		levelMeter.y = 0;
		waveform.x = 23;
		waveform.y = 0;
		scrollbar.x = 25;
		scrollbar.y = waveHeight + 5;
		
		var waveWidth : Int = w - waveform.x;
		waveform.setWidthHeight(waveWidth, waveHeight);
		scrollbar.setWidthHeight(waveWidth, 10);
		
		var nextX : Int = waveform.x - 2;
		var buttonY : Int = waveform.y + waveHeight + 25;
		for (b in buttons){
			b.x = nextX;
			b.y = buttonY;
			nextX += b.width + 8;
		}
		editButton.x = nextX + 20;
		editButton.y = buttonY;
		
		effectsButton.x = editButton.x + editButton.width + 15;
		effectsButton.y = editButton.y;
		
		recordIndicator.x = recordButton.x + 9;
		recordIndicator.y = recordButton.y + 8;
		
		playIndicator.x = playButton.x + 12;
		playIndicator.y = playButton.y + 7;
		
		micVolumeSlider.x = micVolumeLabel.x + micVolumeLabel.textWidth + 15;
		micVolumeSlider.y = micVolumeLabel.y + 7;
	}
	
	private function addControls() : Void{
		playButton = new IconButton(waveform.startPlaying, "playSnd", null, true);
		stopButton = new IconButton(waveform.stopAll, "stopSnd", null, true);
		recordButton = new IconButton(waveform.toggleRecording, "recordSnd", null, true);
		
		buttons = [playButton, stopButton, recordButton];
		for (b in buttons){
			if (Std.is(b, IconButton)) 				b.isMomentary = true;
			addChild(b);
		}
	}
	
	private function addEditAndEffectsButtons() : Void{
		addChild(editButton = UIPart.makeMenuButton("Edit", editMenu, true, CSS.textColor));
		addChild(effectsButton = UIPart.makeMenuButton("Effects", effectsMenu, true, CSS.textColor));
	}
	
	private function addMicVolumeSlider() : Void{
		function setMicLevel(level : Float) : Void{
			if (microphone != null) 				microphone.gain = level;
		};
		
		addChild(micVolumeLabel = Resources.makeLabel(Translator.map("Microphone volume:"), CSS.normalTextFormat, 22, 240));
		
		micVolumeSlider = new Slider(130, 5, setMicLevel);
		micVolumeSlider.min = 1;
		micVolumeSlider.max = 100;
		micVolumeSlider.value = 50;
		addChild(micVolumeSlider);
	}
	
	private function addIndicators() : Void{
		recordIndicator = new Shape();
		var g : Graphics = recordIndicator.graphics;
		g.beginFill(0xFF0000);
		g.drawCircle(8, 8, 8);
		g.endFill();
		addChild(recordIndicator);
		
		playIndicator = new Shape();
		g = playIndicator.graphics;
		g.beginFill(0xFF00);
		g.moveTo(0, 0);
		g.lineTo(11, 8);
		g.lineTo(11, 10);
		g.lineTo(0, 18);
		g.endFill();
		addChild(playIndicator);
	}
	
	public function updateIndicators() : Void{
		recordIndicator.visible = waveform.isRecording();
		playIndicator.visible = waveform.isPlaying();
		if (microphone != null) 			micVolumeSlider.value = microphone.gain;
	}
	
	/* Menus */
	
	private function editMenu(b : IconButton) : Void{
		var m : Menu = new Menu();
		m.addItem("undo", waveform.undo);
		m.addItem("redo", waveform.redo);
		m.addLine();
		m.addItem("cut", waveform.cut);
		m.addItem("copy", waveform.copy);
		m.addItem("paste", waveform.paste);
		m.addLine();
		m.addItem("delete", waveform.deleteSelection);
		m.addItem("select all", waveform.selectAll);
		var p : Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, p.x + 1, p.y + b.height - 1);
	}
	
	private function effectsMenu(b : IconButton) : Void{
		function applyEffect(selection : String) : Void{waveform.applyEffect(selection, shiftKey);
		};
		var shiftKey : Bool = b.lastEvent.shiftKey;
		var m : Menu = new Menu(applyEffect);
		m.addItem("fade in");
		m.addItem("fade out");
		m.addLine();
		m.addItem("louder");
		m.addItem("softer");
		m.addItem("silence");
		m.addLine();
		m.addItem("reverse");
		var p : Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, p.x + 1, p.y + b.height - 1);
	}
	
	/* Keyboard Shortcuts */
	
	public function keyDown(evt : KeyboardEvent) : Void{
		if (!stage || stage.focus) 			return  // sound editor is hidden or someone else has keyboard focus; do nothing  ;
		var k : Int = evt.keyCode;
		if ((k == 8) || (k == 127)) 			waveform.deleteSelection(evt.shiftKey);
		if (k == 37) 			waveform.leftArrow();
		if (k == 39) 			waveform.rightArrow();
		if (evt.ctrlKey || evt.shiftKey) {  // shift or control key commands (control keys may be grabbed by the browser on Windows...)  
			switch (String.fromCharCode(k)) {
				case "A":waveform.selectAll();
				case "C":waveform.copy();
				case "V":waveform.paste();
				case "X":waveform.cut();
				case "Y":waveform.redo();
				case "Z":waveform.undo();
			}
		}
		if (!evt.ctrlKey) {
			var ch : String = String.fromCharCode(evt.charCode);
			if (ch == " ") 				waveform.togglePlaying();
			if (ch == "+") 				waveform.zoomIn();
			if (ch == "-") 				waveform.zoomOut();
		}
	}
}

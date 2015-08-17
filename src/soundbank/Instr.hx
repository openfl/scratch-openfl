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

// Instr.as
// John Maloney, April 2012
//
// This class embeds the sound data for Scratch instruments and drums.
// The static variable 'samples' is a dictionary of named sound buffers.
// Call initSamples() to initialize 'samples' before using.
//
// All instrument and drum samples were created for Scratch by:
//
//		Paul Madden, paulmatthewmadden@yahoo.com
//
// Paul is an excellent sound designer and we appreciate all the effort
// he put into this project.

package soundbank;

import soundbank.ByteArray;

import flash.utils.*;
import sound.WAVFile;

class Instr {
	
	public static var samples : Dynamic;
	
	public static function initSamples() : Void{
		// Initialize the dictionary of named sound buffers.
		// Details: Build the dictionary by enumerating all the embedded sounds in this file
		// (i.e. constants with a value of type 'class'), extracting the sound data from the
		// WAV file, and adding an entry for it to the 'samples' object.
		
		if (samples != null) 			return  // already initialized  ;
		
		samples = { };
		var classDescription : FastXML = describeType(Instr);
		for (k/* AS3HX WARNING could not determine type for var: k exp: ECall(EField(EIdent(classDescription),elements),[EConst(CString(constant))]) type: null */ in classDescription.nodes.elements("constant")){
			if (k.attribute("type") == "Class") {
				var instrName : String = k.attribute("name");
				Reflect.setField(samples, instrName, getWAVSamples(new Instr()[instrName]));
			}
		}
	}
	
	private static function getWAVSamples(wavData : ByteArray) : ByteArray{
		// Extract a sound buffer from a WAV file. Assume the WAV file contains 16-bit, uncompressed sound data.
		var info : Dynamic = WAVFile.decode(wavData);
		var soundBuffer : ByteArray = new ByteArray();
		soundBuffer.endian = Endian.LITTLE_ENDIAN;
		wavData.position = info.sampleDataStart;
		wavData.readBytes(soundBuffer, 0, 2 * info.sampleCount);
		return soundBuffer;
	}
	
	/* Instruments */
	
	@:meta(Embed(source="instruments/AcousticGuitar_F3_22k.wav",mimeType="application/octet-stream"))

	public static var AcousticGuitar_F3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/AcousticPiano(5)_A#3_22k.wav",mimeType="application/octet-stream"))

	public static var AcousticPiano_As3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/AcousticPiano(5)_C4_22k.wav",mimeType="application/octet-stream"))

	public static var AcousticPiano_C4 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/AcousticPiano(5)_G4_22k.wav",mimeType="application/octet-stream"))

	public static var AcousticPiano_G4 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/AcousticPiano(5)_F5_22k.wav",mimeType="application/octet-stream"))

	public static var AcousticPiano_F5 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/AcousticPiano(5)_C6_22k.wav",mimeType="application/octet-stream"))

	public static var AcousticPiano_C6 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/AcousticPiano(5)_D#6_22k.wav",mimeType="application/octet-stream"))

	public static var AcousticPiano_Ds6 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/AcousticPiano(5)_D7_22k.wav",mimeType="application/octet-stream"))

	public static var AcousticPiano_D7 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/AltoSax_A3_22K.wav",mimeType="application/octet-stream"))

	public static var AltoSax_A3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/AltoSax(3)_C6_22k.wav",mimeType="application/octet-stream"))

	public static var AltoSax_C6 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Bassoon_C3_22k.wav",mimeType="application/octet-stream"))

	public static var Bassoon_C3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/BassTrombone_A2(2)_22k.wav",mimeType="application/octet-stream"))

	public static var BassTrombone_A2_2 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/BassTrombone_A2(3)_22k.wav",mimeType="application/octet-stream"))

	public static var BassTrombone_A2_3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Cello(3b)_C2_22k.wav",mimeType="application/octet-stream"))

	public static var Cello_C2 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Cello(3)_A#2_22k.wav",mimeType="application/octet-stream"))

	public static var Cello_As2 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Choir(4)_F3_22k.wav",mimeType="application/octet-stream"))

	public static var Choir_F3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Choir(4)_F4_22k.wav",mimeType="application/octet-stream"))

	public static var Choir_F4 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Choir(4)_F5_22k.wav",mimeType="application/octet-stream"))

	public static var Choir_F5 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Clarinet_C4_22k.wav",mimeType="application/octet-stream"))

	public static var Clarinet_C4 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/ElectricBass(2)_G1_22k.wav",mimeType="application/octet-stream"))

	public static var ElectricBass_G1 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/ElectricGuitar(2)_F3(1)_22k.wav",mimeType="application/octet-stream"))

	public static var ElectricGuitar_F3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/ElectricPiano_C2_22k.wav",mimeType="application/octet-stream"))

	public static var ElectricPiano_C2 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/ElectricPiano_C4_22k.wav",mimeType="application/octet-stream"))

	public static var ElectricPiano_C4 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/EnglishHorn(1)_D4_22k.wav",mimeType="application/octet-stream"))

	public static var EnglishHorn_D4 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/EnglishHorn(1)_F3_22k.wav",mimeType="application/octet-stream"))

	public static var EnglishHorn_F3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Flute(3)_B5(1)_22k.wav",mimeType="application/octet-stream"))

	public static var Flute_B5_1 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Flute(3)_B5(2)_22k.wav",mimeType="application/octet-stream"))

	public static var Flute_B5_2 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Marimba_C4_22k.wav",mimeType="application/octet-stream"))

	public static var Marimba_C4 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/MusicBox_C4_22k.wav",mimeType="application/octet-stream"))

	public static var MusicBox_C4 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Organ(2)_G2_22k.wav",mimeType="application/octet-stream"))

	public static var Organ_G2 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Pizz(2)_A3_22k.wav",mimeType="application/octet-stream"))

	public static var Pizz_A3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Pizz(2)_E4_22k.wav",mimeType="application/octet-stream"))

	public static var Pizz_E4 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Pizz(2)_G2_22k.wav",mimeType="application/octet-stream"))

	public static var Pizz_G2 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/SteelDrum_D5_22k.wav",mimeType="application/octet-stream"))

	public static var SteelDrum_D5 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/SynthLead(6)_C4_22k.wav",mimeType="application/octet-stream"))

	public static var SynthLead_C4 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/SynthLead(6)_C6_22k.wav",mimeType="application/octet-stream"))

	public static var SynthLead_C6 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/SynthPad(2)_A3_22k.wav",mimeType="application/octet-stream"))

	public static var SynthPad_A3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/SynthPad(2)_C6_22k.wav",mimeType="application/octet-stream"))

	public static var SynthPad_C6 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/TenorSax(1)_C3_22k.wav",mimeType="application/octet-stream"))

	public static var TenorSax_C3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Trombone_B3_22k.wav",mimeType="application/octet-stream"))

	public static var Trombone_B3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Trumpet_E5_22k.wav",mimeType="application/octet-stream"))

	public static var Trumpet_E5 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Vibraphone_C3_22k.wav",mimeType="application/octet-stream"))

	public static var Vibraphone_C3 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Violin(2)_D4_22K.wav",mimeType="application/octet-stream"))

	public static var Violin_D4 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Violin(3)_A4_22k.wav",mimeType="application/octet-stream"))

	public static var Violin_A4 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/Violin(3b)_E5_22k.wav",mimeType="application/octet-stream"))

	public static var Violin_E5 : Class<Dynamic>;
	
	@:meta(Embed(source="instruments/WoodenFlute_C5_22k.wav",mimeType="application/octet-stream"))

	public static var WoodenFlute_C5 : Class<Dynamic>;
	
	/* Drums */
	
	@:meta(Embed(source="drums/BassDrum(1b)_22k.wav",mimeType="application/octet-stream"))

	public static var BassDrum : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Bongo_22k.wav",mimeType="application/octet-stream"))

	public static var Bongo : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Cabasa(1)_22k.wav",mimeType="application/octet-stream"))

	public static var Cabasa : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Clap(1)_22k.wav",mimeType="application/octet-stream"))

	public static var Clap : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Claves(1)_22k.wav",mimeType="application/octet-stream"))

	public static var Claves : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Conga(1)_22k.wav",mimeType="application/octet-stream"))

	public static var Conga : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Cowbell(3)_22k.wav",mimeType="application/octet-stream"))

	public static var Cowbell : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Crash(2)_22k.wav",mimeType="application/octet-stream"))

	public static var Crash : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Cuica(2)_22k.wav",mimeType="application/octet-stream"))

	public static var Cuica : Class<Dynamic>;
	
	@:meta(Embed(source="drums/GuiroLong(1)_22k.wav",mimeType="application/octet-stream"))

	public static var GuiroLong : Class<Dynamic>;
	
	@:meta(Embed(source="drums/GuiroShort(1)_22k.wav",mimeType="application/octet-stream"))

	public static var GuiroShort : Class<Dynamic>;
	
	@:meta(Embed(source="drums/HiHatClosed(1)_22k.wav",mimeType="application/octet-stream"))

	public static var HiHatClosed : Class<Dynamic>;
	
	@:meta(Embed(source="drums/HiHatOpen(2)_22k.wav",mimeType="application/octet-stream"))

	public static var HiHatOpen : Class<Dynamic>;
	
	@:meta(Embed(source="drums/HiHatPedal(1)_22k.wav",mimeType="application/octet-stream"))

	public static var HiHatPedal : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Maracas(1)_22k.wav",mimeType="application/octet-stream"))

	public static var Maracas : Class<Dynamic>;
	
	@:meta(Embed(source="drums/SideStick(1)_22k.wav",mimeType="application/octet-stream"))

	public static var SideStick : Class<Dynamic>;
	
	@:meta(Embed(source="drums/SnareDrum(1)_22k.wav",mimeType="application/octet-stream"))

	public static var SnareDrum : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Tambourine(3)_22k.wav",mimeType="application/octet-stream"))

	public static var Tambourine : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Tom(1)_22k.wav",mimeType="application/octet-stream"))

	public static var Tom : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Triangle(1)_22k.wav",mimeType="application/octet-stream"))

	public static var Triangle : Class<Dynamic>;
	
	@:meta(Embed(source="drums/Vibraslap(1)_22k.wav",mimeType="application/octet-stream"))

	public static var Vibraslap : Class<Dynamic>;
	
	@:meta(Embed(source="drums/WoodBlock(1)_22k.wav",mimeType="application/octet-stream"))

	public static var WoodBlock : Class<Dynamic>;

	public function new()
	{
	}
}

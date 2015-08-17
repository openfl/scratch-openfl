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

// SqueakSoundPlayer.as
// John Maloney, June 2010
//
// Decode and play a Squeak ADPCM compressed sound with 2, 3, 4, or 5 bits per sample.
// Note: To make old projects open more quickly, sounds compressed in the old Squeak ACPDM
// format are not converted to WAV format immediately. Such sounds are converted to WAV format
// if and when the project is saved. Meanwhile, this module allows these sounds to be played.

package sound;


import flash.utils.ByteArray;

class SqueakSoundPlayer extends ScratchSoundPlayer {
	
	private static var stepSizeTable : Array<Dynamic> = [
		7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45, 
		50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130, 143, 157, 173, 190, 209, 230, 
		253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658, 724, 796, 876, 963, 
		1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 
		3660, 4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 
		12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767];
	
	// bit stream state
	private var bitsPerSample : Int;
	private var currentByte : Int;
	private var bitPosition : Int;
	
	// decoder state
	private var indexTable : Array<Dynamic>;
	private var deltaSignMask : Int;
	private var deltaValueMask : Int;
	private var deltaValueHighBit : Int;
	private var predicted : Int;
	private var index : Int;
	
	public function new(soundData : ByteArray, bitsPerSample : Int, samplesPerSecond : Float)
	{
		super(null);
		this.soundData = soundData;
		this.bitsPerSample = bitsPerSample;
		stepSize = samplesPerSecond / 44100.0;
		startOffset = 0;
		endOffset = soundData.length;
		getSample = getSqueakSample;
		switch (bitsPerSample) {
			case 2:
				indexTable = [-1, 2];
			case 3:
				indexTable = [-1, -1, 2, 4];
			case 4:
				indexTable = [-1, -1, -1, -1, 2, 4, 6, 8];
			case 5:
				indexTable = [-1, -1, -1, -1, -1, -1, -1, -1, 1, 2, 4, 6, 8, 10, 13, 16];
		}
		deltaSignMask = 1 << (bitsPerSample - 1);
		deltaValueMask = deltaSignMask - 1;
		deltaValueHighBit = deltaSignMask >> 1;
	}
	
	private function getSqueakSample() : Int{
		if (bytePosition >= soundData.length) 			return 0;
		var delta : Int = nextBits();
		var step : Int = stepSizeTable[index];
		var predictedDelta : Int = 0;
		var bit : Int = deltaValueHighBit;
		while (bit > 0){
			if ((delta & bit) != 0) 				predictedDelta += step;
			step = step >> 1;
			bit = bit >> 1;
		}
		predictedDelta += step;
		predicted += (((delta & deltaSignMask) != 0)) ? -predictedDelta : predictedDelta;
		
		index += indexTable[delta & deltaValueMask];
		if (index < 0) 			index = 0;
		if (index > 88) 			index = 88;
		
		if (predicted > 32767) 			predicted = 32767;
		if (predicted < -32768) 			predicted = -32768;
		return predicted;
	}
	
	private function nextBits() : Int{
		var result : Int = 0;
		var remaining : Int = bitsPerSample;
		while (true){
			var shift : Int = remaining - bitPosition;
			result += ((shift < 0)) ? (currentByte >> -shift) : (currentByte << shift);
			if (shift > 0) {  // consumed all bits of currentByte; fetch next byte  
				remaining -= bitPosition;
				if (bytePosition < soundData.length) {
					currentByte = soundData[bytePosition++];
					bitPosition = 8;
				}
				else {
					currentByte = 0;
					bitPosition = 0;
					break;
				}
			}
			else {  // still some bits left in currentByte  
				bitPosition -= remaining;
				currentByte = currentByte & (0xFF >> (8 - bitPosition));
				break;
			}
		}
		return result;
	}
}

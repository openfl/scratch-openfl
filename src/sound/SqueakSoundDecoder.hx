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

// SqueakSoundDecoder.as
// John Maloney, November 2010
//
// Decode a Flash/Squeak ADPCM compressed sounds with 2, 3, 4, or 5 bits per sample.

package sound;


import flash.utils.*;

class SqueakSoundDecoder {
	
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
	private var signMask : Int;
	private var valueMask : Int;
	private var valueHighBit : Int;
	
	public function new(bitsPerSample : Int)
	{
		this.bitsPerSample = bitsPerSample;
		switch (bitsPerSample) {
			case 2:
				indexTable = [-1, 2, -1, 2];
			case 3:
				indexTable = [-1, -1, 2, 4, -1, -1, 2, 4];
			case 4:
				indexTable = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8];
			case 5:
				indexTable = [
						-1, -1, -1, -1, -1, -1, -1, -1, 1, 2, 4, 6, 8, 10, 13, 16, 
						-1, -1, -1, -1, -1, -1, -1, -1, 1, 2, 4, 6, 8, 10, 13, 16];
		}
		signMask = 1 << (bitsPerSample - 1);
		valueMask = signMask - 1;
		valueHighBit = signMask >> 1;
	}
	
	public function decode(soundData : ByteArray) : ByteArray{
		var result : ByteArray = new ByteArray();
		result.endian = Endian.LITTLE_ENDIAN;
		var sample : Int = 0;
		var index : Int = 0;
		soundData.position = 0;
		while (true){
			var code : Int = nextCode(soundData);
			if (code < 0) 				break  // no more input  ;
			var step : Int = stepSizeTable[index];
			var delta : Int = 0;
			var bit : Int = valueHighBit;
			while (bit > 0){
				if ((code & bit) != 0) 					delta += step;
				step = step >> 1;
				bit = bit >> 1;
			}
			delta += step;
			sample += (((code & signMask) != 0)) ? -delta : delta;
			
			index += indexTable[code];
			if (index < 0) 				index = 0;
			if (index > 88) 				index = 88;
			
			if (sample > 32767) 				sample = 32767;
			if (sample < -32768) 				sample = -32768;
			result.writeShort(sample);
		}
		result.position = 0;
		return result;
	}
	
	private function nextCode(soundData : ByteArray) : Int{
		var result : Int = 0;
		var remaining : Int = bitsPerSample;
		while (true){
			var shift : Int = remaining - bitPosition;
			result += ((shift < 0)) ? (currentByte >> -shift) : (currentByte << shift);
			if (shift > 0) {  // consumed all bits of currentByte; fetch next byte  
				remaining -= bitPosition;
				if (soundData.bytesAvailable > 0) {
					currentByte = soundData.readUnsignedByte();
					bitPosition = 8;
				}
				else {  // no more input  
					currentByte = 0;
					bitPosition = 0;
					return -1;
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

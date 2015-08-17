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

/**
* This class lets you decode animated GIF files, and show animated GIF's in the Flash player
* Base Class : http://www.java2s.com/Code/Java/2D-Graphics-GUI/GiffileEncoder.htm
* @author Kevin Weiner (original Java version - kweiner@fmsware.com)
* @author Thibault Imbert (AS3 version - bytearray.org)
* @version 0.1 AS3 implementation
*
* Modified for Scratch by John Maloney.
* Licensed under the MIT Open Source License.
*/

package util;

import nme.errors.Error;

import flash.display.BitmapData;
import flash.geom.Rectangle;
import flash.geom.Point;
import flash.utils.ByteArray;

class GIFDecoder {
	/**
	 * File read status: No errors.
	 */
	private static var STATUS_OK : Int = 0;
	
	/**
	 * File read status: Error decoding file (may be partially decoded)
	 */
	private static var STATUS_FORMAT_ERROR : Int = 1;
	
	/**
	 * File read status: Unable to open source.
	 */
	private static var STATUS_OPEN_ERROR : Int = 2;
	
	private static var frameRect : Rectangle = new Rectangle();
	
	private var inStream : ByteArray;
	private var status : Int;
	
	// full image width
	private var width : Int;
	// full image height
	private var height : Int;
	// global color table used
	private var gctFlag : Bool;
	// size of global color table
	private var gctSize : Int;
	// iterations; 0 = repeat forever
	private var loopCount : Int = 1;
	
	// global color table
	private var gct : Array<Dynamic>;
	// local color table
	private var lct : Array<Dynamic>;
	// active color table
	private var act : Array<Dynamic>;
	
	// background color index
	private var bgIndex : Int;
	// background color
	private var bgColor : Int;
	// previous bg color
	private var lastBgColor : Int;
	// pixel aspect ratio
	private var pixelAspect : Int;
	
	private var lctFlag : Bool;  // local color table flag  
	// interlace flag
	private var interlace : Bool;
	// local color table size
	private var lctSize : Int;
	
	private var ix : Int;
	private var iy : Int;
	private var iw : Int;
	// current image rectangle
	private var ih : Int;
	// last image rect
	private var lastRect : Rectangle;
	// current frame
	private var image : BitmapData;
	private var bitmap : BitmapData;
	// previous frame
	private var lastImage : BitmapData;
	// current data block
	private var block : ByteArray = new ByteArray();
	// block size
	private var blockSize : Int = 0;
	// point for copying pixels
	private var origin : Point = new Point(0, 0);
	
	// last graphic control extension info
	private var dispose : Int = 0;
	// 0=no action; 1=leave in place; 2=restore to bg; 3=restore to prev
	private var lastDispose : Int = 0;
	// use transparent color
	private var transparency : Bool = false;
	// delay in milliseconds
	private var delay : Int = 0;
	// transparent color index
	private var transIndex : Int;
	
	// max decoder pixel stack size
	private static var MaxStackSize : Int = 4096;
	
	// LZW decoder working arrays
	private var prefix : Array<Dynamic>;
	private var suffix : Array<Dynamic>;
	private var pixelStack : Array<Dynamic>;
	private var pixels : Array<Dynamic>;
	
	// frames read from current file
	public var frames : Array<Dynamic>;
	public var frameCount : Int;
	
	/**
	 * Reads GIF image from stream
	 *
	 * @param BufferedInputStream containing GIF file.
	 * @return read status code (0 = no errors)
	 */
	public function read(inStream : ByteArray) : Int{
		init();
		if (inStream != null) {
			this.inStream = inStream;
			readHeader();
			
			if (!hasError()) {
				readContents();
				
				if (frameCount < 0) 					status = STATUS_FORMAT_ERROR;
			}
		}
		else {
			status = STATUS_OPEN_ERROR;
		}
		return status;
	}
	
	/**
	 * Creates new frame image from current data (and previous
	 * frames as specified by their disposition codes).
	 */
	private function getPixels(bitmap : BitmapData) : Array<Dynamic>{
		var pixels : Array<Dynamic> = new Array<Dynamic>(image.width * image.height);
		var count : Int = 0;
		var lngWidth : Int = image.width;
		var lngHeight : Int = image.height;
		var color : Int;
		
		for (th in 0...lngHeight){
			for (tw in 0...lngWidth){
				color = bitmap.getPixel32(tw, th);
				pixels[count++] = color;
			}
		}
		return pixels;
	}
	
	private function setPixels(pixels : Array<Dynamic>) : Void{
		var count : Int = 0;
		var color : Int;
		pixels.position = 0;
		
		var lngWidth : Int = image.width;
		var lngHeight : Int = image.height;
		bitmap.lock();
		
		for (th in 0...lngHeight){
			for (tw in 0...lngWidth){
				color = pixels[count++];
				bitmap.setPixel32(tw, th, color);
			}
		}
		bitmap.unlock();
	}
	
	private function transferPixels() : Void{
		// fill in starting image contents based on last image's dispose code
		if (lastDispose > 0) {
			if (lastDispose == 3) {
				// use image before last
				var n : Int = frameCount - 2;
				lastImage = n >= (0) ? frames[n] : null;
			}
			
			if (lastImage != null) {
				bitmap.copyPixels(lastImage, bitmap.rect, origin, null, null, true);
				// copy pixels
				if (lastDispose == 2) {
					// fill last image rect area with background color
					// assume background is transparent
					var c : Float = (transparency) ? 0x00000000 : lastBgColor;
					// use given background color
					bitmap.fillRect(bitmap.rect, c);
				}
			}
		}  // expose destination image's pixels as int array  
		
		var dest : Array<Dynamic> = getPixels(bitmap);
		
		// copy each source line to the appropriate place in the destination
		var pass : Int = 1;
		var inc : Int = 8;
		var iline : Int = 0;
		for (i in 0...ih){
			var line : Int = i;
			if (interlace) {
				if (iline >= ih) {
					pass++;
					switch (pass) {
						case 2:
							iline = 4;
						case 3:
							iline = 2;
							inc = 4;
						case 4:
							iline = 1;
							inc = 2;
					}
				}
				line = iline;
				iline += inc;
			}
			line += iy;
			if (line < height) {
				var k : Int = line * width;
				var dx : Int = k + ix;  // start of line in dest  
				var dlim : Int = dx + iw;  // end of dest line  
				if ((k + width) < dlim) {
					dlim = k + width;
				}
				var sx : Int = i * iw;  // start of line in source  
				var index : Int;
				var tmp : Int;
				while (dx < dlim){
					// map color and insert in destination
					index = (pixels[sx++]) & 0xff;
					tmp = act[index];
					if (tmp != 0) {
						dest[dx] = tmp;
					}
					dx++;
				}
			}
		}
		setPixels(dest);
	}
	
	/**
	 * Decodes LZW image data into pixel array.
	 * Adapted from John Cristy's ImageMagick.
	 */
	private function decodeImageData() : Void{
		var NullCode : Int = -1;
		var npix : Int = iw * ih;
		var available : Int;
		var clear : Int;
		var code_mask : Int;
		var code_size : Int;
		var end_of_information : Int;
		var in_code : Int;
		var old_code : Int;
		var bits : Int;
		var code : Int;
		var count : Int;
		var i : Int;
		var datum : Int;
		var data_size : Int;
		var first : Int;
		var top : Int;
		var bi : Int;
		var pi : Int;
		
		if ((pixels == null) || (pixels.length < npix)) {
			pixels = new Array<Dynamic>(npix);
		}
		if (prefix == null) 			prefix = new Array<Dynamic>(MaxStackSize);
		if (suffix == null) 			suffix = new Array<Dynamic>(MaxStackSize);
		if (pixelStack == null) 			pixelStack = new Array<Dynamic>(MaxStackSize + 1)  //  Initialize GIF data stream decoder.  ;
		
		
		
		
		data_size = readSingleByte();
		clear = 1 << data_size;
		end_of_information = clear + 1;
		available = clear + 2;
		old_code = NullCode;
		code_size = data_size + 1;
		code_mask = (1 << code_size) - 1;
		for (code in 0...clear){
			prefix[as3hx.Compat.parseInt(code)] = 0;
			suffix[as3hx.Compat.parseInt(code)] = code;
		}  //  Decode GIF pixel stream.  
		
		
		
		datum = bits = count = first = top = pi = bi = 0;
		
		i = 0;
		while (i < npix){
			if (top == 0) {
				if (bits < code_size) {
					//  Load bytes until there are enough bits for a code.
					if (count == 0) {
						// Read a new data block.
						count = readBlock();
						if (count <= 0) 
							break;
						bi = 0;
					}
					datum += (as3hx.Compat.parseInt((block[as3hx.Compat.parseInt(bi)])) & 0xff) << bits;
					bits += 8;
					bi++;
					count--;
					continue;
				}  //  Get the next code.  
				
				
				
				code = datum & code_mask;
				datum >>= code_size;
				bits -= code_size;
				//  Interpret the code
				if ((code > available) || (code == end_of_information)) 
					break;
				if (code == clear) {
					//  Reset decoder.
					code_size = data_size + 1;
					code_mask = (1 << code_size) - 1;
					available = clear + 2;
					old_code = NullCode;
					continue;
				}
				if (old_code == NullCode) {
					pixelStack[as3hx.Compat.parseInt(top++)] = suffix[as3hx.Compat.parseInt(code)];
					old_code = code;
					first = code;
					continue;
				}
				in_code = code;
				if (code == available) {
					pixelStack[as3hx.Compat.parseInt(top++)] = first;
					code = old_code;
				}
				while (code > clear){
					pixelStack[as3hx.Compat.parseInt(top++)] = suffix[as3hx.Compat.parseInt(code)];
					code = prefix[as3hx.Compat.parseInt(code)];
				}
				first = (suffix[as3hx.Compat.parseInt(code)]) & 0xff;
				
				//  Add a new string to the string table,
				
				if (available >= MaxStackSize) 					break;
				pixelStack[as3hx.Compat.parseInt(top++)] = first;
				prefix[as3hx.Compat.parseInt(available)] = old_code;
				suffix[as3hx.Compat.parseInt(available)] = first;
				available++;
				if (((available & code_mask) == 0)
					&& (available < MaxStackSize)) {
					code_size++;
					code_mask += available;
				}
				old_code = in_code;
			}  //  Pop a pixel off the pixel stack.  
			
			
			
			
			top--;
			pixels[as3hx.Compat.parseInt(pi++)] = pixelStack[as3hx.Compat.parseInt(top)];
			i++;
		}
		
		for (i in pi...npix){
			pixels[as3hx.Compat.parseInt(i)] = 0;
		}
	}
	
	/**
	 * Returns true if an error was encountered during reading/decoding
	 */
	private function hasError() : Bool{
		return status != STATUS_OK;
	}
	
	/**
	 * Initializes or re-initializes reader
	*/
	private function init() : Void{
		status = STATUS_OK;
		frameCount = 0;
		frames = new Array<Dynamic>();
		gct = null;
		lct = null;
	}
	
	/**
	 * Reads a single byte from the input stream.
	*/
	private function readSingleByte() : Int{
		var curByte : Int = 0;
		try{
			curByte = inStream.readUnsignedByte();
		}		catch (e : Error){
			status = STATUS_FORMAT_ERROR;
		}
		return curByte;
	}
	
	/**
	 * Reads next variable length block from input.
	 *
	 * @return number of bytes stored in "buffer"
	 */
	private function readBlock() : Int{
		blockSize = readSingleByte();
		var n : Int = 0;
		if (blockSize > 0) {
			try{
				var count : Int = 0;
				while (n < blockSize){
					
					inStream.readBytes(block, n, blockSize - n);
					if ((blockSize - n) == -1) 
						break;
					n += (blockSize - n);
				}
			}			catch (e : Error){
				
			}
			
			if (n < blockSize) {
				status = STATUS_FORMAT_ERROR;
			}
		}
		return n;
	}
	
	/**
	 * Reads color table as 256 RGB integer values
	 *
	 * @param ncolors int number of colors to read
	 * @return int array containing 256 colors (packed ARGB with full alpha)
	 */
	private function readColorTable(ncolors : Int) : Array<Dynamic>{
		var nbytes : Int = 3 * ncolors;
		var tab : Array<Dynamic> = null;
		var c : ByteArray = new ByteArray();
		var n : Int = 0;
		try{
			inStream.readBytes(c, 0, nbytes);
			n = nbytes;
		}		catch (e : Error){
			
		}
		if (n < nbytes) {
			status = STATUS_FORMAT_ERROR;
		}
		else {
			tab = new Array<Dynamic>(256);  // max size to avoid bounds checks  
			var i : Int = 0;
			var j : Int = 0;
			while (i < ncolors){
				var r : Int = (c[j++]) & 0xff;
				var g : Int = (c[j++]) & 0xff;
				var b : Int = (c[j++]) & 0xff;
				tab[i++] = (0xff000000 | (r << 16) | (g << 8) | b);
			}
		}
		return tab;
	}
	
	/**
	 * Main file parser.  Reads GIF content blocks.
	 */
	private function readContents() : Void{
		// read GIF file content blocks
		var done : Bool = false;
		
		while (!(done || hasError())){
			var code : Int = readSingleByte();
			
			switch (code) {
				
				case 0x2C:  // image separator  
				readImage();
				
				case 0x21:  // extension  
					code = readSingleByte();
					switch (code) {
						case 0xf9:  // graphics control extension  
						readGraphicControlExt();
						
						case 0xff:  // application extension  
							readBlock();
							var app : String = "";
							for (i in 0...11){
								app += block[as3hx.Compat.parseInt(i)];
							}
							if (app == "NETSCAPE2.0") {
								readNetscapeExt();
							}
							else 
							skip();  // don't care  
							break;  // uninteresting extension  
							skip();
							break;
						
						default:  // uninteresting extension  
							skip();
							break;
					}
				
				case 0x3b:  // terminator  
				done = true;
				
				case 0x00:  // bad byte, but keep going and see what happens  
					break;
					status = STATUS_FORMAT_ERROR;
					break;
				
				default:
					status = STATUS_FORMAT_ERROR;
					break;
			}
		}
	}
	
	/**
	 * Reads Graphics Control Extension values
	 */
	private function readGraphicControlExt() : Void{
		readSingleByte();  // block size  
		var packed : Int = readSingleByte();  // packed fields  
		dispose = (packed & 0x1c) >> 2;  // disposal method  
		if (dispose == 0) {
			dispose = 1;
		}
		transparency = (packed & 1) != 0;
		delay = readShort() * 10;  // delay in milliseconds  
		transIndex = readSingleByte();  // transparent color index  
		readSingleByte();
	}
	
	/**
	 * Reads GIF file header information.
	 */
	private function readHeader() : Void{
		var id : String = "";
		for (i in 0...6){
			id += String.fromCharCode(readSingleByte());
		}
		if (!(id.indexOf("GIF") == 0)) {
			status = STATUS_FORMAT_ERROR;
			throw new Error("Invalid file type");
			return;
		}
		readLSD();
		if (gctFlag && !hasError()) {
			gct = readColorTable(gctSize);
			bgColor = gct[bgIndex];
		}
	}
	
	/**
	 * Reads next frame image
	 */
	private function readImage() : Void{
		ix = readShort();  // (sub)image position & size  
		iy = readShort();
		iw = readShort();
		ih = readShort();
		
		var packed : Int = readSingleByte();
		lctFlag = (packed & 0x80) != 0;  // 1 - local color table flag  
		interlace = (packed & 0x40) != 0;  // 2 - interlace flag  
		// 3 - sort flag
		// 4-5 - reserved
		lctSize = 2 << (packed & 7);  // 6-8 - local color table size  
		
		if (lctFlag) {
			lct = readColorTable(lctSize);  // read table  
			act = lct;
		}
		else {
			act = gct;  // make global table active  
			if (bgIndex == transIndex) 
				bgColor = 0;
		}
		var save : Int = 0;
		if (transparency) {
			save = act[transIndex];
			act[transIndex] = 0;
		}
		
		if (act == null) {
			status = STATUS_FORMAT_ERROR;
		}
		
		if (hasError()) 			return;
		
		decodeImageData();  // decode pixel data  
		skip();
		if (hasError()) 			return;
		
		frameCount++;
		// create new image to receive frame data
		
		image = bitmap = new BitmapData(width, height);
		transferPixels();  // transfer pixel data to image  
		
		frames.push(bitmap);  // add image to frame list  
		if (transparency) 			act[transIndex] = save;
		resetFrame();
	}
	
	/**
	 * Reads Logical Screen Descriptor
	 */
	private function readLSD() : Void{
		
		// logical screen size
		width = readShort();
		height = readShort();
		
		// packed fields
		var packed : Int = readSingleByte();
		
		gctFlag = (packed & 0x80) != 0;  // 1   : global color table flag  
		// 2-4 : color resolution
		// 5   : gct sort flag
		gctSize = 2 << (packed & 7);  // 6-8 : gct size  
		bgIndex = readSingleByte();  // background color index  
		pixelAspect = readSingleByte();
	}
	
	/**
	 * Reads Netscape extenstion to obtain iteration count
	 */
	private function readNetscapeExt() : Void{
		do{
			readBlock();
			if (block[0] == 1) {
				// loop count sub-block
				var b1 : Int = (block[1]) & 0xff;
				var b2 : Int = (block[2]) & 0xff;
				loopCount = (b2 << 8) | b1;
			}
		}		while (((blockSize > 0) && !hasError()));
	}
	
	/**
	 * Reads next 16-bit value, LSB first
	 */
	private function readShort() : Int{
		// read 16-bit value, LSB first
		return readSingleByte() | (readSingleByte() << 8);
	}
	
	/**
	 * Resets frame state for reading next image.
	 */
	private function resetFrame() : Void{
		lastDispose = dispose;
		lastRect = new Rectangle(ix, iy, iw, ih);
		lastImage = image;
		lastBgColor = bgColor;
		// int dispose = 0;
		var transparency : Bool = false;
		var delay : Int = 0;
		lct = null;
	}
	
	/**
	 * Skips variable length blocks up to and including
	 * next zero length block.
	 */
	private function skip() : Void{
		do{
			readBlock();
		}		while (((blockSize > 0) && !hasError()));
	}

	public function new()
	{
	}
}

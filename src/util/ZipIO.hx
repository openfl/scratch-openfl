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

package util;

import flash.errors.Error;

import flash.utils.Endian;
import flash.utils.ByteArray;




class ZipIO
{

	private static inline var Version : Int = 10;
	private static inline var FileEntryID : Int = 0x04034b50;  // Local File Header Record  
	private static inline var DirEntryID : Int = 0x02014b50;  // Central Directory Record  
	private static inline var EndID : Int = 0x06054b50;  // End of Central Directory Record  

	private static var crcTable : Array<Dynamic> = makeCrcTable();

	private var buf : ByteArray;
	private var entries : Array<Dynamic> = [];
	private var writtenFiles : Dynamic = {};

	//************************************
	// Reading
	//************************************

	public function read(data : ByteArray) : Array<Dynamic>{
		// Read the given zip file data and return an array of [<name>, <data>] pairs.
		var i : Int;
		buf = data;
		buf.endian = Endian.LITTLE_ENDIAN;
		entries = [];
		scanForEndRecord();
		var entryCount : Int = readEndRecord();
		for (i in 0...entryCount){entries.push(readDirEntry());
		}
		var result : Array<Dynamic> = [];
		for (i in 0...entries.length){
			var e : Entry = entries[i];
			readFile(e);
			result.push([e.name, e.data]);
		}
		return result;
	}

	public function recover(data : ByteArray) : Array<Dynamic>{
		// Scan the zip file for file entries and return all the well-formed files.
		// This can be used to recover some of the files if the zip file is damaged.
		var result : Array<Dynamic> = [];
		buf = data;
		buf.endian = Endian.LITTLE_ENDIAN;
		for (i in 0...buf.length - 4){
			if (buf[i] == 0x50) {
				buf.position = i;
				if (buf.readUnsignedInt() == FileEntryID) {
					// Try to extract the file.
					var e : Entry = new Entry();
					e.offset = i;
					try{
						readFile(e, true);
					}                    catch (e : Dynamic){
						e = null;
					}
					if (e != null)                         result.push([e.name, e.data]);
				}
			}
		}
		return result;
	}

	private function readFile(e : Entry, recovering : Bool = false) : Void{
		// Read a local file header and the following file data.
		// Decompress the data if necessary, check the CRC, and record in e.data.
		buf.position = e.offset;
		if (buf.readUnsignedInt() != FileEntryID)             throw cast(("zip: bad local file header"), Error);
		var versionNeeded : Int = buf.readUnsignedShort();
		var flags : Int = buf.readUnsignedShort();
		var compressionMethod : Int = buf.readUnsignedShort();
		var dosTime : Int = buf.readUnsignedInt();
		var crc : Int = buf.readUnsignedInt();
		var compressedSize : Int = buf.readUnsignedInt();
		var uncompressedSize : Int = buf.readUnsignedInt();
		var nameLength : Int = buf.readUnsignedShort();
		var extraLength : Int = buf.readUnsignedShort();
		var fileName : String = buf.readUTFBytes(nameLength);
		var extra : ByteArray = new ByteArray();
		if (extraLength > 0)             buf.readBytes(extra, 0, extraLength);
		if ((flags & 1) != 0)             throw cast(("cannot read encrypted zip files"), Error);
		if ((compressionMethod != 0) && (compressionMethod != 8))             throw cast(("Cannot handle zip compression method " + compressionMethod), Error);
		if (!recovering && ((flags & 8) != 0)) {
			// use the sizes and crc values from directory (these values are also stored following the data)
			compressedSize = e.compressedSize;
			uncompressedSize = e.size;
			crc = e.crc;
		}
		e.name = fileName;
		e.data = new ByteArray();
		if (compressedSize > 0)             buf.readBytes(e.data, 0, compressedSize);
		if (compressionMethod == 8)             e.data.inflate();
		if (Std.int(e.data.length) != uncompressedSize)             throw cast(("Bad uncompressed size"), Error);
		if (crc != computeCRC(e.data))             throw cast(("Bad CRC"), Error);
	}

	private function readDirEntry() : Entry{
		if (buf.readUnsignedInt() != DirEntryID)             throw cast(("zip: bad central directory entry"), Error);
		var versionMadeBy : Int = buf.readUnsignedShort();
		var versionNeeded : Int = buf.readUnsignedShort();
		var flags : Int = buf.readUnsignedShort();
		var compressionMethod : Int = buf.readUnsignedShort();
		var dosTime : Int = buf.readUnsignedInt();
		var crc : Int = buf.readUnsignedInt();
		var compressedSize : Int = buf.readUnsignedInt();
		var uncompressedSize : Int = buf.readUnsignedInt();
		var nameLength : Int = buf.readUnsignedShort();
		var extraLength : Int = buf.readUnsignedShort();
		var commentLength : Int = buf.readUnsignedShort();
		var diskNum : Int = buf.readUnsignedShort();
		var internalAttributes : Int = buf.readUnsignedShort();
		var externalAttributes : Int = buf.readUnsignedInt();
		var offset : Int = buf.readUnsignedInt();
		var fileName : String = buf.readUTFBytes(nameLength);
		var extra : ByteArray = new ByteArray();
		if (extraLength > 0)             buf.readBytes(extra, 0, extraLength);
		var comment : String = buf.readUTFBytes(commentLength);
		var entry : Entry = new Entry();
		entry.name = fileName;
		entry.time = dosTime;
		entry.offset = offset;
		entry.size = uncompressedSize;
		entry.compressedSize = compressedSize;
		entry.crc = crc;
		return entry;
	}

	private function readEndRecord() : Int{
		// Read the end-of-central-directory record. If successful, set entryCount
		// and leave the buffer positioned at the start of the directory.
		if (buf.readUnsignedInt() != EndID)             throw cast(("zip: bad zip end record"), Error);
		var thisDiskNum : Int = buf.readUnsignedShort();
		var startDiskNum : Int = buf.readUnsignedShort();
		var entriesOnThisDisk : Int = buf.readUnsignedShort();
		var totalEntries : Int = buf.readUnsignedShort();
		var directorySize : Int = buf.readUnsignedInt();
		var directoryOffset : Int = buf.readUnsignedInt();
		var comment : String = buf.readUTF();
		if ((thisDiskNum != startDiskNum) || (entriesOnThisDisk != totalEntries)) {
			throw cast(("cannot read multiple disk zip files"), Error);
		}
		buf.position = directoryOffset;
		return totalEntries;
	}

	private function scanForEndRecord() : Void{
		// Scan backwards from the end to find the EndOfCentralDiretory record.
		// If successful, leave the buffer positioned at the start of the record.
		// Otherwise, throw an error.
		var i : Int = buf.length - 4;
		while (i >= 0){
			if (buf[i] == 0x50) {
				buf.position = i;
				if (buf.readUnsignedInt() == EndID) {
					buf.position = i;
					return;
				}
			}
			i--;
		}
		throw new Error("Could not find zip directory; bad zip file?");
	}

	//************************************
	// Writing
	//************************************

	public function startWrite() : Void{
		buf = new ByteArray();
		buf.endian = Endian.LITTLE_ENDIAN;
		entries = [];
		writtenFiles = {};
	}

	public function write(fileName : String, stringOrByteArray : Dynamic, useCompression : Bool = false) : Void{
		if (Reflect.field(writtenFiles, fileName) != null) {
			throw new Error("duplicate file name: " + fileName);
		}
		else {
			Reflect.setField(writtenFiles, fileName, true);
		}
		var e : Entry = new Entry();
		e.name = fileName;
		e.time = dosTime(Date.now().getTime());
		e.offset = buf.position;
		e.compressionMethod = 0;
		e.data = new ByteArray();
		if (Std.is(stringOrByteArray, String))             e.data.writeUTFBytes(Std.string(stringOrByteArray))
		else e.data.writeBytes(stringOrByteArray);
		e.size = e.data.length;
		e.crc = computeCRC(e.data);
		if (useCompression) {
			e.compressionMethod = 8;
			e.data.deflate();
		}
		e.compressedSize = e.data.length;
		entries.push(e);  // record the entry so it can be saved in the directory  

		// write the file header and data
		writeFileHeader(e);
		buf.writeBytes(e.data);
	}

	public function endWrite() : ByteArray{
		if (entries.length < 1)             throw new Error("A zip file must have at least one entry");
		var off : Int = buf.position;
		// write central directory
		for (i in 0...entries.length){
			writeDirectoryEntry(entries[i]);
		}
		writeEndRecord(off, buf.position - off);
		buf.position = 0;
		return buf;
	}

	private function writeFileHeader(e : Entry) : Void{
		buf.writeUnsignedInt(FileEntryID);
		buf.writeShort(Version);
		buf.writeShort(0);  // flags  
		buf.writeShort(e.compressionMethod);
		buf.writeUnsignedInt(e.time);
		buf.writeUnsignedInt(e.crc);
		buf.writeUnsignedInt(e.compressedSize);
		buf.writeUnsignedInt(e.size);
		buf.writeShort(e.name.length);
		buf.writeShort(0);  // extra info length  
		buf.writeUTFBytes(e.name);
	}

	private function writeDirectoryEntry(e : Entry) : Void{
		buf.writeUnsignedInt(DirEntryID);
		buf.writeShort(Version);  // version created by  
		buf.writeShort(Version);  // minimum version needed to extract  
		buf.writeShort(0);  // flags  
		buf.writeShort(e.compressionMethod);
		buf.writeUnsignedInt(e.time);
		buf.writeUnsignedInt(e.crc);
		buf.writeUnsignedInt(e.compressedSize);
		buf.writeUnsignedInt(e.size);
		buf.writeShort(e.name.length);
		buf.writeShort(0);  // extra info length  
		buf.writeShort(0);  // comment length  
		buf.writeShort(0);  // starting disk number  
		buf.writeShort(0);  // internal file attributes  
		buf.writeUnsignedInt(0);  // external file attributes  
		buf.writeUnsignedInt(e.offset);  // relative offset of local header  
		buf.writeUTFBytes(e.name);
	}

	private function writeEndRecord(dirStart : Int, dirSize : Int) : Void{
		buf.writeUnsignedInt(EndID);
		buf.writeShort(0);  // number of this disk  
		buf.writeShort(0);  // central directory start disk  
		buf.writeShort(entries.length);  // number of directory entries on this disk  
		buf.writeShort(entries.length);  // total number of directory entries  
		buf.writeUnsignedInt(dirSize);  // length of central directory in bytes  
		buf.writeUnsignedInt(dirStart);  // offset of central directory from start of file  
		buf.writeUTF("");
	}

	public function dosTime(time : Float) : Int{
		var d : Date = Date.fromTime(time);
		return (d.getFullYear() - 1980 & 0x7F) << 25 | (d.getMonth() + 1) << 21 | d.getDay() << 16 | d.getHours() << 11 | d.getMinutes() << 5 | d.getSeconds() >> 1;
	}

	private function computeCRC(buf : ByteArray) : Int{
		var off : Int = 0;
		var len : Int = buf.length;
		var crc : Int = 0xFFFFFFFF;  // = ~0  
		while (--len >= 0)crc = crcTable[(crc ^ buf[off++]) & 0xFF] ^ (crc >>> 8);
		return ~crc & 0xFFFFFFFF;
	}

	/* CRC table, computed at load time. */
	private static function makeCrcTable() : Array<Dynamic>{
		var crcTable : Array<Dynamic> = Compat.newArray(256, null); // new Array<Dynamic>(256);
		for (n in 0...256){
			var c : Int = n;
			for (i in 0...8){
				if ((c & 1) != 0)                     c = 0xedb88320 ^ (c >>> 1)
				else c = c >>> 1;
			}
			crcTable[n] = c;
		}
		return crcTable;
	}

	public function new()
	{
	}
}

class Entry
{
	public var name : String;
	public var time : Int;
	public var offset : Int;
	public var compressionMethod : Int;  // compression method (0 = uncompressed, 8 = deflate)  
	public var size : Int;
	public var compressedSize : Int;
	public var data : ByteArray;
	public var crc : Int;

	public function new()
	{
	}
}

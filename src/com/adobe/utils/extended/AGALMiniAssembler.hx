/*
Copyright (c) 2011, Adobe Systems Incorporated
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright notice, 
this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the 
documentation and/or other materials provided with the distribution.

* Neither the name of Adobe Systems Incorporated nor the names of its 
contributors may be used to endorse or promote products derived from 
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
package com.adobe.utils.extended;

import com.adobe.utils.extended.ByteArray;
import com.adobe.utils.extended.Context3D;
import com.adobe.utils.extended.Dictionary;
import com.adobe.utils.extended.Program3D;

// ===========================================================================
//	Imports
// ---------------------------------------------------------------------------
import flash.display3d.*;
import flash.utils.*;

// ===========================================================================
//	Class
// ---------------------------------------------------------------------------
class AGALMiniAssembler {
	public var error(get, never) : String;
	public var agalcode(get, never) : ByteArray;
  // ======================================================================  
	//	Constants
	// ----------------------------------------------------------------------
	private static var REGEXP_OUTER_SPACES : RegExp = new EReg('^\\s+|\\s+$', "g");
	
	// ======================================================================
	//	Properties
	// ----------------------------------------------------------------------
	// AGAL bytes and error buffer
	private var _agalcode : ByteArray = null;
	private var _error : String = "";
	
	private var debugEnabled : Bool = false;
	
	private static var initialized : Bool = false;
	public var verbose : Bool = false;
	
	// ======================================================================
	//	Getters
	// ----------------------------------------------------------------------
	private function get_Error() : String{return _error;
	}
	private function get_Agalcode() : ByteArray{return _agalcode;
	}
	
	// ======================================================================
	//	Constructor
	// ----------------------------------------------------------------------
	public function new(debugging : Bool = false)
	{
		debugEnabled = debugging;
		if (!initialized) 
			init();
	}
	// ======================================================================
	//	Methods
	// ----------------------------------------------------------------------
	
	public function assemble2(ctx3d : Context3D, version : UInt, vertexsrc : String, fragmentsrc : String) : Program3D
	{
		var agalvertex : ByteArray = assemble(VERTEX, vertexsrc, version);
		var agalfragment : ByteArray = assemble(FRAGMENT, fragmentsrc, version);
		var prog : Program3D = ctx3d.createProgram();
		prog.upload(agalvertex, agalfragment);
		return prog;
	}
	
	public function assemble(mode : String, source : String, version : UInt = 1, ignorelimits : Bool = false) : ByteArray
	{
		var start : UInt = Math.round(haxe.Timer.stamp() * 1000);
		
		_agalcode = new ByteArray();
		_error = "";
		
		var isFrag : Bool = false;
		
		if (mode == FRAGMENT) 
			isFrag = true
		else if (mode != VERTEX) 
			_error = "ERROR: mode needs to be \"" + FRAGMENT + "\" or \"" + VERTEX + "\" but is \"" + mode + "\".";
		
		agalcode.endian = Endian.LITTLE_ENDIAN;
		agalcode.writeByte(0xa0);  // tag version  
		agalcode.writeUnsignedInt(version);  // AGAL version, big endian, bit pattern will be 0x01000000  
		agalcode.writeByte(0xa1);  // tag program id  
		agalcode.writeByte((isFrag) ? 1 : 0);  // vertex or fragment  
		
		initregmap(version, ignorelimits);
		
		var lines : Array<Dynamic> = source.replace(new EReg('[\\f\\n\\r\\v]+', "g"), "\n").split("\n");
		var nest : Int = 0;
		var nops : Int = 0;
		var i : Int;
		var lng : Int = lines.length;
		
		for (i in 0..._error == ""){
			var line : String = new String(lines[i]);
			line = line.replace(REGEXP_OUTER_SPACES, "");
			
			// remove comments
			var startcomment : Int = line.search("//");
			if (startcomment != -1) 
				line = line.substring(0, startcomment)  // grab options  ;
			
			
			
			var optsi : Int = line.search(new EReg('<.*>', "g"));
			var opts : Array<Dynamic>;
			if (optsi != -1) 
			{
				opts = line.substring(optsi).match(new EReg('([\\w\\.\\-\\+]+)', "gi"));
				line = line.substring(0, optsi);
			}  // find opcode  
			
			
			
			var opCode : Array<Dynamic> = line.match(new EReg('^\\w{3}', "ig"));
			if (opCode == null) 
			{
				if (line.length >= 3) 
					trace("warning: bad line " + i + ": " + lines[i]);
				{i++;continue;
				}
			}
			var opFound : OpCode = OPMAP[opCode[0]];
			
			// if debug is enabled, output the opcodes
			if (debugEnabled) 
				trace(opFound);
			
			if (opFound == null) 
			{
				if (line.length >= 3) 
					trace("warning: bad line " + i + ": " + lines[i]);
				{i++;continue;
				}
			}
			
			line = line.substring(line.search(opFound.name) + opFound.name.length);
			
			if ((opFound.flags & OP_VERSION2 != 0) && version < 2) 
			{
				_error = "error: opcode requires version 2.";
				break;
			}
			
			if ((opFound.flags & OP_VERT_ONLY != 0) && isFrag) 
			{
				_error = "error: opcode is only allowed in vertex programs.";
				break;
			}
			
			if ((opFound.flags & OP_FRAG_ONLY != 0) && !isFrag) 
			{
				_error = "error: opcode is only allowed in fragment programs.";
				break;
			}
			if (verbose) 
				trace("emit opcode=" + opFound);
			
			agalcode.writeUnsignedInt(opFound.emitCode);
			nops++;
			
			if (nops > MAX_OPCODES) 
			{
				_error = "error: too many opcodes. maximum is " + MAX_OPCODES + ".";
				break;
			}  // get operands, use regexp  
			
			
			
			var regs : Array<Dynamic>;
			
			// will match both syntax
			regs = line.match(new EReg('vc\\[([vof][acostdip]?)(\\d*)?(\\.[xyzw](\\+\\d{1,3})?)?\\](\\.[xyzw]{1,4})?|([vof][acostdip]?)(\\d*)?(\\.[xyzw]{1,4})?', "gi"));
			
			if (regs == null || regs.length != opFound.numRegister) 
			{
				_error = "error: wrong number of operands. found " + regs.length + " but expected " + opFound.numRegister + ".";
				break;
			}
			
			var badreg : Bool = false;
			var pad : UInt = 64 + 64 + 32;
			var regLength : UInt = regs.length;
			
			for (j in 0...regLength){
				var isRelative : Bool = false;
				var relreg : Array<Dynamic> = regs[j].match(new EReg('\\[.*\\]', "ig"));
				if (relreg != null && relreg.length > 0) 
				{
					regs[j] = regs[j].replace(relreg[0], "0");
					
					if (verbose) 
						trace("IS REL");
					isRelative = true;
				}
				
				var res : Array<Dynamic> = regs[j].match(new EReg('^\\b[A-Za-z]{1,2}', "ig"));
				if (res == null) 
				{
					_error = "error: could not parse operand " + j + " (" + regs[j] + ").";
					badreg = true;
					break;
				}
				var regFound : Register = REGMAP[res[0]];
				
				// if debug is enabled, output the registers
				if (debugEnabled) 
					trace(regFound);
				
				if (regFound == null) 
				{
					_error = "error: could not find register name for operand " + j + " (" + regs[j] + ").";
					badreg = true;
					break;
				}
				
				if (isFrag) 
				{
					if (!(regFound.flags & REG_FRAG)) 
					{
						_error = "error: register operand " + j + " (" + regs[j] + ") only allowed in vertex programs.";
						badreg = true;
						break;
					}
					if (isRelative) 
					{
						_error = "error: register operand " + j + " (" + regs[j] + ") relative adressing not allowed in fragment programs.";
						badreg = true;
						break;
					}
				}
				else 
				{
					if (!(regFound.flags & REG_VERT)) 
					{
						_error = "error: register operand " + j + " (" + regs[j] + ") only allowed in fragment programs.";
						badreg = true;
						break;
					}
				}
				
				regs[j] = regs[j].substring(regs[j].search(regFound.name) + regFound.name.length);
				//trace( "REGNUM: " +regs[j] );
				var idxmatch : Array<Dynamic> = (isRelative) ? relreg[0].match(new EReg('\\d+', "")) : regs[j].match(new EReg('\\d+', ""));
				var regidx : UInt = 0;
				
				if (idxmatch != null) 
					regidx = UInt(idxmatch[0]);
				
				if (regFound.range < regidx) 
				{
					_error = "error: register operand " + j + " (" + regs[j] + ") index exceeds limit of " + (regFound.range + 1) + ".";
					badreg = true;
					break;
				}
				
				var regmask : UInt = 0;
				var maskmatch : Array<Dynamic> = regs[j].match(new EReg('(\\.[xyzw]{1,4})', ""));
				var isDest : Bool = (j == 0 && !(opFound.flags & OP_NO_DEST));
				var isSampler : Bool = (j == 2 && (opFound.flags & OP_SPECIAL_TEX));
				var reltype : UInt = 0;
				var relsel : UInt = 0;
				var reloffset : Int = 0;
				
				if (isDest && isRelative) 
				{
					_error = "error: relative can not be destination";
					badreg = true;
					break;
				}
				
				if (maskmatch != null) 
				{
					regmask = 0;
					var cv : UInt;
					var maskLength : UInt = maskmatch[0].length;
					for (k in 1...maskLength){
						cv = maskmatch[0].charCodeAt(k) - "x".charCodeAt(0);
						if (cv > 2) 
							cv = 3;
						if (isDest) 
							regmask |= 1 << cv
						else 
						regmask |= cv << ((k - 1) << 1);
					}
					if (!isDest) 
											while (k <= 4){regmask |= cv << ((k - 1) << 1);
						k++;
					}  // repeat last  ;
				}
				else 
				{
					regmask = (isDest) ? 0xf : 0xe4;
				}
				
				if (isRelative) 
				{
					var relname : Array<Dynamic> = relreg[0].match(new EReg('[A-Za-z]{1,2}', "ig"));
					var regFoundRel : Register = REGMAP[relname[0]];
					if (regFoundRel == null) 
					{
						_error = "error: bad index register";
						badreg = true;
						break;
					}
					reltype = regFoundRel.emitCode;
					var selmatch : Array<Dynamic> = relreg[0].match(new EReg('(\\.[xyzw]{1,1})', ""));
					if (selmatch.length == 0) 
					{
						_error = "error: bad index register select";
						badreg = true;
						break;
					}
					relsel = selmatch[0].charCodeAt(1) - "x".charCodeAt(0);
					if (relsel > 2) 
						relsel = 3;
					var relofs : Array<Dynamic> = relreg[0].match(new EReg('\\+\\d{1,3}', "ig"));
					if (relofs.length > 0) 
						reloffset = relofs[0];
					if (reloffset < 0 || reloffset > 255) 
					{
						_error = "error: index offset " + reloffset + " out of bounds. [0..255]";
						badreg = true;
						break;
					}
					if (verbose) 
						trace("RELATIVE: type=" + reltype + "==" + relname[0] + " sel=" + relsel + "==" + selmatch[0] + " idx=" + regidx + " offset=" + reloffset);
				}
				
				if (verbose) 
					trace("  emit argcode=" + regFound + "[" + regidx + "][" + regmask + "]");
				if (isDest) 
				{
					agalcode.writeShort(regidx);
					agalcode.writeByte(regmask);
					agalcode.writeByte(regFound.emitCode);
					pad -= 32;
				}
				else 
				{
					if (isSampler) 
					{
						if (verbose) 
							trace("  emit sampler");
						var samplerbits : UInt = 5;  // type 5  
						var optsLength : UInt = opts == (null) ? 0 : opts.length;
						var bias : Float = 0;
						for (k in 0...optsLength){
							if (verbose) 
								trace("    opt: " + opts[k]);
							var optfound : Sampler = SAMPLEMAP[opts[k]];
							if (optfound == null) 
							{
								// todo check that it's a number...
								//trace( "Warning, unknown sampler option: "+opts[k] );
								bias = Std.parseFloat(opts[k]);
								if (verbose) 
									trace("    bias: " + bias);
							}
							else 
							{
								if (optfound.flag != SAMPLER_SPECIAL_SHIFT) 
									samplerbits &= ~(0xf << optfound.flag);
								samplerbits |= UInt(optfound.mask) << UInt(optfound.flag);
							}
						}
						agalcode.writeShort(regidx);
						agalcode.writeByte(as3hx.Compat.parseInt(bias * 8.0));
						agalcode.writeByte(0);
						agalcode.writeUnsignedInt(samplerbits);
						
						if (verbose) 
							trace("    bits: " + (samplerbits - 5));
						pad -= 64;
					}
					else 
					{
						if (j == 0) 
						{
							agalcode.writeUnsignedInt(0);
							pad -= 32;
						}
						agalcode.writeShort(regidx);
						agalcode.writeByte(reloffset);
						agalcode.writeByte(regmask);
						agalcode.writeByte(regFound.emitCode);
						agalcode.writeByte(reltype);
						agalcode.writeShort((isRelative) ? (relsel | (1 << 15)) : 0);
						
						pad -= 64;
					}
				}
			}  // pad unused regs  
			
			
			
			j = 0;
			while (j < pad){agalcode.writeByte(0);
				j += 8;
			}
			
			if (badreg) 
				break;
		}
		
		if (_error != "") 
		{
			_error += "\n  at line " + i + " " + lines[i];
			agalcode.length = 0;
			trace(_error);
		}  // trace the bytecode bytes if debugging is enabled  
		
		
		
		if (debugEnabled) 
		{
			var dbgLine : String = "generated bytecode:";
			var agalLength : UInt = agalcode.length;
			for (index in 0...agalLength){
				if (!(index % 16)) 
					dbgLine += "\n";
				if (!(index % 4)) 
					dbgLine += " ";
				
				var byteStr : String = Std.string(agalcode[index]);
				if (byteStr.length < 2) 
					byteStr = "0" + byteStr;
				
				dbgLine += byteStr;
			}
			trace(dbgLine);
		}
		
		if (verbose) 
			trace("AGALMiniAssembler.assemble time: " + ((Math.round(haxe.Timer.stamp() * 1000) - start) / 1000) + "s");
		
		return agalcode;
	}
	
	private function initregmap(version : UInt, ignorelimits : Bool) : Void{
		// version changes limits
		REGMAP[VA] = new Register(VA, "vertex attribute", 0x0, (ignorelimits) ? 1024 : 7, REG_VERT | REG_READ);
		REGMAP[VC] = new Register(VC, "vertex constant", 0x1, (ignorelimits) ? 1024 : (version == (1) ? 127 : 249), REG_VERT | REG_READ);
		REGMAP[VT] = new Register(VT, "vertex temporary", 0x2, (ignorelimits) ? 1024 : (version == (1) ? 7 : 25), REG_VERT | REG_WRITE | REG_READ);
		REGMAP[VO] = new Register(VO, "vertex output", 0x3, (ignorelimits) ? 1024 : 0, REG_VERT | REG_WRITE);
		REGMAP[VI] = new Register(VI, "varying", 0x4, (ignorelimits) ? 1024 : (version == (1) ? 7 : 9), REG_VERT | REG_FRAG | REG_READ | REG_WRITE);
		REGMAP[FC] = new Register(FC, "fragment constant", 0x1, (ignorelimits) ? 1024 : (version == (1) ? 27 : 63), REG_FRAG | REG_READ);
		REGMAP[FT] = new Register(FT, "fragment temporary", 0x2, (ignorelimits) ? 1024 : (version == (1) ? 7 : 25), REG_FRAG | REG_WRITE | REG_READ);
		REGMAP[FS] = new Register(FS, "texture sampler", 0x5, (ignorelimits) ? 1024 : 7, REG_FRAG | REG_READ);
		REGMAP[FO] = new Register(FO, "fragment output", 0x3, (ignorelimits) ? 1024 : (version == (1) ? 0 : 3), REG_FRAG | REG_WRITE);
		REGMAP[FD] = new Register(FD, "fragment depth output", 0x6, (ignorelimits) ? 1024 : (version == (1) ? -1 : 0), REG_FRAG | REG_WRITE);
		
		// aliases
		REGMAP["op"] = REGMAP[VO];
		REGMAP["i"] = REGMAP[VI];
		REGMAP["v"] = REGMAP[VI];
		REGMAP["oc"] = REGMAP[FO];
		REGMAP["od"] = REGMAP[FD];
		REGMAP["fi"] = REGMAP[VI];
	}
	
	private static function init() : Void
	{
		initialized = true;
		
		// Fill the dictionaries with opcodes and registers
		OPMAP[MOV] = new OpCode(MOV, 2, 0x00, 0);
		OPMAP[ADD] = new OpCode(ADD, 3, 0x01, 0);
		OPMAP[SUB] = new OpCode(SUB, 3, 0x02, 0);
		OPMAP[MUL] = new OpCode(MUL, 3, 0x03, 0);
		OPMAP[DIV] = new OpCode(DIV, 3, 0x04, 0);
		OPMAP[RCP] = new OpCode(RCP, 2, 0x05, 0);
		OPMAP[MIN] = new OpCode(MIN, 3, 0x06, 0);
		OPMAP[MAX] = new OpCode(MAX, 3, 0x07, 0);
		OPMAP[FRC] = new OpCode(FRC, 2, 0x08, 0);
		OPMAP[SQT] = new OpCode(SQT, 2, 0x09, 0);
		OPMAP[RSQ] = new OpCode(RSQ, 2, 0x0a, 0);
		OPMAP[POW] = new OpCode(POW, 3, 0x0b, 0);
		OPMAP[LOG] = new OpCode(LOG, 2, 0x0c, 0);
		OPMAP[EXP] = new OpCode(EXP, 2, 0x0d, 0);
		OPMAP[NRM] = new OpCode(NRM, 2, 0x0e, 0);
		OPMAP[SIN] = new OpCode(SIN, 2, 0x0f, 0);
		OPMAP[COS] = new OpCode(COS, 2, 0x10, 0);
		OPMAP[CRS] = new OpCode(CRS, 3, 0x11, 0);
		OPMAP[DP3] = new OpCode(DP3, 3, 0x12, 0);
		OPMAP[DP4] = new OpCode(DP4, 3, 0x13, 0);
		OPMAP[ABS] = new OpCode(ABS, 2, 0x14, 0);
		OPMAP[NEG] = new OpCode(NEG, 2, 0x15, 0);
		OPMAP[SAT] = new OpCode(SAT, 2, 0x16, 0);
		OPMAP[M33] = new OpCode(M33, 3, 0x17, OP_SPECIAL_MATRIX);
		OPMAP[M44] = new OpCode(M44, 3, 0x18, OP_SPECIAL_MATRIX);
		OPMAP[M34] = new OpCode(M34, 3, 0x19, OP_SPECIAL_MATRIX);
		OPMAP[DDX] = new OpCode(DDX, 2, 0x1a, OP_VERSION2 | OP_FRAG_ONLY);
		OPMAP[DDY] = new OpCode(DDY, 2, 0x1b, OP_VERSION2 | OP_FRAG_ONLY);
		OPMAP[IFE] = new OpCode(IFE, 2, 0x1c, OP_NO_DEST | OP_VERSION2 | OP_INCNEST | OP_SCALAR);
		OPMAP[INE] = new OpCode(INE, 2, 0x1d, OP_NO_DEST | OP_VERSION2 | OP_INCNEST | OP_SCALAR);
		OPMAP[IFG] = new OpCode(IFG, 2, 0x1e, OP_NO_DEST | OP_VERSION2 | OP_INCNEST | OP_SCALAR);
		OPMAP[IFL] = new OpCode(IFL, 2, 0x1f, OP_NO_DEST | OP_VERSION2 | OP_INCNEST | OP_SCALAR);
		OPMAP[ELS] = new OpCode(ELS, 0, 0x20, OP_NO_DEST | OP_VERSION2 | OP_INCNEST | OP_DECNEST | OP_SCALAR);
		OPMAP[EIF] = new OpCode(EIF, 0, 0x21, OP_NO_DEST | OP_VERSION2 | OP_DECNEST | OP_SCALAR);
		// space
		//OPMAP[ TED ] = new OpCode( TED, 3, 0x26, OP_FRAG_ONLY | OP_SPECIAL_TEX | OP_VERSION2);	//ted is not available in AGAL2
		OPMAP[KIL] = new OpCode(KIL, 1, 0x27, OP_NO_DEST | OP_FRAG_ONLY);
		OPMAP[TEX] = new OpCode(TEX, 3, 0x28, OP_FRAG_ONLY | OP_SPECIAL_TEX);
		OPMAP[SGE] = new OpCode(SGE, 3, 0x29, 0);
		OPMAP[SLT] = new OpCode(SLT, 3, 0x2a, 0);
		OPMAP[SGN] = new OpCode(SGN, 2, 0x2b, 0);
		OPMAP[SEQ] = new OpCode(SEQ, 3, 0x2c, 0);
		OPMAP[SNE] = new OpCode(SNE, 3, 0x2d, 0);
		
		
		SAMPLEMAP[RGBA] = new Sampler(RGBA, SAMPLER_TYPE_SHIFT, 0);
		SAMPLEMAP[DXT1] = new Sampler(DXT1, SAMPLER_TYPE_SHIFT, 1);
		SAMPLEMAP[DXT5] = new Sampler(DXT5, SAMPLER_TYPE_SHIFT, 2);
		SAMPLEMAP[VIDEO] = new Sampler(VIDEO, SAMPLER_TYPE_SHIFT, 3);
		SAMPLEMAP[D2] = new Sampler(D2, SAMPLER_DIM_SHIFT, 0);
		SAMPLEMAP[D3] = new Sampler(D3, SAMPLER_DIM_SHIFT, 2);
		SAMPLEMAP[CUBE] = new Sampler(CUBE, SAMPLER_DIM_SHIFT, 1);
		SAMPLEMAP[MIPNEAREST] = new Sampler(MIPNEAREST, SAMPLER_MIPMAP_SHIFT, 1);
		SAMPLEMAP[MIPLINEAR] = new Sampler(MIPLINEAR, SAMPLER_MIPMAP_SHIFT, 2);
		SAMPLEMAP[MIPNONE] = new Sampler(MIPNONE, SAMPLER_MIPMAP_SHIFT, 0);
		SAMPLEMAP[NOMIP] = new Sampler(NOMIP, SAMPLER_MIPMAP_SHIFT, 0);
		SAMPLEMAP[NEAREST] = new Sampler(NEAREST, SAMPLER_FILTER_SHIFT, 0);
		SAMPLEMAP[LINEAR] = new Sampler(LINEAR, SAMPLER_FILTER_SHIFT, 1);
		SAMPLEMAP[ANISOTROPIC2X] = new Sampler(ANISOTROPIC2X, SAMPLER_FILTER_SHIFT, 2);
		SAMPLEMAP[ANISOTROPIC4X] = new Sampler(ANISOTROPIC4X, SAMPLER_FILTER_SHIFT, 3);
		SAMPLEMAP[ANISOTROPIC8X] = new Sampler(ANISOTROPIC8X, SAMPLER_FILTER_SHIFT, 4);
		SAMPLEMAP[ANISOTROPIC16X] = new Sampler(ANISOTROPIC16X, SAMPLER_FILTER_SHIFT, 5);
		SAMPLEMAP[CENTROID] = new Sampler(CENTROID, SAMPLER_SPECIAL_SHIFT, 1 << 0);
		SAMPLEMAP[SINGLE] = new Sampler(SINGLE, SAMPLER_SPECIAL_SHIFT, 1 << 1);
		SAMPLEMAP[IGNORESAMPLER] = new Sampler(IGNORESAMPLER, SAMPLER_SPECIAL_SHIFT, 1 << 2);
		SAMPLEMAP[REPEAT] = new Sampler(REPEAT, SAMPLER_REPEAT_SHIFT, 1);
		SAMPLEMAP[WRAP] = new Sampler(WRAP, SAMPLER_REPEAT_SHIFT, 1);
		SAMPLEMAP[CLAMP] = new Sampler(CLAMP, SAMPLER_REPEAT_SHIFT, 0);
		SAMPLEMAP[CLAMP_U_REPEAT_V] = new Sampler(CLAMP_U_REPEAT_V, SAMPLER_REPEAT_SHIFT, 2);
		SAMPLEMAP[REPEAT_U_CLAMP_V] = new Sampler(REPEAT_U_CLAMP_V, SAMPLER_REPEAT_SHIFT, 3);
	}
	
	// ======================================================================
	//	Constants
	// ----------------------------------------------------------------------
	private static var OPMAP : Dictionary = new Dictionary();
	private static var REGMAP : Dictionary = new Dictionary();
	private static var SAMPLEMAP : Dictionary = new Dictionary();
	
	private static inline var MAX_NESTING : Int = 4;
	private static inline var MAX_OPCODES : Int = 2048;
	
	private static inline var FRAGMENT : String = "fragment";
	private static inline var VERTEX : String = "vertex";
	
	// masks and shifts
	private static inline var SAMPLER_TYPE_SHIFT : UInt = 8;
	private static inline var SAMPLER_DIM_SHIFT : UInt = 12;
	private static inline var SAMPLER_SPECIAL_SHIFT : UInt = 16;
	private static inline var SAMPLER_REPEAT_SHIFT : UInt = 20;
	private static inline var SAMPLER_MIPMAP_SHIFT : UInt = 24;
	private static inline var SAMPLER_FILTER_SHIFT : UInt = 28;
	
	// regmap flags
	private static inline var REG_WRITE : UInt = 0x1;
	private static inline var REG_READ : UInt = 0x2;
	private static inline var REG_FRAG : UInt = 0x20;
	private static inline var REG_VERT : UInt = 0x40;
	
	// opmap flags
	private static inline var OP_SCALAR : UInt = 0x1;
	private static inline var OP_SPECIAL_TEX : UInt = 0x8;
	private static inline var OP_SPECIAL_MATRIX : UInt = 0x10;
	private static inline var OP_FRAG_ONLY : UInt = 0x20;
	private static inline var OP_VERT_ONLY : UInt = 0x40;
	private static inline var OP_NO_DEST : UInt = 0x80;
	private static inline var OP_VERSION2 : UInt = 0x100;
	private static inline var OP_INCNEST : UInt = 0x200;
	private static inline var OP_DECNEST : UInt = 0x400;
	
	// opcodes
	private static inline var MOV : String = "mov";
	private static inline var ADD : String = "add";
	private static inline var SUB : String = "sub";
	private static inline var MUL : String = "mul";
	private static inline var DIV : String = "div";
	private static inline var RCP : String = "rcp";
	private static inline var MIN : String = "min";
	private static inline var MAX : String = "max";
	private static inline var FRC : String = "frc";
	private static inline var SQT : String = "sqt";
	private static inline var RSQ : String = "rsq";
	private static inline var POW : String = "pow";
	private static inline var LOG : String = "log";
	private static inline var EXP : String = "exp";
	private static inline var NRM : String = "nrm";
	private static inline var SIN : String = "sin";
	private static inline var COS : String = "cos";
	private static inline var CRS : String = "crs";
	private static inline var DP3 : String = "dp3";
	private static inline var DP4 : String = "dp4";
	private static inline var ABS : String = "abs";
	private static inline var NEG : String = "neg";
	private static inline var SAT : String = "sat";
	private static inline var M33 : String = "m33";
	private static inline var M44 : String = "m44";
	private static inline var M34 : String = "m34";
	private static inline var DDX : String = "ddx";
	private static inline var DDY : String = "ddy";
	private static inline var IFE : String = "ife";
	private static inline var INE : String = "ine";
	private static inline var IFG : String = "ifg";
	private static inline var IFL : String = "ifl";
	private static inline var ELS : String = "els";
	private static inline var EIF : String = "eif";
	private static inline var TED : String = "ted";
	private static inline var KIL : String = "kil";
	private static inline var TEX : String = "tex";
	private static inline var SGE : String = "sge";
	private static inline var SLT : String = "slt";
	private static inline var SGN : String = "sgn";
	private static inline var SEQ : String = "seq";
	private static inline var SNE : String = "sne";
	
	// registers
	private static inline var VA : String = "va";
	private static inline var VC : String = "vc";
	private static inline var VT : String = "vt";
	private static inline var VO : String = "vo";
	private static inline var VI : String = "vi";
	private static inline var FC : String = "fc";
	private static inline var FT : String = "ft";
	private static inline var FS : String = "fs";
	private static inline var FO : String = "fo";
	private static inline var FD : String = "fd";
	
	// samplers
	private static inline var D2 : String = "2d";
	private static inline var D3 : String = "3d";
	private static inline var CUBE : String = "cube";
	private static inline var MIPNEAREST : String = "mipnearest";
	private static inline var MIPLINEAR : String = "miplinear";
	private static inline var MIPNONE : String = "mipnone";
	private static inline var NOMIP : String = "nomip";
	private static inline var NEAREST : String = "nearest";
	private static inline var LINEAR : String = "linear";
	private static inline var ANISOTROPIC2X : String = "anisotropic2x";  //Introduced by Flash 14  
	private static inline var ANISOTROPIC4X : String = "anisotropic4x";  //Introduced by Flash 14  
	private static inline var ANISOTROPIC8X : String = "anisotropic8x";  //Introduced by Flash 14  
	private static inline var ANISOTROPIC16X : String = "anisotropic16x";  //Introduced by Flash 14  
	private static inline var CENTROID : String = "centroid";
	private static inline var SINGLE : String = "single";
	private static inline var IGNORESAMPLER : String = "ignoresampler";
	private static inline var REPEAT : String = "repeat";
	private static inline var WRAP : String = "wrap";
	private static inline var CLAMP : String = "clamp";
	private static inline var REPEAT_U_CLAMP_V : String = "repeat_u_clamp_v";  //Introduced by Flash 13  
	private static inline var CLAMP_U_REPEAT_V : String = "clamp_u_repeat_v";  //Introduced by Flash 13  
	private static inline var RGBA : String = "rgba";
	private static inline var DXT1 : String = "dxt1";
	private static inline var DXT5 : String = "dxt5";
	private static inline var VIDEO : String = "video";
}


// ================================================================================
//	Helper Classes
// --------------------------------------------------------------------------------

// ===========================================================================
//	Class
// ---------------------------------------------------------------------------
class OpCode {
	public var emitCode(get, never) : UInt;
	public var flags(get, never) : UInt;
	public var name(get, never) : String;
	public var numRegister(get, never) : UInt;

	// ======================================================================
	//	Properties
	// ----------------------------------------------------------------------
	private var _emitCode : UInt;
	private var _flags : UInt;
	private var _name : String;
	private var _numRegister : UInt;
	
	// ======================================================================
	//	Getters
	// ----------------------------------------------------------------------
	private function get_EmitCode() : UInt{return _emitCode;
	}
	private function get_Flags() : UInt{return _flags;
	}
	private function get_Name() : String{return _name;
	}
	private function get_NumRegister() : UInt{return _numRegister;
	}
	
	// ======================================================================
	//	Constructor
	// ----------------------------------------------------------------------
	public function new(name : String, numRegister : UInt, emitCode : UInt, flags : UInt)
	{
		_name = name;
		_numRegister = numRegister;
		_emitCode = emitCode;
		_flags = flags;
	}
	
	// ======================================================================
	//	Methods
	// ----------------------------------------------------------------------
	public function toString() : String
	{
		return "[OpCode name=\"" + _name + "\", numRegister=" + _numRegister + ", emitCode=" + _emitCode + ", flags=" + _flags + "]";
	}
}

// ===========================================================================
//	Class
// ---------------------------------------------------------------------------
class Register {
	public var emitCode(get, never) : UInt;
	public var longName(get, never) : String;
	public var name(get, never) : String;
	public var flags(get, never) : UInt;
	public var range(get, never) : UInt;

	// ======================================================================
	//	Properties
	// ----------------------------------------------------------------------
	private var _emitCode : UInt;
	private var _name : String;
	private var _longName : String;
	private var _flags : UInt;
	private var _range : UInt;
	
	// ======================================================================
	//	Getters
	// ----------------------------------------------------------------------
	private function get_EmitCode() : UInt{return _emitCode;
	}
	private function get_LongName() : String{return _longName;
	}
	private function get_Name() : String{return _name;
	}
	private function get_Flags() : UInt{return _flags;
	}
	private function get_Range() : UInt{return _range;
	}
	
	// ======================================================================
	//	Constructor
	// ----------------------------------------------------------------------
	public function new(name : String, longName : String, emitCode : UInt, range : UInt, flags : UInt)
	{
		_name = name;
		_longName = longName;
		_emitCode = emitCode;
		_range = range;
		_flags = flags;
	}
	
	// ======================================================================
	//	Methods
	// ----------------------------------------------------------------------
	public function toString() : String
	{
		return "[Register name=\"" + _name + "\", longName=\"" + _longName + "\", emitCode=" + _emitCode + ", range=" + _range + ", flags=" + _flags + "]";
	}
}

// ===========================================================================
//	Class
// ---------------------------------------------------------------------------
class Sampler {
	public var flag(get, never) : UInt;
	public var mask(get, never) : UInt;
	public var name(get, never) : String;

	// ======================================================================
	//	Properties
	// ----------------------------------------------------------------------
	private var _flag : UInt;
	private var _mask : UInt;
	private var _name : String;
	
	// ======================================================================
	//	Getters
	// ----------------------------------------------------------------------
	private function get_Flag() : UInt{return _flag;
	}
	private function get_Mask() : UInt{return _mask;
	}
	private function get_Name() : String{return _name;
	}
	
	// ======================================================================
	//	Constructor
	// ----------------------------------------------------------------------
	public function new(name : String, flag : UInt, mask : UInt)
	{
		_name = name;
		_flag = flag;
		_mask = mask;
	}
	
	// ======================================================================
	//	Methods
	// ----------------------------------------------------------------------
	public function toString() : String
	{
		return "[Sampler name=\"" + _name + "\", flag=\"" + _flag + "\", mask=" + mask + "]";
	}
}

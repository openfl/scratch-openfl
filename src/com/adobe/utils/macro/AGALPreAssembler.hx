package com.adobe.utils.macro;

import com.adobe.utils.macro.Expression;
import com.adobe.utils.macro.ExpressionParser;
import com.adobe.utils.macro.VM;
import nme.errors.Error;

import flash.utils.Dictionary;

/*
 * 	The AGALPreAssembler implements a pre-processing language for AGAL.
 *  The preprocessor is interpreted at compile time, which allows
 *  run time generation of different shader types, often from one
 *  main shader.
 * 
<pre>
Language:
#define FOO num
#define FOO
#undef FOO	

#if <expression>
#elif <expression>
#else
#endif	
</pre>
*/

class AGALPreAssembler {
	public static var TRACE_VM : Bool = false;
	public static var TRACE_AST : Bool = false;
	public static var TRACE_PREPROC : Bool = false;
	
	private var vm : VM = new VM();
	private var expressionParser : ExpressionParser = new ExpressionParser();
	
	public function new()
	{
		
	}
	
	public function processLine(tokens : Array<String>, types : String) : Bool
	{
		// read per-line. Either handle:
		//	- preprocessor tags (and call the proprocessor 'vm')
		//  - check the current 'if' state and stream out tokens.
		
		var slot : String = "";
		var num : Float;
		var exp : Expression = null;
		var result : Float;
		var pos : Int = 0;
		
		if (types.charAt(pos) == "#") {
			slot = "";
			num = Float.NaN;
			
			if (tokens[pos] == "#define") {
				// #define FOO 1
				// #define FOO
				// #define FOO=1
				if (types.length >= 3 && types.substr(pos, 3) == "#in") {
					slot = tokens[pos + 1];
					vm.vars[slot] = Float.NaN;
					if (TRACE_PREPROC) {
						trace("#define #i");
					}
					pos += 3;
				}
				else if (types.length >= 3 && types.substr(pos, 3) == "#i=") {
					exp = expressionParser.parse(tokens.substring(3), types.substr(3));
					exp.exec(vm);
					result = vm.stack.pop();
					
					slot = tokens[pos + 1];
					vm.vars[slot] = result;
					
					if (TRACE_PREPROC) {
						trace("#define= " + slot + "=" + result);
					}
				}
				else {
					exp = expressionParser.parse(tokens.substring(2), types.substr(2));
					exp.exec(vm);
					result = vm.stack.pop();
					
					slot = tokens[pos + 1];
					vm.vars[slot] = result;
					
					if (TRACE_PREPROC) {
						trace("#define " + slot + "=" + result);
					}
				}
			}
			else if (tokens[pos] == "#undef") {
				slot = tokens[pos + 1];
				vm.vars[slot] = null;
				if (TRACE_PREPROC) {
					trace("#undef");
				}
				pos += 3;
			}
			else if (tokens[pos] == "#if") {
				++pos;
				exp = expressionParser.parse(tokens.substring(1), types.substr(1));
				
				vm.pushIf();
				
				exp.exec(vm);
				result = vm.stack.pop();
				vm.setIf(result);
				if (TRACE_PREPROC) {
					trace("#if " + (((result != 0)) ? "true" : "false"));
				}
			}
			else if (tokens[pos] == "#elif") {
				++pos;
				exp = expressionParser.parse(tokens.substring(1), types.substr(1));
				
				exp.exec(vm);
				result = vm.stack.pop();
				vm.setIf(result);
				if (TRACE_PREPROC) {
					trace("#elif " + (((result != 0)) ? "true" : "false"));
				}
			}
			else if (tokens[pos] == "#else") {
				++pos;
				vm.setIf((vm.ifWasTrue()) ? 0 : 1);
				if (TRACE_PREPROC) {
					trace("#else " + (((vm.ifWasTrue())) ? "true" : "false"));
				}
			}
			// eat the newlines
			else if (tokens[pos] == "#endif") {
				vm.popEndif();
				++pos;
				if (TRACE_PREPROC) {
					trace("#endif");
				}
			}
			else {
				throw new Error("unrecognize processor directive.");
			}
			
			
			
			while (pos < types.length && types.charAt(pos) == "n"){
				++pos;
			}
		}
		else {
			throw new Error("PreProcessor called without pre processor directive.");
		}
		return vm.ifIsTrue();
	}
}


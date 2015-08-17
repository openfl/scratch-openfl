package com.adobe.utils.macro;

import com.adobe.utils.macro.NumberExpression;
import com.adobe.utils.macro.UnaryExpression;
import com.adobe.utils.macro.VariableExpression;
import nme.errors.Error;

/*
The parse is based on Dijkstra's shunting yard:
http://en.wikipedia.org/wiki/Shunting_yard_algorithm

As aproached here:
http://www.engr.mun.ca/~theo/Misc/exp_parsing.htm


Precedence (subset of C rules):
-------------------------------
()		Parens						left-to-right		
!		not												
*		Multiplication, division	left-to-right		
+		Addition, subtraction		left-to-right		
> >=	relational					left-to-right		
== !=	relational					left-to-right		
&&		Logical AND					left-to-right		
||		Logical OR					left-to-right		
*/
class ExpressionParser {
	public function new()
	{
		
	}
	
	private var pos : Int = 0;
	private var newline : Int = 0;
	private static inline var UNARY_PRECEDENCE : Int = 5;
	private var tokens : Array<String>;
	private var types : String;
	
	private function expectTok(e : String) : Void{
		if (tokens[pos] != e) 			throw new Error("Unexpected token.")++;pos;
	}
	
	private function parseSingle(token : String, type : String) : Expression
	{
		if (type == "i") {
			var varExp : VariableExpression = new VariableExpression(token);
			return varExp;
		}
		else if (type == "0") {
			var numExp : NumberExpression = new NumberExpression(Std.parseFloat(token));
			return numExp;
		}
		return null;
	}
	
	private function parseChunk() : Expression
	{
		if (pos == newline) 			throw new Error("parseBit out of tokens")  // Unary operator  ;
		
		
		
		if (tokens[pos] == "!") {
			var notExp : UnaryExpression = new UnaryExpression();
			++pos;
			notExp.right = parseExpression(UNARY_PRECEDENCE);
			return notExp;
		}
		
		if (tokens[pos] == "(") {
			++pos;
			var exp : Expression = parseExpression(0);
			expectTok(")");
			return exp;
		}
		
		if (types.charAt(pos) == "i") {
			var varExp : VariableExpression = new VariableExpression(tokens[pos]);
			++pos;
			return varExp;
		}
		if (types.charAt(pos) == "0") {
			var numExp : NumberExpression = new NumberExpression(Std.parseFloat(tokens[pos]));
			++pos;
			return numExp;
		}
		throw new Error("end of parseChunk: token=" + tokens[pos] + " type=" + types.charAt(pos));
	}
	
	private function parseExpression(minPrecedence : Int) : Expression
	{
		var t : Expression = parseChunk();  // consumes what is before the binop  
		if (Std.is(t, NumberExpression)) 			  // numbers are immutable...  
		return t;
		
		var opInfo : OpInfo = new OpInfo();
		if (pos < tokens.length) 
			calcOpInfo(tokens[pos], opInfo);
		
		while (opInfo.order == 2 && opInfo.precedence >= minPrecedence){
			var binExp : BinaryExpression = new BinaryExpression();
			binExp.op = tokens[pos];
			++pos;
			binExp.left = t;
			binExp.right = parseExpression(1 + opInfo.precedence);
			
			t = binExp;
			
			if (pos < tokens.length) 
				calcOpInfo(tokens[pos], opInfo)
			else 
			break;
		}
		return t;
	}
	
	public function parse(tokens : Array<String>, types : String) : Expression
	{
		pos = 0;
		newline = types.indexOf("n", pos + 1);
		if (newline < 0) 
			newline = types.length;
		
		this.tokens = tokens;
		this.types = types;
		
		var exp : Expression = parseExpression(0);
		//trace( "--eparser--" );
		if (AGALPreAssembler.TRACE_AST) {
			exp.print(0);
		}
		if (pos != newline) 			throw new Error("parser didn't end");
		return exp;
	}
	
	
	private function calcOpInfo(op : String, opInfo : OpInfo) : Bool
	{
		opInfo.order = 0;
		opInfo.precedence = -1;
		
		var groups : Array<Dynamic> = [
		new Array<Dynamic>("&&", "||"), 
		new Array<Dynamic>("==", "!="), 
		new Array<Dynamic>(">", "<", ">=", "<="), 
		new Array<Dynamic>("+", "-"), 
		new Array<Dynamic>("*", "/"), 
		new Array<Dynamic>("!")];
		for (i in 0...groups.length){
			var arr : Array<Dynamic> = groups[i];
			var index : Int = Lambda.indexOf(arr, op);
			if (index >= 0) {
				opInfo.order = ((i == UNARY_PRECEDENCE)) ? 1 : 2;
				opInfo.precedence = i;
				return true;
			}
		}
		return false;
	}
}


class OpInfo {
	public var precedence : Int;
	public var order : Int;  // 1: unary, 2: binary  

	public function new()
	{
	}
}

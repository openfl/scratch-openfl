package com.adobe.utils.macro;


/**
 * Class to record information about all the aliases in an AGAL
 * shader. Typically a program is interested in making sure all
 * the needed constants are set in the constant pool. If isConstant()
 * return true, then the x,y,z,w members contain the values required
 * for the shader to run correctly.
 */
class AGALVar {
	public var name : String;  // transform  
	public var target : String;  // "vc3", "va2.x"  
	public var x : Float = Float.NaN;
	public var y : Float = Float.NaN;
	public var z : Float = Float.NaN;
	public var w : Float = Float.NaN;
	
	public function isConstant() : Bool{return !Math.isNaN(x);
	}
	public function toString() : String{
		if (this.isConstant()) 
			return "alias " + target + ", " + name + "( " + x + ", " + y + ", " + z + ", " + w + " )"
		else 
		return "alias " + target + ", " + name;
	}

	public function new()
	{
	}
}

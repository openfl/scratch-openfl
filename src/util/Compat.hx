package util;

/**
 * Some utility functions to help with compatibility when porting ActionScript to Haxe.
 */
class Compat
{
	public static function toFixed(x:Float, numDecimals:Int):String 
	{
		return Reflect.callMethod(x, Reflect.field(x, "toFixed"), [numDecimals]);
	}
	
	public static function hasMethod(x: Dynamic, methodName: String) : Bool
	{
		return Type.getInstanceFields(Type.getClass(x)).indexOf(methodName) != -1;
	}
	
	public static function newArray<T>(size: Int, defaultValue: T) :Array<T> 
	{
		var array:Array<T> = new Array<T>();
		for (n in 0...size)
			array.push(defaultValue);
		return array;
	}
	
}
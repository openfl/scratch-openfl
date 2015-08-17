package com.adobe.utils.macro;


import flash.utils.Dictionary;

class VM {
	public var vars : flash.utils.Dictionary = new flash.utils.Dictionary();
	public var stack : Array<Dynamic> = new Array<Dynamic>();
	
	public function pushIf() : Void
	{
		m_ifIsTrue.push(false);
		m_ifWasTrue.push(false);
	}
	
	public function popEndif() : Void
	{
		m_ifIsTrue.pop();
		m_ifWasTrue.pop();
	}
	
	public function setIf(value : Float) : Void
	{
		m_ifIsTrue[m_ifIsTrue.length - 1] = (value != 0);
		m_ifWasTrue[m_ifIsTrue.length - 1] = (value != 0);
	}
	
	public function ifWasTrue() : Bool
	{
		return m_ifWasTrue[m_ifIsTrue.length - 1];
	}
	
	public function ifIsTrue() : Bool
	{
		if (m_ifIsTrue.length == 0) 
			return true  // All ifs on the stack must be true for current true.  ;
		
		
		
		for (i in 0...m_ifIsTrue.length){
			if (!m_ifIsTrue[i]) {
				return false;
			}
		}
		return true;
	}
	
	private var m_ifIsTrue : Array<Bool> = new Array<Bool>();
	private var m_ifWasTrue : Array<Bool> = new Array<Bool>();

	public function new()
	{
	}
}

package jp.seibe.lib.value;

class Value<T>
{
	public var flag:Bool;
	@:isVar public var value(get, set):T;
	@:isVar public var silentValue(get, never):T;
	private var _value:T;

	public function new(?newValue:T)
	{
		this.flag = false;
		this._value = newValue;
	}
	
	private function set_value(newValue:T):T
	{
		flag = flag || _value != newValue;
		_value = newValue;
		
		return _value;
	}
	
	private function get_value():T
	{
		flag = false;
		return _value;
	}
	
	private function get_silentValue():T
	{
		return _value;
	}
	
}
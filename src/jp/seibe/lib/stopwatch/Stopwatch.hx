package jp.seibe.lib.stopwatch;

class Stopwatch
{
	@:isVar public var now(get, never):Float;
	private var _isWatch:Bool;
	private var _begin:Float;
	private var _length:Float;

	public function new() 
	{
		_isWatch = false;
		_begin = 0;
		_length = 0;
	}
	
	public function start():Void
	{
		if (_isWatch == true) return;
		_isWatch = true;
		
		_begin = Date.now().getTime();
	}
	
	public function stop():Float
	{
		if (_isWatch != true) return _length / 1000;
		_isWatch = false;
		
		_length += (Date.now().getTime() - _begin);
		
		return _length / 1000;
	}
	
	public function finish():Float
	{
		var temp:Float = stop();
		
		_begin = 0;
		_length = 0;
		
		return temp;
	}
	
	public function isRunning():Bool
	{
		return _isWatch;
	}
	
	private function get_now():Float
	{
		return _isWatch ?  (Date.now().getTime() - _begin + _length) / 1000 : _length / 1000;
	}
	
}
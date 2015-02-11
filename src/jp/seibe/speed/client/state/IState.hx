package jp.seibe.speed.client.state;

interface IState 
{
	public function start():Void;
	public function update():Void;
	public function stop():Void;
}
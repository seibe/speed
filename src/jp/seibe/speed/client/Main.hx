package jp.seibe.speed.client;
import jp.seibe.speed.client.GameClient;
import js.Browser;

class Main 
{
	private var _client:GameClient;
	
	static function main() 
	{
		new Main();
	}
	
	public function new()
	{
		Browser.window.onload = init;
	}
	
	private function init(e:Dynamic):Void
	{
		_client = new GameClient();
		_client.start();
	}
	
}
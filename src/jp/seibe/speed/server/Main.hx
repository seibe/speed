package jp.seibe.speed.server;

class Main 
{
	private var _server:GameServer;
	
	static function main() 
	{
		new Main();
	}
	
	public function new()
	{
		_server = new GameServer();
		_server.run();
	}
	
}
package jp.seibe.speed.client.state;
import jp.seibe.speed.client.GameClient;
import jp.seibe.speed.common.Speed;

class MatchState implements IState
{
	private var _client:GameClient;

	public function new(client:GameClient) 
	{
		_client = client;
	}
	
	/* INTERFACE jp.seibe.speed.client.state.IState */
	
	public function start():Void 
	{
		_client.dom.notify("対戦相手を待っています", 0);
	}
	
	public function update():Void 
	{
		var res:Null<Proto> = _client.socket.receive();
		if (res != null) {
			switch (res) {
				case Proto.MATCHING(clientType):
					_client.type = clientType;
					_client.dom.setClientType(clientType);
					_client.change(ClientState.NEGOTIATE);
					
				default:
					throw "受信エラー";
			}
		}
	}
	
	public function stop():Void 
	{
		
	}
	
}
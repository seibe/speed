package jp.seibe.speed.client.state;
import jp.seibe.speed.client.GameClient;
import jp.seibe.speed.common.Speed;

/**
 * ...
 * @author seibe
 */
class FinishState implements IState
{
	private var _client:GameClient;
	
	public function new(client:GameClient) 
	{
		_client = client;
	}
	
	/* INTERFACE jp.seibe.speed.client.state.IState */
	
	public function start():Void 
	{
		_client.dom.disableDrag();
		_client.dom.disableStamp();
		_client.dom.notify("試合が終了しました。", 3000);
		_client.dom.drawDialog("");
		
		_client.socket.close();
		_client.card.close();
		
		_client.change(ClientState.START);
	}
	
	public function update():Void 
	{
		
	}
	
	public function stop():Void 
	{
		
	}
	
}
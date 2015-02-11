package jp.seibe.speed.client.state;
import jp.seibe.speed.client.GameClient;
import jp.seibe.speed.common.Speed;

class ConnectState implements IState
{
	private var _client:GameClient;

	public function new(client:GameClient) 
	{
		_client = client;
	}
	
	/* INTERFACE jp.seibe.speed.client.state.IState */
	
	public function start():Void 
	{
		_client.dom.getElement("#stage, #stamp, .start-buttons").addClass("hidden");
		_client.dom.getElement("#start, .start-loader").removeClass("hidden");
		_client.dom.notify("サーバーに接続中です", 0);
		
		_client.socket.connect(function(success:Bool):Void {
			if (success) {
				_client.change(ClientState.MATCH);
			}
			else {
				_client.dom.notify("サーバー接続中にエラーが発生しました。", 3000);
				_client.change(ClientState.START);
			}
		});
	}
	
	public function update():Void 
	{
		
	}
	
	public function stop():Void 
	{
		
	}
	
}
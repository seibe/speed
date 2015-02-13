package jp.seibe.speed.client.state;
import jp.seibe.speed.client.GameClient;
import jp.seibe.speed.common.Speed;
import js.Zepto.ZeptoEvent;

class StartState implements IState
{
	private var _client:GameClient;

	public function new(client:GameClient) 
	{
		_client = client;
	}
	
	/* INTERFACE jp.seibe.speed.client.state.IState */
	
	public function start():Void 
	{
		_client.dom.getElement("#stage, #stamp, .start-loader").addClass("hidden");
		_client.dom.getElement("#start, .start-buttons").removeClass("hidden");
		_client.dom.getElement("#start-button-online").on("click", function(e:ZeptoEvent):Void {
			_client.change(ClientState.CONNECT);
		});
	}
	
	public function update():Void 
	{
		
	}
	
	public function draw():Void 
	{
		
	}
	
	public function stop():Void 
	{
		_client.dom.getElement("#start-button-online").off("click");
	}
	
}
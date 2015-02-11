package jp.seibe.speed.client;
import jp.seibe.speed.client.CardManager;
import jp.seibe.speed.client.DomManager;
import jp.seibe.speed.client.SocketManager;
import jp.seibe.speed.client.state.*;
import jp.seibe.speed.common.Speed;
import haxe.Timer;

class GameClient
{
	public var FRAME_RATE(default, null):Int = 60;
	
	public var card:CardManager;
	public var dom:DomManager;
	public var socket:SocketManager;
	
	public var type:ClientType;
	public var delayTime:Float;
	public var diffTime:Float;
	
	private var _state:Null<IState>;
	private var _timer:Null<Timer>;
	
	public function new()
	{
		card = CardManager.getInstance();
		dom = DomManager.getInstance();
		socket = SocketManager.getInstance();
		
		type = ClientType.HOST;
		delayTime = 0;
		diffTime = 0;
		
		_state = new StartState(this);
		_state.start();
	}
	
	public function start():Void
	{	
		_timer = new Timer( Std.int(1000 / FRAME_RATE) );
		_timer.run = update;
	}
	
	public function stop():Void
	{
		_timer.stop();
		_timer = null;
	}
	
	public function change(to:ClientState):Void
	{
		if (_state != null) _state.stop();
		
		switch(to) {
			case ClientState.START:		_state = new StartState(this);
			case ClientState.CONNECT:	_state = new ConnectState(this);
			case ClientState.MATCH:		_state = new MatchState(this);
			case ClientState.NEGOTIATE:	_state = new NegotiateState(this);
			case ClientState.INGAME:	_state = new IngameState(this);
			case ClientState.FINISH:	_state = new FinishState(this);
			case ClientState.NOTHING:	_state = null;
		}
		
		if (_state != null) _state.start();
	}
	
	private function update():Void
	{
		if (_state != null) _state.update();
	}
	
}
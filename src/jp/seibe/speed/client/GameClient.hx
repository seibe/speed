package jp.seibe.speed.client;
import jp.seibe.speed.client.CardManager;
import jp.seibe.speed.client.DomManager;
import jp.seibe.speed.client.SocketManager;
import jp.seibe.speed.client.state.*;
import jp.seibe.speed.common.Speed;
import haxe.Timer;
import js.Browser;

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
	private var _isDrawSync:Bool;
	
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
		_timer.run = onUpdate;
		
		_isDrawSync = Browser.window.requestAnimationFrame == null;
		if (!_isDrawSync) {
			Browser.window.requestAnimationFrame(onRequestAnimation);
		}
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
	
	private function onUpdate():Void
	{
		if (_state != null) {
			_state.update();
			if (_isDrawSync) _state.draw();
		}
	}
	
	private function onRequestAnimation(time:Float):Bool
	{
		if (_state != null) _state.draw();
		Browser.window.requestAnimationFrame(onRequestAnimation);
		return true;
	}
	
	/* magic */
	
	private static function __init__() : Void untyped {
		window.requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame || window.msRequestAnimationFrame;
	}
	
}
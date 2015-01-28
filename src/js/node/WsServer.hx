package js.node;
import js.Node;

@:enum
abstract WsSocketState(String) {
	var CONNECTING	= "connecting";
	var OPEN		= "open";
	var CLOSING		= "closing";
	var CLOSED		= "closed";
	
	@:to
	private function toString():String {
		return this;
	}
}

@:enum
abstract WsSocketEvent(String) {
	var OPEN = "open";
	var ERROR = "error";
	var CLOSE = "close";
	var MESSAGE = "message";
	var PING = "ping";
	var PONG = "pong";
	
	@:to
	private function toString():String {
		return this;
	}
}

@:enum
abstract WsServerEvent(String) {
	var ERROR = "error";
	var HEADERS = "headers";
	var CONNECTION = "connection";
	
	@:to
	private function toString():String {
		return this;
	}
}

typedef WsSocketFlags = {
	var masked:Bool;
	var buffer:Dynamic;
	var binary:Bool;
}

typedef WsSocket = {> NodeEventEmitter,
	var bytesReceived:Dynamic;
	var readyState:String;
	var protocolVersion:Dynamic;
	// var url:Dynamic; *only for client
	var supports:Dynamic;
	//var onopen(null,default):Dynamic; *only for client
	var onerror(null,default):Dynamic;
	var onclose(null,default):Dynamic;
	var onmessage(null,default):Dynamic;
	function close(?code:Dynamic, ?data:Dynamic):Void;
	function pause():Void;
	function ping(?data:Dynamic, ?options:Dynamic, ?dontFailWhenClosed:Dynamic):Void;
	function pong(?data:Dynamic, ?options:Dynamic, ?dontFailWhenClosed:Dynamic):Void;
	function resume():Void;
	function send(data:Dynamic, ?options:Dynamic, ?callback:Dynamic):Void;
	function stream(?options:Dynamic, ?callback:Dynamic):Void;
	function terminate():Void;
}

typedef WsServerConfig = {
	@:optional var host:String;
	@:optional var port:Int;
	@:optional var server:NodeHttpServer;
	@:optional var verifyClient:Dynamic;
	@:optional var handleProtocols:Dynamic;
	@:optional var path:String;
	@:optional var noServer:Bool;
	@:optional var disableHixie:Bool;
	@:optional var clientTracking:Bool;
}

@:native("WsServer")
extern class WsServer {
	public var clients:Array<WsSocket>;
    public function new(?options:WsServerConfig, ?callback:Dynamic):Void;
	public function close():Void;
	public function handleUpgrade(request:NodeHttpServerReq, ?socket:Dynamic, ?upgradeHead:Dynamic, ?callback:Dynamic):Void;
	// extends EventEmitter
	public function addListener(event:String, listener:NodeListener):Dynamic;
	public function on(event:String, listener:NodeListener):Dynamic;
	public function once(event:String, listener:NodeListener):Void;
	public function removeListener(event:String, listener:NodeListener):Void;
	public function removeAllListeners(event:String):Void;
	public function listeners(event:String):Array<NodeListener>;
	public function setMaxListeners(m:Int):Void;
	public function emit(event:String, ?arg1:Dynamic, ?arg2:Dynamic, ?arg3:Dynamic):Void;
	public function broadcast(data:Dynamic):Void;

    private static function __init__() : Void untyped
	{
        var WsServer = Node.require('ws').Server;
	}
}
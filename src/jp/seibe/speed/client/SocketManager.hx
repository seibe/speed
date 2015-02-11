package jp.seibe.speed.client;
import jp.seibe.speed.common.Speed;
import js.html.Uint8Array;
import js.html.WebSocket;
import haxe.Timer;

enum SocketStatus {
	CLOSE;
	CONNECTING;
	CONNECT;
}

class SocketManager
{
	private static var _instance:SocketManager;
	private var _status:SocketStatus;
	private var _sendDataList:Array<Int>;
	private var _receiveDataList:Array<Int>;
	private var _ws:WebSocket;
	
	public static function getInstance():SocketManager
	{
		if (_instance == null) _instance = new SocketManager();
		return _instance;
	}
	
	private function new() 
	{
		// 状態：未接続
		_status = SocketStatus.CLOSE;
		
		// 送受信データのリセット
		_sendDataList = new Array<Int>();
		_receiveDataList = new Array<Int>();
	}
	
	public function connect(callback:Bool->Void):Void
	{
		// 状態：接続試行中
		_status = SocketStatus.CONNECTING;
		trace("websocket: connecting start");
		
		// バイナリモードでの接続を試みる
		_ws = new WebSocket("ws://seibe.jp:8080/ws/speed");
		_ws.binaryType = 'arraybuffer';
		
		_ws.onopen = function(e:Dynamic):Void {
			// タイムアウトしていたら中断する
			if (_status == SocketStatus.CLOSE) return;
			
			// 状態：接続
			_status = SocketStatus.CONNECT;
			
			// 接続完了を通知する
			callback(true);
			_ws.onerror = this.onError;
			trace("websocket: connected");
		};
		
		_ws.onclose = this.onClose;
		_ws.onmessage = this.onReceive;
		
		_ws.onerror = function(e:Dynamic):Void {
			// 接続途中にエラーが出たら閉じる
			if (_status == SocketStatus.CONNECTING) {
				callback(false);
				close();
				trace("websocket: connecting error");
			}
		};
		
		Timer.delay(function():Void {
			// タイムアウトしたら接続を強制的に閉じる
			if (_status == SocketStatus.CONNECTING) {
				callback(false);
				close();
				trace("websocket: connecting timeout");
			}
		}, 3000);
	}
	
	public function send(msg:Proto):Bool
	{
		// 接続前なら破棄
		if (_status != SocketStatus.CONNECT) {
			return false;
		}
		
		switch (msg) {
			case Proto.PING:
				_sendDataList.push(RemoteProto.PING);
				_sendDataList.push(0x0);
			
			case Proto.PONG(timestamp_f):
				var timestamp:Int = Std.int(timestamp_f / 1000);
				_sendDataList.push(RemoteProto.PING);
				_sendDataList.push(timestamp >> 28);
				_sendDataList.push((timestamp >> 24) & 0xf);
				_sendDataList.push((timestamp >> 20) & 0xf);
				_sendDataList.push((timestamp >> 16) & 0xf);
				_sendDataList.push((timestamp >> 12) & 0xf);
				_sendDataList.push((timestamp >> 8) & 0xf);
				_sendDataList.push((timestamp >> 4) & 0xf);
				_sendDataList.push(timestamp & 0xf);
			
			case Proto.MATCHING:
				_sendDataList.push(RemoteProto.MATCH);
				_sendDataList.push(0x0);
				
			case Proto.UPDATE(diff):
				if (diff == null || diff.length == 0) return false;
				_sendDataList.push(RemoteProto.UPDATE);
				_sendDataList.push(diff.length >> 4);
				_sendDataList.push(diff.length & 0xf);
				for (card in diff) {
					var data:Int;
					
					switch (card.suit) {
						case CardSuit.CLUB(i):		data = i;
						case CardSuit.SPADE(i):		data = 13 + i;
						case CardSuit.DIAMOND(i):	data = 26 + i;
						case CardSuit.HEART(i):		data = 39 + i;
						case CardSuit.JOKER:		data = 62;
						case CardSuit.NONE:			data = 63;
					}
					_sendDataList.push(data >> 4);
					_sendDataList.push(data & 0xf);
					
					data = posToInt(card.pos);
					_sendDataList.push(data);
				}
				
			case Proto.START(timestamp_f):
				var timestamp:Int = Std.int(timestamp_f / 1000); // UNIXタイム(秒)
				var timestamp_mm:Int = Std.int(timestamp_f % 1000); // ミリ秒
				_sendDataList.push(RemoteProto.START);
				_sendDataList.push(timestamp >> 28);
				_sendDataList.push((timestamp >> 24) & 0xf);
				_sendDataList.push((timestamp >> 20) & 0xf);
				_sendDataList.push((timestamp >> 16) & 0xf);
				_sendDataList.push((timestamp >> 12) & 0xf);
				_sendDataList.push((timestamp >> 8) & 0xf);
				_sendDataList.push((timestamp >> 4) & 0xf);
				_sendDataList.push(timestamp & 0xf);
				_sendDataList.push((timestamp_mm >> 8) & 0xf);
				_sendDataList.push((timestamp_mm >> 4) & 0xf);
				_sendDataList.push(timestamp_mm & 0xf);
				
			case Proto.DRAG(e):
				_sendDataList.push(RemoteProto.DRAG);
				switch (e) {
					case CardDragEvent.DRAG_BEGIN(from):
						_sendDataList.push(0);
						_sendDataList.push(posToInt(from));
						
					case CardDragEvent.DRAG_MOVE(from, dx, dy):
						_sendDataList.push(1);
						_sendDataList.push(posToInt(from));
						_sendDataList.push((dx >>> 28) & 0xf);
						_sendDataList.push((dx >>> 24) & 0xf);
						_sendDataList.push((dx >>> 20) & 0xf);
						_sendDataList.push((dx >>> 16) & 0xf);
						_sendDataList.push((dx >>> 12) & 0xf);
						_sendDataList.push((dx >>> 8) & 0xf);
						_sendDataList.push((dx >>> 4) & 0xf);
						_sendDataList.push((dx >>> 0) & 0xf);
						_sendDataList.push((dy >>> 28) & 0xf);
						_sendDataList.push((dy >>> 24) & 0xf);
						_sendDataList.push((dy >>> 20) & 0xf);
						_sendDataList.push((dy >>> 16) & 0xf);
						_sendDataList.push((dy >>> 12) & 0xf);
						_sendDataList.push((dy >>> 8) & 0xf);
						_sendDataList.push((dy >>> 4) & 0xf);
						_sendDataList.push((dy >>> 0) & 0xf);
						
					case CardDragEvent.DRAG_END(from, to):
						_sendDataList.push(2);
						_sendDataList.push(posToInt(from));
						_sendDataList.push(posToInt(to));
						
					case CardDragEvent.DRAG_CANCEL(from):
						_sendDataList.push(3);
						_sendDataList.push(posToInt(from));
				}
				//
			case Proto.FINISH:
				_sendDataList.push(RemoteProto.FINISH);
				
			case Proto.STAMP(stampType):
				_sendDataList.push(RemoteProto.STAMP);
				_sendDataList.push(stampType & 0xf);
				
				//
			case Proto.ACK:
				trace("未実装: send-ack");
				//
			case Proto.NAK:
				trace("未実装: send-nak");
				//
			default:
				trace("send-error: 0");
				return false;
		}
		
		// 逐次、データを送信する
		var dataLength:Int = _sendDataList.length;
		if (dataLength > 0) {
			var byteLength:Int = Math.ceil(dataLength / 2);
			var data:Uint8Array = new Uint8Array(byteLength);
			for (i in 0...byteLength) {
				data[i] = (i * 2 + 1) == dataLength ? _sendDataList[i * 2] << 4 : (_sendDataList[i * 2] << 4) + _sendDataList[i * 2 + 1];
			}
			
			//trace("send (" + byteLength + " byte)");
			if (_ws.send(data) == false) {
				trace("send-error: 1");
				close();
				return false;
			}
			_sendDataList = new Array<Int>();
		}
		
		// 完了通知
		return true;
	}
	
	public function receive():Null<Proto>
	{
		if (_receiveDataList.length == 0) return null;
		//trace("残りパケット: " + _receiveDataList.length);
		
		var header:Int = _receiveDataList.shift();
		//trace("header: " + header);
		switch (header) {
			case RemoteProto.PING:
				var flag:Int = _receiveDataList.shift();
				if (flag == 0x0) {
					return Proto.PING;
				}
				else {
					var timestamp:Float = flag << 28;
					timestamp += _receiveDataList.shift() << 24;
					timestamp += _receiveDataList.shift() << 20;
					timestamp += _receiveDataList.shift() << 16;
					timestamp += _receiveDataList.shift() << 12;
					timestamp += _receiveDataList.shift() << 8;
					timestamp += _receiveDataList.shift() << 4;
					timestamp += _receiveDataList.shift();
					return Proto.PONG(timestamp * 1000);
				}
				
			case RemoteProto.ACK:
				return Proto.ACK;
				
			case RemoteProto.NAK:
				return Proto.NAK;
				
			case RemoteProto.MATCH:
				var data:Int = _receiveDataList.shift();
				if (data == 1) return Proto.MATCHING(ClientType.HOST);
				else if (data == 2) return Proto.MATCHING(ClientType.GUEST);
				else throw "データ破損？";
				
			case RemoteProto.START:
				var timestamp:Float = _receiveDataList.shift() << 28;
				timestamp += _receiveDataList.shift() << 24;
				timestamp += _receiveDataList.shift() << 20;
				timestamp += _receiveDataList.shift() << 16;
				timestamp += _receiveDataList.shift() << 12;
				timestamp += _receiveDataList.shift() << 8;
				timestamp += _receiveDataList.shift() << 4;
				timestamp += _receiveDataList.shift();
				timestamp *= 1000;
				timestamp += _receiveDataList.shift() << 8;
				timestamp += _receiveDataList.shift() << 4;
				timestamp += _receiveDataList.shift();
				return Proto.START(timestamp);
				
			case RemoteProto.FINISH:
				return Proto.FINISH;
				
			case RemoteProto.ERROR:
				var errno:Int = _receiveDataList.shift();
				return Proto.ERROR(errno);
				
			case RemoteProto.UPDATE:
				var diff:Array<Card> = new Array<Card>();
				var length:Int = _receiveDataList.shift();
				length = (length << 4) + _receiveDataList.shift();
				for (i in 0...length) {
					var card:Card = {suit: null, pos:null};
					
					var data:Int = (_receiveDataList.shift() << 4) + _receiveDataList.shift();
					if (data == 63) card.suit = CardSuit.NONE;
					else if (data == 62) card.suit = CardSuit.JOKER;
					else card.suit = CardSuit.createByIndex( Std.int(data / 13), [data % 13] );
					
					data = _receiveDataList.shift();
					card.pos = intToPos(data);
					
					diff.push(card);
				}
				return Proto.UPDATE(diff);
				
			case RemoteProto.DRAG:
				var type:Int = _receiveDataList.shift();
				var from:Int = _receiveDataList.shift();
				switch (type) {
					case 0:
						return Proto.DRAG( CardDragEvent.DRAG_BEGIN( intToPos(from) ) );
						
					case 1:
						var dx:Int = _receiveDataList.shift() << 28;
						dx += _receiveDataList.shift() << 24;
						dx += _receiveDataList.shift() << 20;
						dx += _receiveDataList.shift() << 16;
						dx += _receiveDataList.shift() << 12;
						dx += _receiveDataList.shift() << 8;
						dx += _receiveDataList.shift() << 4;
						dx += _receiveDataList.shift();
						dx = dx >= 0x80000000 ? (0xffffffff - dx + 0x1) * -1 : dx;
						var dy:Int = _receiveDataList.shift() << 28;
						dy += _receiveDataList.shift() << 24;
						dy += _receiveDataList.shift() << 20;
						dy += _receiveDataList.shift() << 16;
						dy += _receiveDataList.shift() << 12;
						dy += _receiveDataList.shift() << 8;
						dy += _receiveDataList.shift() << 4;
						dy += _receiveDataList.shift();
						dy = dy >= 0x80000000 ? (0xffffffff - dy + 0x1) * -1 : dy;
						return Proto.DRAG( CardDragEvent.DRAG_MOVE( intToPos(from), -dx, -dy ) );
						
					case 2:
						var to:Int = _receiveDataList.shift();
						return Proto.DRAG( CardDragEvent.DRAG_END( intToPos(from), intToPos(to) ) );
						
					case 3:
						return Proto.DRAG( CardDragEvent.DRAG_CANCEL( intToPos(from) ) );
				}
				
			case RemoteProto.STAMP:
				var type:Int = _receiveDataList.shift();
				return Proto.STAMP(type);
				
			default:
				return null;
		}
		
		return null;
	}
	
	public function close():Void
	{
		// 接続が開いていたら閉じる
		if (_status == SocketStatus.CONNECT) {
			_ws.onopen = _ws.onerror = null;
			_ws.close();
		}
		
		_status = SocketStatus.CLOSE;
		_ws = null;
		_sendDataList = new Array<Int>();
		_receiveDataList = new Array<Int>();
	}
	
	private function onReceive(e:{data:Dynamic}):Void
	{
		var bytes:Uint8Array = new Uint8Array(e.data);
		for (i in 0...bytes.byteLength) {
			//trace(bytes[i]);
			_receiveDataList.push(bytes[i] >> 4);
			_receiveDataList.push(bytes[i] & 0xf);
		}
		
		//trace("receive: (" + bytes.byteLength + " byte)");
	}
	
	private function onClose(e:Dynamic):Void
	{
		_status = SocketStatus.CLOSE;
	}
	
	private function onError(e:Dynamic):Void
	{
		_status = SocketStatus.CLOSE;
		throw "実行中にソケット接続が閉じられました。";
	}
	
	private function posToInt(pos:CardPos):Int
	{
		var data:Int;
		switch (pos) {
			case CardPos.TALON(i):	data = i;
			case CardPos.FIELD(i):	data = 2 + i;
			case CardPos.HAND(i, j):data = 4 + i*4 + j;
		}
		return data;
	}
	
	private function intToPos(data:Int):CardPos
	{
		if (data < 2)		return CardPos.TALON(data);
		else if (data < 4)	return CardPos.FIELD(data - 2);
		return CardPos.HAND( Std.int((data - 4) / 4), (data - 4) % 4 );
	}
	
}
package jp.seibe.speed.client.state;
import jp.seibe.speed.client.GameClient;
import jp.seibe.speed.common.Speed;

class NegotiateState implements IState
{
	private var _client:GameClient;
	
	private var PING_MAX(default, null):Int = 10;
	private var _pingCount:Int;
	private var _prevPingTime:Float;

	public function new(client:GameClient) 
	{
		_client = client;
	}
	
	/* INTERFACE jp.seibe.speed.client.state.IState */
	
	public function start():Void 
	{
		// Pingを送る
		_client.delayTime = 0;
		_client.diffTime = 0;
		_pingCount = 0;
		_prevPingTime = Date.now().getTime();
		
		if (!_client.socket.send(Proto.PING)) throw "送信エラー";
	}
	
	public function update():Void 
	{
		// タイミング調整
		var res:Null<Proto> = _client.socket.receive();
		while (res != null) {
			switch (res) {
				case Proto.PING:
					// PONGを返す
					if (_client.socket.send(Proto.PONG(Date.now().getTime())) == false) throw "送信エラー";
				
				case Proto.PONG(timestamp):
					// 相手とのズレを算出する
					_pingCount++;
					var now:Float = Date.now().getTime();
					var delay:Float = now - _prevPingTime; //往復遅延
					var diff:Float = (timestamp * 2 - _prevPingTime - now) / 2; //相対的な時計の誤差
					//trace("recieve PONG: ", delay, timestamp, now, diff);
					_client.delayTime += delay;
					_client.diffTime += diff;
					
					if (_pingCount < PING_MAX) {
						// もっとPingを送る
						_prevPingTime = Date.now().getTime();
						if (!_client.socket.send(Proto.PING)) throw "送信エラー";
					} else {
						// 規定数のPing/Pongを受信できたら
						// ズレの中央値を計算して、調整を終える
						_client.delayTime = _client.delayTime / PING_MAX;
						_client.diffTime = Std.int(_client.diffTime / PING_MAX / 1000) * 1000;
						trace("ズレ: ", _client.delayTime, _client.diffTime);
						
						_client.change(ClientState.INGAME);
					}
					
				default:
					throw "受信エラー";
			}
			res = _client.socket.receive();
		}
	}
	
	public function stop():Void 
	{
		
	}
	
}
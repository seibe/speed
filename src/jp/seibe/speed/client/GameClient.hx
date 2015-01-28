package jp.seibe.speed.client;
import jp.seibe.speed.common.Speed;
import haxe.Timer;

enum GameClientState {
	INIT;
	CONNECT;
	CONNECTING;
	CONNECTED;
	MATCHING;
	NEGOTIATE;
	NEGOTIATING;
	NEGOTIATED;
	INGAME_INIT;
	INGAME_LOOP;
	INGAME_START(timestamp:Float);
	FINISHED;
	ERROR(prev:GameClientState);
}

class GameClient
{
	private var FRAME_RATE(default, null):Int = 60;
	private var PING_MAX(default, null):Int = 10;
	private var _cardManager:CardManager;
	private var _domManager:DomManager;
	private var _socketManager:SocketManager;
	private var _state:GameClientState;
	private var _clientType:ClientType;
	private var _pingCount:Int;
	private var _prevPingTime:Float;
	private var _delayTime:Float;
	private var _diffTime:Float;
	private var _timer:Timer;
	private var _prevDragTime:Float;
	
	public function new()
	{
		_state = GameClientState.INIT;
		_prevDragTime = 0;
	}
	
	public function run():Void
	{
		_timer = new Timer( Std.int(1000 / FRAME_RATE) );
		_timer.run = onEnterFrame;
	}
	
	public function stop():Void
	{
		_timer.stop();
		_timer = null;
	}
	
	private function onEnterFrame():Void
	{
		trace(_state);
		
		switch(_state) {
			case GameClientState.INIT:
				// 初期化
				_cardManager = new CardManager();
				_domManager = new DomManager();
				_socketManager = new SocketManager();
				_state = GameClientState.CONNECT;
				
			case GameClientState.CONNECT:
				// 接続要求
				_socketManager.connect(function(success:Bool):Void {
					if (success) _state = GameClientState.CONNECTED;
					else _state = GameClientState.ERROR(_state);
				});
				_state = GameClientState.CONNECTING;
				
			case GameClientState.CONNECTING:
				// 接続待ち
				
			case GameClientState.CONNECTED:
				// 接続完了
				_state = GameClientState.MATCHING;
				
			case GameClientState.MATCHING:
				// 対戦相手待ち
				var res:Proto = _socketManager.receive();
				if (res != null) {
					switch (res) {
						case Proto.MATCHING(clientType):
							trace("type", clientType);
							_clientType = clientType;
							_state = GameClientState.NEGOTIATE;
							
						default:
							_state = GameClientState.ERROR(_state);
					}
				}
				
			case GameClientState.NEGOTIATE:
				// Pingを送る
				_delayTime = 0;
				_diffTime = 0;
				_pingCount = 0;
				
				trace("PING!");
				_prevPingTime = Date.now().getTime();
				_socketManager.send(Proto.PING);
				
				_state = GameClientState.NEGOTIATING;
				
			case GameClientState.NEGOTIATING:
				// タイミング調整
				var res:Proto = _socketManager.receive();
				if (res != null) {
					switch (res) {
						case Proto.PING:
							// PONGを返す
							_socketManager.send(Proto.PONG(Date.now().getTime()));
						
						case Proto.PONG(timestamp):
							// 相手とのズレを算出する
							_pingCount++;
							var now:Float = Date.now().getTime();
							var delay:Float = now - _prevPingTime; //往復遅延
							var diff:Float = (timestamp * 2 - _prevPingTime - now) / 2; //相対的な時計の誤差
							//trace("recieve PONG: ", delay, timestamp, now, diff);
							_delayTime += delay;
							_diffTime += diff;
							
							if (_pingCount < PING_MAX) {
								// もっとPingを送る
								_prevPingTime = Date.now().getTime();
								_socketManager.send(Proto.PING);
							} else {
								// 規定数のPing/Pongを受信できたら
								// ズレの中央値を計算して、調整を終える
								_delayTime = _delayTime / PING_MAX;
								_diffTime = Std.int(_diffTime / PING_MAX / 1000) * 1000;
								trace("ズレ: ", _delayTime, _diffTime);
								_state = GameClientState.NEGOTIATED;
							}
							
						default:
							_state = GameClientState.ERROR(_state);
					}
				}
				
			case GameClientState.NEGOTIATED:
				// タイミング調整完了
				_state = GameClientState.INGAME_INIT;
				
			case GameClientState.INGAME_INIT:
				// ゲーム開始
				_domManager.setClientType(_clientType);
				if (_clientType == ClientType.HOST) {
					// ホストならカードを初期化する
					var cardList:Array<Card> = _cardManager.deal();
					_domManager.drawCard(cardList);
					_socketManager.send( Proto.UPDATE(cardList) );
					// スタート予告
					var target:Float = Date.now().getTime() + 5000 + _delayTime;
					_socketManager.send( Proto.START(target + _diffTime) );
					_state = GameClientState.INGAME_START(target);
				}
				else {
					// ゲストなら待つ
					_state = GameClientState.INGAME_LOOP;
				}
				
			case GameClientState.INGAME_LOOP:
				// 合図待ち
				var res:Proto = _socketManager.receive();
				while (res != null)
				{
					switch (res)
					{
						case Proto.PING:
							// PONGを返す
							_socketManager.send(Proto.PONG(Date.now().getTime()));
						
						case Proto.UPDATE(diff):
							// カード情報を同期
							_cardManager.update(diff);
							_domManager.drawCard(_cardManager.getDiff());
							
						case Proto.START(target):
							// timestampに合わせて同時スタート用意
							_domManager.disableDrag();
							//var now:Float = Date.now().getTime();
							//var timestamp:Float = now % 60000 > target ? now - (now % 60000) + target + 60000 : now - (now % 60000) + target;
							_state = GameClientState.INGAME_START(target);
							
						case Proto.DRAG(e):
							_domManager.dragCard(e);
							
						case Proto.FINISH:
							_state = GameClientState.FINISHED;
							
						default:
							// 予期しない通知
							_state = GameClientState.ERROR(_state);
							return;
					}
					res = _socketManager.receive();
				}
				
				// 差分抽出
				var cardList:Array<Card> = _cardManager.getDiff();
				if (cardList != null && cardList.length > 0) {
					// 描画更新
					_domManager.drawCard(cardList);
					// 変更送出
					_socketManager.send( Proto.UPDATE(cardList) );
				}
				
				if (_cardManager.isClose()) {
					// 試合終了
					trace("試合終了");
					_socketManager.send( Proto.FINISH );
					_state = GameClientState.FINISHED;
				}
				else if (_clientType == ClientType.HOST && _cardManager.isStalemate()) {
					// 膠着状態なので、再度スタートする
					trace("膠着状態");
					var target:Float = Date.now().getTime() + 5000 + _delayTime;
					_socketManager.send( Proto.START(target + _diffTime) );
					_state = GameClientState.INGAME_START(target);
				}
				
			case GameClientState.INGAME_START(timestamp):
				var now:Float = Date.now().getTime();
				if (now < timestamp) {
					// 現在時刻がtimestampになるまでカウントダウン表示
					var msg:String = Std.string( Std.int((timestamp - now) / 1000)+1 );
					_domManager.drawDialog(msg);
				}
				else {
					// timestamp以上となったらflipする
					_cardManager.start();
					_domManager.drawDialog("");
					
					// Input有効化後LOOPに戻る
					_domManager.enableDrag(onDragCard);
					_state = GameClientState.INGAME_LOOP;
				}
				
			case GameClientState.FINISHED:
				// 正常終了
				_domManager.disableDrag();
				_socketManager.close();
				stop();
				
			case GameClientState.ERROR(prev):
				// エラー終了
				stop();
				throw "クライアントはエラー終了しました。";
				
		}
	}
	
	private function onDragCard(e:CardDragEvent):Void
	{
		switch (e) {
			case CardDragEvent.DRAG_END(from, to):
				// スタック可否判断
				if ( !_cardManager.canStack(from, to) ) {
					// ダメなら無かったことにする
					e = CardDragEvent.DRAG_CANCEL(from);
				}
				else {
					// stack成功
					var talonLengthList:Array<Int> = _cardManager.getTalonLength();
					trace("残り", talonLengthList);
					for (i in 0...2) {
						// 山札の残りが無くなっていたら描画を更新する
						if (talonLengthList[i] == 0) {
							_domManager.drawCardAt(CardPos.TALON(i), CardSuit.NONE);
						}
					}
				}
				
			default:
				// なにもしない
		}
		
		// 描画更新
		_domManager.dragCard(e);
		
		// 送信
		var now:Float = Date.now().getTime();
		if (!e.match(CardDragEvent.DRAG_MOVE) || now - _prevDragTime > 33) {
			_socketManager.send( DRAG(e) );
			_prevDragTime = now;
		}
	}
	
}
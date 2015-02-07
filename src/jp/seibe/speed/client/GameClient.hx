package jp.seibe.speed.client;
import jp.seibe.speed.common.Speed;
import haxe.Timer;

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
	private var _dragNum:Int;
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
		//trace(_state);
		
		switch(_state) {
			case GameClientState.INIT:
				// 初期化
				_cardManager = new CardManager();
				_domManager = new DomManager();
				_domManager.on(function(state:GameClientState):Void {
					_state = state;
				});
				_socketManager = new SocketManager();
				_state = GameClientState.INITED;
				
			case GameClientState.INITED:
				// 初期化済み、待機
				
			case GameClientState.CONNECT:
				// 接続要求
				_socketManager.connect(function(success:Bool):Void {
					if (success) _state = GameClientState.CONNECTED;
					else {
						_domManager.notify("サーバー接続中にエラーが発生しました。", 3000);
						_state = GameClientState.INIT;
					}
				});
				_domManager.setScene(ClientScene.CONNECTING);
				_domManager.notify("サーバーに接続中です", 0);
				_state = GameClientState.CONNECTING;
				
			case GameClientState.CONNECTING:
				// 接続待ち
				
			case GameClientState.CONNECTED:
				// 接続完了
				_state = GameClientState.MATCHING;
				_domManager.notify("対戦相手を待っています", 0);
				
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
				
				_prevPingTime = Date.now().getTime();
				if (_socketManager.send(Proto.PING) == true) {
					_state = GameClientState.NEGOTIATING;
				}
				else {
					_state = GameClientState.ERROR(_state);
				}
				
			case GameClientState.NEGOTIATING:
				// タイミング調整
				var res:Proto = _socketManager.receive();
				if (res != null) {
					switch (res) {
						case Proto.PING:
							// PONGを返す
							if (_socketManager.send(Proto.PONG(Date.now().getTime())) == false) {
								_state = GameClientState.ERROR(_state);
							}
						
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
								if (_socketManager.send(Proto.PING) == false) {
									_state = GameClientState.ERROR(_state);
								}
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
				_domManager.setScene(ClientScene.INGAME(_clientType));
				_domManager.enableStamp(onTapStamp);
				_domManager.notify("対戦相手が見つかりました。対戦を開始します。", 3000);
				
				if (_clientType == ClientType.HOST) {
					// ホストならカードを初期化する
					var cardList:Array<Card> = _cardManager.deal();
					_domManager.drawCard(cardList);
					if (_socketManager.send( Proto.UPDATE(cardList) ) == false) {
						_state = GameClientState.ERROR(_state);
						return;
					}
					// スタート予告
					var target:Float = Date.now().getTime() + 5000 + _delayTime;
					if (_socketManager.send( Proto.START(target + _diffTime) ) == false) {
						_state = GameClientState.ERROR(_state);
						return;
					}
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
							if (_socketManager.send(Proto.PONG(Date.now().getTime())) == false) {
								_state = GameClientState.ERROR(_state);
								return;
							}
						
						case Proto.UPDATE(diff):
							// カード情報を同期
							_cardManager.update(diff);
							_domManager.drawCard(_cardManager.getDiff());
							_domManager.drawTalon(_cardManager.getTalonLength());
							
						case Proto.START(target):
							// timestampに合わせて同時スタート用意
							_domManager.disableDrag();
							_state = GameClientState.INGAME_START(target);
							
						case Proto.DRAG(e):
							_domManager.dragCard(e, 1 - _clientType);
							
						case Proto.STAMP(type):
							_domManager.drawStamp(type);
							
						case Proto.FINISH:
							_state = GameClientState.FINISHED;
							return;
							
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
					if (_socketManager.send( Proto.UPDATE(cardList) ) == false) {
						_state = GameClientState.ERROR(_state);
						return;
					}
				}
				
				if (_cardManager.isClose()) {
					// 試合終了
					if (_socketManager.send( Proto.FINISH ) == false) {
						_state = GameClientState.ERROR(_state);
						return;
					}
					// どちらが勝ったか
					if (_cardManager.getTalonLength()[_clientType] == 0) {
						if (_cardManager.getTalonLength()[1-_clientType] == 0) {
							_domManager.drawDialog("引き分け");
						} else {
							_domManager.drawDialog("勝利");
						}
					} else {
						_domManager.drawDialog("敗北");
					}
					Timer.delay(function():Void {
						_state = GameClientState.FINISHED;
					}, 3000);
					_state = GameClientState.NOTHING;
					return;
				}
				else if (_clientType == ClientType.HOST && _cardManager.isStalemate()) {
					// 膠着状態なので、再度スタートする
					var target:Float = Date.now().getTime() + 5000 + _delayTime;
					if (_socketManager.send( Proto.START(target + _diffTime) ) == false) {
						_state = GameClientState.ERROR(_state);
						return;
					}
					_state = GameClientState.INGAME_START(target);
				}
				
			case GameClientState.INGAME_START(timestamp):
				var now:Float = Date.now().getTime();
				if (now < timestamp) {
					// 現在時刻がtimestampになるまでカウントダウン表示
					var msg:String = Std.string( Std.int((timestamp - now) / 1000)+1 );
					_domManager.drawDialog(msg);
					
					// カウントダウン中も受信
					var res:Proto = _socketManager.receive();
					while (res != null)
					{
						switch (res)
						{
							case Proto.PING:
								// PONGを返す
								if (_socketManager.send(Proto.PONG(Date.now().getTime())) == false) {
									_state = GameClientState.ERROR(_state);
									return;
								}
							
							case Proto.DRAG(e):
								_domManager.dragCard(e, 1 - _clientType);
								
							case Proto.STAMP(type):
								_domManager.drawStamp(type);
							
							case Proto.UPDATE(diff):
								trace("NOTICE: カウントダウン中に同期通知");
								if (_clientType == ClientType.GUEST) {
									_cardManager.update(diff);
									_domManager.drawCard(_cardManager.getDiff());
								}
								
							case Proto.FINISH:
								trace("NOTICE: カウントダウン中に終了通知");
								_state = GameClientState.FINISHED;
								return;
								
							default:
								// 予期しない通知
								trace("NOTICE: カウントダウン中に通知", res);
								//_state = GameClientState.ERROR(_state);
								//return;
						}
						res = _socketManager.receive();
					}
				}
				else {
					// timestamp以上となったらflipする
					_cardManager.start();
					_domManager.drawDialog("");
					_domManager.drawTalon(_cardManager.getTalonLength());
					
					// Input有効化後LOOPに戻る
					_domManager.enableDrag(onDragCard);
					_state = GameClientState.INGAME_LOOP;
				}
				
			case GameClientState.FINISHED:
				// 正常終了
				_domManager.disableDrag();
				_domManager.disableStamp();
				_domManager.notify("試合が終了しました。", 3000);
				_socketManager.close();
				_cardManager.close();
				
				_domManager.drawDialog("");
				_domManager.setScene(ClientScene.START);
				_state = GameClientState.INIT;
				
			case GameClientState.ERROR(prev):
				// エラー終了
				_domManager.disableDrag();
				_domManager.disableStamp();
				_domManager.notify("クライアントはエラー終了しました。", 3000);
				Timer.delay(function() {
					_state = GameClientState.INIT;
				}, 3000);
				_state = GameClientState.NOTHING;
				//stop();
				//throw "クライアントはエラー終了しました。";
				
			case GameClientState.NOTHING:
				// なにもしない
				
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
					//trace("残り", talonLengthList);
					_domManager.drawTalon(talonLengthList);
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
		_domManager.dragCard(e, _clientType);
		
		// 送信
		var now:Float = Date.now().getTime();
		if (!e.match(CardDragEvent.DRAG_MOVE) || now - _prevDragTime > 33) {
			if (_socketManager.send( DRAG(e) ) == false) {
				_state = GameClientState.ERROR(_state);
				return;
			}
			_prevDragTime = now;
		}
	}
	
	private function onTapStamp(stampType:Int):Void
	{
		if (_socketManager.send(Proto.STAMP(stampType)) == false) {
			_state = GameClientState.ERROR(_state);
			return;
		}
	}
	
}
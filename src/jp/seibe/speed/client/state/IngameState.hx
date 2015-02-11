package jp.seibe.speed.client.state;
import haxe.Timer;
import jp.seibe.speed.client.GameClient;
import jp.seibe.speed.common.Speed;
import js.Zepto;

class IngameState implements IState
{
	private var _client:GameClient;
	
	private var _startTime:Float;
	private var _dragNum:Int;
	private var _prevDragTime:Float;

	public function new(client:GameClient) 
	{
		_client = client;
	}
	
	/* INTERFACE jp.seibe.speed.client.state.IState */
	
	public function start():Void 
	{
		_startTime = 0;
		_dragNum = 0;
		_prevDragTime = 0;
		
		_client.dom.enableStamp(onTapStamp);
		_client.dom.notify("対戦相手が見つかりました。対戦を開始します。", 3000);
		_client.dom.getElement("#start").addClass("hidden");
		_client.dom.getElement("#stage, #stamp").removeClass("hidden");
		for (i in 0...2) {
			_client.dom.drawCardAt(CardPos.FIELD(i), CardSuit.NONE);
		}
		
		if (_client.type == ClientType.HOST) {
			// ホストならカードを初期化する
			var cardList:Array<Card> = _client.card.deal();
			_client.dom.drawCard(cardList);
			if (_client.socket.send( Proto.UPDATE(cardList) ) == false) {
				throw "error";
				return;
			}
			// スタート予告
			_startTime = Date.now().getTime() + 5000 + _client.delayTime;
			if (_client.socket.send( Proto.START(_startTime + _client.diffTime) ) == false) {
				throw "error";
				return;
			}
		}
	}
	
	public function update():Void 
	{
		if (_startTime > 0)
		{
			var now:Float = Date.now().getTime();
			if (_startTime > now) {
				// カウントダウン中
				var msg:String = Std.string( Std.int((_startTime - now) / 1000) + 1 );
				_client.dom.drawDialog(msg);
				
				var res:Null<Proto> = _client.socket.receive();
				while (res != null) {
					switch (res)
					{
						case Proto.PING:
							// PONGを返す
							if (_client.socket.send(Proto.PONG(Date.now().getTime())) == false) {
								throw "error";
								return;
							}
							
						case Proto.DRAG(e):
							// 遅れてきたドラッグ情報も処理する
							_client.dom.dragCard(e, 1 - _client.type);
							
						case Proto.STAMP(type):
							_client.dom.drawStamp(type);
							
						case Proto.UPDATE(diff):
							trace("NOTICE: カウントダウン中に同期通知");
							// ホスト側の情報を優先して上書き
							if (_client.type == ClientType.GUEST) {
								_client.card.update(diff);
								_client.dom.drawCard(_client.card.getDiff());
							}
							
						case Proto.FINISH:
							trace("NOTICE: カウントダウン中に終了通知");
							_client.change(ClientState.FINISH);
							return;
							
						default:
							// 予期しない通知
							trace("NOTICE: カウントダウン中に通知", res);
					}
					res = _client.socket.receive();
				}
				
				return;
			}
			else {
				// カウントダウン終了
				_client.card.start();
				_client.dom.drawDialog("");
				_client.dom.drawTalon(_client.card.getTalonLength());
				_client.dom.enableDrag(onDragCard);
				_startTime = 0;
			}
		}
		
		//
		var res:Proto = _client.socket.receive();
		while (res != null)
		{
			switch (res)
			{
				case Proto.PING:
					// PONGを返す
					if (_client.socket.send(Proto.PONG(Date.now().getTime())) == false) {
						throw "error";
						return;
					}
				
				case Proto.UPDATE(diff):
					// カード情報を同期
					_client.card.update(diff);
					_client.dom.drawCard(_client.card.getDiff());
					_client.dom.drawTalon(_client.card.getTalonLength());
					
				case Proto.START(target):
					// timestampに合わせて同時スタート用意
					_client.dom.disableDrag();
					_startTime = target;
					
				case Proto.DRAG(e):
					_client.dom.dragCard(e, 1 - _client.type);
					
				case Proto.STAMP(type):
					_client.dom.drawStamp(type);
					
				case Proto.FINISH:
					_client.change(ClientState.FINISH);
					return;
					
				default:
					// 予期しない通知
					throw "error";
					return;
			}
			res = _client.socket.receive();
		}
		
		// 差分抽出
		var cardList:Array<Card> = _client.card.getDiff();
		if (cardList.length > 0) {
			// 描画更新
			_client.dom.drawCard(cardList);
			// 変更送出
			if (_client.socket.send( Proto.UPDATE(cardList) ) == false) {
				throw "error";
				return;
			}
		}
		
		if (_client.card.isClose()) {
			// 試合終了
			if (_client.socket.send( Proto.FINISH ) == false) {
				throw "error";
				return;
			}
			// どちらが勝ったか
			if (_client.card.getTalonLength()[_client.type] == 0) {
				if (_client.card.getTalonLength()[1-_client.type] == 0) {
					_client.dom.drawDialog("引き分け");
				} else {
					_client.dom.drawDialog("勝利");
				}
			} else {
				_client.dom.drawDialog("敗北");
			}
			Timer.delay(function():Void {
				_client.change(ClientState.FINISH);
			}, 3000);
			_client.change(ClientState.NOTHING);
			return;
		}
		else if (_client.type == ClientType.HOST && _client.card.isStalemate()) {
			// 膠着状態なので、再度スタートする
			_startTime = Date.now().getTime() + 5000 + _client.delayTime;
			if (_client.socket.send( Proto.START(_startTime + _client.diffTime) ) == false) {
				throw "error";
				return;
			}
		}
	}
	
	public function stop():Void 
	{
		_client.dom.disableDrag();
		_client.dom.disableStamp();
	}
	
	private function onDragCard(e:CardDragEvent):Void
	{
		switch (e) {
			case CardDragEvent.DRAG_END(from, to):
				// スタック可否判断
				if ( !_client.card.canStack(from, to) ) {
					// ダメなら無かったことにする
					e = CardDragEvent.DRAG_CANCEL(from);
				}
				else {
					// stack成功
					var talonLengthList:Array<Int> = _client.card.getTalonLength();
					//trace("残り", talonLengthList);
					_client.dom.drawTalon(talonLengthList);
					for (i in 0...2) {
						// 山札の残りが無くなっていたら描画を更新する
						if (talonLengthList[i] == 0) {
							_client.dom.drawCardAt(CardPos.TALON(i), CardSuit.NONE);
						}
					}
				}
				
			default:
				// なにもしない
		}
		
		// 描画更新
		_client.dom.dragCard(e, _client.type);
		
		// 送信
		var now:Float = Date.now().getTime();
		if (!e.match(CardDragEvent.DRAG_MOVE) || now - _prevDragTime > 33) {
			if (_client.socket.send( DRAG(e) ) == false) {
				throw "error";
				return;
			}
			_prevDragTime = now;
		}
	}
	
	private function onTapStamp(stampType:Int):Void
	{
		if (_client.socket.send(Proto.STAMP(stampType)) == false) {
			throw "error";
			return;
		}
	}
	
}
package jp.seibe.speed.client;
import haxe.ds.Vector;
import haxe.Timer;
import jp.seibe.lib.stopwatch.Stopwatch;
import jp.seibe.speed.client.DomManager.Point;
import jp.seibe.speed.common.Speed;
import js.Browser;
import js.html.DOMWindow;
import js.Zepto;

typedef Point = {
	x:Int,
	y:Int
}

class DomManager
{
	private var _clientType:ClientType;
	private var _window:DOMWindow;
	private var _notify:Zepto;
	private var _notifyTimer:Timer;
	private var _dialog:Zepto;
	private var _dialogStr:String;
	private var _console:Zepto;
	private var _consoleTimer:Timer;
	private var _stampCard:Zepto;
	private var _stampList:Vector<Zepto>;
	private var _stampButtonList:Vector<Zepto>;
	private var _talonLength:Vector<Zepto>;
	private var _cardDomMap:Map<CardPos,Zepto>;
	private var _cardSrcMap:Map<CardSuit, String>;
	private var _draggable:Bool;
	private var _dragListener:CardDragEvent->Void;
	private var _dragIdMap:Map<Zepto, Int>;
	private var _dragPointMap:Map<Zepto, Point>;
	private var _dragCount:Vector<Int>;
	private var _watch:Stopwatch;
	private var _watchAction:Vector<Stopwatch>;
	private var _actionCount:Vector<Int>;
	private var _actionTime:Vector<Float>;
	private var _successActionCount:Vector<Int>;
	private var _changeSceneFunc:GameClientState->Void;
	
	private static inline function _(selector:String):Zepto {
		return untyped $(selector);
	}

	public function new() 
	{
		_window = Browser.window;
		_notify = _("#notify");
		_notifyTimer = null;
		_dialog = _("#dialog");
		_console = _("#console");
		_draggable = false;
		
		_stampCard = _("#stampcard");
		_stampList = new Vector<Zepto>(4);
		_stampList[0] = _('<img src="./img/stamp/stack.png" alt="出せる" />');
		_stampList[1] = _('<img src="./img/stamp/urge.png" alt="出せない" />');
		_stampList[2] = _('<img src="./img/stamp/glad.png" alt="よゆう" />');
		_stampList[3] = _('<img src="./img/stamp/sad.png" alt="あせる" />');
		_stampButtonList = new Vector<Zepto>(4);
		_stampButtonList[0] = _("#stamp-button-stack");
		_stampButtonList[1] = _("#stamp-button-urge");
		_stampButtonList[2] = _("#stamp-button-glad");
		_stampButtonList[3] = _("#stamp-button-sad");
		
		_cardSrcMap = new Map<CardSuit, String>();
		_cardSrcMap.set(CardSuit.NONE, "img/card/null.png");
		for (i in 0...13) {
			var istr:String = i < 9 ? "0" + Std.string(i+1) : Std.string(i+1);
			_cardSrcMap.set(CardSuit.CLUB(i), "img/card/c" + istr + ".png");
			_cardSrcMap.set(CardSuit.SPADE(i), "img/card/s" + istr + ".png");
			_cardSrcMap.set(CardSuit.DIAMOND(i), "img/card/d" + istr + ".png");
			_cardSrcMap.set(CardSuit.HEART(i), "img/card/h" + istr + ".png");
		}
		
		// スタート画面に移動する
		setScene(ClientScene.START);
	}
	
	public function on(callback:GameClientState-> Void):Void
	{
		_changeSceneFunc = callback;
	}
	
	public function setScene(scene:ClientScene):Void
	{
		switch (scene) {
			case ClientScene.START:
				// スタート画面に移る
				_("#stage, .start-loader").addClass("hidden");
				_("#start, .start-buttons").removeClass("hidden");
				_("#start-button-online").on("click", function(e:ZeptoTouchEvent):Void {
					trace("click!");
					if (_changeSceneFunc != null) _changeSceneFunc(GameClientState.CONNECT);
				});
				
				if (_consoleTimer != null) _consoleTimer.stop();
				
			case ClientScene.CONNECTING:
				// マッチング中
				_("#stage, .start-buttons").addClass("hidden");
				_("#start, .start-loader").removeClass("hidden");
				
				if (_consoleTimer != null) _consoleTimer.stop();
				
			case ClientScene.INGAME(clientType):
				// 対戦画面に移る
				_("#start").addClass("hidden");
				_("#stage").removeClass("hidden");
				
				// ホストorゲスト指定
				_clientType = clientType;
				_talonLength = new Vector<Zepto>(2);
				_cardDomMap = new Map<CardPos, Zepto>();
				for (i in 0...2) {
					var pre:String = i == _clientType ? "#stage-player-" : "#stage-enemy-";
					_talonLength[i] = _(pre + "talon-length");
					_cardDomMap.set( CardPos.TALON(i), _(pre + "talon") );
					_cardDomMap.set( CardPos.FIELD(i ^ _clientType), _("#stage-field-" + Std.string(i)) );
					
					for (j in 0...4) {
						_cardDomMap.set( CardPos.HAND(i, j), _(pre + "hand-" + Std.string(j)) );
					}
				}
				
				// 場の初期化
				for (i in 0...2) {
					drawCardAt(CardPos.FIELD(i), CardSuit.NONE);
				}
				
				// デバッグ用表示
				/*
				_watch = new Stopwatch();
				_watchAction = new Vector<Stopwatch>(6);
				for (i in 0..._watchAction.length) _watchAction[i] = new Stopwatch();
				_dragCount = new Vector<Int>(2);
				_actionCount = new Vector<Int>(2);
				_actionTime = new Vector<Float>(2);
				_successActionCount = new Vector<Int>(2);
				for (i in 0...2) {
					_dragCount[i] = 0;
					_actionCount[i] = 0;
					_actionTime[i] = 0;
					_successActionCount[i] = 0;
				}
				_watch.start();
				_watchAction[3].start();
				
				_consoleTimer = new Timer(100);
				_consoleTimer.run = traceConsole;
				*/
		}
	}
	
	private function traceConsole():Void
	{
		_console.html(
			"経過時間：　" + Std.string(_watch.now) + " 秒<br />" +
			"操作数(全て)： 1P " + Std.string(_actionCount[0]) + " 回　2P " + Std.string(_actionCount[1]) + " 回<br />" +
			"操作数(成功)： 1P " + Std.string(_successActionCount[0]) + " 回　2P " + Std.string(_successActionCount[1]) + " 回<br />" +
			"操作時間(成功)：　1P " + Std.string(_actionTime[0]) + " 秒　2P " + Std.string(_actionTime[1]) + " 秒<br />" +
			"無操作時間：　" + Std.string(_watchAction[3].now) + " 秒<br />" +
			"マルチタッチ：　1P " + Std.string(_watchAction[4].now) + " 秒　2P " + Std.string(_watchAction[5].now) + " 秒"
		);
	}
	
	public function notify(text:String, ms:Int):Void
	{
		_notify.text(text);
		
		if (ms > 0) {
			if (_notifyTimer != null) _notifyTimer.stop();
			_notifyTimer = Timer.delay(function() {
				_notify.text("");
				_notifyTimer = null;
			}, ms);
		}
	}
	
	public function drawCard(cardList:Array<Card>):Void
	{
		if (cardList == null) return;
		
		for (card in cardList) {
			drawCardAt(card.pos, card.suit);
		}
	}
	
	public function drawCardAt(pos:CardPos, suit:CardSuit):Void
	{
		switch (pos) {
			case CardPos.TALON(i):
				if (suit == CardSuit.NONE) _cardDomMap.get(pos).attr("src", _cardSrcMap.get(suit) );
				else _cardDomMap.get(pos).attr("src", "img/card/back.png" );
				
			default:
				_cardDomMap.get(pos).attr("src", _cardSrcMap.get(suit) );
		}
	}
	
	public function drawTalon(lengthList:Array<Int>):Void
	{
		for (i in 0...2) {
			if (lengthList[i] == 0) _talonLength[i].text("");
			else _talonLength[i].text(Std.string(lengthList[i]));
		}
	}
	
	public function drawStamp(stampType:Int):Void
	{
		var stamp:Zepto = _stampList[stampType].clone();
		trace("clone");
		stamp.css( {
			left: Std.string(Std.int(Math.random() * (_window.innerWidth - 120))) + "px"
		});
		stamp.on("animationend webkitAnimationEnd", function(e:ZeptoEvent):Void {
			stamp.remove();
		});
		
		_stampCard.append(stamp);
	}
	
	public function drawDialog(str:String):Void
	{
		if (_dialogStr == str) return;
		
		if (str == null || str.length == 0) _dialog.html("");
		else _dialog.html("<span>" + str + "</span>");
		
		_dialogStr = str;
	}
	
	public function enableStamp(listner:Int-> Void):Void
	{
		_("#stamp").removeClass("hidden");
		
		for (i in 0...4) {
			_stampButtonList[i].on("click", function(e:ZeptoTouchEvent):Void {
				listner(i);
			});
		}
	}
	
	public function disableStamp():Void
	{
		_("#stamp").addClass("hidden");
		
		for (i in 0...4) {
			_stampButtonList[i].off("click");
		}
	}
	
	public function enableDrag(listner:CardDragEvent->Void):Void
	{
		if (_draggable == true) return;
		_draggable = true;
		
		_dragListener = listner;
		_dragIdMap = new Map<Zepto, Int>();
		_dragPointMap = new Map<Zepto, Point>();
		
		var talon:Zepto = _cardDomMap.get(CardPos.TALON(_clientType));
		talon.on("mousedown mousemove mouseup mouseout", function(e:ZeptoMouseEvent):Void {
			onClickCard(e, CardPos.TALON(_clientType));
		});
		talon.on("touchstart touchmove touchend touchcancel", function(e:ZeptoTouchEvent):Void {
			onTouchCard(e, CardPos.TALON(_clientType));
		});
		for (i in 0...4) {
			var hand:Zepto = _cardDomMap.get(CardPos.HAND(_clientType, i));
			hand.on("mousedown mousemove mouseup mouseout", function(e:ZeptoMouseEvent):Void {
				onClickCard(e, CardPos.HAND(_clientType, i));
			});
			hand.on("touchstart touchmove touchend touchcancel", function(e:ZeptoTouchEvent):Void {
				onTouchCard(e, CardPos.HAND(_clientType, i));
			});
		}
	}
	
	public function disableDrag():Void
	{
		if (_draggable == false) return;
		_draggable = false;
		
		for (i in 0...2) {
			_cardDomMap.get(CardPos.TALON(i)).off("mousedown mousemove mouseup mouseout touchstart touchmove touchend touchcancel");
			for (j in 0...4) {
				_cardDomMap.get(CardPos.HAND(i, j)).off("mousedown mousemove mouseup mouseout touchstart touchmove touchend touchcancel");
			}
		}
		
		_dragListener = null;
		_dragIdMap = null;
		_dragPointMap = null;
	}
	
	public function dragCard(e:CardDragEvent, client:Int):Void
	{
		switch (e) {
			case CardDragEvent.DRAG_BEGIN(pos):
				/*
				if (_dragCount[client] == 0) {
					_watchAction[3].stop();
					_watchAction[client].start();
					if (_watchAction[0].isRunning() && _watchAction[1].isRunning()) _watchAction[2].start();
				} else if (_dragCount[client] == 1) {
					_watchAction[client + 4].start();
				}
				_dragCount[client] += 1;*/
				_cardDomMap.get(pos).css({
					"transform": "matrix3d(1.2,0,0,0,0,1.2,0,0,0,0,1,0,0,0,0,1)",
					"z-index": "999"
				});
				
			case CardDragEvent.DRAG_MOVE(pos, dx, dy):
				_cardDomMap.get(pos).css({
					"transform": "matrix3d(1.2,0,0,0,0,1.2,0,0,0,0,1,0," + Std.string(dx) + "," + Std.string(dy) + ",0,1)",
					"z-index": "999"
				});
				
			case CardDragEvent.DRAG_END(from, to):
				/*
				_actionCount[client] += 1;
				_successActionCount[client] += 1;
				_dragCount[client] -= 1;
				if (_dragCount[client] == 0) {
					_actionTime[client] += _watchAction[client].finish();
					_watchAction[2].stop();
					if (!_watchAction[0].isRunning() && !_watchAction[1].isRunning()) _watchAction[3].start();
				} else if (_dragCount[client] == 1) {
					_watchAction[client + 4].stop();
				}*/
				_cardDomMap.get(from).css( {
					"transform": "",
					"z-index": ""
				});
				// 手札の描画更新が遅れる事象への暫定対処
				if (from.match(CardPos.HAND)) drawCardAt(from, CardSuit.NONE);
				
			case CardDragEvent.DRAG_CANCEL(pos):
				/*
				_actionCount[client] += 1;
				_dragCount[client] -= 1;
				if (_dragCount[client] == 0) {
					_watchAction[client].finish();
					_watchAction[2].stop();
					if (!_watchAction[0].isRunning() && !_watchAction[1].isRunning()) _watchAction[3].start();
				} else if (_dragCount[client] == 1) {
					_watchAction[client + 4].stop();
				}*/
				_cardDomMap.get(pos).css( {
					"transform": "",
					"z-index": ""
				});
		}
	}
	
	private function onClickCard(e:ZeptoMouseEvent, pos:CardPos):Void
	{
		e.preventDefault();
		var target:Zepto = _cardDomMap.get(pos);
		
		switch (e.type) {
			case "mousedown":
				// ドラッグ開始
				_dragPointMap.set(target, { x: e.pageX, y: e.pageY });
				_dragListener(CardDragEvent.DRAG_BEGIN(pos));
				
			case "mousemove":
				var beginPoint:Point = _dragPointMap.get(target);
				if (beginPoint == null) return;
				// ドラッグ処理
				var dx:Int = e.pageX - beginPoint.x;
				var dy:Int = e.pageY - beginPoint.y;
				_dragListener(CardDragEvent.DRAG_MOVE(pos, dx, dy));
				
			case "mouseup":
				if (_dragPointMap.get(target) == null) return;
				// 元の場所に戻す
				var to:CardPos = whereStack(pos);
				if (to != null) _dragListener(CardDragEvent.DRAG_END(pos, to));
				else _dragListener(CardDragEvent.DRAG_CANCEL(pos));
				_dragPointMap.remove(target);
				
			case "mouseout":
				if (_dragPointMap.get(target) == null) return;
				// 元の場所に戻す
				_dragListener(CardDragEvent.DRAG_CANCEL(pos));
				_dragPointMap.remove(target);
		}
	}
	
	private function onTouchCard(e:ZeptoTouchEvent, pos:CardPos):Void
	{
		e.preventDefault();
		var target:Zepto = _cardDomMap.get(pos);
		
		switch (e.type) {
			case "touchstart":
				// ドラッグ開始
				var i:Int = e.touches.length - 1;
				_dragPointMap.set(target, { x: e.touches.item(i).pageX, y: e.touches.item(i).pageY });
				_dragIdMap.set(target, e.touches.item(i).identifier);
				_dragListener(CardDragEvent.DRAG_BEGIN(pos));
				
			case "touchmove":
				var id:Int = _dragIdMap.get(target);
				if (id == null) return;
				// ドラッグ処理
				for (touch in e.touches) {
					if (id == touch.identifier) {
						var beginPoint:Point = _dragPointMap.get(target);
						var dx:Int = touch.pageX - beginPoint.x;
						var dy:Int = touch.pageY - beginPoint.y;
						_dragListener(CardDragEvent.DRAG_MOVE(pos, dx, dy));
						break;
					}
				}
				
			case "touchend":
				var id:Int = _dragIdMap.get(target);
				if (id == null) return;
				// 元の場所に戻す
				var to:CardPos = whereStack(pos);
				if (to != null) _dragListener(CardDragEvent.DRAG_END(pos, to));
				else _dragListener(CardDragEvent.DRAG_CANCEL(pos));
				_dragIdMap.remove(target);
				_dragPointMap.remove(target);
				
			case "touchcancel":
				var id:Int = _dragIdMap.get(target);
				if (id == null) return;
				// 元の場所に戻す
				_dragListener(CardDragEvent.DRAG_CANCEL(pos));
				_dragIdMap.remove(target);
				_dragPointMap.remove(target);
		}
	}
	
	private function whereStack(from:CardPos):CardPos
	{
		var offset:ZeptoOffset = _cardDomMap.get(from).offset();
		var distArea:Int = 90*90;
		var min:Int = distArea;
		var distList:Vector<Int>;
		var targetOffset:ZeptoOffset;
		var dx, dy:Int;
		
		switch (from) {
			case CardPos.TALON(i):
				distList = new Vector<Int>(4);
				for (j in 0...4) {
					targetOffset = _cardDomMap.get(CardPos.HAND(i, j)).offset();
					dx = offset.left - targetOffset.left;
					dy = offset.top - targetOffset.top;
					distList[j] = dx * dx + dy * dy;
					min = distList[j] < min ? distList[j] : min;
				}
				if (min < distArea) {
					for (j in 0...4) {
						if (min == distList[j]) {
							return CardPos.HAND(i, j);
						}
					}
				}
			
			case CardPos.HAND(i, j):
				distList = new Vector<Int>(2);
				for (j in 0...2) {
					targetOffset = _cardDomMap.get(CardPos.FIELD(j)).offset();
					dx = offset.left - targetOffset.left;
					dy = offset.top - targetOffset.top;
					distList[j] = dx * dx + dy * dy;
					min = distList[j] < min ? distList[j] : min;
				}
				if (min < distArea) {
					for (j in 0...2) {
						if (min == distList[j]) {
							return CardPos.FIELD(j);
						}
					}
				}
			
			default:
				return null;
		}
		
		return null;
	}
	
}
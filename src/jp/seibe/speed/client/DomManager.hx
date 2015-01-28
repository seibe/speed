package jp.seibe.speed.client;
import haxe.ds.Vector;
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
	private var _dialog:Zepto;
	private var _dialogStr:String;
	private var _cardDomMap:Map<CardPos,Zepto>;
	private var _cardSrcMap:Map<CardSuit, String>;
	private var _dragListener:CardDragEvent->Void;
	private var _dragIdMap:Map<Zepto, Int>;
	private var _dragPointMap:Map<Zepto, Point>;
	
	private static inline function _(selector:String):Zepto {
		return untyped $(selector);
	}

	public function new() 
	{
		_window = Browser.window;
		_dialog = _("#dialog");
		
		// とりあえずホスト側として初期化する
		setClientType(ClientType.HOST);
		
		_cardSrcMap = new Map<CardSuit, String>();
		_cardSrcMap.set(CardSuit.NONE, "img/card/null.png");
		for (i in 0...13) {
			var istr:String = i < 9 ? "0" + Std.string(i+1) : Std.string(i+1);
			_cardSrcMap.set(CardSuit.CLUB(i), "img/card/c" + istr + ".png");
			_cardSrcMap.set(CardSuit.SPADE(i), "img/card/s" + istr + ".png");
			_cardSrcMap.set(CardSuit.DIAMOND(i), "img/card/d" + istr + ".png");
			_cardSrcMap.set(CardSuit.HEART(i), "img/card/h" + istr + ".png");
		}
	}
	
	public function setClientType(clientType:ClientType):Void
	{
		_clientType = clientType;
		_cardDomMap = new Map<CardPos, Zepto>();
		
		for (i in 0...2) {
			var pre:String = i == _clientType ? "#host-" : "#guest-";
			_cardDomMap.set( CardPos.TALON(i), _(pre + "talon") );
			_cardDomMap.set( CardPos.FIELD(i ^ _clientType), _("#field-" + Std.string(i)) );
			
			for (j in 0...4) {
				_cardDomMap.set( CardPos.HAND(i, j), _(pre + "hand-" + Std.string(j)) );
			}
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
	
	public function drawDialog(str:String):Void
	{
		if (_dialogStr == str) return;
		
		if (str == null || str.length == 0) _dialog.html("");
		else _dialog.html("<span>" + str + "</span>");
		
		_dialogStr = str;
	}
	
	public function enableDrag(listner:CardDragEvent->Void):Void
	{
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
	
	public function dragCard(e:CardDragEvent):Void
	{
		switch (e) {
			case CardDragEvent.DRAG_BEGIN(pos):
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
				_cardDomMap.get(from).css( {
					"transform": "",
					"z-index": ""
				});
				// 手札の描画更新が遅れる事象への暫定対処
				if (from.match(CardPos.HAND)) {
					drawCardAt(from, CardSuit.NONE);
				}
				
			case CardDragEvent.DRAG_CANCEL(pos):
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
		var distArea:Int = 60*60;
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
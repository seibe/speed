package client;
import jp.seibe.speed.common.Card;
import jp.seibe.speed.common.ext.Zepto;
import haxe.ds.Vector;
import js.Browser;
import js.html.Document;
import js.html.DOMWindow;
import js.html.Point;
import js.html.Touch;

class Viewer
{
	private static var _instance:Viewer;
	private var _w:DOMWindow;
	private var _d:Document;
	
	private var _talonLength:Vector<Int>;
	private var _handList:Vector<Card>;
	private var _fieldList:Vector<Card>;
	
	private var _touchListener:CardPos->CardPos->?Bool->Bool;
	private var _touchStart:Touch;
	private var _touchPrev:Touch;
	
	private static inline function _(selector:String):Zepto {
		return untyped $(selector);
	}
	
	public static function getInstance():Viewer
	{
		if (_instance == null) _instance = new Viewer();
		return _instance;
	}
	
	public function new() 
	{
		_w = Browser.window;
		_d = _w.document;
		
		_handList = new Vector<Card>(8);
		_fieldList = new Vector<Card>(2);
	}
	
	public function enableTouch(listener:CardPos->CardPos->?Bool->Bool, ?debugMode:Bool)
	{
		_touchListener = listener;
		
		_("#host-talon").on("touchstart touchmove touchend touchcancel", function(e:ZeptoTouchEvent):Void {
			onTouchCard(e, CardPos.TALON(CardOwner.PLAYER));
		});
		if (debugMode) {
			_("#guest-talon").on("touchstart touchmove touchend touchcancel", function(e:ZeptoTouchEvent):Void {
				onTouchCard(e, CardPos.TALON(CardOwner.GUEST));
			});
		}
		
		for (i in 0...4) {
			_("#host-hand-" + Std.string(i)).on("touchstart touchmove touchend touchcancel", function(e:ZeptoTouchEvent):Void {
				onTouchCard(e, CardPos.HAND(i, CardOwner.PLAYER));
			});
			if (debugMode) {
				_("#guest-hand-" + Std.string(i)).on("touchstart touchmove touchend touchcancel", function(e:ZeptoTouchEvent):Void {
					onTouchCard(e, CardPos.HAND(i, CardOwner.GUEST));
				});
			}
		}
	}
	
	public function disableTouch():Void
	{
		_("#host-talon").off("touchstart touchmove touchend touchcancel");
		
		for (i in 0...4) {
			_("#host-hand-" + Std.string(i)).off("touchstart touchmove touchend touchcancel");
		}
	}
	
	public function update(cardList:Vector<Card>):Void
	{
		for (i in 0...52)
		{
			switch (cardList[i].pos)
			{
				case TALON(owner):
					// 山札
					
				case HAND(n, owner):
					// 手札
					n = owner == CardOwner.PLAYER ? n : n + 4;
					if (_handList[n] != cardList[i]) {
						changeImage(cardList[i]);
						_handList[n] = cardList[i].copy();
					}
					
				case FIELD(n):
					// 場A
					if (_fieldList[n] != cardList[i]) {
						changeImage(cardList[i]);
						_fieldList[n] = cardList[i].copy();
					}
					
				case DRAGGING(from, x, y):
					// ドラッグ中
					
				case ANIMATION(to, x, y):
					// アニメーション中
					
			}
		}
	}
	
	private function onTouchCard(e:ZeptoTouchEvent, pos:CardPos):Void
	{
		var target:Zepto = getDom(pos);
		trace(e.type);
		
		switch (e.type)
		{
			case "touchstart":
				_touchStart = e.touches.item(0);
				target.css({
					"transform": "matrix3d(1.2,0,0,0,0,1.2,0,0,0,0,1,0,0,0,0,1)",
					"z-index": "999"
				});
				
			case "touchmove":
				// 追随処理
				_touchPrev = e.touches.item(0);
				var dx:Int = _touchPrev.pageX - _touchStart.pageX;
				var dy:Int = _touchPrev.pageY - _touchStart.pageY;
				target.css({
					"transform": "matrix3d(1.2,0,0,0,0,1.2,0,0,0,0,1,0," + Std.string(dx) + "," + Std.string(dy) + ",0,1)",
					"z-index": "999"
				});
				
			case "touchend":
				if (_touchPrev != null)
				{
					switch(pos) {
						case HAND(i, owner):
							// 場Aおよび場Bとの距離を算出し、基準値以内かつ最も近いところへのセットを試みる
							var p:ZeptoOffset;
							var px, py, distA, distB:Float;
							
							p = target.offset();
							px = p.left + _touchPrev.pageX - _touchStart.pageX;
							py = p.top + _touchPrev.pageY - _touchStart.pageY;
							distA = getDistance(p, getDom(CardPos.FIELD(0)).offset());
							distB = getDistance(p, getDom(CardPos.FIELD(1)).offset());
							
							if (distA < 50 && distA <= distB) {
								// 場Aへのセットを試みる
								if (_touchListener(pos, CardPos.FIELD(0))) {
									// 成功したら画像を消す
									if (owner == CardOwner.PLAYER) _handList[i] = null;
									else _handList[i+4] = null;
									target.attr("src", null);
								}
							}
							else if (distB < 50 && distA > distB) {
								// 場Bへのセットを試みる
								if (_touchListener(pos, CardPos.FIELD(1))) {
									// 成功したら画像を消す
									if (owner == CardOwner.PLAYER) _handList[i] = null;
									else _handList[i+4] = null;
									target.attr("src", null);
								}
							}
							
						case TALON(owner):
							// 各手札との距離を算出し、基準値以内かつ最も近いところにセットする
							var px, py:Float;
							var p:ZeptoOffset = target.offset();
							px = p.left + _touchPrev.pageX - _touchStart.pageX;
							py = p.top + _touchPrev.pageY - _touchStart.pageY;
							var min:Float = 50;
							var distList:Vector<Float> = new Vector<Float>(4);
							for (i in 0...4) {
								distList[i] = getDistance(p, getDom(CardPos.HAND(i, owner)).offset());
								min = distList[i] < min ? distList[i] : min;
							}
							if (min < 50) {
								for (i in 0...4) {
									if (min == distList[i]) {
										// 手札へのセットを試みる
										if (_touchListener(pos, CardPos.HAND(i, owner))) {
											// 成功したら終了
											trace("flip request:", pos);
										}
										break;
									}
								}
							}
							
						default:
							// 想定していない値
							throw "Error";
					}
				}
				
				// 元の場所に戻す
				target.css( {
					"transform": "",
					"z-index": ""
				});
				_touchStart = null;
				_touchPrev = null;
				
			case "touchcancel":
				// 元の場所に戻す
				target.css( {
					"transform": "",
					"z-index": ""
				});
				_touchStart = null;
				_touchPrev = null;
				
		}
	}
	
	private function changeImage(card:Card):Void
	{
		getDom(card.pos).attr("src", getUri(card.suit));
	}
	
	private function getDistance(a:ZeptoOffset, b:ZeptoOffset):Float
	{
		var dx:Int = a.left - b.left;
		var dy:Int = a.top - b.top;
		
		return Math.sqrt(dx * dx + dy * dy);
	}
	
	private function getDom(pos:CardPos):Zepto
	{
		var domId:String = "#";
		
		switch (pos)
		{
			case TALON(owner):
				domId += owner.equals(CardOwner.PLAYER) ? "host-" : "guest-";
				domId += "talon";
			
			case HAND(n, owner):
				// 手札
				domId += owner.equals(CardOwner.PLAYER) ? "host-" : "guest-";
				domId += "hand-" + Std.string(n);
				
			case FIELD(n):
				// 場A
				domId += "field-" + Std.string(n);
				
			case DRAGGING(from, x, y):
				// ドラッグ中
				return getDom(from);
				
			case ANIMATION(to, x, y):
				// アニメーション中
				return getDom(to);
		}
		
		return _(domId);
	}
	
	private function getUri(suit:CardSuit):String
	{
		var imageUri:String = "img/card/";
		
		switch (suit)
		{
			case CLUB(n):
				imageUri += "c";
				n++;
				if (n < 10) imageUri += "0";
				imageUri += Std.string(n);
				
			case DIAMOND(n):
				imageUri += "d";
				n++;
				if (n < 10) imageUri += "0";
				imageUri += Std.string(n);
				
			case HEART(n):
				imageUri += "h";
				n++;
				if (n < 10) imageUri += "0";
				imageUri += Std.string(n);
				
			case SPADE(n):
				imageUri += "s";
				n++;
				if (n < 10) imageUri += "0";
				imageUri += Std.string(n);
				
			default:
				imageUri += "null";
		}
		
		return imageUri + ".png";
	}
	
	
}
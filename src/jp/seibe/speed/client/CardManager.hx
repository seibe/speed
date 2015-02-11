package jp.seibe.speed.client;
import jp.seibe.lib.value.Value;
import jp.seibe.speed.common.Speed;
import haxe.ds.Vector;
import haxe.EnumTools;

class CardManager
{
	private static var _instance:CardManager;
	private var _isInit:Bool;
	private var _fieldCardList:Vector<Value<CardSuit> >;
	private var _talonCardList:Vector<Array<CardSuit> >;
	private var _talonCardLength:Vector<Value<Int> >;
	private var _handCardList:Vector<Vector<Value<CardSuit> > >;
	
	public static function getInstance():CardManager
	{
		if (_instance == null) _instance = new CardManager();
		return _instance;
	}

	private function new() 
	{
		_isInit = false;
		
		_fieldCardList = new Vector< Value<CardSuit> >(2);
		_talonCardList = new Vector< Array<CardSuit> >(2);
		_talonCardLength = new Vector< Value<Int> >(2);
		_handCardList = new Vector< Vector< Value<CardSuit> > >(2);
		for (i in 0...2) {
			_fieldCardList[i] = new Value<CardSuit>(CardSuit.NONE);
			_talonCardList[i] = new Array<CardSuit>();
			_talonCardLength[i] = new Value<Int>();
			_handCardList[i] = new Vector< Value<CardSuit> >(4);
			for (j in 0...4) {
				_handCardList[i][j] = new Value<CardSuit>(CardSuit.NONE);
			}
		}
	}
	
	public function canStack(from:CardPos, to:CardPos, ?silent:Bool):Bool
	{
		// カード移動
		// silent = true なら判定するだけ
		
		if (!_isInit) return false;
		
		switch (from) {
			case CardPos.TALON(i):
				switch (to) {
					case CardPos.HAND(j, k):
						if (i == j && _handCardList[j][k].silentValue == CardSuit.NONE) {
							if (silent == null || !silent) {
								_handCardList[j][k].value = _talonCardList[i].shift();
								_talonCardLength[i].value = _talonCardList[i].length;
							}
							return true;
						}
						
					default:
						return false;
				}
				
			case CardPos.HAND(i, j):
				switch (to) {
					case CardPos.FIELD(k):
						var a:CardSuit = _handCardList[i][j].silentValue;
						var b:CardSuit = _fieldCardList[k].silentValue;
						if (a == CardSuit.NONE) return false;
						if (a.match(CardSuit.JOKER) || b.match(CardSuit.JOKER)) return true;
						var aNum:Int = a.getParameters()[0];
						var bNum:Int = b.getParameters()[0];
						var diff:Int = aNum > bNum ? aNum - bNum : bNum - aNum;
						if (diff == 1 || diff == 12) {
							if (silent == null || !silent) {
								_fieldCardList[k].value = _handCardList[i][j].value;
								_handCardList[i][j].value = CardSuit.NONE;
							}
							return true;
						}
						
					default:
						return false;
				}
				
			default:
				throw "ERROR";
		}
		
		return false;
	}
	
	public function isClose():Bool
	{
		// 試合終了の判定
		
		if (!_isInit) return false;
		
		for (i in 0...2) {
			if (_talonCardList[i].length == 0 &&
				_handCardList[i][0].silentValue == CardSuit.NONE &&
				_handCardList[i][1].silentValue == CardSuit.NONE &&
				_handCardList[i][2].silentValue == CardSuit.NONE &&
				_handCardList[i][3].silentValue == CardSuit.NONE) {
					return true;
			}
		}
		
		return false;
	}
	
	public function isStalemate():Bool
	{
		// 膠着状態の判定
		
		for (i in 0...2) {
			for (j in 0...4) {
				if (_handCardList[i][j].silentValue == CardSuit.NONE && _talonCardLength[i].silentValue > 0) return false;
				
				for (k in 0...2) {
					if ( canStack(CardPos.HAND(i, j), CardPos.FIELD(k), true) ) return false;
				}
			}
		}
		
		return true;
	}
	
	public function getDiff():Array<Card>
	{
		// 前回との差分を抽出して配列にして返す
		
		var diff:Array<Card> = new Array<Card>();
		for (i in 0...2)
		{
			if (_fieldCardList[i].flag) {
				diff.push({
					suit: _fieldCardList[i].value,
					pos: CardPos.FIELD(i)
				});
			}
			
			if (_talonCardLength[i].flag) {
				if (_talonCardLength[i].value == 0) {
					diff.push({
						suit: CardSuit.NONE,
						pos: CardPos.TALON(i)
					});
				}
				else {
					for (j in 0...(_talonCardLength[i].value)) {
						diff.push({
							suit: _talonCardList[i][j],
							pos: CardPos.TALON(i)
						});
					}
				}
			}
			
			for (j in 0...4) {
				if (_handCardList[i][j].flag) {
					diff.push({
						suit: _handCardList[i][j].value,
						pos: CardPos.HAND(i, j)
					});
				}
			}
		}
		
		return diff;
	}
	
	public function getTalonLength():Array<Int>
	{
		// 山札の残り枚数を返す
		return [_talonCardLength[0].silentValue, _talonCardLength[1].silentValue];
	}
	
	public function update(diff:Array<Card>):Void
	{
		// カード情報を上書きする
		
		var talon:Vector<Bool> = new Vector<Bool>(2);
		talon[0] = talon[1] = false;
		
		for (card in diff) {
			switch(card.pos) {
				case CardPos.TALON(i):
					if (!talon[i]) {
						_talonCardList[i] = new Array<CardSuit>();
						talon[i] = true;
					}
					if (card.suit != CardSuit.NONE) _talonCardList[i].push(card.suit);
					
				case CardPos.HAND(i, j):
					_handCardList[i][j].value = card.suit;
					
				case CardPos.FIELD(i):
					_fieldCardList[i].value = card.suit;
			}
		}
		
		for (i in 0...2) {
			_talonCardLength[i].value = _talonCardList[i].length;
		}
		
		_isInit = true;
	}
	
	public function deal():Array<Card>
	{
		// カードを混ぜて配布し、スタート時の状態とする
		
		var cardList:Array<CardSuit> = new Array<CardSuit>();
		for (i in 0...2)
		{
			// カードを26枚ずつ用意
			for (j in 0...26) {
				cardList[j] = EnumTools.createByIndex(
					CardSuit,
					i * 2 + Std.int(j / 13),
					[j % 13]
				);
			}
			
			// 26枚をシャッフル
			for (j in 0...26) {
				var a:Int = Std.random(26 - i);
				var b:Int = 26 - i - 1;
				
				var temp:CardSuit = cardList[a];
				cardList[a] = cardList[b];
				cardList[b] = temp;
			}
			
			// 4枚を手札に、それ以外を山に積む
			for (j in 0...26) {
				if (j < 4) _handCardList[i][j].value = cardList[j];
				else _talonCardList[i][j - 4] = cardList[j];
			}
			_talonCardLength[i].value = _talonCardList[i].length;
		}
		
		_isInit = true;
		
		return getDiff();
	}
	
	public function start():Void
	{
		// 山から場に１枚カードを出す
		// 山に無い場合は手札から出す
		
		for (i in 0...2) {
			if (_talonCardList[i].length > 0) {
				// 山から場に１枚カードを出す
				_fieldCardList[i].value = _talonCardList[i].shift();
				_talonCardLength[i].value = _talonCardList[i].length;
			}
			else {
				// 山に無い場合は手札から出す
				for (j in 0...4) {
					if (_handCardList[i][j].value != CardSuit.NONE) {
						_fieldCardList[i].value = _handCardList[i][j].value;
						_handCardList[i][j].value = CardSuit.NONE;
						break;
					}
				}
			}
		}
	}
	
	public function close():Void
	{
		_isInit = false;
	}
	
}
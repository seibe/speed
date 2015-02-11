package jp.seibe.speed.common ;

enum CardSuit {
	CLUB(i:Int);
	SPADE(i:Int);
	DIAMOND(i:Int);
	HEART(i:Int);
	JOKER;
	NONE;
}

enum CardPos {
	TALON(owner:Int);
	FIELD(index:Int);
	HAND(owner:Int, index:Int);
}

typedef Card = {
	suit:CardSuit,
	pos:CardPos
}

@:enum
abstract StampType(Int) {
	var STACK = 0;
	var URGE = 1;
	var GLAD = 2;
	var SAD = 3;
	
	@:to
	private function toInt():Int {
		return this;
	}
}

enum CardDragEvent {
	DRAG_BEGIN(pos:CardPos);
	DRAG_MOVE(pos:CardPos, dx:Int, dy:Int);
	DRAG_END(from:CardPos, to:CardPos);
	DRAG_CANCEL(pos:CardPos);
}

enum ClientState {
	START;
	CONNECT;
	MATCH;
	NEGOTIATE;
	INGAME;
	FINISH;
	NOTHING;
}

@:enum
abstract ClientType(Int) {
	var HOST = 0;
	var GUEST = 1;
	
	@:to
	private function toInt():Int {
		return this;
	}
}

enum Proto {
	PING;
	PONG(timestamp:Float);
	ACK;
	NAK;
	MATCHING(clientType:ClientType);
	START(timestamp:Float);
	FINISH;
	ERROR(errno:Int);
	UPDATE(diff:Array<Card>);
	DRAG(e:CardDragEvent);
	STAMP(stampType:Int);
}

@:enum
abstract RemoteProto(Int) {
	var PING	= 1;
	var ACK		= 2;
	var NAK		= 3;
	var MATCH	= 4;
	var START	= 5;
	var FINISH	= 6;
	var ERROR	= 7;
	var UPDATE	= 8;
	var DRAG	= 9;
	var STAMP	= 10;
	
	@:to
	private function toInt():Int {
		return this;
	}
}

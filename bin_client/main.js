(function () { "use strict";
var $estr = function() { return js.Boot.__string_rec(this,''); };
function $extend(from, fields) {
	function Inherit() {} Inherit.prototype = from; var proto = new Inherit();
	for (var name in fields) proto[name] = fields[name];
	if( fields.toString !== Object.prototype.toString ) proto.toString = fields.toString;
	return proto;
}
var IMap = function() { };
IMap.__name__ = true;
Math.__name__ = true;
var Reflect = function() { };
Reflect.__name__ = true;
Reflect.field = function(o,field) {
	try {
		return o[field];
	} catch( e ) {
		return null;
	}
};
Reflect.isFunction = function(f) {
	return typeof(f) == "function" && !(f.__name__ || f.__ename__);
};
Reflect.compare = function(a,b) {
	if(a == b) return 0; else if(a > b) return 1; else return -1;
};
Reflect.isEnumValue = function(v) {
	return v != null && v.__enum__ != null;
};
var Std = function() { };
Std.__name__ = true;
Std.string = function(s) {
	return js.Boot.__string_rec(s,"");
};
Std["int"] = function(x) {
	return x | 0;
};
Std.random = function(x) {
	if(x <= 0) return 0; else return Math.floor(Math.random() * x);
};
var Type = function() { };
Type.__name__ = true;
Type.createEnum = function(e,constr,params) {
	var f = Reflect.field(e,constr);
	if(f == null) throw "No such constructor " + constr;
	if(Reflect.isFunction(f)) {
		if(params == null) throw "Constructor " + constr + " need parameters";
		return f.apply(e,params);
	}
	if(params != null && params.length != 0) throw "Constructor " + constr + " does not need parameters";
	return f;
};
Type.createEnumIndex = function(e,index,params) {
	var c = e.__constructs__[index];
	if(c == null) throw index + " is not a valid enum constructor index";
	return Type.createEnum(e,c,params);
};
var haxe = {};
haxe.Log = function() { };
haxe.Log.__name__ = true;
haxe.Log.trace = function(v,infos) {
	js.Boot.__trace(v,infos);
};
haxe.Timer = function(time_ms) {
	var me = this;
	this.id = setInterval(function() {
		me.run();
	},time_ms);
};
haxe.Timer.__name__ = true;
haxe.Timer.delay = function(f,time_ms) {
	var t = new haxe.Timer(time_ms);
	t.run = function() {
		t.stop();
		f();
	};
	return t;
};
haxe.Timer.prototype = {
	stop: function() {
		if(this.id == null) return;
		clearInterval(this.id);
		this.id = null;
	}
	,run: function() {
	}
};
haxe.ds = {};
haxe.ds.BalancedTree = function() {
};
haxe.ds.BalancedTree.__name__ = true;
haxe.ds.BalancedTree.prototype = {
	set: function(key,value) {
		this.root = this.setLoop(key,value,this.root);
	}
	,get: function(key) {
		var node = this.root;
		while(node != null) {
			var c = this.compare(key,node.key);
			if(c == 0) return node.value;
			if(c < 0) node = node.left; else node = node.right;
		}
		return null;
	}
	,setLoop: function(k,v,node) {
		if(node == null) return new haxe.ds.TreeNode(null,k,v,null);
		var c = this.compare(k,node.key);
		if(c == 0) return new haxe.ds.TreeNode(node.left,k,v,node.right,node == null?0:node._height); else if(c < 0) {
			var nl = this.setLoop(k,v,node.left);
			return this.balance(nl,node.key,node.value,node.right);
		} else {
			var nr = this.setLoop(k,v,node.right);
			return this.balance(node.left,node.key,node.value,nr);
		}
	}
	,balance: function(l,k,v,r) {
		var hl;
		if(l == null) hl = 0; else hl = l._height;
		var hr;
		if(r == null) hr = 0; else hr = r._height;
		if(hl > hr + 2) {
			if((function($this) {
				var $r;
				var _this = l.left;
				$r = _this == null?0:_this._height;
				return $r;
			}(this)) >= (function($this) {
				var $r;
				var _this1 = l.right;
				$r = _this1 == null?0:_this1._height;
				return $r;
			}(this))) return new haxe.ds.TreeNode(l.left,l.key,l.value,new haxe.ds.TreeNode(l.right,k,v,r)); else return new haxe.ds.TreeNode(new haxe.ds.TreeNode(l.left,l.key,l.value,l.right.left),l.right.key,l.right.value,new haxe.ds.TreeNode(l.right.right,k,v,r));
		} else if(hr > hl + 2) {
			if((function($this) {
				var $r;
				var _this2 = r.right;
				$r = _this2 == null?0:_this2._height;
				return $r;
			}(this)) > (function($this) {
				var $r;
				var _this3 = r.left;
				$r = _this3 == null?0:_this3._height;
				return $r;
			}(this))) return new haxe.ds.TreeNode(new haxe.ds.TreeNode(l,k,v,r.left),r.key,r.value,r.right); else return new haxe.ds.TreeNode(new haxe.ds.TreeNode(l,k,v,r.left.left),r.left.key,r.left.value,new haxe.ds.TreeNode(r.left.right,r.key,r.value,r.right));
		} else return new haxe.ds.TreeNode(l,k,v,r,(hl > hr?hl:hr) + 1);
	}
	,compare: function(k1,k2) {
		return Reflect.compare(k1,k2);
	}
};
haxe.ds.TreeNode = function(l,k,v,r,h) {
	if(h == null) h = -1;
	this.left = l;
	this.key = k;
	this.value = v;
	this.right = r;
	if(h == -1) this._height = ((function($this) {
		var $r;
		var _this = $this.left;
		$r = _this == null?0:_this._height;
		return $r;
	}(this)) > (function($this) {
		var $r;
		var _this1 = $this.right;
		$r = _this1 == null?0:_this1._height;
		return $r;
	}(this))?(function($this) {
		var $r;
		var _this2 = $this.left;
		$r = _this2 == null?0:_this2._height;
		return $r;
	}(this)):(function($this) {
		var $r;
		var _this3 = $this.right;
		$r = _this3 == null?0:_this3._height;
		return $r;
	}(this))) + 1; else this._height = h;
};
haxe.ds.TreeNode.__name__ = true;
haxe.ds.EnumValueMap = function() {
	haxe.ds.BalancedTree.call(this);
};
haxe.ds.EnumValueMap.__name__ = true;
haxe.ds.EnumValueMap.__interfaces__ = [IMap];
haxe.ds.EnumValueMap.__super__ = haxe.ds.BalancedTree;
haxe.ds.EnumValueMap.prototype = $extend(haxe.ds.BalancedTree.prototype,{
	compare: function(k1,k2) {
		var d = k1[1] - k2[1];
		if(d != 0) return d;
		var p1 = k1.slice(2);
		var p2 = k2.slice(2);
		if(p1.length == 0 && p2.length == 0) return 0;
		return this.compareArgs(p1,p2);
	}
	,compareArgs: function(a1,a2) {
		var ld = a1.length - a2.length;
		if(ld != 0) return ld;
		var _g1 = 0;
		var _g = a1.length;
		while(_g1 < _g) {
			var i = _g1++;
			var d = this.compareArg(a1[i],a2[i]);
			if(d != 0) return d;
		}
		return 0;
	}
	,compareArg: function(v1,v2) {
		if(Reflect.isEnumValue(v1) && Reflect.isEnumValue(v2)) return this.compare(v1,v2); else if((v1 instanceof Array) && v1.__enum__ == null && ((v2 instanceof Array) && v2.__enum__ == null)) return this.compareArgs(v1,v2); else return Reflect.compare(v1,v2);
	}
});
haxe.ds.ObjectMap = function() {
	this.h = { };
	this.h.__keys__ = { };
};
haxe.ds.ObjectMap.__name__ = true;
haxe.ds.ObjectMap.__interfaces__ = [IMap];
haxe.ds.ObjectMap.prototype = {
	set: function(key,value) {
		var id = key.__id__ || (key.__id__ = ++haxe.ds.ObjectMap.count);
		this.h[id] = value;
		this.h.__keys__[id] = key;
	}
	,remove: function(key) {
		var id = key.__id__;
		if(this.h.__keys__[id] == null) return false;
		delete(this.h[id]);
		delete(this.h.__keys__[id]);
		return true;
	}
};
var jp = {};
jp.seibe = {};
jp.seibe.lib = {};
jp.seibe.lib.value = {};
jp.seibe.lib.value.Value = function(newValue) {
	this.flag = false;
	this._value = newValue;
};
jp.seibe.lib.value.Value.__name__ = true;
jp.seibe.lib.value.Value.prototype = {
	set_value: function(newValue) {
		this.flag = this.flag || this._value != newValue;
		this._value = newValue;
		return this._value;
	}
	,get_value: function() {
		this.flag = false;
		return this._value;
	}
	,get_silentValue: function() {
		return this._value;
	}
};
jp.seibe.speed = {};
jp.seibe.speed.client = {};
jp.seibe.speed.client.CardManager = function() {
	this._isInit = false;
	var this1;
	this1 = new Array(2);
	this._fieldCardList = this1;
	var this2;
	this2 = new Array(2);
	this._talonCardList = this2;
	var this3;
	this3 = new Array(2);
	this._talonCardLength = this3;
	var this4;
	this4 = new Array(2);
	this._handCardList = this4;
	var _g = 0;
	while(_g < 2) {
		var i = _g++;
		var val = new jp.seibe.lib.value.Value(jp.seibe.speed.common.CardSuit.NONE);
		this._fieldCardList[i] = val;
		var val1 = new Array();
		this._talonCardList[i] = val1;
		var val2 = new jp.seibe.lib.value.Value();
		this._talonCardLength[i] = val2;
		var val3;
		var this5;
		this5 = new Array(4);
		val3 = this5;
		this._handCardList[i] = val3;
		var _g1 = 0;
		while(_g1 < 4) {
			var j = _g1++;
			var val4 = new jp.seibe.lib.value.Value(jp.seibe.speed.common.CardSuit.NONE);
			this._handCardList[i][j] = val4;
		}
	}
};
jp.seibe.speed.client.CardManager.__name__ = true;
jp.seibe.speed.client.CardManager.getInstance = function() {
	if(jp.seibe.speed.client.CardManager._instance == null) jp.seibe.speed.client.CardManager._instance = new jp.seibe.speed.client.CardManager();
	return jp.seibe.speed.client.CardManager._instance;
};
jp.seibe.speed.client.CardManager.prototype = {
	canStack: function(from,to,silent) {
		if(!this._isInit) return false;
		switch(from[1]) {
		case 0:
			var i = from[2];
			switch(to[1]) {
			case 2:
				var k = to[3];
				var j = to[2];
				if(i == j && this._handCardList[j][k].get_silentValue() == jp.seibe.speed.common.CardSuit.NONE) {
					if(silent == null || !silent) {
						this._handCardList[j][k].set_value(this._talonCardList[i].shift());
						this._talonCardLength[i].set_value(this._talonCardList[i].length);
					}
					return true;
				}
				break;
			default:
				return false;
			}
			break;
		case 2:
			var j1 = from[3];
			var i1 = from[2];
			switch(to[1]) {
			case 1:
				var k1 = to[2];
				var a = this._handCardList[i1][j1].get_silentValue();
				var b = this._fieldCardList[k1].get_silentValue();
				if(a == jp.seibe.speed.common.CardSuit.NONE) return false;
				if((function($this) {
					var $r;
					switch(a[1]) {
					case 4:
						$r = true;
						break;
					default:
						$r = false;
					}
					return $r;
				}(this)) || (function($this) {
					var $r;
					switch(b[1]) {
					case 4:
						$r = true;
						break;
					default:
						$r = false;
					}
					return $r;
				}(this))) return true;
				var aNum = a.slice(2)[0];
				var bNum = b.slice(2)[0];
				var diff;
				if(aNum > bNum) diff = aNum - bNum; else diff = bNum - aNum;
				if(diff == 1 || diff == 12) {
					if(silent == null || !silent) {
						this._fieldCardList[k1].set_value(this._handCardList[i1][j1].get_value());
						this._handCardList[i1][j1].set_value(jp.seibe.speed.common.CardSuit.NONE);
					}
					return true;
				}
				break;
			default:
				return false;
			}
			break;
		default:
			throw "ERROR";
		}
		return false;
	}
	,isClose: function() {
		if(!this._isInit) return false;
		var _g = 0;
		while(_g < 2) {
			var i = _g++;
			if(this._talonCardList[i].length == 0 && this._handCardList[i][0].get_silentValue() == jp.seibe.speed.common.CardSuit.NONE && this._handCardList[i][1].get_silentValue() == jp.seibe.speed.common.CardSuit.NONE && this._handCardList[i][2].get_silentValue() == jp.seibe.speed.common.CardSuit.NONE && this._handCardList[i][3].get_silentValue() == jp.seibe.speed.common.CardSuit.NONE) return true;
		}
		return false;
	}
	,isStalemate: function() {
		var _g = 0;
		while(_g < 2) {
			var i = _g++;
			var _g1 = 0;
			while(_g1 < 4) {
				var j = _g1++;
				if(this._handCardList[i][j].get_silentValue() == jp.seibe.speed.common.CardSuit.NONE && this._talonCardLength[i].get_silentValue() > 0) return false;
				var _g2 = 0;
				while(_g2 < 2) {
					var k = _g2++;
					if(this.canStack(jp.seibe.speed.common.CardPos.HAND(i,j),jp.seibe.speed.common.CardPos.FIELD(k),true)) return false;
				}
			}
		}
		return true;
	}
	,getDiff: function() {
		var diff = new Array();
		var _g = 0;
		while(_g < 2) {
			var i = _g++;
			if(this._fieldCardList[i].flag) diff.push({ suit : this._fieldCardList[i].get_value(), pos : jp.seibe.speed.common.CardPos.FIELD(i)});
			if(this._talonCardLength[i].flag) {
				if(this._talonCardLength[i].get_value() == 0) diff.push({ suit : jp.seibe.speed.common.CardSuit.NONE, pos : jp.seibe.speed.common.CardPos.TALON(i)}); else {
					var _g2 = 0;
					var _g1 = this._talonCardLength[i].get_value();
					while(_g2 < _g1) {
						var j = _g2++;
						diff.push({ suit : this._talonCardList[i][j], pos : jp.seibe.speed.common.CardPos.TALON(i)});
					}
				}
			}
			var _g11 = 0;
			while(_g11 < 4) {
				var j1 = _g11++;
				if(this._handCardList[i][j1].flag) diff.push({ suit : this._handCardList[i][j1].get_value(), pos : jp.seibe.speed.common.CardPos.HAND(i,j1)});
			}
		}
		return diff;
	}
	,getTalonLength: function() {
		return [this._talonCardLength[0].get_silentValue(),this._talonCardLength[1].get_silentValue()];
	}
	,update: function(diff) {
		var talon;
		var this1;
		this1 = new Array(2);
		talon = this1;
		var val = talon[1] = false;
		talon[0] = val;
		var _g = 0;
		while(_g < diff.length) {
			var card = diff[_g];
			++_g;
			{
				var _g1 = card.pos;
				switch(_g1[1]) {
				case 0:
					var i = _g1[2];
					if(!talon[i]) {
						var val1 = new Array();
						this._talonCardList[i] = val1;
						talon[i] = true;
					}
					if(card.suit != jp.seibe.speed.common.CardSuit.NONE) this._talonCardList[i].push(card.suit);
					break;
				case 2:
					var j = _g1[3];
					var i1 = _g1[2];
					this._handCardList[i1][j].set_value(card.suit);
					break;
				case 1:
					var i2 = _g1[2];
					this._fieldCardList[i2].set_value(card.suit);
					break;
				}
			}
		}
		var _g2 = 0;
		while(_g2 < 2) {
			var i3 = _g2++;
			this._talonCardLength[i3].set_value(this._talonCardList[i3].length);
		}
		this._isInit = true;
	}
	,deal: function() {
		var cardList = new Array();
		var _g = 0;
		while(_g < 2) {
			var i = _g++;
			var _g1 = 0;
			while(_g1 < 26) {
				var j = _g1++;
				cardList[j] = Type.createEnumIndex(jp.seibe.speed.common.CardSuit,i * 2 + (j / 13 | 0),[j % 13]);
			}
			var _g11 = 0;
			while(_g11 < 26) {
				var j1 = _g11++;
				var a = Std.random(26 - i);
				var b = 26 - i - 1;
				var temp = cardList[a];
				cardList[a] = cardList[b];
				cardList[b] = temp;
			}
			var _g12 = 0;
			while(_g12 < 26) {
				var j2 = _g12++;
				if(j2 < 4) this._handCardList[i][j2].set_value(cardList[j2]); else this._talonCardList[i][j2 - 4] = cardList[j2];
			}
			this._talonCardLength[i].set_value(this._talonCardList[i].length);
		}
		this._isInit = true;
		return this.getDiff();
	}
	,start: function() {
		var _g = 0;
		while(_g < 2) {
			var i = _g++;
			if(this._talonCardList[i].length > 0) {
				this._fieldCardList[i].set_value(this._talonCardList[i].shift());
				this._talonCardLength[i].set_value(this._talonCardList[i].length);
			} else {
				var _g1 = 0;
				while(_g1 < 4) {
					var j = _g1++;
					if(this._handCardList[i][j].get_value() != jp.seibe.speed.common.CardSuit.NONE) {
						this._fieldCardList[i].set_value(this._handCardList[i][j].get_value());
						this._handCardList[i][j].set_value(jp.seibe.speed.common.CardSuit.NONE);
						break;
					}
				}
			}
		}
	}
	,close: function() {
		this._isInit = false;
	}
};
jp.seibe.speed.client.DomManager = function() {
	this._window = window;
	this._notify = $("#notify");
	this._notifyTimer = null;
	this._dialog = $("#dialog");
	this._console = $("#console");
	this._draggable = false;
	this._stampCard = $("#stampcard");
	var this1;
	this1 = new Array(4);
	this._stampList = this1;
	var val = $("<img src=\"./img/stamp/stack.png\" alt=\"出せる\" />");
	this._stampList[0] = val;
	var val1 = $("<img src=\"./img/stamp/urge.png\" alt=\"出せない\" />");
	this._stampList[1] = val1;
	var val2 = $("<img src=\"./img/stamp/glad.png\" alt=\"よゆう\" />");
	this._stampList[2] = val2;
	var val3 = $("<img src=\"./img/stamp/sad.png\" alt=\"あせる\" />");
	this._stampList[3] = val3;
	var this2;
	this2 = new Array(4);
	this._stampButtonList = this2;
	var val4 = $("#stamp-button-stack");
	this._stampButtonList[0] = val4;
	var val5 = $("#stamp-button-urge");
	this._stampButtonList[1] = val5;
	var val6 = $("#stamp-button-glad");
	this._stampButtonList[2] = val6;
	var val7 = $("#stamp-button-sad");
	this._stampButtonList[3] = val7;
	this._cardSrcMap = new haxe.ds.EnumValueMap();
	this._cardSrcMap.set(jp.seibe.speed.common.CardSuit.NONE,"img/card/null.png");
	var _g = 0;
	while(_g < 13) {
		var i = _g++;
		var istr;
		if(i < 9) istr = "0" + Std.string(i + 1); else istr = Std.string(i + 1);
		var key = jp.seibe.speed.common.CardSuit.CLUB(i);
		this._cardSrcMap.set(key,"img/card/c" + istr + ".png");
		var key1 = jp.seibe.speed.common.CardSuit.SPADE(i);
		this._cardSrcMap.set(key1,"img/card/s" + istr + ".png");
		var key2 = jp.seibe.speed.common.CardSuit.DIAMOND(i);
		this._cardSrcMap.set(key2,"img/card/d" + istr + ".png");
		var key3 = jp.seibe.speed.common.CardSuit.HEART(i);
		this._cardSrcMap.set(key3,"img/card/h" + istr + ".png");
	}
};
jp.seibe.speed.client.DomManager.__name__ = true;
jp.seibe.speed.client.DomManager.getInstance = function() {
	if(jp.seibe.speed.client.DomManager._instance == null) jp.seibe.speed.client.DomManager._instance = new jp.seibe.speed.client.DomManager();
	return jp.seibe.speed.client.DomManager._instance;
};
jp.seibe.speed.client.DomManager.prototype = {
	getElement: function(selector) {
		return $(selector);
	}
	,setClientType: function(clientType) {
		this._clientType = clientType;
		var this1;
		this1 = new Array(2);
		this._talonLength = this1;
		this._cardDomMap = new haxe.ds.EnumValueMap();
		var _g = 0;
		while(_g < 2) {
			var i = _g++;
			var pre;
			if(i == jp.seibe.speed.common._Speed.ClientType_Impl_.toInt(this._clientType)) pre = "#stage-player-"; else pre = "#stage-enemy-";
			var val = $(pre + "talon-length");
			this._talonLength[i] = val;
			var key = jp.seibe.speed.common.CardPos.TALON(i);
			var value = $(pre + "talon");
			this._cardDomMap.set(key,value);
			var key1 = jp.seibe.speed.common.CardPos.FIELD(i ^ this._clientType);
			var value1 = $("#stage-field-" + (i == null?"null":"" + i));
			this._cardDomMap.set(key1,value1);
			var _g1 = 0;
			while(_g1 < 4) {
				var j = _g1++;
				var key2 = jp.seibe.speed.common.CardPos.HAND(i,j);
				var value2 = $(pre + "hand-" + (j == null?"null":"" + j));
				this._cardDomMap.set(key2,value2);
			}
		}
	}
	,notify: function(text,ms) {
		var _g = this;
		this._notify.text(text);
		if(ms > 0) {
			if(this._notifyTimer != null) this._notifyTimer.stop();
			this._notifyTimer = haxe.Timer.delay(function() {
				_g._notify.text("");
				_g._notifyTimer = null;
			},ms);
		}
	}
	,drawCard: function(cardList) {
		if(cardList == null) return;
		var _g = 0;
		while(_g < cardList.length) {
			var card = cardList[_g];
			++_g;
			this.drawCardAt(card.pos,card.suit);
		}
	}
	,drawCardAt: function(pos,suit) {
		switch(pos[1]) {
		case 0:
			var i = pos[2];
			if(suit == jp.seibe.speed.common.CardSuit.NONE) this._cardDomMap.get(pos).attr("src",this._cardSrcMap.get(suit)); else this._cardDomMap.get(pos).attr("src","img/card/back.png");
			break;
		default:
			this._cardDomMap.get(pos).attr("src",this._cardSrcMap.get(suit));
		}
	}
	,drawTalon: function(lengthList) {
		var _g = 0;
		while(_g < 2) {
			var i = _g++;
			if(lengthList[i] == 0) this._talonLength[i].text(""); else this._talonLength[i].text(Std.string(lengthList[i]));
		}
	}
	,drawStamp: function(stampType) {
		var stamp = this._stampList[stampType].clone();
		stamp.css({ left : Std.string(Std["int"](Math.random() * (this._window.innerWidth - 120))) + "px"});
		stamp.on("animationend webkitAnimationEnd",function(e) {
			stamp.remove();
		});
		this._stampCard.append(stamp);
	}
	,drawDialog: function(str) {
		if(this._dialogStr == str) return;
		if(str == null || str.length == 0) this._dialog.html(""); else this._dialog.html("<span>" + str + "</span>");
		this._dialogStr = str;
	}
	,enableStamp: function(listner) {
		$("#stamp").removeClass("hidden");
		var _g = 0;
		while(_g < 4) {
			var i = [_g++];
			this._stampButtonList[i[0]].on("click",(function(i) {
				return function(e) {
					listner(i[0]);
				};
			})(i));
		}
	}
	,disableStamp: function() {
		$("#stamp").addClass("hidden");
		var _g = 0;
		while(_g < 4) {
			var i = _g++;
			this._stampButtonList[i].off("click");
		}
	}
	,enableDrag: function(listner) {
		var _g = this;
		if(this._draggable == true) return;
		this._draggable = true;
		this._dragListener = listner;
		this._dragIdMap = new haxe.ds.ObjectMap();
		this._dragPointMap = new haxe.ds.ObjectMap();
		var talon;
		var key = jp.seibe.speed.common.CardPos.TALON(jp.seibe.speed.common._Speed.ClientType_Impl_.toInt(this._clientType));
		talon = this._cardDomMap.get(key);
		talon.on("mousedown mousemove mouseup mouseout",function(e) {
			_g.onClickCard(e,jp.seibe.speed.common.CardPos.TALON(jp.seibe.speed.common._Speed.ClientType_Impl_.toInt(_g._clientType)));
		});
		talon.on("touchstart touchmove touchend touchcancel",function(e1) {
			_g.onTouchCard(e1,jp.seibe.speed.common.CardPos.TALON(jp.seibe.speed.common._Speed.ClientType_Impl_.toInt(_g._clientType)));
		});
		var _g1 = 0;
		while(_g1 < 4) {
			var i = [_g1++];
			var hand;
			var key1 = jp.seibe.speed.common.CardPos.HAND(jp.seibe.speed.common._Speed.ClientType_Impl_.toInt(this._clientType),i[0]);
			hand = this._cardDomMap.get(key1);
			hand.on("mousedown mousemove mouseup mouseout",(function(i) {
				return function(e2) {
					_g.onClickCard(e2,jp.seibe.speed.common.CardPos.HAND(jp.seibe.speed.common._Speed.ClientType_Impl_.toInt(_g._clientType),i[0]));
				};
			})(i));
			hand.on("touchstart touchmove touchend touchcancel",(function(i) {
				return function(e3) {
					_g.onTouchCard(e3,jp.seibe.speed.common.CardPos.HAND(jp.seibe.speed.common._Speed.ClientType_Impl_.toInt(_g._clientType),i[0]));
				};
			})(i));
		}
	}
	,disableDrag: function() {
		if(this._draggable == false) return;
		this._draggable = false;
		var _g = 0;
		while(_g < 2) {
			var i = _g++;
			((function($this) {
				var $r;
				var key = jp.seibe.speed.common.CardPos.TALON(i);
				$r = $this._cardDomMap.get(key);
				return $r;
			}(this))).off("mousedown mousemove mouseup mouseout touchstart touchmove touchend touchcancel");
			var _g1 = 0;
			while(_g1 < 4) {
				var j = _g1++;
				((function($this) {
					var $r;
					var key1 = jp.seibe.speed.common.CardPos.HAND(i,j);
					$r = $this._cardDomMap.get(key1);
					return $r;
				}(this))).off("mousedown mousemove mouseup mouseout touchstart touchmove touchend touchcancel");
			}
		}
		this._dragListener = null;
		this._dragIdMap = null;
		this._dragPointMap = null;
	}
	,dragCard: function(e,client) {
		switch(e[1]) {
		case 0:
			var pos = e[2];
			this._cardDomMap.get(pos).css({ transform : "matrix3d(1.2,0,0,0,0,1.2,0,0,0,0,1,0,0,0,0,1)", 'z-index' : "999"});
			break;
		case 1:
			var dy = e[4];
			var dx = e[3];
			var pos1 = e[2];
			this._cardDomMap.get(pos1).css({ transform : "matrix3d(1.2,0,0,0,0,1.2,0,0,0,0,1,0," + (dx == null?"null":"" + dx) + "," + (dy == null?"null":"" + dy) + ",0,1)", 'z-index' : "999"});
			break;
		case 2:
			var to = e[3];
			var from = e[2];
			this._cardDomMap.get(from).css({ transform : "", 'z-index' : ""});
			if((function($this) {
				var $r;
				switch(from[1]) {
				case 2:
					$r = true;
					break;
				default:
					$r = false;
				}
				return $r;
			}(this))) this.drawCardAt(from,jp.seibe.speed.common.CardSuit.NONE);
			break;
		case 3:
			var pos2 = e[2];
			this._cardDomMap.get(pos2).css({ transform : "", 'z-index' : ""});
			break;
		}
	}
	,onClickCard: function(e,pos) {
		e.preventDefault();
		var target = this._cardDomMap.get(pos);
		var _g = e.type;
		switch(_g) {
		case "mousedown":
			this._dragPointMap.set(target,{ x : e.pageX, y : e.pageY});
			this._dragListener(jp.seibe.speed.common.CardDragEvent.DRAG_BEGIN(pos));
			break;
		case "mousemove":
			var beginPoint = this._dragPointMap.h[target.__id__];
			if(beginPoint == null) return;
			var dx = e.pageX - beginPoint.x;
			var dy = e.pageY - beginPoint.y;
			this._dragListener(jp.seibe.speed.common.CardDragEvent.DRAG_MOVE(pos,dx,dy));
			break;
		case "mouseup":
			if(this._dragPointMap.h[target.__id__] == null) return;
			var to = this.whereStack(pos);
			if(to != null) this._dragListener(jp.seibe.speed.common.CardDragEvent.DRAG_END(pos,to)); else this._dragListener(jp.seibe.speed.common.CardDragEvent.DRAG_CANCEL(pos));
			this._dragPointMap.remove(target);
			break;
		case "mouseout":
			if(this._dragPointMap.h[target.__id__] == null) return;
			this._dragListener(jp.seibe.speed.common.CardDragEvent.DRAG_CANCEL(pos));
			this._dragPointMap.remove(target);
			break;
		}
	}
	,onTouchCard: function(e,pos) {
		e.preventDefault();
		var target = this._cardDomMap.get(pos);
		var _g = e.type;
		switch(_g) {
		case "touchstart":
			var i = e.touches.length - 1;
			this._dragPointMap.set(target,{ x : e.touches.item(i).pageX, y : e.touches.item(i).pageY});
			this._dragIdMap.set(target,e.touches.item(i).identifier);
			this._dragListener(jp.seibe.speed.common.CardDragEvent.DRAG_BEGIN(pos));
			break;
		case "touchmove":
			var id = this._dragIdMap.h[target.__id__];
			if(id == null) return;
			var _g1 = 0;
			var _g2 = e.changedTouches;
			while(_g1 < _g2.length) {
				var touch = _g2[_g1];
				++_g1;
				if(id == touch.identifier) {
					var beginPoint = this._dragPointMap.h[target.__id__];
					var dx = touch.pageX - beginPoint.x;
					var dy = touch.pageY - beginPoint.y;
					this._dragListener(jp.seibe.speed.common.CardDragEvent.DRAG_MOVE(pos,dx,dy));
				}
			}
			break;
		case "touchend":
			var id1 = this._dragIdMap.h[target.__id__];
			if(id1 == null) return;
			var to = this.whereStack(pos);
			if(to != null) this._dragListener(jp.seibe.speed.common.CardDragEvent.DRAG_END(pos,to)); else this._dragListener(jp.seibe.speed.common.CardDragEvent.DRAG_CANCEL(pos));
			this._dragIdMap.remove(target);
			this._dragPointMap.remove(target);
			break;
		case "touchcancel":
			var id2 = this._dragIdMap.h[target.__id__];
			if(id2 == null) return;
			this._dragListener(jp.seibe.speed.common.CardDragEvent.DRAG_CANCEL(pos));
			this._dragIdMap.remove(target);
			this._dragPointMap.remove(target);
			break;
		}
	}
	,whereStack: function(from) {
		var offset = this._cardDomMap.get(from).offset();
		var distArea = 8100;
		var min = distArea;
		var distList;
		var targetOffset;
		var dx;
		var dy;
		switch(from[1]) {
		case 0:
			var i = from[2];
			var this1;
			this1 = new Array(4);
			distList = this1;
			var _g = 0;
			while(_g < 4) {
				var j = _g++;
				targetOffset = ((function($this) {
					var $r;
					var key = jp.seibe.speed.common.CardPos.HAND(i,j);
					$r = $this._cardDomMap.get(key);
					return $r;
				}(this))).offset();
				dx = offset.left - targetOffset.left;
				dy = offset.top - targetOffset.top;
				distList[j] = dx * dx + dy * dy;
				if(distList[j] < min) min = distList[j]; else min = min;
			}
			if(min < distArea) {
				var _g1 = 0;
				while(_g1 < 4) {
					var j1 = _g1++;
					if(min == distList[j1]) return jp.seibe.speed.common.CardPos.HAND(i,j1);
				}
			}
			break;
		case 2:
			var j2 = from[3];
			var i1 = from[2];
			var this2;
			this2 = new Array(2);
			distList = this2;
			var _g2 = 0;
			while(_g2 < 2) {
				var j3 = _g2++;
				targetOffset = ((function($this) {
					var $r;
					var key1 = jp.seibe.speed.common.CardPos.FIELD(j3);
					$r = $this._cardDomMap.get(key1);
					return $r;
				}(this))).offset();
				dx = offset.left - targetOffset.left;
				dy = offset.top - targetOffset.top;
				distList[j3] = dx * dx + dy * dy;
				if(distList[j3] < min) min = distList[j3]; else min = min;
			}
			if(min < distArea) {
				var _g3 = 0;
				while(_g3 < 2) {
					var j4 = _g3++;
					if(min == distList[j4]) return jp.seibe.speed.common.CardPos.FIELD(j4);
				}
			}
			break;
		default:
			return null;
		}
		return null;
	}
};
jp.seibe.speed.client.GameClient = function() {
	this.FRAME_RATE = 60;
	this.card = jp.seibe.speed.client.CardManager.getInstance();
	this.dom = jp.seibe.speed.client.DomManager.getInstance();
	this.socket = jp.seibe.speed.client.SocketManager.getInstance();
	this.type = 0;
	this.delayTime = 0;
	this.diffTime = 0;
	this._state = new jp.seibe.speed.client.state.StartState(this);
	this._state.start();
};
jp.seibe.speed.client.GameClient.__name__ = true;
jp.seibe.speed.client.GameClient.prototype = {
	start: function() {
		this._timer = new haxe.Timer(1000 / this.FRAME_RATE | 0);
		this._timer.run = $bind(this,this.onUpdate);
		this._isDrawSync = ($_=window,$bind($_,$_.requestAnimationFrame)) == null;
		if(!this._isDrawSync) window.requestAnimationFrame($bind(this,this.onRequestAnimation));
	}
	,change: function(to) {
		if(this._state != null) this._state.stop();
		switch(to[1]) {
		case 0:
			this._state = new jp.seibe.speed.client.state.StartState(this);
			break;
		case 1:
			this._state = new jp.seibe.speed.client.state.ConnectState(this);
			break;
		case 2:
			this._state = new jp.seibe.speed.client.state.MatchState(this);
			break;
		case 3:
			this._state = new jp.seibe.speed.client.state.NegotiateState(this);
			break;
		case 4:
			this._state = new jp.seibe.speed.client.state.IngameState(this);
			break;
		case 5:
			this._state = new jp.seibe.speed.client.state.FinishState(this);
			break;
		case 6:
			this._state = null;
			break;
		}
		if(this._state != null) this._state.start();
	}
	,onUpdate: function() {
		if(this._state != null) {
			this._state.update();
			if(this._isDrawSync) this._state.draw();
		}
	}
	,onRequestAnimation: function(time) {
		if(this._state != null) this._state.draw();
		window.requestAnimationFrame($bind(this,this.onRequestAnimation));
		return true;
	}
};
jp.seibe.speed.client.Main = function() {
	window.onload = $bind(this,this.init);
};
jp.seibe.speed.client.Main.__name__ = true;
jp.seibe.speed.client.Main.main = function() {
	new jp.seibe.speed.client.Main();
};
jp.seibe.speed.client.Main.prototype = {
	init: function(e) {
		this._client = new jp.seibe.speed.client.GameClient();
		this._client.start();
	}
};
jp.seibe.speed.client.SocketStatus = { __ename__ : true, __constructs__ : ["CLOSE","CONNECTING","MATCHING","CONNECT_WS","CONNECT_ALL"] };
jp.seibe.speed.client.SocketStatus.CLOSE = ["CLOSE",0];
jp.seibe.speed.client.SocketStatus.CLOSE.toString = $estr;
jp.seibe.speed.client.SocketStatus.CLOSE.__enum__ = jp.seibe.speed.client.SocketStatus;
jp.seibe.speed.client.SocketStatus.CONNECTING = ["CONNECTING",1];
jp.seibe.speed.client.SocketStatus.CONNECTING.toString = $estr;
jp.seibe.speed.client.SocketStatus.CONNECTING.__enum__ = jp.seibe.speed.client.SocketStatus;
jp.seibe.speed.client.SocketStatus.MATCHING = ["MATCHING",2];
jp.seibe.speed.client.SocketStatus.MATCHING.toString = $estr;
jp.seibe.speed.client.SocketStatus.MATCHING.__enum__ = jp.seibe.speed.client.SocketStatus;
jp.seibe.speed.client.SocketStatus.CONNECT_WS = ["CONNECT_WS",3];
jp.seibe.speed.client.SocketStatus.CONNECT_WS.toString = $estr;
jp.seibe.speed.client.SocketStatus.CONNECT_WS.__enum__ = jp.seibe.speed.client.SocketStatus;
jp.seibe.speed.client.SocketStatus.CONNECT_ALL = ["CONNECT_ALL",4];
jp.seibe.speed.client.SocketStatus.CONNECT_ALL.toString = $estr;
jp.seibe.speed.client.SocketStatus.CONNECT_ALL.__enum__ = jp.seibe.speed.client.SocketStatus;
jp.seibe.speed.client.SocketManager = function() {
	this.WS_URL = "ws://seibe.jp:8080/ws/speed";
	this._status = jp.seibe.speed.client.SocketStatus.CLOSE;
	this._sendDataList = new Array();
	this._receiveDataList = new Array();
};
jp.seibe.speed.client.SocketManager.__name__ = true;
jp.seibe.speed.client.SocketManager.getInstance = function() {
	if(jp.seibe.speed.client.SocketManager._instance == null) jp.seibe.speed.client.SocketManager._instance = new jp.seibe.speed.client.SocketManager();
	return jp.seibe.speed.client.SocketManager._instance;
};
jp.seibe.speed.client.SocketManager.prototype = {
	connect: function(callback) {
		var _g = this;
		if(this._status != jp.seibe.speed.client.SocketStatus.CLOSE) this.close();
		this._status = jp.seibe.speed.client.SocketStatus.CONNECTING;
		this._pc = new RTCPeerConnection({ iceServers : [{ url : "stun:stun.l.google.com:19302"}]});
		this._pc.onicecandidate = $bind(this,this.onIceCandidate);
		this._pc.ondatachannel = $bind(this,this.onDataChannel);
		this._ws = new WebSocket(this.WS_URL);
		this._ws.onopen = function(e) {
			if(_g._status == jp.seibe.speed.client.SocketStatus.CLOSE) return;
			_g._status = jp.seibe.speed.client.SocketStatus.MATCHING;
			callback(true);
			_g._ws.onerror = $bind(_g,_g.onErrorWs);
		};
		this._ws.onclose = $bind(this,this.onCloseWs);
		this._ws.onmessage = $bind(this,this.onReceiveWs);
		this._ws.onerror = function(e1) {
			if(_g._status == jp.seibe.speed.client.SocketStatus.CONNECTING) {
				callback(false);
				_g.close();
			}
		};
		haxe.Timer.delay(function() {
			if(_g._status == jp.seibe.speed.client.SocketStatus.CONNECTING) {
				callback(false);
				_g.close();
			}
		},3000);
	}
	,send: function(msg) {
		if(this._status != jp.seibe.speed.client.SocketStatus.CONNECT_ALL) return false;
		switch(msg[1]) {
		case 0:
			this._sendDataList.push(jp.seibe.speed.common._Speed.RemoteProto_Impl_.toInt(1));
			this._sendDataList.push(0);
			break;
		case 1:
			var timestamp_f = msg[2];
			var timestamp = timestamp_f / 1000 | 0;
			this._sendDataList.push(jp.seibe.speed.common._Speed.RemoteProto_Impl_.toInt(1));
			this._sendDataList.push(timestamp >> 28);
			this._sendDataList.push(timestamp >> 24 & 15);
			this._sendDataList.push(timestamp >> 20 & 15);
			this._sendDataList.push(timestamp >> 16 & 15);
			this._sendDataList.push(timestamp >> 12 & 15);
			this._sendDataList.push(timestamp >> 8 & 15);
			this._sendDataList.push(timestamp >> 4 & 15);
			this._sendDataList.push(timestamp & 15);
			break;
		case 4:
			this._sendDataList.push(jp.seibe.speed.common._Speed.RemoteProto_Impl_.toInt(4));
			this._sendDataList.push(0);
			break;
		case 8:
			var diff = msg[2];
			if(diff == null || diff.length == 0) return false;
			this._sendDataList.push(jp.seibe.speed.common._Speed.RemoteProto_Impl_.toInt(8));
			this._sendDataList.push(diff.length >> 4);
			this._sendDataList.push(diff.length & 15);
			var _g = 0;
			while(_g < diff.length) {
				var card = diff[_g];
				++_g;
				var data;
				{
					var _g1 = card.suit;
					switch(_g1[1]) {
					case 0:
						var i = _g1[2];
						data = i;
						break;
					case 1:
						var i1 = _g1[2];
						data = 13 + i1;
						break;
					case 2:
						var i2 = _g1[2];
						data = 26 + i2;
						break;
					case 3:
						var i3 = _g1[2];
						data = 39 + i3;
						break;
					case 4:
						data = 62;
						break;
					case 5:
						data = 63;
						break;
					}
				}
				this._sendDataList.push(data >> 4);
				this._sendDataList.push(data & 15);
				data = this.posToInt(card.pos);
				this._sendDataList.push(data);
			}
			break;
		case 5:
			var timestamp_f1 = msg[2];
			var timestamp1 = timestamp_f1 / 1000 | 0;
			var timestamp_mm = timestamp_f1 % 1000 | 0;
			this._sendDataList.push(jp.seibe.speed.common._Speed.RemoteProto_Impl_.toInt(5));
			this._sendDataList.push(timestamp1 >> 28);
			this._sendDataList.push(timestamp1 >> 24 & 15);
			this._sendDataList.push(timestamp1 >> 20 & 15);
			this._sendDataList.push(timestamp1 >> 16 & 15);
			this._sendDataList.push(timestamp1 >> 12 & 15);
			this._sendDataList.push(timestamp1 >> 8 & 15);
			this._sendDataList.push(timestamp1 >> 4 & 15);
			this._sendDataList.push(timestamp1 & 15);
			this._sendDataList.push(timestamp_mm >> 8 & 15);
			this._sendDataList.push(timestamp_mm >> 4 & 15);
			this._sendDataList.push(timestamp_mm & 15);
			break;
		case 9:
			var e = msg[2];
			this._sendDataList.push(jp.seibe.speed.common._Speed.RemoteProto_Impl_.toInt(9));
			switch(e[1]) {
			case 0:
				var from = e[2];
				this._sendDataList.push(0);
				this._sendDataList.push(this.posToInt(from));
				break;
			case 1:
				var dy = e[4];
				var dx = e[3];
				var from1 = e[2];
				this._sendDataList.push(1);
				this._sendDataList.push(this.posToInt(from1));
				this._sendDataList.push(dx >>> 28 & 15);
				this._sendDataList.push(dx >>> 24 & 15);
				this._sendDataList.push(dx >>> 20 & 15);
				this._sendDataList.push(dx >>> 16 & 15);
				this._sendDataList.push(dx >>> 12 & 15);
				this._sendDataList.push(dx >>> 8 & 15);
				this._sendDataList.push(dx >>> 4 & 15);
				this._sendDataList.push(dx >>> 0 & 15);
				this._sendDataList.push(dy >>> 28 & 15);
				this._sendDataList.push(dy >>> 24 & 15);
				this._sendDataList.push(dy >>> 20 & 15);
				this._sendDataList.push(dy >>> 16 & 15);
				this._sendDataList.push(dy >>> 12 & 15);
				this._sendDataList.push(dy >>> 8 & 15);
				this._sendDataList.push(dy >>> 4 & 15);
				this._sendDataList.push(dy >>> 0 & 15);
				break;
			case 2:
				var to = e[3];
				var from2 = e[2];
				this._sendDataList.push(2);
				this._sendDataList.push(this.posToInt(from2));
				this._sendDataList.push(this.posToInt(to));
				break;
			case 3:
				var from3 = e[2];
				this._sendDataList.push(3);
				this._sendDataList.push(this.posToInt(from3));
				break;
			}
			break;
		case 6:
			this._sendDataList.push(jp.seibe.speed.common._Speed.RemoteProto_Impl_.toInt(6));
			break;
		case 10:
			var stampType = msg[2];
			this._sendDataList.push(jp.seibe.speed.common._Speed.RemoteProto_Impl_.toInt(10));
			this._sendDataList.push(stampType & 15);
			break;
		case 2:
			haxe.Log.trace("未実装: send-ack",{ fileName : "SocketManager.hx", lineNumber : 207, className : "jp.seibe.speed.client.SocketManager", methodName : "send"});
			break;
		case 3:
			haxe.Log.trace("未実装: send-nak",{ fileName : "SocketManager.hx", lineNumber : 210, className : "jp.seibe.speed.client.SocketManager", methodName : "send"});
			break;
		default:
			haxe.Log.trace("send-error: 0",{ fileName : "SocketManager.hx", lineNumber : 213, className : "jp.seibe.speed.client.SocketManager", methodName : "send"});
			return false;
		}
		var dataLength = this._sendDataList.length;
		if(dataLength > 0) {
			var byteLength = Math.ceil(dataLength / 2);
			var data1 = new Uint8Array(byteLength);
			var _g2 = 0;
			while(_g2 < byteLength) {
				var i4 = _g2++;
				if(i4 * 2 + 1 == dataLength) data1[i4] = this._sendDataList[i4 * 2] << 4; else data1[i4] = (this._sendDataList[i4 * 2] << 4) + this._sendDataList[i4 * 2 + 1];
			}
			try {
				this._dc.send(data1);
			} catch( e1 ) {
				this.close();
				return false;
			}
			this._sendDataList = new Array();
		}
		return true;
	}
	,receive: function() {
		if(this._receiveDataList.length == 0) return null;
		var header = this._receiveDataList.shift();
		switch(header) {
		case 1:
			var flag = this._receiveDataList.shift();
			if(flag == 0) return jp.seibe.speed.common.Proto.PING; else {
				var timestamp = flag << 28;
				timestamp += this._receiveDataList.shift() << 24;
				timestamp += this._receiveDataList.shift() << 20;
				timestamp += this._receiveDataList.shift() << 16;
				timestamp += this._receiveDataList.shift() << 12;
				timestamp += this._receiveDataList.shift() << 8;
				timestamp += this._receiveDataList.shift() << 4;
				timestamp += this._receiveDataList.shift();
				return jp.seibe.speed.common.Proto.PONG(timestamp * 1000);
			}
			break;
		case 2:
			return jp.seibe.speed.common.Proto.ACK;
		case 3:
			return jp.seibe.speed.common.Proto.NAK;
		case 4:
			var data = this._receiveDataList.shift();
			if(data == 1) return jp.seibe.speed.common.Proto.MATCHING(0); else if(data == 2) return jp.seibe.speed.common.Proto.MATCHING(1); else throw "データ破損？";
			break;
		case 5:
			var timestamp1 = this._receiveDataList.shift() << 28;
			timestamp1 += this._receiveDataList.shift() << 24;
			timestamp1 += this._receiveDataList.shift() << 20;
			timestamp1 += this._receiveDataList.shift() << 16;
			timestamp1 += this._receiveDataList.shift() << 12;
			timestamp1 += this._receiveDataList.shift() << 8;
			timestamp1 += this._receiveDataList.shift() << 4;
			timestamp1 += this._receiveDataList.shift();
			timestamp1 *= 1000;
			timestamp1 += this._receiveDataList.shift() << 8;
			timestamp1 += this._receiveDataList.shift() << 4;
			timestamp1 += this._receiveDataList.shift();
			return jp.seibe.speed.common.Proto.START(timestamp1);
		case 6:
			return jp.seibe.speed.common.Proto.FINISH;
		case 7:
			var errno = this._receiveDataList.shift();
			return jp.seibe.speed.common.Proto.ERROR(errno);
		case 8:
			var diff = new Array();
			var length = this._receiveDataList.shift();
			length = (length << 4) + this._receiveDataList.shift();
			var _g = 0;
			while(_g < length) {
				var i = _g++;
				var card = { suit : null, pos : null};
				var data1 = (this._receiveDataList.shift() << 4) + this._receiveDataList.shift();
				if(data1 == 63) card.suit = jp.seibe.speed.common.CardSuit.NONE; else if(data1 == 62) card.suit = jp.seibe.speed.common.CardSuit.JOKER; else card.suit = Type.createEnumIndex(jp.seibe.speed.common.CardSuit,data1 / 13 | 0,[data1 % 13]);
				data1 = this._receiveDataList.shift();
				card.pos = this.intToPos(data1);
				diff.push(card);
			}
			return jp.seibe.speed.common.Proto.UPDATE(diff);
		case 9:
			var type = this._receiveDataList.shift();
			var from = this._receiveDataList.shift();
			switch(type) {
			case 0:
				return jp.seibe.speed.common.Proto.DRAG(jp.seibe.speed.common.CardDragEvent.DRAG_BEGIN(this.intToPos(from)));
			case 1:
				var dx = this._receiveDataList.shift() << 28;
				dx += this._receiveDataList.shift() << 24;
				dx += this._receiveDataList.shift() << 20;
				dx += this._receiveDataList.shift() << 16;
				dx += this._receiveDataList.shift() << 12;
				dx += this._receiveDataList.shift() << 8;
				dx += this._receiveDataList.shift() << 4;
				dx += this._receiveDataList.shift();
				if(dx >= -2147483648) dx = (-1 - dx + 1) * -1; else dx = dx;
				var dy = this._receiveDataList.shift() << 28;
				dy += this._receiveDataList.shift() << 24;
				dy += this._receiveDataList.shift() << 20;
				dy += this._receiveDataList.shift() << 16;
				dy += this._receiveDataList.shift() << 12;
				dy += this._receiveDataList.shift() << 8;
				dy += this._receiveDataList.shift() << 4;
				dy += this._receiveDataList.shift();
				if(dy >= -2147483648) dy = (-1 - dy + 1) * -1; else dy = dy;
				return jp.seibe.speed.common.Proto.DRAG(jp.seibe.speed.common.CardDragEvent.DRAG_MOVE(this.intToPos(from),-dx,-dy));
			case 2:
				var to = this._receiveDataList.shift();
				return jp.seibe.speed.common.Proto.DRAG(jp.seibe.speed.common.CardDragEvent.DRAG_END(this.intToPos(from),this.intToPos(to)));
			case 3:
				return jp.seibe.speed.common.Proto.DRAG(jp.seibe.speed.common.CardDragEvent.DRAG_CANCEL(this.intToPos(from)));
			}
			break;
		case 10:
			var type1 = this._receiveDataList.shift();
			return jp.seibe.speed.common.Proto.STAMP(type1);
		default:
			return null;
		}
		return null;
	}
	,close: function() {
		if(this._status != jp.seibe.speed.client.SocketStatus.CLOSE) {
			this._ws.close();
			this._dc.close();
			this._pc.close();
		}
		this._status = jp.seibe.speed.client.SocketStatus.CLOSE;
		this._ws = null;
		this._dc = null;
		this._pc = null;
		this._sendDataList = new Array();
		this._receiveDataList = new Array();
	}
	,initDataChannel: function(dc) {
		var _g = this;
		dc.binaryType = "arraybuffer";
		dc.onopen = function(e) {
			_g._status = jp.seibe.speed.client.SocketStatus.CONNECT_ALL;
			_g._receiveDataList.push(jp.seibe.speed.common._Speed.RemoteProto_Impl_.toInt(4));
			_g._receiveDataList.push(_g._clientType);
		};
		dc.onclose = $bind(this,this.onCloseDc);
		dc.onmessage = $bind(this,this.onReceiveDc);
		dc.onerror = $bind(this,this.onErrorDc);
	}
	,onCreateSdp: function(sd) {
		var _g = this;
		this._pc.setLocalDescription(sd,function() {
			return _g._ws.send(JSON.stringify({ type : "sdp", data : sd}));
		},$bind(this,this.onFailure));
		return true;
	}
	,onFailure: function(err) {
		haxe.Log.trace(err,{ fileName : "SocketManager.hx", lineNumber : 407, className : "jp.seibe.speed.client.SocketManager", methodName : "onFailure"});
		return false;
	}
	,onIceCandidate: function(evt) {
		if(evt && evt.candidate) this._ws.send(JSON.stringify({ type : "candidate", data : evt.candidate}));
	}
	,onDataChannel: function(evt) {
		if(evt && evt.channel) {
			this._dc = evt.channel;
			this.initDataChannel(this._dc);
		}
	}
	,onReceiveWs: function(e) {
		var _g1 = this;
		var msg = JSON.parse(e.data);
		var _g = msg.type;
		switch(_g) {
		case "match":
			if(msg.data) this._clientType = 1; else this._clientType = 2;
			this._status = jp.seibe.speed.client.SocketStatus.CONNECT_WS;
			if(this._clientType == 1) {
				this._dc = this._pc.createDataChannel("speedDataChannel");
				this.initDataChannel(this._dc);
				this._pc.createOffer($bind(this,this.onCreateSdp),$bind(this,this.onFailure));
			}
			break;
		case "sdp":
			var sd = new RTCSessionDescription(msg.data);
			this._pc.setRemoteDescription(sd,function() {
				if(sd.type == "offer") _g1._pc.createAnswer($bind(_g1,_g1.onCreateSdp),$bind(_g1,_g1.onFailure));
				return true;
			},$bind(this,this.onFailure));
			break;
		case "candidate":
			var candidate = new RTCIceCandidate(msg.data);
			this._pc.addIceCandidate(candidate);
			break;
		default:
			throw "error";
		}
	}
	,onCloseWs: function(e) {
		haxe.Log.trace("ws: close",{ fileName : "SocketManager.hx", lineNumber : 467, className : "jp.seibe.speed.client.SocketManager", methodName : "onCloseWs"});
	}
	,onErrorWs: function(e) {
		throw "error";
	}
	,onReceiveDc: function(e) {
		var bytes = new Uint8Array(e.data);
		var _g1 = 0;
		var _g = bytes.byteLength;
		while(_g1 < _g) {
			var i = _g1++;
			this._receiveDataList.push(bytes[i] >> 4);
			this._receiveDataList.push(bytes[i] & 15);
		}
	}
	,onCloseDc: function(e) {
		haxe.Log.trace("dc: close",{ fileName : "SocketManager.hx", lineNumber : 486, className : "jp.seibe.speed.client.SocketManager", methodName : "onCloseDc"});
	}
	,onErrorDc: function(e) {
		throw "error";
	}
	,posToInt: function(pos) {
		var data;
		switch(pos[1]) {
		case 0:
			var i = pos[2];
			data = i;
			break;
		case 1:
			var i1 = pos[2];
			data = 2 + i1;
			break;
		case 2:
			var j = pos[3];
			var i2 = pos[2];
			data = 4 + i2 * 4 + j;
			break;
		}
		return data;
	}
	,intToPos: function(data) {
		if(data < 2) return jp.seibe.speed.common.CardPos.TALON(data); else if(data < 4) return jp.seibe.speed.common.CardPos.FIELD(data - 2);
		return jp.seibe.speed.common.CardPos.HAND((data - 4) / 4 | 0,(data - 4) % 4);
	}
};
jp.seibe.speed.client.state = {};
jp.seibe.speed.client.state.IState = function() { };
jp.seibe.speed.client.state.IState.__name__ = true;
jp.seibe.speed.client.state.ConnectState = function(client) {
	this._client = client;
};
jp.seibe.speed.client.state.ConnectState.__name__ = true;
jp.seibe.speed.client.state.ConnectState.__interfaces__ = [jp.seibe.speed.client.state.IState];
jp.seibe.speed.client.state.ConnectState.prototype = {
	start: function() {
		var _g = this;
		this._client.dom.getElement("#stage, #stamp, .start-buttons").addClass("hidden");
		this._client.dom.getElement("#start, .start-loader").removeClass("hidden");
		this._client.dom.notify("サーバーに接続中です",0);
		this._client.socket.connect(function(success) {
			if(success) _g._client.change(jp.seibe.speed.common.ClientState.MATCH); else {
				_g._client.dom.notify("サーバー接続中にエラーが発生しました。",3000);
				_g._client.change(jp.seibe.speed.common.ClientState.START);
			}
		});
	}
	,update: function() {
	}
	,draw: function() {
	}
	,stop: function() {
	}
};
jp.seibe.speed.client.state.FinishState = function(client) {
	this._client = client;
};
jp.seibe.speed.client.state.FinishState.__name__ = true;
jp.seibe.speed.client.state.FinishState.__interfaces__ = [jp.seibe.speed.client.state.IState];
jp.seibe.speed.client.state.FinishState.prototype = {
	start: function() {
		this._client.dom.disableDrag();
		this._client.dom.disableStamp();
		this._client.dom.notify("試合が終了しました。",3000);
		this._client.dom.drawDialog("");
		this._client.socket.close();
		this._client.card.close();
		this._client.change(jp.seibe.speed.common.ClientState.START);
	}
	,update: function() {
	}
	,draw: function() {
	}
	,stop: function() {
	}
};
jp.seibe.speed.client.state.IngameState = function(client) {
	this._client = client;
};
jp.seibe.speed.client.state.IngameState.__name__ = true;
jp.seibe.speed.client.state.IngameState.__interfaces__ = [jp.seibe.speed.client.state.IState];
jp.seibe.speed.client.state.IngameState.prototype = {
	start: function() {
		this._startTime = 0;
		this._dragNum = 0;
		this._prevDragTime = 0;
		this._client.dom.enableStamp($bind(this,this.onTapStamp));
		this._client.dom.notify("対戦相手が見つかりました。対戦を開始します。",3000);
		this._client.dom.getElement("#start").addClass("hidden");
		this._client.dom.getElement("#stage, #stamp").removeClass("hidden");
		var _g = 0;
		while(_g < 2) {
			var i = _g++;
			this._client.dom.drawCardAt(jp.seibe.speed.common.CardPos.FIELD(i),jp.seibe.speed.common.CardSuit.NONE);
		}
		if(this._client.type == 0) {
			var cardList = this._client.card.deal();
			this._client.dom.drawCard(cardList);
			if(this._client.socket.send(jp.seibe.speed.common.Proto.UPDATE(cardList)) == false) {
				throw "error";
				return;
			}
			this._startTime = new Date().getTime() + 5000 + this._client.delayTime;
			if(this._client.socket.send(jp.seibe.speed.common.Proto.START(this._startTime + this._client.diffTime)) == false) {
				throw "error";
				return;
			}
		}
	}
	,update: function() {
		var _g = this;
		if(this._startTime > 0) {
			var now = new Date().getTime();
			if(this._startTime > now) {
				var res = this._client.socket.receive();
				while(res != null) {
					switch(res[1]) {
					case 0:
						if(this._client.socket.send(jp.seibe.speed.common.Proto.PONG(new Date().getTime())) == false) {
							this.onFail();
							return;
						}
						break;
					case 9:
						var e = res[2];
						this._client.dom.dragCard(e,1 - this._client.type);
						break;
					case 10:
						var type = res[2];
						this._client.dom.drawStamp(type);
						break;
					case 8:
						var diff = res[2];
						haxe.Log.trace("NOTICE: カウントダウン中に同期通知",{ fileName : "IngameState.hx", lineNumber : 79, className : "jp.seibe.speed.client.state.IngameState", methodName : "update"});
						if(this._client.type == 1) {
							this._client.card.update(diff);
							this._client.dom.drawCard(this._client.card.getDiff());
						}
						break;
					case 6:
						haxe.Log.trace("NOTICE: カウントダウン中に終了通知",{ fileName : "IngameState.hx", lineNumber : 87, className : "jp.seibe.speed.client.state.IngameState", methodName : "update"});
						this._client.change(jp.seibe.speed.common.ClientState.FINISH);
						return;
					default:
						haxe.Log.trace("NOTICE: カウントダウン中に通知",{ fileName : "IngameState.hx", lineNumber : 93, className : "jp.seibe.speed.client.state.IngameState", methodName : "update", customParams : [res]});
					}
					res = this._client.socket.receive();
				}
				return;
			} else {
				this._client.card.start();
				this._client.dom.drawDialog("");
				this._client.dom.drawTalon(this._client.card.getTalonLength());
				this._client.dom.enableDrag($bind(this,this.onDragCard));
				this._startTime = 0;
			}
		}
		var res1 = this._client.socket.receive();
		while(res1 != null) {
			switch(res1[1]) {
			case 0:
				if(this._client.socket.send(jp.seibe.speed.common.Proto.PONG(new Date().getTime())) == false) {
					throw "error";
					return;
				}
				break;
			case 8:
				var diff1 = res1[2];
				this._client.card.update(diff1);
				this._client.dom.drawCard(this._client.card.getDiff());
				this._client.dom.drawTalon(this._client.card.getTalonLength());
				break;
			case 5:
				var target = res1[2];
				this._client.dom.disableDrag();
				this._startTime = target;
				break;
			case 9:
				var e1 = res1[2];
				this._client.dom.dragCard(e1,1 - this._client.type);
				break;
			case 10:
				var type1 = res1[2];
				this._client.dom.drawStamp(type1);
				break;
			case 6:
				this._client.change(jp.seibe.speed.common.ClientState.FINISH);
				return;
			default:
				throw "error";
				return;
			}
			res1 = this._client.socket.receive();
		}
		var cardList = this._client.card.getDiff();
		if(cardList.length > 0) {
			this._client.dom.drawCard(cardList);
			if(this._client.socket.send(jp.seibe.speed.common.Proto.UPDATE(cardList)) == false) {
				this.onFail();
				return;
			}
		}
		if(this._client.card.isClose()) {
			if(this._client.socket.send(jp.seibe.speed.common.Proto.FINISH) == false) {
				throw "error";
				return;
			}
			if(this._client.card.getTalonLength()[this._client.type] == 0) {
				if(this._client.card.getTalonLength()[1 - this._client.type] == 0) this._client.dom.drawDialog("引き分け"); else this._client.dom.drawDialog("勝利");
			} else this._client.dom.drawDialog("敗北");
			haxe.Timer.delay(function() {
				_g._client.change(jp.seibe.speed.common.ClientState.FINISH);
			},3000);
			this._client.change(jp.seibe.speed.common.ClientState.NOTHING);
			return;
		} else if(this._client.type == 0 && this._client.card.isStalemate()) {
			this._startTime = new Date().getTime() + 5000 + this._client.delayTime;
			if(this._client.socket.send(jp.seibe.speed.common.Proto.START(this._startTime + this._client.diffTime)) == false) {
				this.onFail();
				return;
			}
		}
	}
	,draw: function() {
		if(this._startTime > 0) {
			var now = new Date().getTime();
			var msg = Std.string(((this._startTime - now) / 1000 | 0) + 1);
			this._client.dom.drawDialog(msg);
		}
	}
	,stop: function() {
		this._client.dom.disableDrag();
		this._client.dom.disableStamp();
	}
	,onFail: function() {
		this._client.dom.drawDialog("");
		this._client.dom.notify("通信に失敗しました。",3000);
		this._client.change(jp.seibe.speed.common.ClientState.START);
	}
	,onDragCard: function(e) {
		switch(e[1]) {
		case 2:
			var to = e[3];
			var from = e[2];
			if(!this._client.card.canStack(from,to)) e = jp.seibe.speed.common.CardDragEvent.DRAG_CANCEL(from); else {
				var talonLengthList = this._client.card.getTalonLength();
				this._client.dom.drawTalon(talonLengthList);
				var _g = 0;
				while(_g < 2) {
					var i = _g++;
					if(talonLengthList[i] == 0) this._client.dom.drawCardAt(jp.seibe.speed.common.CardPos.TALON(i),jp.seibe.speed.common.CardSuit.NONE);
				}
			}
			break;
		default:
		}
		this._client.dom.dragCard(e,jp.seibe.speed.common._Speed.ClientType_Impl_.toInt(this._client.type));
		var now = new Date().getTime();
		if(!(function($this) {
			var $r;
			switch(e[1]) {
			case 1:
				$r = true;
				break;
			default:
				$r = false;
			}
			return $r;
		}(this)) || now - this._prevDragTime > 33) {
			if(this._client.socket.send(jp.seibe.speed.common.Proto.DRAG(e)) == false) {
				this.onFail();
				return;
			}
			this._prevDragTime = now;
		}
	}
	,onTapStamp: function(stampType) {
		if(this._client.socket.send(jp.seibe.speed.common.Proto.STAMP(stampType)) == false) {
			this.onFail();
			return;
		}
	}
};
jp.seibe.speed.client.state.MatchState = function(client) {
	this._client = client;
};
jp.seibe.speed.client.state.MatchState.__name__ = true;
jp.seibe.speed.client.state.MatchState.__interfaces__ = [jp.seibe.speed.client.state.IState];
jp.seibe.speed.client.state.MatchState.prototype = {
	start: function() {
		this._client.dom.notify("対戦相手を待っています",0);
	}
	,update: function() {
		var res = this._client.socket.receive();
		if(res != null) switch(res[1]) {
		case 4:
			var clientType = res[2];
			this._client.type = clientType;
			this._client.dom.setClientType(clientType);
			this._client.change(jp.seibe.speed.common.ClientState.NEGOTIATE);
			break;
		default:
			throw "受信エラー";
		}
	}
	,draw: function() {
	}
	,stop: function() {
	}
};
jp.seibe.speed.client.state.NegotiateState = function(client) {
	this.PING_MAX = 10;
	this._client = client;
};
jp.seibe.speed.client.state.NegotiateState.__name__ = true;
jp.seibe.speed.client.state.NegotiateState.__interfaces__ = [jp.seibe.speed.client.state.IState];
jp.seibe.speed.client.state.NegotiateState.prototype = {
	start: function() {
		this._client.delayTime = 0;
		this._client.diffTime = 0;
		this._pingCount = 0;
		this._prevPingTime = new Date().getTime();
		if(!this._client.socket.send(jp.seibe.speed.common.Proto.PING)) throw "送信エラー";
	}
	,update: function() {
		var res = this._client.socket.receive();
		while(res != null) {
			switch(res[1]) {
			case 0:
				if(this._client.socket.send(jp.seibe.speed.common.Proto.PONG(new Date().getTime())) == false) throw "送信エラー";
				break;
			case 1:
				var timestamp = res[2];
				this._pingCount++;
				var now = new Date().getTime();
				var delay = now - this._prevPingTime;
				var diff = (timestamp * 2 - this._prevPingTime - now) / 2;
				this._client.delayTime += delay;
				this._client.diffTime += diff;
				if(this._pingCount < this.PING_MAX) {
					this._prevPingTime = new Date().getTime();
					if(!this._client.socket.send(jp.seibe.speed.common.Proto.PING)) throw "送信エラー";
				} else {
					this._client.delayTime = this._client.delayTime / this.PING_MAX;
					this._client.diffTime = (this._client.diffTime / this.PING_MAX / 1000 | 0) * 1000;
					haxe.Log.trace("ズレ: ",{ fileName : "NegotiateState.hx", lineNumber : 60, className : "jp.seibe.speed.client.state.NegotiateState", methodName : "update", customParams : [this._client.delayTime,this._client.diffTime]});
					this._client.change(jp.seibe.speed.common.ClientState.INGAME);
				}
				break;
			default:
				throw "受信エラー";
			}
			res = this._client.socket.receive();
		}
	}
	,draw: function() {
	}
	,stop: function() {
	}
};
jp.seibe.speed.client.state.StartState = function(client) {
	this._client = client;
};
jp.seibe.speed.client.state.StartState.__name__ = true;
jp.seibe.speed.client.state.StartState.__interfaces__ = [jp.seibe.speed.client.state.IState];
jp.seibe.speed.client.state.StartState.prototype = {
	start: function() {
		var _g = this;
		this._client.dom.getElement("#stage, #stamp, .start-loader").addClass("hidden");
		this._client.dom.getElement("#start, .start-buttons").removeClass("hidden");
		this._client.dom.getElement("#start-button-online").on("click",function(e) {
			_g._client.change(jp.seibe.speed.common.ClientState.CONNECT);
		});
	}
	,update: function() {
	}
	,draw: function() {
	}
	,stop: function() {
		this._client.dom.getElement("#start-button-online").off("click");
	}
};
jp.seibe.speed.common = {};
jp.seibe.speed.common.CardSuit = { __ename__ : true, __constructs__ : ["CLUB","SPADE","DIAMOND","HEART","JOKER","NONE"] };
jp.seibe.speed.common.CardSuit.CLUB = function(i) { var $x = ["CLUB",0,i]; $x.__enum__ = jp.seibe.speed.common.CardSuit; $x.toString = $estr; return $x; };
jp.seibe.speed.common.CardSuit.SPADE = function(i) { var $x = ["SPADE",1,i]; $x.__enum__ = jp.seibe.speed.common.CardSuit; $x.toString = $estr; return $x; };
jp.seibe.speed.common.CardSuit.DIAMOND = function(i) { var $x = ["DIAMOND",2,i]; $x.__enum__ = jp.seibe.speed.common.CardSuit; $x.toString = $estr; return $x; };
jp.seibe.speed.common.CardSuit.HEART = function(i) { var $x = ["HEART",3,i]; $x.__enum__ = jp.seibe.speed.common.CardSuit; $x.toString = $estr; return $x; };
jp.seibe.speed.common.CardSuit.JOKER = ["JOKER",4];
jp.seibe.speed.common.CardSuit.JOKER.toString = $estr;
jp.seibe.speed.common.CardSuit.JOKER.__enum__ = jp.seibe.speed.common.CardSuit;
jp.seibe.speed.common.CardSuit.NONE = ["NONE",5];
jp.seibe.speed.common.CardSuit.NONE.toString = $estr;
jp.seibe.speed.common.CardSuit.NONE.__enum__ = jp.seibe.speed.common.CardSuit;
jp.seibe.speed.common.CardPos = { __ename__ : true, __constructs__ : ["TALON","FIELD","HAND"] };
jp.seibe.speed.common.CardPos.TALON = function(owner) { var $x = ["TALON",0,owner]; $x.__enum__ = jp.seibe.speed.common.CardPos; $x.toString = $estr; return $x; };
jp.seibe.speed.common.CardPos.FIELD = function(index) { var $x = ["FIELD",1,index]; $x.__enum__ = jp.seibe.speed.common.CardPos; $x.toString = $estr; return $x; };
jp.seibe.speed.common.CardPos.HAND = function(owner,index) { var $x = ["HAND",2,owner,index]; $x.__enum__ = jp.seibe.speed.common.CardPos; $x.toString = $estr; return $x; };
jp.seibe.speed.common.CardDragEvent = { __ename__ : true, __constructs__ : ["DRAG_BEGIN","DRAG_MOVE","DRAG_END","DRAG_CANCEL"] };
jp.seibe.speed.common.CardDragEvent.DRAG_BEGIN = function(pos) { var $x = ["DRAG_BEGIN",0,pos]; $x.__enum__ = jp.seibe.speed.common.CardDragEvent; $x.toString = $estr; return $x; };
jp.seibe.speed.common.CardDragEvent.DRAG_MOVE = function(pos,dx,dy) { var $x = ["DRAG_MOVE",1,pos,dx,dy]; $x.__enum__ = jp.seibe.speed.common.CardDragEvent; $x.toString = $estr; return $x; };
jp.seibe.speed.common.CardDragEvent.DRAG_END = function(from,to) { var $x = ["DRAG_END",2,from,to]; $x.__enum__ = jp.seibe.speed.common.CardDragEvent; $x.toString = $estr; return $x; };
jp.seibe.speed.common.CardDragEvent.DRAG_CANCEL = function(pos) { var $x = ["DRAG_CANCEL",3,pos]; $x.__enum__ = jp.seibe.speed.common.CardDragEvent; $x.toString = $estr; return $x; };
jp.seibe.speed.common.ClientState = { __ename__ : true, __constructs__ : ["START","CONNECT","MATCH","NEGOTIATE","INGAME","FINISH","NOTHING"] };
jp.seibe.speed.common.ClientState.START = ["START",0];
jp.seibe.speed.common.ClientState.START.toString = $estr;
jp.seibe.speed.common.ClientState.START.__enum__ = jp.seibe.speed.common.ClientState;
jp.seibe.speed.common.ClientState.CONNECT = ["CONNECT",1];
jp.seibe.speed.common.ClientState.CONNECT.toString = $estr;
jp.seibe.speed.common.ClientState.CONNECT.__enum__ = jp.seibe.speed.common.ClientState;
jp.seibe.speed.common.ClientState.MATCH = ["MATCH",2];
jp.seibe.speed.common.ClientState.MATCH.toString = $estr;
jp.seibe.speed.common.ClientState.MATCH.__enum__ = jp.seibe.speed.common.ClientState;
jp.seibe.speed.common.ClientState.NEGOTIATE = ["NEGOTIATE",3];
jp.seibe.speed.common.ClientState.NEGOTIATE.toString = $estr;
jp.seibe.speed.common.ClientState.NEGOTIATE.__enum__ = jp.seibe.speed.common.ClientState;
jp.seibe.speed.common.ClientState.INGAME = ["INGAME",4];
jp.seibe.speed.common.ClientState.INGAME.toString = $estr;
jp.seibe.speed.common.ClientState.INGAME.__enum__ = jp.seibe.speed.common.ClientState;
jp.seibe.speed.common.ClientState.FINISH = ["FINISH",5];
jp.seibe.speed.common.ClientState.FINISH.toString = $estr;
jp.seibe.speed.common.ClientState.FINISH.__enum__ = jp.seibe.speed.common.ClientState;
jp.seibe.speed.common.ClientState.NOTHING = ["NOTHING",6];
jp.seibe.speed.common.ClientState.NOTHING.toString = $estr;
jp.seibe.speed.common.ClientState.NOTHING.__enum__ = jp.seibe.speed.common.ClientState;
jp.seibe.speed.common._Speed = {};
jp.seibe.speed.common._Speed.ClientType_Impl_ = function() { };
jp.seibe.speed.common._Speed.ClientType_Impl_.__name__ = true;
jp.seibe.speed.common._Speed.ClientType_Impl_.toInt = function(this1) {
	return this1;
};
jp.seibe.speed.common.Proto = { __ename__ : true, __constructs__ : ["PING","PONG","ACK","NAK","MATCHING","START","FINISH","ERROR","UPDATE","DRAG","STAMP"] };
jp.seibe.speed.common.Proto.PING = ["PING",0];
jp.seibe.speed.common.Proto.PING.toString = $estr;
jp.seibe.speed.common.Proto.PING.__enum__ = jp.seibe.speed.common.Proto;
jp.seibe.speed.common.Proto.PONG = function(timestamp) { var $x = ["PONG",1,timestamp]; $x.__enum__ = jp.seibe.speed.common.Proto; $x.toString = $estr; return $x; };
jp.seibe.speed.common.Proto.ACK = ["ACK",2];
jp.seibe.speed.common.Proto.ACK.toString = $estr;
jp.seibe.speed.common.Proto.ACK.__enum__ = jp.seibe.speed.common.Proto;
jp.seibe.speed.common.Proto.NAK = ["NAK",3];
jp.seibe.speed.common.Proto.NAK.toString = $estr;
jp.seibe.speed.common.Proto.NAK.__enum__ = jp.seibe.speed.common.Proto;
jp.seibe.speed.common.Proto.MATCHING = function(clientType) { var $x = ["MATCHING",4,clientType]; $x.__enum__ = jp.seibe.speed.common.Proto; $x.toString = $estr; return $x; };
jp.seibe.speed.common.Proto.START = function(timestamp) { var $x = ["START",5,timestamp]; $x.__enum__ = jp.seibe.speed.common.Proto; $x.toString = $estr; return $x; };
jp.seibe.speed.common.Proto.FINISH = ["FINISH",6];
jp.seibe.speed.common.Proto.FINISH.toString = $estr;
jp.seibe.speed.common.Proto.FINISH.__enum__ = jp.seibe.speed.common.Proto;
jp.seibe.speed.common.Proto.ERROR = function(errno) { var $x = ["ERROR",7,errno]; $x.__enum__ = jp.seibe.speed.common.Proto; $x.toString = $estr; return $x; };
jp.seibe.speed.common.Proto.UPDATE = function(diff) { var $x = ["UPDATE",8,diff]; $x.__enum__ = jp.seibe.speed.common.Proto; $x.toString = $estr; return $x; };
jp.seibe.speed.common.Proto.DRAG = function(e) { var $x = ["DRAG",9,e]; $x.__enum__ = jp.seibe.speed.common.Proto; $x.toString = $estr; return $x; };
jp.seibe.speed.common.Proto.STAMP = function(stampType) { var $x = ["STAMP",10,stampType]; $x.__enum__ = jp.seibe.speed.common.Proto; $x.toString = $estr; return $x; };
jp.seibe.speed.common._Speed.RemoteProto_Impl_ = function() { };
jp.seibe.speed.common._Speed.RemoteProto_Impl_.__name__ = true;
jp.seibe.speed.common._Speed.RemoteProto_Impl_.toInt = function(this1) {
	return this1;
};
var js = {};
js.Boot = function() { };
js.Boot.__name__ = true;
js.Boot.__unhtml = function(s) {
	return s.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
};
js.Boot.__trace = function(v,i) {
	var msg;
	if(i != null) msg = i.fileName + ":" + i.lineNumber + ": "; else msg = "";
	msg += js.Boot.__string_rec(v,"");
	if(i != null && i.customParams != null) {
		var _g = 0;
		var _g1 = i.customParams;
		while(_g < _g1.length) {
			var v1 = _g1[_g];
			++_g;
			msg += "," + js.Boot.__string_rec(v1,"");
		}
	}
	var d;
	if(typeof(document) != "undefined" && (d = document.getElementById("haxe:trace")) != null) d.innerHTML += js.Boot.__unhtml(msg) + "<br/>"; else if(typeof console != "undefined" && console.log != null) console.log(msg);
};
js.Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) t = "object";
	switch(t) {
	case "object":
		if(o instanceof Array) {
			if(o.__enum__) {
				if(o.length == 2) return o[0];
				var str = o[0] + "(";
				s += "\t";
				var _g1 = 2;
				var _g = o.length;
				while(_g1 < _g) {
					var i = _g1++;
					if(i != 2) str += "," + js.Boot.__string_rec(o[i],s); else str += js.Boot.__string_rec(o[i],s);
				}
				return str + ")";
			}
			var l = o.length;
			var i1;
			var str1 = "[";
			s += "\t";
			var _g2 = 0;
			while(_g2 < l) {
				var i2 = _g2++;
				str1 += (i2 > 0?",":"") + js.Boot.__string_rec(o[i2],s);
			}
			str1 += "]";
			return str1;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e ) {
			return "???";
		}
		if(tostr != null && tostr != Object.toString) {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str2 = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		for( var k in o ) {
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str2.length != 2) str2 += ", \n";
		str2 += s + k + " : " + js.Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str2 += "\n" + s + "}";
		return str2;
	case "function":
		return "<function>";
	case "string":
		return o;
	default:
		return String(o);
	}
};
var $_, $fid = 0;
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $fid++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; o.hx__closures__[m.__id__] = f; } return f; }
Math.NaN = Number.NaN;
Math.NEGATIVE_INFINITY = Number.NEGATIVE_INFINITY;
Math.POSITIVE_INFINITY = Number.POSITIVE_INFINITY;
Math.isFinite = function(i) {
	return isFinite(i);
};
Math.isNaN = function(i1) {
	return isNaN(i1);
};
String.__name__ = true;
Array.__name__ = true;
Date.__name__ = ["Date"];
window.requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame || window.msRequestAnimationFrame;
window.RTCPeerConnection = window.RTCPeerConnection || window.webkitRTCPeerConnection || window.mozRTCPeerConnection;
window.RTCIceCandidate = window.RTCIceCandidate || window.mozRTCIceCandidate;
window.RTCSessionDescription = window.RTCSessionDescription || window.mozRTCSessionDescription;
var q = window.Zepto;
js.Zepto = q;
haxe.ds.ObjectMap.count = 0;
jp.seibe.speed.client.Main.main();
})();

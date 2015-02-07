(function () { "use strict";
var HxOverrides = function() { };
HxOverrides.__name__ = true;
HxOverrides.cca = function(s,index) {
	var x = s.charCodeAt(index);
	if(x != x) return undefined;
	return x;
};
HxOverrides.substr = function(s,pos,len) {
	if(pos != null && pos != 0 && len != null && len < 0) return "";
	if(len == null) len = s.length;
	if(pos < 0) {
		pos = s.length + pos;
		if(pos < 0) pos = 0;
	} else if(len < 0) len = s.length + len - pos;
	return s.substr(pos,len);
};
HxOverrides.indexOf = function(a,obj,i) {
	var len = a.length;
	if(i < 0) {
		i += len;
		if(i < 0) i = 0;
	}
	while(i < len) {
		if(a[i] === obj) return i;
		i++;
	}
	return -1;
};
HxOverrides.remove = function(a,obj) {
	var i = HxOverrides.indexOf(a,obj,0);
	if(i == -1) return false;
	a.splice(i,1);
	return true;
};
var Std = function() { };
Std.__name__ = true;
Std.string = function(s) {
	return js.Boot.__string_rec(s,"");
};
Std.parseInt = function(x) {
	var v = parseInt(x,10);
	if(v == 0 && (HxOverrides.cca(x,1) == 120 || HxOverrides.cca(x,1) == 88)) v = parseInt(x);
	if(isNaN(v)) return null;
	return v;
};
var jp = {};
jp.seibe = {};
jp.seibe.speed = {};
jp.seibe.speed.server = {};
jp.seibe.speed.server.GameServer = function() {
};
jp.seibe.speed.server.GameServer.__name__ = true;
jp.seibe.speed.server.GameServer.prototype = {
	run: function() {
		this._combList = new Array();
		this._server = new WsServer({ port : 8080, path : "/ws/speed"});
		this._server.on(js.node._WsServer.WsServerEvent_Impl_.toString("connection"),$bind(this,this.onOpen));
	}
	,getOpponent: function(ws) {
		var _g = 0;
		var _g1 = this._combList;
		while(_g < _g1.length) {
			var comb = _g1[_g];
			++_g;
			if(comb[0] == ws) return { ws : comb[1], comb : comb}; else if(comb[1] == ws) return { ws : comb[0], comb : comb};
		}
		return null;
	}
	,onOpen: function(client) {
		var _g = this;
		console.log("open: (" + this._server.clients.length + ")");
		client.on(js.node._WsServer.WsSocketEvent_Impl_.toString("message"),function(data,flags) {
			_g.onMessage(client,data,flags);
		});
		client.on(js.node._WsServer.WsSocketEvent_Impl_.toString("close"),function(code,msg) {
			_g.onClose(client,code,msg);
		});
		client.on(js.node._WsServer.WsSocketEvent_Impl_.toString("error"),function(error) {
			_g.onError(client,error);
		});
		var length = this._combList.length;
		if(length == 0 || this._combList[length - 1][1] != null) {
			var comb;
			var this1;
			this1 = new Array(2);
			comb = this1;
			comb[0] = client;
			comb[1] = null;
			this._combList.push(comb);
			console.log("wating...");
		} else {
			this._combList[length - 1][1] = client;
			console.log("match!!");
			var data1 = new Uint8Array(1);
			data1[0] = (4 << 4) + 1;
			console.log("send: " + data1[0]);
			this._combList[length - 1][0].send(data1);
			data1[0] = (4 << 4) + 2;
			console.log("send: " + data1[0]);
			this._combList[length - 1][1].send(data1);
		}
	}
	,onMessage: function(ws,data,flags) {
		if(!flags.binary) {
			console.log("エラー: 不正なデータ");
			return;
		}
		var opp = this.getOpponent(ws);
		if(opp.ws != null) {
			if(ws == opp.comb[0]) console.log("pass data from host."); else console.log("pass data from guest.");
			opp.ws.send(data);
		}
	}
	,onClose: function(ws,code,msg) {
		console.log("close: " + Std.string(code));
		var opp = this.getOpponent(ws);
		if(opp != null) {
			if(ws == opp.comb[0]) console.log("(host close)"); else console.log("(guest close)");
			if(opp.ws != null) opp.ws.close();
			if(opp.comb != null) HxOverrides.remove(this._combList,opp.comb);
		}
	}
	,onError: function(ws,error) {
		console.log("error: " + Std.string(error));
		var opp = this.getOpponent(ws);
		if(opp.ws != null) opp.ws.close();
		HxOverrides.remove(this._combList,opp.comb);
	}
};
jp.seibe.speed.server.Main = function() {
	this._server = new jp.seibe.speed.server.GameServer();
	this._server.run();
};
jp.seibe.speed.server.Main.__name__ = true;
jp.seibe.speed.server.Main.main = function() {
	new jp.seibe.speed.server.Main();
};
var js = {};
js.Boot = function() { };
js.Boot.__name__ = true;
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
js.Node = function() { };
js.Node.__name__ = true;
js.node = {};
js.node._WsServer = {};
js.node._WsServer.WsSocketEvent_Impl_ = function() { };
js.node._WsServer.WsSocketEvent_Impl_.__name__ = true;
js.node._WsServer.WsSocketEvent_Impl_.toString = function(this1) {
	return this1;
};
js.node._WsServer.WsServerEvent_Impl_ = function() { };
js.node._WsServer.WsServerEvent_Impl_.__name__ = true;
js.node._WsServer.WsServerEvent_Impl_.toString = function(this1) {
	return this1;
};
var $_, $fid = 0;
function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $fid++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; o.hx__closures__[m.__id__] = f; } return f; }
if(Array.prototype.indexOf) HxOverrides.indexOf = function(a,o,i) {
	return Array.prototype.indexOf.call(a,o,i);
};
String.__name__ = true;
Array.__name__ = true;
if(Array.prototype.map == null) Array.prototype.map = function(f) {
	var a = [];
	var _g1 = 0;
	var _g = this.length;
	while(_g1 < _g) {
		var i = _g1++;
		a[i] = f(this[i]);
	}
	return a;
};
js.Node.setTimeout = setTimeout;
js.Node.clearTimeout = clearTimeout;
js.Node.setInterval = setInterval;
js.Node.clearInterval = clearInterval;
js.Node.global = global;
js.Node.process = process;
js.Node.require = require;
js.Node.console = console;
js.Node.module = module;
js.Node.stringify = JSON.stringify;
js.Node.parse = JSON.parse;
var version = HxOverrides.substr(js.Node.process.version,1,null).split(".").map(Std.parseInt);
if(version[0] > 0 || version[1] >= 9) {
	js.Node.setImmediate = setImmediate;
	js.Node.clearImmediate = clearImmediate;
}
var WsServer = js.Node.require("ws").Server;
jp.seibe.speed.server.Main.main();
})();

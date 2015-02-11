package jp.seibe.speed.server;
import haxe.ds.Vector;
import haxe.Json;
import jp.seibe.speed.common.Speed;
import js.html.Uint8Array;
import js.Node;
import js.node.WsServer;

class GameServer
{
	private var _server:WsServer;
	private var _combList:Array<Vector<WsSocket> >;

	public function new() 
	{
		//
	}
	
	public function run()
	{
		_combList = new Array<Vector<WsSocket> >();
		
		_server = new WsServer( { port: 8080, path: '/ws/speed' } );
		_server.on(WsServerEvent.CONNECTION, onOpen);
	}
	
	public function stop()
	{
		_server.close();
		_server = null;
		_combList = null;
	}
	
	private function getOpponent(ws:WsSocket):{ws:WsSocket, comb:Vector<WsSocket>}
	{
		for (comb in _combList) {
			if (comb[0] == ws) return {ws: comb[1], comb: comb};
			else if (comb[1] == ws) return {ws: comb[0], comb: comb};
		}
		
		return null;
	}
	
	private function onOpen(client:WsSocket):Void
	{
		//trace("open: (" + _server.clients.length + ")");
		
		// イベント登録
		client.on(WsSocketEvent.MESSAGE, function (data:Dynamic, flags:WsSocketFlags):Void {
			onMessage(client, data, flags);
		});
		client.on(WsSocketEvent.CLOSE, function (code:Dynamic, msg:Dynamic):Void {
			onClose(client, code, msg);
		});
		client.on(WsSocketEvent.ERROR, function (error:Dynamic):Void {
			onError(client, error);
		});
		
		// マッチング処理
		var length:Int = _combList.length;
		if (length == 0 || _combList[length - 1][1] != null) {
			// 新しい組み合わせを作る
			var comb:Vector<WsSocket> = new Vector<WsSocket>(2);
			comb[0] = client;
			comb[1] = null;
			_combList.push(comb);
			
			// 待機させる
			//trace("wating...");
		}
		else {
			// 待機していたプレイヤーと組み合わせる
			_combList[length - 1][1] = client;
			//trace("match!!");
			
			// マッチング成功通知
			_combList[length - 1][0].send(Json.stringify({
				type: "match",
				data: true
			}));
			_combList[length - 1][1].send(Json.stringify({
				type: "match",
				data: false
			}));
			/*
			var data:Uint8Array = new Uint8Array(1);
			data[0] = (RemoteProto.MATCH << 4) + 1;
			trace("send: " + data[0]);
			_combList[length - 1][0].send(data);
			data[0] = (RemoteProto.MATCH << 4) + 2;
			trace("send: " + data[0]);
			_combList[length - 1][1].send(data);
			*/
		}
	}
	
	private function onMessage(ws:WsSocket, data:Dynamic, flags:WsSocketFlags):Void
	{
		var opp = getOpponent(ws);
		if (opp.ws != null) {
			opp.ws.send(data);
		}
	}
	
	private function onClose(ws:WsSocket, code:Dynamic, msg:Dynamic):Void
	{
		//trace("close: " + code);
		
		// 対戦相手の接続を切り、マッチングリストから削除する
		var opp = getOpponent(ws);
		if (opp != null) {
			//if (ws == opp.comb[0]) trace("(host close)");
			//else trace("(guest close)");
			
			if (opp.ws != null) {
				opp.ws.close();
			}
			if (opp.comb != null) _combList.remove(opp.comb);
		}
	}
	
	private function onError(ws:WsSocket, error:Dynamic):Void
	{
		trace("error: " + error);
		
		// 対戦相手の接続を切り、マッチングリストから削除する
		var opp = getOpponent(ws);
		if (opp.ws != null) opp.ws.close();
		_combList.remove(opp.comb);
	}
	
}
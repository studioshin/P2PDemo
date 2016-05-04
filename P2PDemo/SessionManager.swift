//
//  SessionManager.swift
//  P2PDemo
//
//  Created by STUDIO SHIN on 2016/05/04.
//  Copyright © 2016年 STUDIO SHIN. All rights reserved.
//

import UIKit
import MultipeerConnectivity

//ステータス
enum SessionManagerState : Int {
	
	case NotConnected		//未接続
	case Connecting			//接続中
	case Connected			//接続完了
}


//デリゲートメソッド
// ベーシック
protocol SessionManagerBasicDelegate {
	//メンバー更新通知
	func sessionManagerDidChangeConnectedMember(sessionManager: SessionManager, 
	                                            memberName: String, 
	                                            state: SessionManagerState)
	//セッション結果
	func sessionManagerSessionConnectResult(sessionManager: SessionManager, ok: Bool)
	//データ受信
	func sessionManagerDidRecieveData(sessionManager: SessionManager, 
	                                  data: NSData?, 
	                                  name: String, 
	                                  displayName: String)
	//メッセージ受信
	func sessionManagerDidRecieveMessage(sessionManager: SessionManager, 
	                                     message: String, 
	                                     displayName: String)
	
}
// カスタム
protocol SessionManagerCustomDelegate {
	//ステータス更新通知
	func sessionManagerDidChangeConnectedPeer(sessionManager: SessionManager, 
	                                          peerID: MCPeerID, 
	                                          state: SessionManagerState)
	//招待通知結果
	func sessionManagerInvitationResult(sessionManager: SessionManager, 
	                                    peerID: MCPeerID, 
	                                    handler: (ok: Bool) -> Void)
	//ピア発見通知
	func sessionManagerFoundPeer(sessionManager: SessionManager, 
	                             peerID: MCPeerID)
	//ピア消失通知
	func sessionManagerLostPeer(sessionManager: SessionManager, 
	                            peerID: MCPeerID)
}


class SessionManager: NSObject, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
	
	var basicDelegate: SessionManagerBasicDelegate?
	var advertiserAssistant: MCAdvertiserAssistant!
	var peerID: MCPeerID!
	var session: MCSession!
	
	
	var customDelegate: SessionManagerCustomDelegate?
	var advertiser: MCNearbyServiceAdvertiser!
	var browser: MCNearbyServiceBrowser!
	
	
	//クラスが削除される前にセッションを停止させる
	deinit {
		self.stop()
	}
	
	func stop() {
		
		self.advertiserAssistant?.stop()
		self.advertiserAssistant = nil
		
		self.browser?.stopBrowsingForPeers()
		self.browser = nil
		
		self.advertiser?.stopAdvertisingPeer()
		self.advertiser = nil
		
		self.session?.disconnect()
		self.session = nil
		
		self.peerID = nil
	}
	
	/*==================================================
	//MARK: - 指定イニシャライザ
	==================================================*/
	init(displayName: String, 
	     serviceType: String, 
	     viewController: UIViewController) {
		
		super.init()
		
		// ピアとセッションを作成する
		self.makePeerAndSession(displayName)
		
		/*==================== 
		アドバタイズ開始 
		====================*/
		self.advertiserAssistant = MCAdvertiserAssistant(serviceType: serviceType, 
		                                                 discoveryInfo: nil, 
		                                                 session: self.session)
		self.advertiserAssistant.start()
		
		/*==================== 
		ブラウザーを表示する 
		====================*/
		let browser = MCBrowserViewController(serviceType: serviceType, 
		                                      session: self.session)
		browser.delegate = self;
		browser.minimumNumberOfPeers = kMCSessionMinimumNumberOfPeers	// 最小接続数 = 2
		browser.maximumNumberOfPeers = kMCSessionMaximumNumberOfPeers	// 最大接続数 = 8
		viewController.presentViewController(browser, animated: true, completion: nil)
	}
	
	
	// ホストとクライアントに分けて接続UIカスタム
	init(displayName: String, serviceType: String) {
		
		super.init()
		
		// ピアとセッションを作成する
		self.makePeerAndSession(displayName)
		
		/*==================== 
		ブラウズ 
		====================*/
		self.browser = MCNearbyServiceBrowser(peer: self.peerID, 
		                                      serviceType: serviceType)
		self.browser.delegate = self
		self.browser.startBrowsingForPeers()	//Peer の検索を開始
		
		
		/*==================== 
		アドバタイズ 
		====================*/
		self.advertiser = MCNearbyServiceAdvertiser(peer: self.peerID, 
		                                            discoveryInfo: nil, 
		                                            serviceType: serviceType)
		self.advertiser.delegate = self
		self.advertiser.startAdvertisingPeer()	//Peer の告知を開始
	}
	
	// ピアとセッションを作成する
	private func makePeerAndSession(displayName: String) {
		
		// ピアを作成する
		self.peerID = MCPeerID(displayName: displayName)
		
		// セッションを作成する
		self.session = MCSession(peer: self.peerID, 
		                         securityIdentity: nil, 
		                         encryptionPreference: .Required)
		self.session.delegate = self
	}
	
	
	
	
	//MARK: - インスタンスメソッド
	func sendMsaage(message: String, nameList: [String]?, handler: (Bool) -> Void ) {
		
		if let data = message.dataUsingEncoding(NSUTF8StringEncoding) {
			var sendPeers: [MCPeerID] = []
			if let list =  nameList {
				for name in list {
					var start = 0
					for i in start ..< self.session.connectedPeers.count {
						start += 1
						let peer = self.session.connectedPeers[i] 
						if name == peer.displayName {
							sendPeers.append(peer)
							break
						}
					}
				}
			} else {
				sendPeers = self.session.connectedPeers
			}
			do{
				try self.session.sendData(data, toPeers: sendPeers, withMode: .Reliable)
				handler(true)
			}
			catch {
				print("送信失敗！")
				handler(false)
			}
		} else {
			handler(false)
		}
	}
	
	func sendURL(url: NSURL, nameList: [String]?, handler: (displayName: String, ok: Bool) -> Void ) {
		
		var sendPeers: [MCPeerID] = []
		if let list =  nameList {
			for name in list {
				var start = 0
				for i in start ..< self.session.connectedPeers.count {
					start += 1
					let peer = self.session.connectedPeers[i] 
					if name == peer.displayName {
						sendPeers.append(peer)
						break
					}
				}
			}
		} else {
			sendPeers = self.session.connectedPeers
		}
		for peer in sendPeers {
			self.session.sendResourceAtURL(url, withName: url.lastPathComponent!, 
			                               toPeer: peer, 
			                               withCompletionHandler: { (error) -> Void in
				if error != nil {
					print("送信失敗！" + peer.displayName + "\(error!)")
					handler(displayName: peer.displayName, ok: false)
				} else {
					print("送信成功！" + peer.displayName)
					handler(displayName: peer.displayName, ok: true)
				}
			})
		}
	}
	
	func connectedMembers() -> [String] {
		
		var ary: [String] = []
		if let session = self.session {
			for peer in session.connectedPeers {
				let displayName = peer.displayName
				ary.append(displayName)
			}
		}
		return ary
	}
	
	//招待を送る
	func sendInvite(peer: AnyObject) {
		
		let peerID = peer as! MCPeerID
		self.browser.invitePeer(peerID, toSession: self.session, 
		                        withContext: nil, 
		                        timeout: 60)
	}
	
	func convertState(sta: MCSessionState) -> SessionManagerState {
		
		var ret: SessionManagerState = .NotConnected
		if sta == .Connecting {
			ret = .Connecting
		}
		else if sta == .Connected {
			ret = .Connected
		}
		return ret
	}
	
	
	//--------------------------------------------
	//MARK: - MCBrowserViewControllerDelegate
	//--------------------------------------------
	// 完了ボタンがタップされた	＜リクエスト＞
	func browserViewControllerDidFinish(browserViewController: MCBrowserViewController) {
		
		browserViewController.dismissViewControllerAnimated(true, completion: nil)
		self.basicDelegate?.sessionManagerSessionConnectResult(self, ok: true)
	}
	
	// キャンセルボタンがタップされた	＜リクエスト＞
	func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController) {
		
		self.stop()
		browserViewController.dismissViewControllerAnimated(true, completion: nil)
		self.basicDelegate?.sessionManagerSessionConnectResult(self, ok: false)
	}
	
	// peerIDのユーザーを除外したい場合は false を返す	＜オプショナル＞
	func browserViewController(browserViewController: MCBrowserViewController, 
	                           shouldPresentNearbyPeer peerID: MCPeerID, 
	                                                   withDiscoveryInfo info: [String : String]?) -> Bool {
		
		return true
	}
	
	
	//--------------------------------------------
	//MARK: - MCNearbyServiceBrowserDelegate
	//--------------------------------------------
	//Peer を発見した際に呼ばれる	＜リクエスト＞
	func browser(browser: MCNearbyServiceBrowser, 
	             foundPeer peerID: MCPeerID, 
	             withDiscoveryInfo info: [String : String]?) {
		
		print("Peerを発見:\(peerID.displayName)")
		
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			self.customDelegate?.sessionManagerFoundPeer(self, peerID: peerID)
		})
	}
	
	// Peer を見失った際に呼ばれる	＜リクエスト＞
	func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
		
		print("Peerを見失った:\(peerID.displayName)")
		
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			self.customDelegate?.sessionManagerLostPeer(self, peerID: peerID)
		})
	}
	
	// エラー	　＜オプショナル＞
	func browser(browser: MCNearbyServiceBrowser, 
	             didNotStartBrowsingForPeers error: NSError) {
		
		print(error.localizedDescription)
	}
	
	
	//--------------------------------------------
	//MARK: - MCNearbyServiceAdvertiserDelegate
	//--------------------------------------------
	// ホストから招待を受けたときに呼ばれる	＜リクエスト＞
	func advertiser(advertiser: MCNearbyServiceAdvertiser, 
	                didReceiveInvitationFromPeer peerID: MCPeerID, 
	                                             withContext context: NSData?, 
	                                                         invitationHandler: (Bool, MCSession) -> Void) {
		
		print("ホストからの招待:\(peerID.displayName)")
		
		self.customDelegate?.sessionManagerInvitationResult(self, peerID: peerID, handler: { (ok) -> Void in
			invitationHandler(ok, self.session)
		})
	}
	
	// エラー　	＜オプショナル＞
	func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
		
		print("エラーのために起動できなかった:" + error.localizedDescription)
	}
	
	
	
	
	//------------------------------------
	//MARK: - MCSessionDelegate
	//------------------------------------
	// sessionのステータスが変更された時の処理を行う。
	func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
		
		//session の接続が完了した
		if state == .Connected {
			print("session の接続が完了した:[\(peerID.displayName)]")
		}
		//session は接続中
		else if state == .Connecting {
			print("session は接続中:[\(peerID.displayName)]")
		}
		//session は接続されていない
		else if state == .NotConnected {
			print("session は接続されていない:[\(peerID.displayName)]")
		}
		
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			let sta = self.convertState(state)
			self.basicDelegate?.sessionManagerDidChangeConnectedMember(self, memberName: peerID.displayName, state: sta)
			self.customDelegate?.sessionManagerDidChangeConnectedPeer(self, peerID: peerID, state: sta)
		})
	}
	
	// リモートPeerからデータを受信
	func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
		
		if let message = NSString(data: data, encoding: NSUTF8StringEncoding) {
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self.basicDelegate?.sessionManagerDidRecieveMessage(self, 
					message: message as String, 
					displayName: peerID.displayName)
			})
		}
	}
	
	// リモートPeerからリソースの受信開始
	func session(session: MCSession, 
	             didStartReceivingResourceWithName resourceName: String, 
	                                               fromPeer peerID: MCPeerID, 
	                                                        withProgress progress: NSProgress) {
		
		print("Start receiving resource: resourceName=\(resourceName)  peer=\(peerID.displayName)  progress=\(progress)")
	}
	// リモートPeerからリソースの受信完了
	func session(session: MCSession, 
	             didFinishReceivingResourceWithName resourceName: String, 
	                                                fromPeer peerID: MCPeerID, 
	                                                         atURL url: NSURL, 
	                                                               withError error: NSError?) {
		
		if error != nil {
			print("Error: \(error!.localizedDescription)")
		}
		else {
			let config = NSURLSessionConfiguration.defaultSessionConfiguration()
			let session = NSURLSession(configuration: config)
			let task = session.dataTaskWithURL(url) { (data: NSData?, request: NSURLResponse?, error: NSError?) in
				dispatch_async(dispatch_get_main_queue(), { 
					self.basicDelegate?.sessionManagerDidRecieveData(self, 
												data: data, name: resourceName, displayName: peerID.displayName)
				})
			}
			task.resume()
		}
		
	}
	
	// リモートPeerからバイトストリームの受信
	func session(session: MCSession, 
	             didReceiveStream stream: NSInputStream, 
	                              withName streamName: String, 
	                                       fromPeer peerID: MCPeerID) {
		
	}
	
	
}

//
//  PeerBrowserViewController.swift
//  P2PDemo
//
//  Created by STUDIO SHIN on 2016/05/04.
//  Copyright © 2016年 STUDIO SHIN. All rights reserved.
//

import UIKit
import MultipeerConnectivity

enum PeerBrowserViewControllerState: Int {
	case Canceled
	case Done
	case Invite
}

typealias	PeerBrowserViewControllerHandler = (state: PeerBrowserViewControllerState, peer: AnyObject?) -> Void

class PeerBrowserViewController: UIViewController, SessionManagerCustomDelegate {

	
	var handler: PeerBrowserViewControllerHandler?
	
	
	class func peerBrowserViewController() -> PeerBrowserViewController {
		let vc = PeerBrowserViewController(nibName: "PeerBrowserViewController", bundle: nil)
		let screen = UIScreen.mainScreen().applicationFrame
		vc.view.frame = CGRectMake(0, 0, screen.size.width, screen.size.height)
		return vc
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

		self.baseView.layer.masksToBounds = true
		self.baseView.layer.cornerRadius = 6.0
		
		self.doneButton.enabled = false
    }

    
	@IBOutlet weak var baseView: UIView!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var titleLabel: UILabel!

	//キャンセル
	@IBOutlet weak var cancelButton: UIButton!
	@IBAction func cancelButtonAction(sender: AnyObject) {
		
		self.handler?(state: .Canceled, peer: nil)
	}
	
	//完了
	@IBOutlet weak var doneButton: UIButton!
	@IBAction func doneButtonAction(sender: AnyObject) {
		
		self.handler?(state: .Done, peer: nil)
	}
	
	
	
	
	
	
	//MARK: - UITableViewDataSource
	
	var peerList: [[String:AnyObject]] = []
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		return self.peerList.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		var cell: UITableViewCell!
		cell = tableView.dequeueReusableCellWithIdentifier("peer_cell")
		if cell == nil {
			cell = UITableViewCell(style: .Value1, reuseIdentifier: "peer_cell")
		}
		
		let dic =  self.peerList[indexPath.row]
		let peer = dic["peer"] as! MCPeerID 
		cell!.textLabel?.text = peer.displayName
		let state = dic["state"] as! String 
		cell!.detailTextLabel?.text = state
		
		return cell
	}
	
	
	//MARK: UITableViewDelegate
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		
		var dic =  self.peerList[indexPath.row]
		let peer = dic["peer"] as! MCPeerID 
		
		self.handler?(state: .Invite, peer: peer)
		
		dic["state"] = "接続中..."
		self.peerList.removeAtIndex(indexPath.row)
		self.peerList.insert(dic, atIndex: indexPath.row)
		tableView.reloadData()
	}
	
	
	
	//MARK: - SessionManagerCustomDelegate
	
	//ステータス更新通知
	func sessionManagerDidChangeConnectedPeer(sessionManager: SessionManager, peerID: MCPeerID, state: SessionManagerState) {
		
		if state == .NotConnected || state == .Connected {
			//未接続 or 接続完了
			for i in 0 ..< self.peerList.count {
				var dic =  self.peerList[i]
				let peer = dic["peer"] as! MCPeerID 
				if peer.displayName == peerID.displayName {
					if state == .Connected {
						dic["state"] = "接続完了!"
						self.peerList.removeAtIndex(i)
						self.peerList.insert(dic, atIndex: i)
					} else {
						self.peerList.removeAtIndex(i)
					}
					break
				}
			}
			if state == .Connected {
				self.doneButton.enabled = true
			}
			self.tableView.reloadData()
		}
	}
	
	
	//招待通知結果
	func sessionManagerInvitationResult(sessionManager: SessionManager, peerID: MCPeerID, handler: (ok: Bool) -> Void) {
		
		let alert = UIAlertController(title: "招待", message: "\(peerID.displayName)から招待が届いています。参加しますか？", preferredStyle: .Alert)
		let no = UIAlertAction(title: "いいえ", style: .Default) { (action) in
			handler(ok: false)
			self.titleLabel.text = "承認拒否"
		}
		alert.addAction(no)
		let yes = UIAlertAction(title: "はい", style: .Default) { (action) in
			handler(ok: true)
			self.titleLabel.text = "承認済み"
		}
		alert.addAction(yes)
		
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	
	//ピア発見通知
	func sessionManagerFoundPeer(sessionManager: SessionManager, peerID: MCPeerID) {
		
		self.peerList.append(["peer":peerID, "state":"待機中"])
		self.tableView.reloadData()
	}
	//ピア消失通知
	func sessionManagerLostPeer(sessionManager: SessionManager, peerID: MCPeerID) {
		
		for i in 0 ..< self.peerList.count {
			let dic = self.peerList[i]
			let peer = dic["peer"] as! MCPeerID
			if peer.displayName == peerID.displayName {
				self.peerList.removeAtIndex(i)
				break
			}
		}
		self.tableView.reloadData()
	}
	
	
	
	
}

//
//  ViewController.swift
//  P2PDemo
//
//  Created by STUDIO SHIN on 2016/05/04.
//  Copyright © 2016年 STUDIO SHIN. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, SessionManagerBasicDelegate, UITableViewDataSource, UITableViewDelegate, DrawingViewDelegate {

	
	var sessionManager: SessionManager?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//名前
		let userDef = NSUserDefaults.standardUserDefaults()
		if let name = userDef.objectForKey("name") as? String {
			self.nameTextField.text = name
		} else {
			let device = UIDevice.currentDevice()
			self.nameTextField.text = device.name
			userDef.setObject(device.name, forKey: "name")
		}
		
		// DrawingViewデリゲート
		self.drawView.delegate = self
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	//MARK: 切断
	@IBOutlet weak var shutDownButton: UIButton!
	@IBAction func shutDownAction(sender: AnyObject) {
		
		if let sessionManager = self.sessionManager {
			sessionManager.stop()
			self.sessionManager = nil
		}
		self.memberList.removeAll()
		self.tableView.reloadData()
		
		let	array = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)
		let path = array[0]
		let savePath = path + "/image"  
		let fileMrg = NSFileManager.defaultManager()
		do {
			try fileMrg.removeItemAtPath(savePath)
			print("削除成功！")
		} catch {
			print("削除失敗！")
		}
	}
	
	//MARK: 検索（MCBrowserViewControllerを使う）
	@IBOutlet weak var peerSerachButton: UIButton!
	@IBAction func peerSerachAction(sender: AnyObject) {
		
		self.sessionManager = SessionManager(displayName: self.nameTextField.text!, 
		                                     serviceType: "p2pdemo", 
		                                     viewController: self)
		self.sessionManager?.basicDelegate = self
		
	}
	
	
	
	//MARK: 検索（カスタムUIを使う）
	@IBOutlet weak var peerSerachCustomButton: UIButton!
	@IBAction func peerSerachCustomButtonAction(sender: AnyObject) {
		
		self.memberList = []
		self.sessionManager = SessionManager(displayName: self.nameTextField.text!, 
		                                     serviceType: "p2pdemo")
		self.sessionManager?.basicDelegate = self
		
		/*==================== 
		ブラウザー表示
		====================*/
		let browser = PeerBrowserViewController.peerBrowserViewController()
		self.sessionManager?.customDelegate = browser
		browser.view.frame = CGRectMake(0, 0, self.view.frame.size.width, 
		                                self.view.frame.size.height)
		self.view.addSubview(browser.view)
		self.addChildViewController(browser)
		browser.view.alpha = 0
		UIView.animateWithDuration(0.25, animations: { 
			browser.view.alpha = 1.0
		}) { (stop) in
			
		}
		browser.titleLabel.text = "検索中..."
		browser.handler = {(state: PeerBrowserViewControllerState, peer: AnyObject?) in
			
			if state == .Canceled {
				//キャンセル
				if let sessionManager = self.sessionManager {
					sessionManager.stop()
					self.sessionManager = nil
				}
				self.memberList.removeAll()
				self.tableView.reloadData()
				
				UIView.animateWithDuration(0.25, animations: { 
					browser.view.alpha = 0.0
				}) { (stop) in
					browser.view.removeFromSuperview()
					browser.removeFromParentViewController()
				}
			}
			else if state == .Done {
				//完了
				UIView.animateWithDuration(0.25, animations: { 
					browser.view.alpha = 0.0
				}) { (stop) in
					browser.view.removeFromSuperview()
					browser.removeFromParentViewController()
				}
			}
			else if state == .Invite {
				//招待
				if let peerID = peer {
					self.sessionManager?.sendInvite(peerID)
				}
			}
		}
	}
	
	
	
	
	
	
	//MARK: 画像を消去する
	@IBOutlet weak var clearButton: UIButton!
	@IBAction func clearButtonAction(sender: AnyObject) {
		
		self.drawView.allClear()
	}
	
	
	
	
	
	
	//MARK: -
	
	@IBOutlet weak var nameTextField: UITextField!
	@IBOutlet weak var messageTextField: UITextField!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var drawView: DrawingView!
	
	
	
	//MARK: - DrawingViewDelegate
	
	func drawingViewDrawFinish(drawView: DrawingView) -> Void {
		
		let path = drawView.imageSavePath()
		var list: [String] = []
		for dic in self.memberList {
			let state = dic["state"]
			if state == "true" {
				list.append(dic["name"]!)
			}
		}
		let url = NSURL(fileURLWithPath: path)
		self.sessionManager?.sendURL(url, nameList: list, handler: { (displayName: String, ok: Bool) in
			if ok == true {
				print("画像URL送信成功: \(url)")
			}
		})
		
	}
	
	
	//MARK: - UITextFieldDelegate
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		
		let tag = textField.tag
		if tag == 1 {
			if let message = textField.text {
				var list: [String] = []
				for dic in self.memberList {
					let state = dic["state"]
					if state == "true" {
						list.append(dic["name"]!)
					}
				}
				self.sessionManager?.sendMsaage(message, nameList: list, handler: { (ok: Bool) in
					if ok == true {
						print("メッセージ送信成功: " + message)
					}
				})
			}
		}
		textField.resignFirstResponder()
		
		return true
	}
	
	

	
	
	//MARK: - UITableViewDataSource
	
	var memberList: [[String:String]] = []
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		return self.memberList.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		var cell: UITableViewCell!
		cell = tableView.dequeueReusableCellWithIdentifier("menber_cell")
		if cell == nil {
			cell = UITableViewCell(style: .Subtitle, reuseIdentifier: "menber_cell")
		}
		
		let dic =  self.memberList[indexPath.row]
		let name = dic["name"]
		let message = dic["message"]
		let state = dic["state"]
		cell!.textLabel?.text = name
		cell!.detailTextLabel!.text = message
		if state == "true" {
			cell!.accessoryType = .Checkmark
		} else {
			cell!.accessoryType = .None
		}
		if let path = dic["image"] {
			if let data = NSData(contentsOfFile: path) {
				let image = UIImage(data: data)
				cell!.imageView!.image = image
			}
		}
		
		return cell
	}
	
	
	//MARK: UITableViewDelegate
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		var dic =  self.memberList[indexPath.row]
		let state = dic["state"]
		if state == "true" {
			dic["state"] = "false"
		} else {
			dic["state"] = "true"
		}
		self.memberList.removeAtIndex(indexPath.row)
		self.memberList.insert(dic, atIndex: indexPath.row)
		
		tableView.reloadData()
	}
	
	
	
	
	
	
	//MARK: - SessionManagerBasicDelegate
	
	//メンバー更新通知
	func sessionManagerDidChangeConnectedMember(sessionManager: SessionManager, 
	                                            memberName: String, 
	                                            state: SessionManagerState) {
		
		self.memberList.removeAll()
		let list = sessionManager.connectedMembers()
		for name in list {
			self.memberList.append(["name":name, "message":"", "state":"true"])
		}
		self.tableView.reloadData()
	}
	
	//セッション接続結果
	func sessionManagerSessionConnectResult(sessionManager: SessionManager, ok: Bool) {
		
		if ok == true {
			
		} else {
			if let sessionManager = self.sessionManager {
				sessionManager.stop()
				self.sessionManager = nil
			}
			self.memberList.removeAll()
			self.tableView.reloadData()
		}
	}
	
	//データ受信
	func sessionManagerDidRecieveData(sessionManager: SessionManager, 
	                                  data: NSData?, 
	                                  name: String, 
	                                  displayName: String) {
		
		if let d = data {
			print("画像受信成功！")
			if let image = UIImage(data: d) {
				self.drawView.setImage(image)
			}
		}
	}
	
	//メッセージ受信
	func sessionManagerDidRecieveMessage(sessionManager: SessionManager, 
	                                     message: String, 
	                                     displayName: String) {
		
		//テキストを辞書に設定する
		for i in 0 ..< self.memberList.count {
			var dic = self.memberList[i]
			let name = dic["name"]
			if name == displayName {
				dic["message"] = message
				self.memberList.removeAtIndex(i)
				self.memberList.insert(dic, atIndex: i)
				break
			}
		}
		self.tableView.reloadData()
	}
	
}


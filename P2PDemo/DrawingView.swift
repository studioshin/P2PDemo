//
//  DrawingView.swift
//  P2PDemo
//
//  Created by STUDIO SHIN on 2016/05/04.
//  Copyright © 2016年 STUDIO SHIN. All rights reserved.
//

import UIKit

protocol DrawingViewDelegate {
	func drawingViewDrawFinish(drawView: DrawingView) -> Void
}

class DrawingView: UIView {

	var drawContext: CGContextRef!
	var delegate: DrawingViewDelegate?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		self.makeContents()
		if let image = self.getSaveImage() {
			self.setImage(image)
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
	}
	
	override func awakeFromNib() {
		
		self.makeContents()
		if let image = self.getSaveImage() {
			self.setImage(image)
		}
	}
	
	//引数追加
	func makeContents() {
		
		self.drawContext = CGBitmapContextCreate(nil,
		                                         Int(frame.size.width), 
		                                         Int(frame.size.height), 
		                                         8,
		                                         4 * Int(frame.size.width),
		                                         CGColorSpaceCreateDeviceRGB(),
		                                         2)
		//ラインの太さ
		CGContextSetLineWidth(drawContext, 3)
	}
	
	
	
	//MARK: - Drawing
	
	//画面に指を置いたときに呼ばれる
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		var location: CGPoint!
		for touch in touches {
			location = touch.locationInView(self)
		}
		print("\(location)")
		
	}
	
	//指を置いて、画面上で指を動かしたときに呼ばれる
	override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		var pt_now: CGPoint!
		var pt_old: CGPoint!
		
		for touch in touches {
			pt_now = touch.locationInView(self)
			pt_old = touch.previousLocationInView(self)
		}
		
		self.drawing(pt_now, pt2: pt_old)
	}
	
	//画面から指を離したときに呼ばれる
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		
		if let image = self.getImage() {
			let data = UIImagePNGRepresentation(image)
			let savePath = self.imageSavePath()
			data?.writeToFile(savePath, atomically: true)
			
			self.delegate?.drawingViewDrawFinish(self)
		}
	}
	
	func drawing(pt1: CGPoint,pt2: CGPoint) {
		
		CGContextSaveGState(self.drawContext)  //保存
		
		//線を滑らかに
		CGContextSetLineCap(drawContext, .Round)
		CGContextSetLineJoin(drawContext, .Round)
		
		
		//紙をxの位置は変えずにひっくり返す
		CGContextTranslateCTM(self.drawContext, 0, self.frame.size.height)
		CGContextScaleCTM(self.drawContext, 1, -1)
		
		CGContextBeginPath(self.drawContext)
		CGContextMoveToPoint(self.drawContext, pt1.x, pt1.y)
		CGContextAddLineToPoint(self.drawContext, pt2.x, pt2.y)
		CGContextStrokePath(self.drawContext)
		
		CGContextRestoreGState(self.drawContext) // 復元
		
		//imageとして保存
		let cgImage = CGBitmapContextCreateImage(self.drawContext)
		self.layer.contents = cgImage
		
	}
	
	
	
	//MARK: - Setting
	
	//イメージをセット
	func setImage(image: UIImage) {
		
		//コンテキストをクリア
		CGContextClearRect(self.drawContext, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height))
		//コンテキストに画像を描画する
		CGContextDrawImage(self.drawContext, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height), image.CGImage)
		
		//imageとして保存
		let cgImage = CGBitmapContextCreateImage(self.drawContext)
		self.layer.contents = cgImage
		
		let data = UIImagePNGRepresentation(image)
		let savePath = self.imageSavePath()
		data?.writeToFile(savePath, atomically: true)
	}
	//コンテキストをイメージにする
	func getImage () -> UIImage? {
		
		let cgImage = CGBitmapContextCreateImage(self.drawContext)
		return UIImage(CGImage: cgImage!)
	}
	
	
	//ラインの色
	func setLineColor(red red: CGFloat,green: CGFloat,blue: CGFloat) {
		
		CGContextSetRGBStrokeColor(drawContext, red, green, blue, 1.0)
		CGContextSetRGBFillColor(drawContext, red, green, blue, 1.0)
		
	}
	
	//ラインの太さ
	func setLineSize(line: CGFloat) {
		
		CGContextSetLineWidth(drawContext, line)
	}
	
	//全消し
	func allClear() {
		
		CGContextClearRect(self.drawContext, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height))
		
		//imageとして保存
		let cgImage = CGBitmapContextCreateImage(self.drawContext)
		self.layer.contents = cgImage
		
		let data = UIImagePNGRepresentation(UIImage(CGImage: cgImage!))
		let savePath = self.imageSavePath()
		data?.writeToFile(savePath, atomically: true)
		
		self.delegate?.drawingViewDrawFinish(self)
	}
	
	func imageSavePath() -> String{
		
		let	array = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)
		let libPath = array[0]
		let savePath = libPath + "/" + "image"
		return savePath
	}
	
	func getSaveImage() -> UIImage? {
		
		let path = self.imageSavePath()
		if let image = UIImage(contentsOfFile: path) {
			return image
		} else {
			return nil
		}
	}
}

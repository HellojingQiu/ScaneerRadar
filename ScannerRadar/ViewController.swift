//
//  ViewController.swift
//  ScannerRadar
//
//  Created by OliHire-HellowJingQiu on 15/4/28.
//  Copyright (c) 2015年 OliHire-HellowJingQiu. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet weak var labelResult: UILabel!
    @IBOutlet weak var buttonReset: UIButton!

    //session
    var session:AVCaptureSession?
    //展示层
    var videoLayer:AVCaptureVideoPreviewLayer?
    //锁定View视图
    var autoLockView:UIView?
    
    //重新扫描
    @IBAction func reScan(sender: UIButton) {
        session?.startRunning()
        sender.hidden = true
    }
    //停止扫描
    func stopScan(){
        session?.stopRunning()
        buttonReset.hidden = false
        
        view.bringSubviewToFront(buttonReset)
    }
    
    //打开一个Url对应的程序
    func launchApp(decodedStr:String){
        let alert = UIAlertController(title: "二维码", message:"\(decodedStr)", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let okAction = UIAlertAction(title: "打开", style: UIAlertActionStyle.Destructive) { (_) -> Void in
            if let url = NSURL(string: decodedStr){
                if UIApplication.sharedApplication().canOpenURL(url){
                    UIApplication.sharedApplication().openURL(url)
                }
            }
        }
        let cancel = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel) { (_) -> Void in
            self.reScan(self.buttonReset)
        }
        
        alert.addAction(okAction)
        alert.addAction(cancel)
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = labelResult.frame
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonReset.hidden = true
        
        session = AVCaptureSession()
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        if let input = AVCaptureDeviceInput.deviceInputWithDevice(device, error: nil) as? AVCaptureDeviceInput{
            session?.addInput(input)
        }else{
            println("无法使用摄像头!")
            return
        }
        
        let output = AVCaptureMetadataOutput()
        
        session?.addOutput(output)
        
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        output.metadataObjectTypes = [AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeFace,AVMetadataObjectTypeQRCode]
        
        videoLayer = AVCaptureVideoPreviewLayer(session: session)
        videoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoLayer?.frame = view.layer.frame
        view.layer.addSublayer(videoLayer)
        
        session?.startRunning()
        
        view.bringSubviewToFront(labelResult)
        
        autoLockView = UIView()
        autoLockView?.layer.borderColor = UIColor.greenColor().CGColor
        autoLockView?.layer.borderWidth = 2
        view.addSubview(autoLockView!)
        view.bringSubviewToFront(autoLockView!)
    }
    

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if metadataObjects == nil || metadataObjects.count == 0{
            autoLockView?.frame = CGRectZero
            labelResult.text = "间谍雷达扫描中"
            return
        }
        
        //人脸识别
        if let obj = metadataObjects.first as? AVMetadataFaceObject{
            let faceObj = videoLayer?.transformedMetadataObjectForMetadataObject(obj)
            autoLockView?.frame = faceObj!.bounds
            
            labelResult.text = "人脸扫描成功!"
        }
        
        //商品码,二维码识别
        if let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject{
            let barcodeObj = videoLayer?.transformedMetadataObjectForMetadataObject(obj) as? AVMetadataMachineReadableCodeObject
            
            autoLockView?.frame = barcodeObj!.bounds
            
            switch obj.type{
            case AVMetadataObjectTypeQRCode:
                if let decodedStr = barcodeObj?.stringValue{
                    stopScan()
                    labelResult.text = "二维码:\n" + decodedStr
                    
                    launchApp(decodedStr)
                }
            case AVMetadataObjectTypeEAN13Code:
                if let decodeStr = barcodeObj?.stringValue{
                    stopScan()
                    labelResult.text = "商品码:\n" + decodeStr
                    
                    showGoodsName(decodeStr)
                }
            default:return
            }
        }
        
    }
    
    //http://api.juheapi.com/jhbar/bar?appkey=a95c869fdfd1af2218cc01ce4633bb79&pkg=com.JokerV.ScannerRadar&cityid=1&barcode=
    
    //获取商品名
    func showGoodsName(decodedStr:String){
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        let baseURL = "http://api.juheapi.com/jhbar/bar?appkey=a95c869fdfd1af2218cc01ce4633bb79&pkg=com.JokerV.ScannerRadar&cityid=1&barcode="
        
        let request = NSURLRequest(URL: NSURL(string: baseURL + decodedStr)!)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, _, e) -> Void in
            if e == nil{
                if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as? NSDictionary{
                    //确认赋值成功才会进入
                    if let data = json["result"]?["summary"] as? NSDictionary{
                        //所以,这里不需要再对data加可选符?
                        let name = data["name"] as? String
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.labelResult.text = name
                        })
                    }
                    
                    
                }
            }
        })
        
        task.resume()
    }
    
//    func showGoodsName(ean13numberStr:String){
//        
//        
//        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
//        
//        let baseURL = "http://api.juheapi.com/jhbar/bar?appkey=6dbeb78efa84f3b745623d2c99297ba0&pkg=me.hcxy&cityid=1&barcode="
//        
//        let request = NSURLRequest(URL: NSURL(string: baseURL + ean13numberStr)!)
//        
//        
//        
//        let task = session.dataTaskWithRequest(request, completionHandler: { (data, _, error) -> Void in
//            if error == nil {
//                if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: nil) as? NSDictionary {
//                    
//                    println(json)
//                    if let summary = json["result"]?["summary"] as? NSDictionary {
//                        let name = summary.valueForKey("name") as? String
//                        
//                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                            self.labelResult.text = (summary.valueForKey("barcode") as? String)! + "\n" + name!
//                        })
//                        
//                        
//                    }
//                }
//            }
//        })
//        
//        task.resume()
//    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


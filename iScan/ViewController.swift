//
//  ViewController.swift
//  iScan
//
//  Created by William Thompson on 1/10/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData


class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var lightAction: UIBarButtonItem!
    @IBOutlet weak var doneAction: UIBarButtonItem!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var topbar: UINavigationBar!
    
    @IBOutlet weak var focusIndicator: UIImageView!
    
   
    
   
    var captureDevice: AVCaptureDevice!
    var objTableView = TableVController()
    var alertController = UIAlertController()
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    let supportedCodeTypes = [AVMetadataObjectTypeUPCECode,
                              AVMetadataObjectTypeCode39Code,
                              AVMetadataObjectTypeCode39Mod43Code,
                              AVMetadataObjectTypeCode93Code,
                              AVMetadataObjectTypeCode128Code,
                              AVMetadataObjectTypeEAN8Code,
                              AVMetadataObjectTypeEAN13Code,
                              AVMetadataObjectTypeAztecCode,
                              AVMetadataObjectTypePDF417Code,
                              AVMetadataObjectTypeDataMatrixCode,
                              AVMetadataObjectTypeITF14Code,
                              AVMetadataObjectTypeInterleaved2of5Code,
                              AVMetadataObjectTypeQRCode]
    
    
    // Loads the view controller when the scan button is tapped in the orignal view controller
    override func viewDidLoad() {
        super.viewDidLoad()
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        // Turns the camera on when the scan button is tapped in the original view controller
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.canAddOutput(captureMetadataOutput)
            captureSession?.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            captureSession?.startRunning()
            view.bringSubview(toFront: messageLabel!)
            view.bringSubview(toFront: topbar)
            qrCodeFrameView = UIView()
            // Sets the color and bounds of the frame when scanning a barcode
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.red.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront: qrCodeFrameView)
            }
            
        } catch {
            print(error)
            return
        }
        
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    // This function isn't usually used unless your app is consuming large amounts of memory on the device
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func dismissAlert(){
        
        self.dismiss(animated: true, completion: nil)
    }
    // Captures the output of the camera and allows the camera the ability to read barcodes
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        // Sets the message label to "No Barcode is detected" when nothing is being scanned
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel?.text = "No barcode detected" ; dismissAlert()
            return
        }
        // Sets the message label to the output of the scanned item
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if supportedCodeTypes.contains(metadataObj.type) {
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            qrCodeFrameView?.frame = barCodeObject.bounds
            // Sets the label text to match the output of the scanned barcode and calls the goToWeb function I created
            if metadataObj.stringValue != nil {
                messageLabel?.text = metadataObj.stringValue ; saveAlert() 
                    }
                }
            }
    // Turns the camera flash on for a light in low light barcode reading when the light button is tapped
    @IBAction func lightAction(_ sender: Any) {
        if let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo), device.hasTorch {
            do {
                try device.lockForConfiguration()
                let torchOn = !device.isTorchActive
                try device.setTorchModeOnWithLevel(1.0)
                device.torchMode = torchOn ? .on : .off
                device.unlockForConfiguration()
            } catch {
                print("error")
            }
        }
    }
    func saveAlert() {
        
        alertController = UIAlertController(title: "Choose action", message: "What would you like to do?", preferredStyle: .alert)
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
        }
        alertController.addAction(cancelAction)
        
        let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .default) { (action:UIAlertAction) in
            TableVController().savescan(name: (self.messageLabel?.text)!)
            
            }
        
        alertController.addAction(saveAction)
        
        func goToWeb() {
            // Checks to see if the message in the label has a value and that it's not the default "No barcode is detected"
            if messageLabel?.text != nil || messageLabel?.text != "No barcode detected"{
                let input = messageLabel?.text
                let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                let matches = detector.matches(in: input!, options: [], range: NSRange(location: 0, length: (input?.utf16.count)!))
                for _ in matches {
                    let yesAction: UIAlertAction = UIAlertAction(title: "Go To Web Page", style: .default) { (action:UIAlertAction) in
                        UIApplication.shared.openURL(NSURL(string: self.messageLabel!.text!) as! URL)
                    }
                    alertController.addAction(yesAction)
                }
            }
        }
        goToWeb()
        self.present(alertController, animated: true, completion: nil)
        }
    // Closes the View Controller when the Done Button is tapped
    @IBAction func doneAction(_ sender: Any) {
        self .dismiss(animated: true, completion: nil)
    }
           // This function determines if the text in the message label is a URL and redirects the user to the URL in safari
    
}


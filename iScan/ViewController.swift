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
import Firebase

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeRight
        case .landscapeLeft: return .landscapeLeft
        case .portrait: return .portrait
        default: return nil
        }
    }
}

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var lightAction: UIBarButtonItem!
    @IBOutlet weak var doneAction: UIBarButtonItem!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var topbar: UINavigationBar!
    @IBOutlet weak var selectorAction: UISegmentedControl!
    @IBOutlet weak var selectorView: UIView!
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
        bannerView.adUnitID = "ca-app-pub-7317713550657480/5127447259"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
    }
    override func viewDidAppear(_ animated: Bool) {
        start()
        view.bringSubview(toFront: bannerView)        
        view.bringSubview(toFront: selectorView)
        view.bringSubview(toFront: stackView)
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        print("Banner loaded successfully")
    }
    func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("Fail to receive ads")
        print(error)
    }
    func start() {
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
    func updateVideoOrientation() {
        guard let previewLayer = self.videoPreviewLayer else {
            return
        }
        guard previewLayer.connection.isVideoOrientationSupported else {
            print("isVideoOrientationSupported is false")
            return
        }
        
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        let videoOrientation: AVCaptureVideoOrientation = statusBarOrientation.videoOrientation ?? .portrait
        
        if previewLayer.connection.videoOrientation == videoOrientation {
            print("no change to videoOrientation")
            return
        }
        
        previewLayer.frame = view.bounds
        previewLayer.connection.videoOrientation = videoOrientation
        previewLayer.removeAllAnimations()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: nil, completion: { [weak self] (context) in
            DispatchQueue.main.async(execute: {
                self?.updateVideoOrientation()
            })
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
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
        toggleFlash()
    }
    func toggleFlash() {
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
        } else {
            alertController = UIAlertController(title: "", message: "Your device doesn't have a light", preferredStyle: .alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "Dismiss", style: .cancel) { (action:UIAlertAction) in
            }
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
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
            if messageLabel?.text != nil && messageLabel?.text != "No barcode detected"{
                let input = messageLabel?.text
                let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                let matches = detector.matches(in: input!, options: [], range: NSRange(location: 0, length: (input?.utf16.count)!))
                for _ in matches {
                    let yesAction: UIAlertAction = UIAlertAction(title: "Go To Web Page", style: .default) { (action:UIAlertAction) in
                        UIApplication.shared.openURL(NSURL(string: self.messageLabel!.text!)! as URL)
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
        dismissAlert()
    }
    @IBAction func selectorAction(_ sender: UISegmentedControl) {
        switch selectorAction.selectedSegmentIndex{
        case 0:
            performSegue(withIdentifier: "segueBarcodeScan", sender: self)
        case 1:

            performSegue(withIdentifier: "segueDocScan", sender: self)
        default:
            break;
        }
    
    }
    
}


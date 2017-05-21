//
//  DocScannerController.swift
//  iScan
//
//  Created by William Thompson on 1/28/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
import QuartzCore
import AVFoundation
import Firebase

class DocScannerController: UIViewController {
    var imagesDirectoryPath:String!
    var images: UIImage!
    var titles:[String]!
    var captureDevice: AVCaptureDevice?
    var documentsDirectories:String!    
    var viewController = ViewController()
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var isPurchase = true
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var cameraViewController: DocScannerViewController!
    @IBOutlet weak var focusIndicator: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var torchToggle: UIButton!
    
    @IBOutlet weak var cameraViewBottom: NSLayoutConstraint!
    
    @IBOutlet weak var filterToggle: UIButton!
    @IBOutlet weak var cropToggle: UIButton!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        bannerView.adUnitID = "ca-app-pub-7317713550657480/5127447259"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        makePath()
        view.bringSubview(toFront: cameraViewController)
        self.cameraViewController.setupCameraView()
        self.cameraViewController.enableBorderDetection = true
        self.cameraViewController.borderDetectFrames = true        
        self.updateTitleLabel()
        self.focusIndicator.isHidden = true
        adViewDidReceiveAd(bannerView)
        let screenRect = UIScreen.main.bounds
        let screenHieght = screenRect.size.height
        if isPurchase == false {
            self.toolbar.frame.origin.y = screenHieght - 170
            self.cameraViewBottom.constant = 50
        }
        else {
            bannerView.isHidden = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    override func viewDidAppear(_ animated: Bool) {
        view.bringSubview(toFront: bannerView)
        
        
    }
    func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        print("Banner loaded successfully")
        let screenRect = UIScreen.main.bounds
        let screenHieght = screenRect.size.height
        if isPurchase == false {
            self.toolbar.frame.origin.y = screenHieght - 170
            self.cameraViewBottom.constant = 50
        }
        else {
            bannerView.isHidden = true
        }
    }
    
    func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("Fail to receive ads")
        print(error)
    }    
    
    override func viewWillAppear(_ animated: Bool) {
        self.cameraViewController?.start()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    @IBAction func focusGesture(_ sender: UITapGestureRecognizer) {
        
            let location = sender.location(in: self.cameraViewController)
            self.focusIndicatorAnimateToPoint(targetPoint: location)
            self.cameraViewController.focusAtPoint(point: location, completionHandler: {() -> Void in
                self.focusIndicatorAnimateToPoint(targetPoint: location)
            })
        
    
    
    }
    
    func makePath() {
        var filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        //create an array and store result of our search for the documents directory in it
        let documentsDirectory: String = filePath[0]
        // Create a new path for the new images folder
        documentsDirectories = documentsDirectory
        var objcBool:ObjCBool = true
        let isExist = FileManager.default.fileExists(atPath: documentsDirectories, isDirectory: &objcBool)
        // If the folder with the given path doesn't exist already, create it
        if isExist == false{
            do{
                try FileManager.default.createDirectory(atPath: documentsDirectories, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print("Something went wrong while creating a new folder")
            }
        }
    }
    
    func focusIndicatorAnimateToPoint(targetPoint: CGPoint) {
        (self.focusIndicator).center = targetPoint
        self.focusIndicator.alpha = 0.0
        self.focusIndicator.isHidden = false
        UIView.animate(withDuration: 0.4, animations: {() -> Void in
            self.focusIndicator.alpha = 1.0
        }, completion: {(finished: Bool) -> Void in
            UIView.animate(withDuration: 0.4, animations: {() -> Void in
                self.focusIndicator.alpha = 0.0
            })
        })
    }
    
    func chnageTorchButtonImage() {
        
    }
    
    
    /*
    @IBAction func selectorAction(_ sender: UISegmentedControl) {
        switch selectorAction.selectedSegmentIndex {
            case 0:
                performSegue(withIdentifier: "segueDocScan", sender: self)
            case 1:
                performSegue(withIdentifier: "segueBarcodeScan", sender: self)
            default:
                break;
        }
    }
    */
    func changeButton(button: UIButton, targetTitle title: String, toStateEnabled enabled: Bool) {
        button.setTitle(title, for: .normal)
        button.setTitleColor((enabled) ? UIColor(red: 1, green: 0.81, blue: 0, alpha: 1) : UIColor.white, for: .normal)
    }
    
    @IBAction func captureButton(_ sender: Any) {
        makePath()
        weak var weakSelf = self
        self.cameraViewController.captureImage(completionHandler: {(fullPath) -> Void in
            let captureImageView: UIImageView = UIImageView(image: UIImage(contentsOfFile:(fullPath)))
            
            captureImageView.backgroundColor = UIColor(white: 0.0, alpha: 0.7);
            captureImageView.frame = (weakSelf?.view.bounds.offsetBy(dx: 0, dy: -(weakSelf?.view.bounds.size.height)!))!;
            captureImageView.alpha = 1.0;
            captureImageView.contentMode = .scaleAspectFit;
            captureImageView.isUserInteractionEnabled = true;
            weakSelf?.view!.addSubview(captureImageView)
            let dismissTap: UITapGestureRecognizer = UITapGestureRecognizer(target: weakSelf, action: #selector(self.dismissPreview))
            captureImageView.addGestureRecognizer(dismissTap)
            UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.7, options: .allowUserInteraction, animations: {() -> Void in
                captureImageView.frame = (weakSelf?.view.bounds)!
            }, completion: { _ in })
        })
    }
    
    func dismissPreview(_ dismissTap: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: .allowUserInteraction, animations: {() -> Void in
            dismissTap.view?.frame = self.view.bounds.offsetBy(dx: CGFloat(0), dy: CGFloat(self.view.bounds.size.height))
        }, completion: {(_ finished: Bool) -> Void in
            dismissTap.view?.removeFromSuperview()
        })
    }
    
    func updateTitleLabel() {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.type = kCATransitionPush
        animation.subtype = kCATransitionFromBottom
        animation.duration = 0.35
        self.titleLabel!.layer.add(animation, forKey: "kCATransitionFade")
        let filterMode = (self.cameraViewController.cameraViewType == .blackAndWhite) ? "TEXT FILTER" : "COLOR FILTER"
        self.titleLabel!.text! = filterMode.appendingFormat(" | %@", (self.cameraViewController.enableBorderDetection) ? "AUTOCROP On" : "AUTOCROP Off")
    }
    
    @IBAction func torchToggle(_ sender: Any) {
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
                if device.isTorchActive == true {
                    torchToggle.setImage(#imageLiteral(resourceName: "torch_off"), for: UIControlState.normal)
                }
                else {
                    torchToggle.setImage(#imageLiteral(resourceName: "torch_on"), for: UIControlState.normal)
                }
            } catch {
                print("error")
            }
        } else {
            let alertController = UIAlertController(title: "", message: "Your device doesn't have a light", preferredStyle: .alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "Dismiss", style: .cancel) { (action:UIAlertAction) in
            }
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func filterToggle(_ sender: Any) {
        (self.cameraViewController).cameraViewType = (self.cameraViewController.cameraViewType == DocScannerCameraViewType.blackAndWhite) ? DocScannerCameraViewType.normal : DocScannerCameraViewType.blackAndWhite
        self.updateTitleLabel()
        if self.cameraViewController.cameraViewType == DocScannerCameraViewType.blackAndWhite {
            filterToggle.setImage(#imageLiteral(resourceName: "filter_off"), for: UIControlState.normal)
        }
        else {
            filterToggle.setImage(#imageLiteral(resourceName: "filter"), for: UIControlState.normal)
        }
        
    }
    
    @IBAction func borderDetectToggle(_ sender: Any) {
    let enable: Bool = !self.cameraViewController.enableBorderDetection
    self.cameraViewController.enableBorderDetection = enable
    self.updateTitleLabel()
        self.changeButton(button: sender as! UIButton, targetTitle: (enable) ? "CROP On" : "CROP Off", toStateEnabled: enable)
        if enable == true {
            cropToggle.setImage(#imageLiteral(resourceName: "crop_on-1"), for: UIControlState.normal)
        }
        else {
            cropToggle.setImage(#imageLiteral(resourceName: "crop-1"), for: UIControlState.normal)
        }
    }
    
    @IBAction func doneAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        //dismiss(animated: true, completion: nil)
    
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

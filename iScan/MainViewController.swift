//
//  ViewController.swift
//  iScan
//
//  Created by William Thompson on 1/12/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase

class MainViewController: UIViewController {
    
    
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var selector: UISegmentedControl!
    
    @IBOutlet weak var documentView: UIView!
    @IBOutlet weak var barcodeView: UIView!
    
    @IBOutlet weak var bottomToolbarConstraint: NSLayoutConstraint!
    
    
    
    
    
    var isPurchased = false
    //var iapHelper = IAPHelper()
    override func viewDidLoad() {
        super.viewDidLoad()
        bannerView.adUnitID = "ca-app-pub-7317713550657480/5127447259"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        view.bringSubview(toFront: bannerView)
        adViewDidReceiveAd(bannerView)
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        adViewDidReceiveAd(bannerView)
        let screenRect = UIScreen.main.bounds
        let screenHieght = screenRect.size.height
        view.sendSubview(toBack: documentView)
        view.sendSubview(toBack: barcodeView)
        messageLabel.isHidden = true
        if isPurchased == false {
            bottomToolbarConstraint.constant = 50
            self.toolbar.frame.origin.y = screenHieght - 170
            self.documentView.frame.size.height = screenHieght - 170
            self.barcodeView.frame.size.height = screenHieght - 170
            
            
            
        }
        
        
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        if device?.hasTorch == true {
            do {
                try device?.lockForConfiguration()
            }
            catch {
                print("error")
            }
            if device?.isTorchActive == true {
                device?.torchMode = AVCaptureTorchMode.off
            }
            device?.unlockForConfiguration()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        //isPurchased = iapHelper.isProductPurchased(removeAds)
        print("Banner loaded successfully")
        //let bannerFrame = bannerView!.frame
        let screenRect = UIScreen.main.bounds
        let screenHieght = screenRect.size.height
        if isPurchased == false {
            bannerView.isHidden = false
            self.toolbar.frame.origin.y = screenHieght - 170
            
            
            
        } else {
            bannerView.isHidden = true
            
        }
    }
    func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("Fail to receive ads")
        print(error)
    }
    
    @IBAction func viewSelector(_ sender: UISegmentedControl) {
        switch selector.selectedSegmentIndex {
        case 0:
            
            view.sendSubview(toBack: barcodeView)
            
        case 1:
            
            view.sendSubview(toBack: documentView)
            
            
        default:
            break;
        }
    
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

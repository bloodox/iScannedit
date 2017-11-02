//
//  GenerateViewController.swift
//  iScan
//
//  Created by William Thompson on 1/12/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
import Social
import Firebase
import StoreKit

var qrcodeImage: CIImage!
var genImage: UIImage!


class GenerateViewController: UIViewController {
    
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var doneAction: UIBarButtonItem!
    @IBOutlet weak var shareAction: UIBarButtonItem!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var imgQRCode: UIImageView!
    @IBOutlet weak var genAction: UIButton!
    var documentsDirectories:String!
    var isPurchased = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bannerView.adUnitID = "ca-app-pub-7317713550657480/5127447259"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        if qrcodeImage == nil {
            slider.isHidden = true
        }
        else  {
            slider.isHidden = false
        }
        isPurchased = iScanProducts.store.isProductPurchased(iScanProducts.RemoveAds)
        if isPurchased == true {
            bannerView.isHidden = true
        }
        // Do any additional setup after loading the view.
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        let alertController = UIAlertController(title: "", message: "Your device is low on memory. Please close other applications.", preferredStyle: .alert)
        let cancelAction: UIAlertAction = UIAlertAction(title: "Dismiss", style: .cancel) { (action:UIAlertAction) in
        }
        alertController.addAction(cancelAction)
        
        
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    @IBAction func performButtonAction(_ sender: AnyObject) {
        if genImage == nil{
            if textField.text != "" {
                let image = generateQRCode(from: textField.text!)
                imgQRCode.image = image
                textField.resignFirstResponder()
                genAction.setTitle("Clear", for: UIControlState.normal)
                slider.isHidden = false
            }
        }
        else {
            imgQRCode.image = nil
            genImage = nil
            genAction.setTitle("Generate", for: UIControlState.normal)
            self.textField.text = ""
            slider.isHidden = true
        }
        textField.isEnabled = !textField.isEnabled
        return
    }
    
    @IBAction func changeImageViewScale(_ sender: AnyObject) {
        imgQRCode.transform = CGAffineTransform(scaleX: CGFloat(slider.value), y: CGFloat(slider.value))
    }
    
    func displayQRCodeImage() {
        let scaleX = imgQRCode.frame.size.width / qrcodeImage.extent .size.width
        let scaleY = imgQRCode.frame.size.height / qrcodeImage.extent .size.height
        let transformedImage = qrcodeImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        imgQRCode.image = UIImage(ciImage: transformedImage)
 
    }
    
    @IBAction func doneAction(_ sender: Any) {
        self .dismiss(animated: true, completion: nil);
    }
    
    @IBAction func shareAction(_ sender: UIBarButtonItem) {
        if imgQRCode.image != nil {
            if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
                let message: String! = "Created by iScannedit"
                let img = self.imgQRCode.image
                let shareItem = [img as Any, message] as [Any]
                let vc = UIActivityViewController(activityItems: shareItem, applicationActivities: nil)
                vc.popoverPresentationController?.barButtonItem = sender
                vc.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
                self.present(vc, animated: true, completion: nil)
            }
            else {
                let message: String! = "Created by iScannedit"
                let img = self.imgQRCode.image
                let shareItem = [img as Any, message] as [Any]
                let vc = UIActivityViewController(activityItems: shareItem, applicationActivities: nil)
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let ciContext = CIContext()
        let data = string.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("Q", forKey: "inputCorrectionLevel")
            let scaleX = imgQRCode.frame.size.width
            let scaleY = imgQRCode.frame.size.height
            let transformImage = CGAffineTransform(scaleX: scaleX, y: scaleY)
            let upScaledImage = filter.outputImage?.transformed(by: transformImage)
            let cgImage = ciContext.createCGImage(upScaledImage!, from: upScaledImage!.extent)
            genImage = UIImage(cgImage: cgImage!)
            return genImage
        }
        return nil
    }
    func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        print("Banner loaded successfully")
    }
    func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("Fail to receive ads")
        print(error)
    }
    
    
    
    
    // MARK: - Navigation
    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

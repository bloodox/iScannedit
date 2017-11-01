//
//  DocumentViewController.swift
//  iScan
//
//  Created by William Thompson on 2/7/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
import WebKit
import Firebase

class DocumentViewController: UIViewController {
    
    var isPurchase = false
    var tableView = TableViewController()
    var documentsDirectories: String!
    var newImage: UIImage!
    var alertController = UIAlertController()
    @IBOutlet weak var documentImage: UIImageView!
    @IBOutlet weak var bannerView: GADBannerView!
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bannerView.adUnitID = "ca-app-pub-7317713550657480/5127447259"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        view.bringSubview(toFront: bannerView)
        self.documentImage.image = newImage
        var filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory: String = filePath[0]
        self.documentsDirectories = documentsDirectory
        var objcBool:ObjCBool = true
        let isExist = FileManager.default.fileExists(atPath: self.documentsDirectories, isDirectory: &objcBool)
        if isExist == false{
            do{
                try FileManager.default.createDirectory(atPath: self.documentsDirectories, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print("Something went wrong while creating a new folder")
            }
        
        }
        isPurchase = iScanProducts.store.isProductPurchased(iScanProducts.RemoveAds)
        if isPurchase == true {
            bannerView.isHidden = true
        }
        
        /*
        func saveAlert() {
            
            alertController = UIAlertController(title: "Choose action", message: "Would you like to save as PDF?", preferredStyle: .alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            }
            alertController.addAction(cancelAction)
            
            let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .default) { (action:UIAlertAction) in
                if let image: UIImage = self.documentImage.image, // 1.
                    let imageData = UIImageJPEGRepresentation(image, 0.8){
                    let pdfSize = image.size // 2.
                    let pdfData = NSMutableData(capacity: imageData.count)! // 3.
                    
                    UIGraphicsBeginPDFContextToData(pdfData, CGRect(origin: CGPoint(), size: pdfSize), nil)
                    let context = UIGraphicsGetCurrentContext()!
                    UIGraphicsBeginPDFPage()
                    
                    // required so the UIImage can render into our context
                    UIGraphicsPushContext(context)
                    image.draw(at: CGPoint())
                    UIGraphicsPopContext()
                    
                    UIGraphicsEndPDFContext()
                    // now pdfData contains the rendered image.
                    let date = Date()
                    let imagePath = DateFormatter()
                    imagePath.dateFormat = "MM-dd-y_H-m-ss"
                    
                    
                    let directory = self.documentsDirectories + "/\(imagePath.string(from: date)).pdf"
                    let data = pdfData
                    _ = FileManager.default.createFile(atPath: directory, contents: data as Data, attributes: nil)
                     NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)                  
                    // saved it to the documentDirectory
                    
                }
                
            }
            
            alertController.addAction(saveAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
        
        saveAlert()
        */
        // Do any additional setup after loading the view.
    }
    
    
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        print("Banner loaded successfully")
    }
    func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("Fail to receive ads")
        print(error)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func doneAction(_ sender: Any) {
    
        self.dismiss(animated: true, completion: nil)
        
    }

    @IBAction func shareAction(_ sender: UIBarButtonItem) {
        if let image: UIImage = self.documentImage.image, // 1.
            let imageData = UIImageJPEGRepresentation(image, 0.8){
            let pdfSize = image.size // 2.
            let pdfData = NSMutableData(capacity: imageData.count)! // 3.
            
            UIGraphicsBeginPDFContextToData(pdfData, CGRect(origin: CGPoint(), size: pdfSize), nil)
            let context = UIGraphicsGetCurrentContext()!
            UIGraphicsBeginPDFPage()
            
            // required so the UIImage can render into our context
            UIGraphicsPushContext(context)
            image.draw(at: CGPoint())
            UIGraphicsPopContext()
            
            UIGraphicsEndPDFContext()
            // now pdfData contains the rendered image.
            let message: String = "Created by iScannedit"
            let img = pdfData
            let shareItem: [AnyObject] = [img, message as AnyObject]
            
            let vc = UIActivityViewController(activityItems: shareItem, applicationActivities: nil)
            if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
                vc.popoverPresentationController?.barButtonItem = sender
                vc.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
                self.present(vc, animated: true, completion: nil)
            } else{
                self.present(vc, animated: true, completion: nil)
            }
        
        
        
        
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

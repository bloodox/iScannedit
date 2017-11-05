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
import StoreKit
import CoreData

class MainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var bottomDocumentViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var imagePicker: UIBarButtonItem!
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var selector: UISegmentedControl!
    @IBOutlet weak var documentView: UIView!
    @IBOutlet weak var barcodeView: UIView!
    @IBOutlet weak var bottomToolbarConstraint: NSLayoutConstraint!
    
    var interactor = SlideRevealViewInteractor()
    var documentCollectionView: DocumentCollectionViewController!
    var isPurchased = false
    var images:[UIImage]!
    var titles:[String]!
    var documentsDirectories:String!
    var scanned = [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.bannerView.adUnitID = "ca-app-pub-7317713550657480/5127447259"
            self.bannerView.rootViewController = self
            self.bannerView.load(GADRequest())
            self.adViewDidReceiveAd(self.self.bannerView)
        }
        
        images = []
        var filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory: String = filePath[0]
        documentsDirectories = documentsDirectory + "/"
        var objcBool:ObjCBool = true
        let isExist = FileManager.default.fileExists(atPath: documentsDirectories, isDirectory: &objcBool)
        if isExist == false{
            do{
                try FileManager.default.createDirectory(atPath: documentsDirectories, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print("Something went wrong while creating a new folder")
            }
        }
        reloadData()
        // Do any additional setup after loading the view.
    }
    
    func reloadData() {
        do{
            images.removeAll()
            titles = try FileManager.default.contentsOfDirectory(atPath: documentsDirectories)
            for image in titles{
                let data = FileManager.default.contents(atPath: documentsDirectories + "/\(image)")
                
                let image = UIImage(data: data!)
                if image != nil {
                    images.append(image!)
                }
            }
        }catch{
            print("Error")
        }
        
    }
    override func viewWillAppear(_ animated: Bool) {
        if #available(iOS 10.0, *) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.persistentContainer.viewContext
            let fetchRequest : NSFetchRequest<Results> = Results.fetchRequest()
            do {
                let results = try managedContext.fetch(fetchRequest)
                scanned = results as [NSManagedObject]
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
            
        } else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            let fetchRequest : NSFetchRequest<Results> = Results.fetchRequest()
            do {
                let results = try managedContext.fetch(fetchRequest)
                scanned = results as [NSManagedObject]
            } catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
            
            // Fallback on earlier versions
        }
        let numberOfImagesInCollectionView: Int = images.count
        if numberOfImagesInCollectionView >= scanned.count {
            selector.selectedSegmentIndex = 0
        } else {
            selector.selectedSegmentIndex = 1
        }
        if selector.selectedSegmentIndex == 0 {
            view.sendSubview(toBack: barcodeView)
        }
        else {
            view.sendSubview(toBack: documentView)
        }
        reloadData()
        if numberOfImagesInCollectionView > 0 || scanned.count > 0 {
            messageLabel.isHidden = true
        }
        else {
            messageLabel.isHidden = false
        }
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        adViewDidReceiveAd(bannerView)
        let numberOfImagesInCollectionView: Int = images.count
        view.bringSubview(toFront: toolbar)
        view.bringSubview(toFront: bannerView)
        view.bringSubview(toFront: messageLabel)
        if numberOfImagesInCollectionView >= scanned.count {
            selector.selectedSegmentIndex = 0
        } else {
            selector.selectedSegmentIndex = 1
        }
        
        
        if selector.selectedSegmentIndex == 0 {
            view.sendSubview(toBack: barcodeView)
        }
        else {
            view.sendSubview(toBack: documentView)
        }
        reloadData()
        
        
        if numberOfImagesInCollectionView > 0 || scanned.count > 0 {
            messageLabel.isHidden = true
        }
        else {
            messageLabel.isHidden = false
        }
        let screenRect = UIScreen.main.bounds
        let screenHieght = screenRect.size.height
        isPurchased = iScanProducts.store.isProductPurchased(iScanProducts.RemoveAds)
        if isPurchased == false {
            bottomToolbarConstraint.constant = 50
            self.toolbar.frame.origin.y = screenHieght - 170
            self.documentView.frame.size.height = screenHieght - 170
            self.barcodeView.frame.size.height = screenHieght - 170
        }
        else {
            bannerView.isHidden = true
            bottomToolbarConstraint.constant = 0
            self.toolbar.frame.origin.y = screenHieght
            self.documentView.frame.size.height = screenHieght
            self.barcodeView.frame.size.height = screenHieght 
        }
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        if device?.hasTorch == true {
            do {
                try device?.lockForConfiguration()
            }
            catch {
                print("error")
            }
            if device?.isTorchActive == true {
                device?.torchMode = AVCaptureDevice.TorchMode.off
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
        print("Banner loaded successfully")
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
    
    @IBAction func presentScanner(_ sender: Any) {
    
        if selector.selectedSegmentIndex == 0 {
            let destination = storyboard?.instantiateViewController(withIdentifier: "document")
            show(destination!, sender: self)
        }
        else {
            let destination = storyboard?.instantiateViewController(withIdentifier: "barcode")
            show(destination!, sender: self)
        }

    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
        
        // Save image to Document directory
            let directory = documentsDirectories.appending("/iScan_\(Int(Date().timeIntervalSince1970)).pdf")
            let data = UIImageJPEGRepresentation(image, 0.8)
            _ = FileManager.default.createFile(atPath: directory, contents: data, attributes: nil)
            dismiss(animated: true) { () -> Void in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
            }
        }
    }
    
    @IBAction func imagePicker(_ sender: UIBarButtonItem) {
        let imagePicker = UIImagePickerController()
        present(imagePicker, animated: true, completion: nil)
        imagePicker.delegate = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? MenuViewController {
            destination.transitioningDelegate = self
            destination.interactor = interactor
        }
    }
    
    @IBAction func slideMenu(_ sender: Any) {
        performSegue(withIdentifier: "slideMenu", sender: nil)
    }
    
    @IBAction func edgePanGesture(_ sender: UIScreenEdgePanGestureRecognizer) {
        let translation = sender.translation(in: view)
        let progress = SlideRevealViewHelper.calculateProgress(translation, viewBounds: view.bounds, direction: .Right)
        SlideRevealViewHelper.mapGestureStateToInteractor(sender.state, progress: progress, interactor: interactor){
            self.performSegue(withIdentifier: "slideMenu", sender: nil)
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

extension MainViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideRevealViewAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideRevealDismissAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
    
}




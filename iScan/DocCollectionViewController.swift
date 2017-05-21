//
//  DocCollectionViewController.swift
//  iScan
//
//  Created by William Thompson on 2/10/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
import CoreFoundation
import Firebase

private let reuseIdentifier = "Cell"

class DocCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    
    @IBOutlet weak var bannerView: GADBannerView!
    var documentsDirectories:String!
    var images:[UIImage]!
    var titles:[String]!
    var newImage: UIImage!
    var selected:Bool = false
    var collectionViewCell = CollectionViewCell()
    var filePaths: Array<String?>?
    var tableView: TableViewController?
    var path: [String]!
    
    struct Storyboard {
        
        static let leftAndRightPaddings: CGFloat = 1.0
        static let numberOfItemsPerRow: CGFloat = 2.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //bannerView.adUnitID = "ca-app-pub-7317713550657480/5127447259"
        //bannerView.rootViewController = self
        //bannerView.load(GADRequest())
        //collectionView?.bringSubview(toFront: bannerView)
        let collectionViewWidth = collectionView?.frame.width
        let itemWidth = (collectionViewWidth! - Storyboard.leftAndRightPaddings) / Storyboard.numberOfItemsPerRow
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        
        images = []
        var filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        //create an array and store result of our search for the documents directory in it
        let documentsDirectory: String = filePath[0]
        // Create a new path for the new images folder
        documentsDirectories = documentsDirectory + "/"
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
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        

        // Do any additional setup after loading the view.
        refreshTable()
        NotificationCenter.default.addObserver(self, selector: #selector(DocCollectionViewController.refreshTable),name:NSNotification.Name(rawValue: "load"), object: nil)
        
        
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
    func refreshTable(){
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
            self.collectionView?.reloadData()
        }catch{
            print("Error")
        }
    }
    @IBAction func `switchAction`(_ sender: UISwitch) {
    selected = sender.isOn
        if selected == false {
            refreshTable()
        }
    
    }
    
    @IBAction func mergeAction(_ sender: Any) {
        do {
            var search = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            search = search.appending("/")
            let url = URL(fileURLWithPath: documentsDirectories)
            let options: FileManager.DirectoryEnumerationOptions = [ .skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]
            let listOfPaths = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: options)
            joinPDF(listOfPaths)
        } catch{
            print("oops")
        }
        
        
    }
 
    func joinPDF(_ listOfPaths: [Any]) {
        var pdfPathOutput = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        pdfPathOutput = pdfPathOutput.appending("/iScan_pdf_\(Int(Date().timeIntervalSince1970)).pdf")
        let pdfURLOutput: CFURL? = (URL(fileURLWithPath: pdfPathOutput) as CFURL?)
        
        // Create the output context
        let writeContext = CGContext(pdfURLOutput!, mediaBox: nil, nil)
        for source in listOfPaths {
            let pdfURL: CFURL = (source) as! CFURL
            //file ref
            let pdfRef = CGPDFDocument(pdfURL)
            
            let numberOfPages = pdfRef!.numberOfPages
            // Loop variables
            var page: CGPDFPage
            var mediaBox = CGRect.zero
            // Read the first PDF and generate the output pages
            // Finalize the output file
            print("GENERATING PAGES FROM PDF 1 (%@)...")
            for i in 1...numberOfPages {
                page = pdfRef!.page(at: i)!
                mediaBox = page.getBoxRect(.mediaBox)
                writeContext!.beginPage(mediaBox: &mediaBox)
                writeContext!.drawPDFPage(page)
                writeContext!.endPage()
            }
        
        }
        writeContext!.closePDF()
    }
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        var enable: Bool = false
        if selected == false {
            enable = true
        } else {
            enable = false
        }
        
        return enable
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segue1"{
            if let indexPath = self.collectionView?.indexPath(for: sender as! UICollectionViewCell) {
                let nav = segue.destination as! UINavigationController
                let destination = nav.topViewController as! DocumentViewController
                let selectedRow = images[indexPath.item]
                destination.newImage = selectedRow
            }
        }
    }
    
/*
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
        return headerView
    }
 */
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if selected == true {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderWidth = 2.0
            cell?.layer.borderColor = UIColor.red.cgColor
            
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.isSelected = false
        
        
    }
    
    /*
     // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        // Save image to Document directory
        let directory = documentsDirectories.appending("/iScan_\(Int(Date().timeIntervalSince1970)).pdf")
        let data = UIImageJPEGRepresentation(image, 0.8)
        _ = FileManager.default.createFile(atPath: directory, contents: data, attributes: nil)
        dismiss(animated: true) { () -> Void in
         NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
        }
    }
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
        cell.imageView.image = images[indexPath.item]
        if cell.isSelected == true {
            cell.layer.borderColor = UIColor.red.cgColor
        } else {
            cell.layer.borderColor = UIColor.clear.cgColor
        }
        // Configure the cell
    
        return cell
    }
    func getThumbnail(url:[NSURL], pageNumber:Int) -> UIImage {
        
        let pdf:CGPDFDocument = CGPDFDocument.init(url as! CFURL)!;
        
        let firstPage = pdf.page(at: pageNumber)
        
        // Change the width of the thumbnail here
        let width:CGFloat = 240.0;
        
        var pageRect:CGRect = firstPage!.getBoxRect(.mediaBox)
        let pdfScale:CGFloat = width/pageRect.size.width
        pageRect.size = CGSize(width: pageRect.size.width*pdfScale, height: pageRect.size.height*pdfScale)
        pageRect.origin = CGPoint.zero;
        
        UIGraphicsBeginImageContext(pageRect.size);
        
        let context:CGContext = UIGraphicsGetCurrentContext()!;
        
        // White BG
        context.setFillColor(red: 1.0,green: 1.0,blue: 1.0,alpha: 1.0);
        context.fill(pageRect);
        
        context.saveGState();
        
        // ***********
        // Next 3 lines makes the rotations so that the page look in the right direction
        // ***********
        context.translateBy(x: 0.0, y: pageRect.size.height);
        context.scaleBy(x: 1.0, y: -1.0);
        context.concatenate(firstPage!.getDrawingTransform(.mediaBox, rect: pageRect, rotate: 0, preserveAspectRatio: true));
        
        context.drawPDFPage(firstPage!);
        context.restoreGState();
        
        let thm:UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        
        UIGraphicsEndImageContext();
        return thm;
    }
    
    @IBAction func doneAction(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
    }

    @IBAction func imagePicker(_ sender: UIBarButtonItem) {
        let imagePicker = UIImagePickerController()
        present(imagePicker, animated: true, completion: nil)
        imagePicker.delegate = self
    }
    
    // MARK: UICollectionViewDelegate

    
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
 

    
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

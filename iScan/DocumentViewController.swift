//
//  DocumentViewController.swift
//  iScan
//
//  Created by William Thompson on 2/7/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit

class DocumentViewController: UIViewController {
    var documentsDirectories: String!
    var newImage: UIImage!
    var alertController = UIAlertController()
    @IBOutlet weak var documentImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.documentImage.image = newImage
        var filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory: String = filePath[0]
        self.documentsDirectories = documentsDirectory + "/ImagePicker"
        var objcBool:ObjCBool = true
        let isExist = FileManager.default.fileExists(atPath: self.documentsDirectories, isDirectory: &objcBool)
        if isExist == false{
            do{
                try FileManager.default.createDirectory(atPath: self.documentsDirectories, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print("Something went wrong while creating a new folder")
            }
        }
        
        
        func saveAlert() {
            
            alertController = UIAlertController(title: "Choose action", message: "Would you like to save as PDF?", preferredStyle: .alert)
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            }
            alertController.addAction(cancelAction)
            
            let saveAction: UIAlertAction = UIAlertAction(title: "Save", style: .default) { (action:UIAlertAction) in
                if let image: UIImage = self.documentImage.image, // 1.
                    let imageData = UIImageJPEGRepresentation(image, 0.8) {
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
                    var imagePath = Date().description
                    imagePath = imagePath.replacingOccurrences(of: " ", with: "")
                    imagePath = self.documentsDirectories + "/\(imagePath).pdf"
                    let data = pdfData
                    _ = FileManager.default.createFile(atPath: imagePath, contents: data as Data, attributes: nil)
                    // saved it to the documentDirectory
                    
                }
            }
            
            alertController.addAction(saveAction)
            
            
            self.present(alertController, animated: true, completion: nil)
        }
        saveAlert()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func doneAction(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
        
    }

    @IBAction func shareAction(_ sender: UIBarButtonItem) {
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            let img: [AnyObject] = [self.documentImage.image as AnyObject]
            let vc = UIActivityViewController(activityItems: img, applicationActivities: nil)
            vc.popoverPresentationController?.barButtonItem = sender
            vc.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.up
            self.present(vc, animated: true, completion: nil)
        }
        else {
            let img: [AnyObject] = [self.documentImage.image as AnyObject]
            let vc = UIActivityViewController(activityItems: img, applicationActivities: nil)
            self.present(vc, animated: true, completion: nil)
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

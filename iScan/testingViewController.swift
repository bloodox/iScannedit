//
//  testingViewController.swift
//  iScan
//
//  Created by William Thompson on 2/10/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit



class testingViewController: UIViewController {
    @IBOutlet weak var doneAction: UIBarButtonItem!
    @IBOutlet weak var shareAction: UIBarButtonItem!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var imgQRCode: UIImageView!
    @IBOutlet weak var genAction: UIButton!
    var documentsDirectories:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if qrcodeImage == nil {
            slider.isHidden = true
        }
        else  {
            slider.isHidden = false
        }
        NotificationCenter.default.addObserver(self, selector:#selector(GenerateViewController.performButtonAction(_:)), name:NSNotification.Name.UIApplicationWillEnterForeground, object:UIApplication.shared
        )        // Do any additional setup after loading the view.
    }
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func performButtonAction(_ sender: AnyObject) {
        if qrcodeImage == nil{
            if textField.text != "" {
                let data = textField.text?.data(using: String.Encoding.isoLatin1, allowLossyConversion: false)
                let filter = CIFilter(name: "CIQRCodeGenerator")
                filter?.setValue(data, forKey: "inputMessage")
                filter?.setValue("Q", forKey: "inputCorrectionLevel")
                qrcodeImage = filter?.outputImage
                displayQRCodeImage()
                textField.resignFirstResponder()
                genAction.setTitle("Clear", for: UIControlState.normal)
                slider.isHidden = false
            }
        }
        else {
            imgQRCode.image = nil
            qrcodeImage = nil
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
        let transformedImage = qrcodeImage.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
        imgQRCode.image = UIImage(ciImage: transformedImage)
        var filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory: String = filePath[0]
        documentsDirectories = documentsDirectory + "/ImagePicker"
        var objcBool:ObjCBool = true
        let isExist = FileManager.default.fileExists(atPath: documentsDirectories, isDirectory: &objcBool)
        if isExist == false{
            do{
                try FileManager.default.createDirectory(atPath: documentsDirectories, withIntermediateDirectories: true, attributes: nil)
            }catch{
                print("Something went wrong while creating a new folder")
            }
        }
        var imagePath = Date().description
        imagePath = imagePath.replacingOccurrences(of: " ", with: "")
        imagePath = documentsDirectories + "/\(imagePath).png"
        let image = imgQRCode.image
        let datas = UIImagePNGRepresentation(image!)
        _ = FileManager.default.createFile(atPath: imagePath, contents: datas, attributes: nil)
    }
    @IBAction func doneAction(_ sender: Any) {
        self .dismiss(animated: true, completion: nil);
    }
    
    @IBAction func shareAction(_ sender: Any) {
        
        if imgQRCode.image != nil {
            
            let img = UIImagePNGRepresentation(imgQRCode.image!)
            let imageToShare = [img!]
            let vc = UIActivityViewController(activityItems: imageToShare, applicationActivities: [])
            self.present(vc, animated: true, completion: nil)
        }
    }
    /* func generateQRCode(from textField: UITextField) -> UIImage? {
     
     }
     */
    
    
    
    /*
     
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}

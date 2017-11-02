//
//  TableViewController.swift
//  iScan
//
//  Created by William Thompson on 1/28/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
import Firebase

struct TitleFile {
    var name: String
}

class TableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var bannerView: GADBannerView!
    
    // Properties
    var documentsDirectories:String!
    var images:[UIImage]!
    var titles:[String]!
    var titleFiles = [TitleFile]()
    var isPurchased = false
    
    @IBAction func choosePhoto(_ sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        present(imagePicker, animated: true, completion: nil)
        imagePicker.delegate = self
 
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        bannerView.adUnitID = "ca-app-pub-7317713550657480/5127447259"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        navigationItem.rightBarButtonItem = self.editButtonItem
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
        refreshTable()
        NotificationCenter.default.addObserver(self, selector: #selector(TableViewController.refreshTable),name:NSNotification.Name(rawValue: "load"), object: nil)
        isPurchased = iScanProducts.store.isProductPurchased(iScanProducts.RemoveAds)
        if isPurchased == true {
            bannerView.isHidden = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func refreshTable(){
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
            self.tableView.reloadData()
        }catch{
            print("Error")
        }
    }
    
    
    //MARK: UIImagePickerControllerDelegate Protocol
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        // Save image to Document directory
        let directory = documentsDirectories.appending("/iScan_\(Int(Date().timeIntervalSince1970)).pdf")
        let data = UIImageJPEGRepresentation(image, 0.8)
        _ = FileManager.default.createFile(atPath: directory, contents: data, attributes: nil)
        dismiss(animated: true) { () -> Void in
            self.refreshTable()
        }
    }
 
    //MARK: UITableView DataSource
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "CellID")
        cell.imageView?.image = images[indexPath.row]
        cell.textLabel?.text = titles[indexPath.row]
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return images.count
    }
    @IBAction func doneAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let filePaths = titles[indexPath.row]
            let fileManager = FileManager.default
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let documentPath = documentsPath
            let filePath = "\(documentPath)/\(filePaths)"
            do {
               
                try fileManager.removeItem(atPath: filePath)
                 self.refreshTable()                
                
                
            } catch {
                print("error")
            }
            
            // Delete the row from the data source
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segue" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let nav = segue.destination as! UINavigationController
                let destination = nav.topViewController as! DocumentViewController
                let selectedRow = images[indexPath.row]
                destination.newImage = selectedRow
                
            }
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
    }
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
        print("Banner loaded successfully")
    }
    func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("Fail to receive ads")
        print(error)
    }

}
/*
 

*/
/*
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
 
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.

 
 
    */
    /*
    // Override to support rearranging the table view.
 

    }
    */

    /*
    //
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
        */



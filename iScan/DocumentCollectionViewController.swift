//
//  DocumentCollectionViewController.swift
//  iScan
//
//  Created by Thompson on 5/20/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class DocumentCollectionViewController: UICollectionViewController {

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
        refreshTable()
        NotificationCenter.default.addObserver(self, selector: #selector(DocumentCollectionViewController.refreshTable),name:NSNotification.Name(rawValue: "load"), object: nil)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

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
    
        // Configure the cell
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

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

//
//  DocumentCollectionViewController.swift
//  iScan
//
//  Created by William Thompson on 5/20/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class DocumentCollectionViewController: UICollectionViewController {

    // Mark: Variables
    var documentsDirectories:String!
    var images:[UIImage]!
    var titles:[String]!
    var newImage: UIImage!
    var selected:Bool = false
    var collectionViewCell = CollectionViewCell()
    var filePaths: Array<String?>?
    var tableView: TableViewController?
    var path: [String]!
    var alerController = UIAlertController()
    var mainViewController: MainViewController!
    
    fileprivate var activeCell: CollectionViewCell!
    
    // Mark: Outlets
    @IBOutlet var theCollectionView: UICollectionView!
    
    struct Storyboard {
        
        static let leftAndRightPaddings: CGFloat = 1.0
        static let numberOfItemsPerRow: CGFloat = 2.0
        static let iPadNumberOfItemsPerRow: CGFloat = 3.0
        
    }
    
    // Mark: View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            let collectionViewWidth = collectionView?.frame.width
            let itemWidth = (collectionViewWidth! - Storyboard.leftAndRightPaddings) / Storyboard.iPadNumberOfItemsPerRow
            let layout = collectionViewLayout as! UICollectionViewFlowLayout
            layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        } else {
            let collectionViewWidth = collectionView?.frame.width
            let itemWidth = (collectionViewWidth! - Storyboard.leftAndRightPaddings) / Storyboard.numberOfItemsPerRow
            let layout = collectionViewLayout as! UICollectionViewFlowLayout
            layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        }
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
        setupView()
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        refreshTable()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        userDidSwipeRight()
    }

    // Mark: Collection View refreshing
    
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
            self.collectionView?.reloadData()
        }catch{
            print("Error")
        }
        
    }
    
    // MARK: - Navigation
    
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
    func countItemsInCollectionView() -> Int {
        return images.count
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
    
    // Mark: CollectionView Cell animations
    
    func setupView() {
        let swipeUp: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(DocumentCollectionViewController.userDidSwipeLeft))
        swipeUp.direction = .left
        view.addGestureRecognizer(swipeUp)
        let swipeDown: UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(DocumentCollectionViewController.userDidSwipeRight))
        swipeDown.direction = .right
        view.addGestureRecognizer(swipeDown)
    }

    func getCellAtPoint(_ point: CGPoint) -> CollectionViewCell? {
        let indexPath = theCollectionView.indexPathForItem(at: point)
        var cell: CollectionViewCell?
        if indexPath != nil {
            cell = theCollectionView.cellForItem(at: indexPath!) as? CollectionViewCell
        } else {
            cell = nil
        }
        return cell
    }
    
    @objc func userDidSwipeLeft(_ gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: theCollectionView)
        let duration = animationDuration()
        if (activeCell == nil) {
            activeCell = getCellAtPoint(point)
            if activeCell != nil {
            UIView.animate(withDuration: duration, animations: {
                self.activeCell.cellView.transform = CGAffineTransform(translationX: -self.activeCell.frame.width/2, y: 0)
            });
            }
            
        } else {
            let cell = getCellAtPoint(point)
            
            /* /*
               // uncomment this section if the items stored in the collection view aren't stored in
               //the documents directory if they are leave commented out for a better way of deletion 
               //or the app will crash due to not handling items removed from the datasource when 
               //objects are deleted
               */
            if cell == nil || cell == activeCell {
                let cellFrame = activeCell.frame
                let rect = CGRect(x: cellFrame.origin.x, y: cellFrame.origin.y - cellFrame.height, width: cellFrame.width, height: cellFrame.height*2)
                
                if rect.contains(point) {
                    let indexPath = theCollectionView.indexPath(for: activeCell)
                    titles.remove(at: indexPath!.row)
                    theCollectionView.deleteItems(at: [indexPath!])
                }
 
            } else*/ if activeCell != cell {
                UIView.animate(withDuration: duration, animations: {
                    self.activeCell.cellView.transform = CGAffineTransform.identity
                    cell!.cellView.transform = CGAffineTransform(translationX: -self.activeCell.frame.width/2, y: 0)
                }, completion: {
                    (Void) in
                    self.activeCell = cell
                })
                
            }
        }
    }
    
    @objc func userDidSwipeRight() {
        if (activeCell != nil) {
            let duration = animationDuration()
            UIView.animate(withDuration: duration, animations: {
                self.activeCell.cellView.transform = CGAffineTransform.identity
            }, completion: {
                (Void) in
                self.activeCell = nil
            })
        }
    }
    
    func animationDuration() -> Double {
        return 0.3
    }
    
    // Mark: Button actions
    
    // delete action
    @IBAction func deleteAction(_ sender: UIButton) {
        alerController = UIAlertController(title: "Delete", message: "Are you sure you want to delete the selected item", preferredStyle: .alert)
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { (action: UIAlertAction) in
            self.userDidSwipeRight()
        }
        alerController.addAction(cancelAction)
        let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .default) { (action: UIAlertAction) in
        let indexPath = self.theCollectionView.indexPath(for: self.activeCell)
        let filePaths = self.titles[(indexPath?.row)!]
        let fileManager = FileManager.default
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let documentPath = documentsPath
        let filePath = "\(documentPath)/\(filePaths)"
        do {
            try fileManager.removeItem(atPath: filePath)
            self.refreshTable()
            self.userDidSwipeRight()
        } catch {
            print("error")
        }
        self.refreshTable()
        }
        alerController.addAction(deleteAction)
        self.present(alerController, animated: true, completion: nil)
    }
    
    // share action
    @IBAction func shareAction(_ sender: UIButton) {
        let indexPath = self.theCollectionView.indexPath(for: self.activeCell)
        let image: UIImage = self.images[(indexPath?.row)!]
        let imageData = UIImageJPEGRepresentation(image, 0.8)
        let pdfSize = image.size // 2.
        let pdfData = NSMutableData(capacity: (imageData?.count)!)! // 3.
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
            vc.popoverPresentationController?.sourceView = activeCell
            vc.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
            self.present(vc, animated: true, completion: nil)
            userDidSwipeRight()
        } else{
            self.present(vc, animated: true, completion: nil)
            userDidSwipeRight()
        }
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

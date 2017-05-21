//
//  TableVController.swift
//  iScan
//
//  Created by William Thompson on 1/23/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
import CoreData
import Firebase


class TableVController: UITableViewController {

    var scanned = [NSManagedObject]()
    
    
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var doneAction: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        bannerView.adUnitID = "ca-app-pub-7317713550657480/5127447259"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        navigationItem.rightBarButtonItem = editButtonItem
        title = "iScan History"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
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
            tableView.reloadData()
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
            tableView.reloadData()
            
            // Fallback on earlier versions
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
    // MARK: - Table view data source
    /*
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }
    */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return scanned.count
    }

    
     override func tableView(_ tableView: UITableView,cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     
     let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
     
     let text = scanned[indexPath.row]
     
     cell!.textLabel!.text = text.value(forKey: "scan") as? String
     
     return cell!
    }
    func savescan(name: String) {
        if #available(iOS 10.0, *) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.persistentContainer.viewContext
            let entity =  NSEntityDescription.entity(forEntityName: "Results", in:managedContext)
            let text = NSManagedObject(entity: entity!, insertInto: managedContext)
            text.setValue(name, forKey: "scan")
            do {
                try managedContext.save()
                scanned.append(text)
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
        
        
        
        } else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            let entity =  NSEntityDescription.entity(forEntityName: "Results", in:managedContext)
            let text = NSManagedObject(entity: entity!, insertInto: managedContext)
            text.setValue(name, forKey: "scan")
            do {
                try managedContext.save()
                scanned.append(text)
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
            // Fallback on earlier versions
        }
        
        
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let noteEntity = "Results" //Entity Name
        
        if #available(iOS 10.0, *) {
            let managedContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let note = scanned[indexPath.row]
            
            if editingStyle == .delete {
                managedContext.delete(note)
                
                do {
                    try managedContext.save()
                } catch let error as NSError {
                    print("Error While Deleting Note: \(error.userInfo)")
                }
                
            }
            
            //Code to Fetch New Data From The DB and Reload Table.
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: noteEntity)
            
            do {
                scanned = try managedContext.fetch(fetchRequest) as! [Results]
            } catch let error as NSError {
                print("Error While Fetching Data From DB: \(error.userInfo)")
            }
            tableView.reloadData()        
        
        
        
        
        
        } else {
            let managedContext = (UIApplication.shared.delegate as! AppDelegate).managedObjectContext
            let note = scanned[indexPath.row]
            
            if editingStyle == .delete {
                managedContext.delete(note)
                
                do {
                    try managedContext.save()
                } catch let error as NSError {
                    print("Error While Deleting Note: \(error.userInfo)")
                }
                
            }
            
            //Code to Fetch New Data From The DB and Reload Table.
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: noteEntity)
            
            do {
                scanned = try managedContext.fetch(fetchRequest) as! [Results]
            } catch let error as NSError {
                print("Error While Fetching Data From DB: \(error.userInfo)")
            }
            tableView.reloadData()        }
        
        
    }
    @IBAction func doneAction(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
    }

   
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    

   
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
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

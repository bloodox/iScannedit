//
//  BarcodeTableViewController.swift
//  iScan
//
//  Created by Thompson on 5/26/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit
import CoreData

class BarcodeTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var scanned = [NSManagedObject]()    
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editAction: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        /*
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
        
         // Do any additional setup after loading the view.
         }
         */
    }

    override func viewDidAppear(_ animated: Bool) {
        reload()
        
    }
    
    @IBAction func editAction(_ sender: UIBarButtonItem) {
        let indexPath = tableView.indexPathForSelectedRow
        let editStyle = UITableViewCellEditingStyle.delete
        if indexPath != nil {
        tableView(tableView, commit: editStyle, forRowAt: indexPath!)
        }
    
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func reload() {
        scanned = []
        tableView.reloadData()
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
            
            // Do any additional setup after loading the view.
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scanned.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        let text = scanned[indexPath.row]
        cell!.textLabel!.text = text.value(forKey: "scan") as? String
        return cell!
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        
    }    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        editAction = editButtonItem
        
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
            tableView.reloadData()
        }
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.delegate!.tableView!(tableView, didDeselectRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print("row deselected")
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
/*
extension BarcodeTableViewController: UITableViewDataSource, UITableViewDelegate{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scanned.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        let text = scanned[indexPath.row]
        cell!.textLabel!.text = text.value(forKey: "scan") as? String
        return cell!
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        editAction = editButtonItem
        
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
            tableView.reloadData()
        }
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.delegate!.tableView!(tableView, didDeselectRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        print("row deselected")
    }
    
}
*/

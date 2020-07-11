//
//  ViewController.swift
//  Inventory
//
//  Created by Mason Parry on 6/25/20.
//  Copyright © 2020 Mason Parry. All rights reserved.
//

import UIKit
import SQLite3

struct Item{
    var shortDescription: String = ""
    var longDescription: String = ""
}


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddItemProtocol, EditItemProtocol {
    
    var db: OpaquePointer?
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            self.itemIndex = indexPath.row
            self.items.remove(at: self.itemIndex)
            
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action:UIContextualAction, sourceView:UIView, actionPerformed:(Bool) -> Void) in
            
            self.itemIndex = indexPath.row
            self.items.remove(at: self.itemIndex)
            
            tableView.reloadData()
            
            actionPerformed(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        itemData = items[indexPath.row]
        cell.textLabel?.text = itemData.shortDescription
        cell.detailTextLabel?.text = itemData.longDescription
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var valueSentFromAddViewController:Item?
    var valueSentFromEditViewController:Item?
    var items: [Item]! = []
    var itemIndex: Int!
    var itemBeingEdited: Int!
    var itemData: Item!
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addSegue" {
            let view = segue.destination as! AddViewController
            view.delegate = self
        
        } else if segue.identifier == "editSegue" {
            let view = segue.destination as! EditViewController
            view.delegate = self
            itemIndex = tableView.indexPathForSelectedRow?.row
            view.item.shortDescription = items[itemIndex].shortDescription
            view.item.longDescription = items[itemIndex].longDescription
        }
    }
    
    func addItem(_ item: Item) {
        items.append(item)
        tableView.reloadData()
    }
    
    func editItem(_ item: Item) {
        itemBeingEdited = tableView.indexPathForSelectedRow?.row
        items[itemBeingEdited].shortDescription = item.shortDescription
        items[itemBeingEdited].longDescription = item.longDescription
        tableView.reloadData()
    }
    
    @objc func saveToDatabase(_ notification:Notification) {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Inventory.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        if sqlite3_exec(db, "DELETE FROM Items", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }
        
        for item in items {
            //the insert query
            let queryString = "INSERT INTO Items (shortDescription, longDescription) VALUES (?,?)"
            
            //creating a statement
            var stmt: OpaquePointer?
            
            //preparing the query
            if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
               let errmsg = String(cString: sqlite3_errmsg(db)!)
               print("error preparing insert: \(errmsg)")
               return
            }
            
            //binding the parameters
            if sqlite3_bind_text(stmt, 1, (item.shortDescription as NSString).utf8String, -1, nil) != SQLITE_OK{
               let errmsg = String(cString: sqlite3_errmsg(db)!)
               print("failure binding shortDescription: \(errmsg)")
               return
            }

            if sqlite3_bind_text(stmt, 2, (item.longDescription as NSString).utf8String, -1, nil) != SQLITE_OK{
               let errmsg = String(cString: sqlite3_errmsg(db)!)
               print("failure binding longDescription: \(errmsg)")
               return
            }

            //executing the query to insert values
            if sqlite3_step(stmt) != SQLITE_DONE {
               let errmsg = String(cString: sqlite3_errmsg(db)!)
               print("failure inserting item: \(errmsg)")
               return
            }
        }
        
        sqlite3_close(db)
    }
    
    func readValues(){
            //first empty the list of heroes
            items.removeAll()

            //this is our select query
            let queryString = "SELECT * FROM Items"

            //statement pointer
            var stmt:OpaquePointer?

            //preparing the query
            if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
                let errmsg = String(cString: sqlite3_errmsg(db)!)
                print("error preparing insert: \(errmsg)")
                return
            }

            //traversing through all the records
            while(sqlite3_step(stmt) == SQLITE_ROW){
                let shortDescription = String(cString: sqlite3_column_text(stmt, 1))
                let longDescription = String(cString: sqlite3_column_text(stmt, 2))

                //adding values to list
                items.append(Item(shortDescription: shortDescription, longDescription: longDescription))
            }
            tableView.reloadData()
       }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "Inventory"
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,selector: #selector(saveToDatabase(_:)),name: UIApplication.willResignActiveNotification, object: nil)

        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Inventory.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Items (id INTEGER PRIMARY KEY AUTOINCREMENT, shortDescription VARCGAR, longDescription VARCHAR)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }
        
        readValues()
    }


}


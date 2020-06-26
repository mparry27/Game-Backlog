//
//  ViewController.swift
//  Inventory
//
//  Created by Mason Parry on 6/25/20.
//  Copyright © 2020 Mason Parry. All rights reserved.
//

import UIKit

struct Item{
    var shortDescription: String = ""
    var longDescription: String = ""
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddItemProtocol, EditItemProtocol {
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.title = "Inventory"
    }


}


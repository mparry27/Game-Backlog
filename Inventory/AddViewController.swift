//
//  AddViewController.swift
//  Inventory
//
//  Created by Mason Parry on 6/25/20.
//  Copyright © 2020 Mason Parry. All rights reserved.
//

import UIKit

protocol AddItemProtocol {
    func addItem(_ item:Item)
}

class AddViewController: UIViewController {
    
    @IBOutlet weak var addShortDescription: UITextField!
    @IBOutlet weak var addLongDescription: UITextView!
    var delegate:AddItemProtocol?
    
    @objc func saveItem() {
        let item:Item = Item(shortDescription: addShortDescription.text!, longDescription: addLongDescription.text)
        delegate?.addItem(item)
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Add New Item"
        
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveItem))
        
        self.navigationItem.rightBarButtonItem = save

    }

}

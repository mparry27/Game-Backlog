//
//  EditViewController.swift
//  Inventory
//
//  Created by Mason Parry on 6/25/20.
//  Copyright © 2020 Mason Parry. All rights reserved.
//

import UIKit

protocol EditItemProtocol {
    func editItem(_ item:Item)
}

class EditViewController: UIViewController {
    
    @IBOutlet weak var editLongDescription: UITextView!
    @IBOutlet weak var editShortDescription: UITextField!
    var item:Item = Item()
    var delegate:EditItemProtocol?

    
    @objc func saveItem() {
        item.shortDescription = editShortDescription.text!
        item.longDescription = editLongDescription.text
        delegate?.editItem(item)
        self.navigationController?.popViewController(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Edit Item"
        
        editShortDescription.text! = item.shortDescription
        editLongDescription.text = item.longDescription
        
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveItem))
        
        self.navigationItem.rightBarButtonItem = save
    }

}

//
//  AddViewController.swift
//  Game BackLog
//
//  Created by Mason Parry on 6/25/20.
//  Copyright © 2020 Mason Parry. All rights reserved.
//

import UIKit

protocol AddGameProtocol {
    func addGame(_ game:Game, _ cover:UIImage?)
}

class AddViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var addTitle: UITextField!
    @IBOutlet weak var addDeveloper: UITextField!
    @IBOutlet weak var addReleaseDate: UITextField!
    @IBOutlet weak var addCover: UIImageView!
    @IBOutlet weak var addDescription: UITextView!
    @IBOutlet weak var addGenre: UITextView!
    @IBOutlet weak var addPlatform: UITextView!
    @IBOutlet weak var addCategory: UIPickerView!
    var delegate:AddGameProtocol?
    let dateFormatter = DateFormatter()
    var pickerData:[Category] = [Category]()
    
    @IBAction func tappedAddTitle(_ sender: Any) {
        self.addTitle.layer.borderColor = UIColor.black.cgColor
    }
    
    @IBAction func tappedAddDeveloper(_ sender: Any) {
        self.addDeveloper.layer.borderColor = UIColor.black.cgColor
    }
    
    @IBAction func tappedAddReleaseDate(_ sender: Any) {
        self.addReleaseDate.layer.borderColor = UIColor.black.cgColor
    }
    
    @IBAction func tappedEditCover(_ sender: Any) {
        let alert = UIAlertController(title: "Get Game Cover", message: "Enter URL for game cover image", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
        }

        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak alert] (_) in
            if let imageURL = alert?.textFields![0].text, !imageURL.isEmpty {
                let url = URL(string: imageURL)!
                if let data = try? Data(contentsOf: url) {
                    self.addCover.image = UIImage(data: data)
                }
            }
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerData[row] {
            case Category.playing:
                return "Currently Playing"
            case Category.finished:
                return "Finished Playing"
            case Category.completed:
                return "Completed Playing"
            default:
                return "Plan To Play"
        }
    }
    
    @objc func saveGame() {
        if(self.addTitle.text?.isEmpty ?? true) {
            self.addTitle.layer.borderColor = UIColor.red.cgColor
        } else if(self.addDeveloper.text?.isEmpty ?? true) {
            self.addDeveloper.layer.borderColor = UIColor.red.cgColor
        } else if(self.addReleaseDate.text?.isEmpty ?? true || dateFormatter.date(from: addReleaseDate.text!) == nil) {
            self.addReleaseDate.layer.borderColor = UIColor.red.cgColor
        } else {
            let game:Game = Game(title: addTitle.text!, developer: addDeveloper.text!, releaseDate: dateFormatter.date(from: addReleaseDate.text!)!, coverURL: addTitle.text! + addDeveloper.text! + addReleaseDate.text!, description: addDescription.text, genre: addGenre.text, platform: addPlatform.text, category: pickerData[addCategory.selectedRow(inComponent: 0)])
            delegate?.addGame(game, addCover.image)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Add New Game"
        
        dateFormatter.dateFormat = "yyyy"
        
        //Add borders to text views
        addDescription!.layer.borderWidth = 1
        addDescription!.layer.cornerRadius = 6
        addDescription!.layer.borderColor = UIColor.black.cgColor
        addGenre!.layer.borderWidth = 1
        addGenre!.layer.cornerRadius = 6
        addGenre!.layer.borderColor = UIColor.black.cgColor
        addPlatform!.layer.borderWidth = 1
        addPlatform!.layer.cornerRadius = 6
        addPlatform!.layer.borderColor = UIColor.black.cgColor
        addTitle.layer.borderWidth = 1
        addDeveloper.layer.borderWidth = 1
        addReleaseDate.layer.borderWidth = 1
        
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveGame))
        
        // set up category picier
        self.addCategory.delegate = self
        self.addCategory.dataSource = self
        for category in Category.allValues {
            pickerData.append(category)
        }
        
        self.navigationItem.rightBarButtonItem = save

    }
}

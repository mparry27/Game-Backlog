//
//  EditViewController.swift
//  Game Backlog
//
//  Created by Mason Parry on 6/25/20.
//  Copyright © 2020 Mason Parry. All rights reserved.
//

import UIKit

protocol EditGameProtocol {
    func editGame(_ item:Game, _ cover: UIImage?)
}

class EditViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var editTitle: UITextField!
    @IBOutlet weak var editDeveloper: UITextField!
    @IBOutlet weak var editReleaseDate: UITextField!
    @IBOutlet weak var editCover: UIImageView!
    @IBOutlet weak var editDescription: UITextView!
    @IBOutlet weak var editGenre: UITextView!
    @IBOutlet weak var editPlatform: UITextView!
    @IBOutlet weak var editCategory: UIPickerView!
    @IBOutlet var keyboardHeightLayoutConstraint: NSLayoutConstraint?
    var game:Game = Game()
    var delegate:EditGameProtocol?
    let dateFormatter = DateFormatter()
    var pickerData:[Category] = [Category]()
    
    @IBAction func tappedEditTitle(_ sender: UITextField) {
        self.editTitle.layer.borderColor = UIColor.black.cgColor
    }
    
    @objc func saveGame() {
        if(self.editTitle.text?.isEmpty ?? true) {
            self.editTitle.layer.borderColor = UIColor.red.cgColor
        } else if(dateFormatter.date(from: editReleaseDate.text!) == nil && self.editReleaseDate.text?.isEmpty == false) {
            self.editReleaseDate.layer.borderColor = UIColor.red.cgColor
        } else {
            game.title = editTitle.text!
            game.developer = editDeveloper.text!
            game.releaseDate = dateFormatter.date(from: editReleaseDate.text ?? "")
            game.coverURL = editTitle.text! + editDeveloper.text! + editReleaseDate.text!
            game.description = editDescription.text!
            game.genre = editGenre.text!
            game.platform = editPlatform.text!
            game.category = pickerData[editCategory.selectedRow(inComponent: 0)]
            delegate?.editGame(game, editCover.image)
            self.navigationController?.popViewController(animated: true)
        }
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
    
    func loadImageFromDiskWith(coverURL: String) -> UIImage? {

      let documentDirectory = FileManager.SearchPathDirectory.documentDirectory

        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)

        if let dirPath = paths.first {
            let imageUrl = URL(fileURLWithPath: dirPath).appendingPathComponent(coverURL)
            let image = UIImage(contentsOfFile: imageUrl.path)
            return image

        }

        return nil
    }

    @IBAction func tappedEditCover(_ sender: Any) {
        let alert = UIAlertController(title: "Get Game Cover", message: "Enter URL for game cover image", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
        }

        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak alert] (_) in
            if let imageURL = alert?.textFields![0].text, !imageURL.isEmpty {
                let url = URL(string: imageURL)!
                if let data = try? Data(contentsOf: url) {
                    self.editCover.image = UIImage(data: data)
                }
            }
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    func downloadImageFrom(imageURL: String) {
        let url = (URL(string: imageURL) ?? URL(string: ""))!
        if let data = try? Data(contentsOf: url) {
            editCover.image = UIImage(data: data)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //push content up when keyboard is on screen
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let endFrameY = endFrame?.origin.y ?? 0
            let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            if endFrameY >= UIScreen.main.bounds.size.height {
                self.keyboardHeightLayoutConstraint?.constant = 0.0
            } else {
                self.keyboardHeightLayoutConstraint?.constant = endFrame?.size.height ?? 0.0
            }
            UIView.animate(withDuration: duration,
                                       delay: TimeInterval(0),
                                       options: animationCurve,
                                       animations: { self.view.layoutIfNeeded() },
                                       completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Edit Game"
        
        dateFormatter.dateFormat = "yyyy"
        
        //Add borders to text views
        editDescription!.layer.borderWidth = 1
        editDescription!.layer.cornerRadius = 6
        editDescription!.layer.borderColor = UIColor.black.cgColor
        editGenre!.layer.borderWidth = 1
        editGenre!.layer.cornerRadius = 6
        editGenre!.layer.borderColor = UIColor.black.cgColor
        editPlatform!.layer.borderWidth = 1
        editPlatform!.layer.cornerRadius = 6
        editPlatform!.layer.borderColor = UIColor.black.cgColor
        editTitle.layer.borderWidth = 1
        editDeveloper.layer.borderWidth = 1
        editReleaseDate.layer.borderWidth = 1
        
        // set up category picier
        self.editCategory.delegate = self
        self.editCategory.dataSource = self
        for category in Category.allValues {
            pickerData.append(category)
        }
        
        // load image from disk
        if let cover = loadImageFromDiskWith(coverURL: game.coverURL!) {
            editCover.image = cover
        }
        
        // set info boxes to game being edited
        editTitle.text! = game.title
        editDeveloper.text! = game.developer!
        if(game.releaseDate != nil){
            editReleaseDate.text = dateFormatter.string(from: game.releaseDate!)
        }
        editDescription.text! = game.description!
        editGenre.text = game.genre
        editPlatform.text = game.platform
        editCategory.selectRow(pickerData.firstIndex(of: game.category)!, inComponent: 0, animated: false)
        
        let save = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveGame))
        
        self.navigationItem.rightBarButtonItem = save
        
        // Notification to avoid keyboard overlapping elements
        NotificationCenter.default.addObserver(self,
        selector: #selector(self.keyboardNotification(notification:)),
        name: UIResponder.keyboardWillChangeFrameNotification,
        object: nil)
        
        self.hideKeyboardWhenTappedAround()
    }

}

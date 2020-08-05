//
//  ViewController.swift
//  Game Backlog
//
//  Created by Mason Parry on 6/25/20.
//  Copyright © 2020 Mason Parry. All rights reserved.
//

import UIKit
import SQLite3

struct Game{
    var title: String = ""
    var developer: String = ""
    var releaseDate: Date = Date()
    var coverURL: String = ""
    var description: String = ""
    var genre: String = ""
    var platform: String = ""
    var category: Category = Category.planned
}

enum Category : String {
    case playing, planned, finished, completed
    
    static let allValues = [planned, playing, finished, completed]
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddGameProtocol, EditGameProtocol {
    
    var db: OpaquePointer?
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            self.gameIndex = indexPath.row
            switch indexPath.section {
            case 0:
                gamesPlanned.remove(at: gameIndex)
            case 1:
                gamesPlaying.remove(at: gameIndex)
            case 2:
                gamesFinished.remove(at: gameIndex)
            case 3:
                gamesCompleted.remove(at: gameIndex)
            default:
                tableView.reloadData()
            }
            tableView.reloadData()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Category.allValues.count
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (action:UIContextualAction, sourceView:UIView, actionPerformed:(Bool) -> Void) in
            self.gameIndex = indexPath.row
            switch indexPath.section {
            case 0:
                self.gamesPlanned.remove(at: self.gameIndex)
            case 1:
                self.gamesPlaying.remove(at: self.gameIndex)
            case 2:
                self.gamesFinished.remove(at: self.gameIndex)
            case 3:
                self.gamesCompleted.remove(at: self.gameIndex)
            default:
                tableView.reloadData()
            }
            tableView.reloadData()
            
            actionPerformed(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return gamesPlanned.count
        case 1:
            return gamesPlaying.count
        case 2:
            return gamesFinished.count
        case 3:
            return gamesCompleted.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Plan To Play"
        case 1:
            return "Currently Playing"
        case 2:
            return "Finished Playing"
        case 3:
            return "Completed Playing"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        switch indexPath.section {
        case 0:
            gameData = gamesPlanned[indexPath.row]
        case 1:
            gameData = gamesPlaying[indexPath.row]
        case 2:
            gameData = gamesFinished[indexPath.row]
        case 3:
            gameData = gamesCompleted[indexPath.row]
        default:
            cell.textLabel?.text = "Something went wrong"
        }
        
        cell.textLabel?.text = gameData.title
        cell.detailTextLabel?.text = gameData.developer + " (" + dateFormatter.string(from: gameData.releaseDate) + ")"
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var valueSentFromAddViewController:Game?
    var valueSentFromEditViewController:Game?
    var gamesPlaying: [Game]! = []
    var gamesPlanned: [Game]! = []
    var gamesFinished: [Game]! = []
    var gamesCompleted: [Game]! = []
    var gameIndex: Int!
    var gameBeingEdited: Int!
    var gamePreviousCategory: Category!
    var gameData: Game!
    let dateFormatter = DateFormatter()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addSegue" {
            let view = segue.destination as! AddViewController
            view.delegate = self
        
        } else if segue.identifier == "editSegue" {
            let view = segue.destination as! EditViewController
            var currentGame = Game()
            view.delegate = self
            gameIndex = tableView.indexPathForSelectedRow?.row
            switch tableView.indexPathForSelectedRow?.section {
            case 0:
                currentGame = gamesPlanned[gameIndex]
            case 1:
                currentGame = gamesPlaying[gameIndex]
            case 2:
                currentGame = gamesFinished[gameIndex]
            case 3:
                currentGame = gamesCompleted[gameIndex]
            default:
                tableView.reloadData()
            }
            
            view.game.title = currentGame.title
            view.game.developer = currentGame.developer
            view.game.releaseDate = currentGame.releaseDate
            view.game.coverURL = currentGame.coverURL
            view.game.description = currentGame.description
            view.game.genre = currentGame.genre
            view.game.platform = currentGame.platform
            view.game.category = currentGame.category
        }
    }
    func addGame(_ game: Game, _ cover: UIImage?) {
        switch game.category {
            case Category.playing:
                gamesPlaying.append(game)
            case Category.finished:
                gamesFinished.append(game)
            case Category.completed:
                gamesCompleted.append(game)
            default:
                gamesPlanned.append(game)
            }
        saveImage(coverURL: game.coverURL, image: cover!)
        tableView.reloadData()
    }
    
    func editGame(_ game: Game, _ cover: UIImage?) {
        var currentGame = Game()
        gameBeingEdited = tableView.indexPathForSelectedRow?.row
        switch tableView.indexPathForSelectedRow?.section {
        case 0:
            currentGame = gamesPlanned[gameIndex]
            gamesPlanned.remove(at: gameIndex)
        case 1:
            currentGame = gamesPlaying[gameIndex]
            gamesPlaying.remove(at: gameIndex)
        case 2:
            currentGame = gamesFinished[gameIndex]
            gamesFinished.remove(at: gameIndex)
        case 3:
            currentGame = gamesCompleted[gameIndex]
            gamesCompleted.remove(at: gameIndex)
        default:
            tableView.reloadData()
        }
        currentGame.title = game.title
        currentGame.developer = game.developer
        currentGame.releaseDate = game.releaseDate
        currentGame.coverURL = game.coverURL
        currentGame.description = game.description
        currentGame.genre = game.genre
        currentGame.platform = game.platform
        currentGame.category = game.category
        
        switch game.category {
            case Category.playing:
                gamesPlaying.append(game)
            case Category.finished:
                gamesFinished.append(game)
            case Category.completed:
                gamesCompleted.append(game)
            default:
                gamesPlanned.append(game)
            }
        
        saveImage(coverURL: game.coverURL, image: cover!)
        tableView.reloadData()
    }
    
    // Save the game cover image to local directory
    func saveImage(coverURL: String, image: UIImage) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let fileName = coverURL
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 1) else { return }

        //Checks if file exists, removes it if so.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path)
            } catch let removeError {
                print("couldn't remove file at path", removeError)
            }

        }

        do {
            try data.write(to: fileURL)
        } catch let error {
            print("error saving file with error", error)
        }

    }
    
    @objc func saveToDatabase(_ notification:Notification) {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("GameBacklog.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }
        
        if sqlite3_exec(db, "DELETE FROM Games", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }
        
        for game in gamesPlanned {
            insertIntoDatabase(game)
        }
        
        for game in gamesPlaying {
            insertIntoDatabase(game)
        }
        
        for game in gamesFinished {
            insertIntoDatabase(game)
        }
        
        for game in gamesCompleted {
            insertIntoDatabase(game)
        }
        
        sqlite3_close(db)
    }
    
    func insertIntoDatabase(_ game: Game) {
        //the insert query
        let queryString = "INSERT INTO Games (title, developer, releaseDate, coverURL, description, genre, platform, category) VALUES (?,?,?,?,?,?,?,?)"
        
        //creating a statement
        var stmt: OpaquePointer?
        
        //preparing the query
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK{
           let errmsg = String(cString: sqlite3_errmsg(db)!)
           print("error preparing insert: \(errmsg)")
           return
        }
        
        //binding the parameters
        if sqlite3_bind_text(stmt, 1, (game.title as NSString).utf8String, -1, nil) != SQLITE_OK{
           let errmsg = String(cString: sqlite3_errmsg(db)!)
           print("failure binding title: \(errmsg)")
           return
        }

        if sqlite3_bind_text(stmt, 2, (game.developer as NSString).utf8String, -1, nil) != SQLITE_OK{
           let errmsg = String(cString: sqlite3_errmsg(db)!)
           print("failure binding developer: \(errmsg)")
           return
        }
        
        if sqlite3_bind_text(stmt, 3, (dateFormatter.string(from: game.releaseDate) as NSString).utf8String, -1, nil) != SQLITE_OK{
           let errmsg = String(cString: sqlite3_errmsg(db)!)
           print("failure binding releaseDate: \(errmsg)")
           return
        }
        
        if sqlite3_bind_text(stmt, 4, (game.coverURL as NSString).utf8String, -1, nil) != SQLITE_OK{
           let errmsg = String(cString: sqlite3_errmsg(db)!)
           print("failure binding coverURL: \(errmsg)")
           return
        }
        
        if sqlite3_bind_text(stmt, 5, (game.description as NSString).utf8String, -1, nil) != SQLITE_OK{
           let errmsg = String(cString: sqlite3_errmsg(db)!)
           print("failure binding description: \(errmsg)")
           return
        }
        
        if sqlite3_bind_text(stmt, 6, (game.genre as NSString).utf8String, -1, nil) != SQLITE_OK{
           let errmsg = String(cString: sqlite3_errmsg(db)!)
           print("failure binding genre: \(errmsg)")
           return
        }
        
        if sqlite3_bind_text(stmt, 7, (game.platform as NSString).utf8String, -1, nil) != SQLITE_OK{
           let errmsg = String(cString: sqlite3_errmsg(db)!)
           print("failure binding platform: \(errmsg)")
           return
        }
        
        if sqlite3_bind_text(stmt, 8, (game.category.rawValue as NSString).utf8String, -1, nil) != SQLITE_OK{
           let errmsg = String(cString: sqlite3_errmsg(db)!)
           print("failure binding category: \(errmsg)")
           return
        }

        //executing the query to insert values
        if sqlite3_step(stmt) != SQLITE_DONE {
           let errmsg = String(cString: sqlite3_errmsg(db)!)
           print("failure inserting game: \(errmsg)")
           return
        }
    }
    
    func readValues() {
        //first empty the list of games
        gamesPlanned.removeAll()
        gamesPlaying.removeAll()
        gamesFinished.removeAll()
        gamesCompleted.removeAll()

        //this is our select query
        let queryString = "SELECT * FROM Games"

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
            let title = String(cString: sqlite3_column_text(stmt, 1))
            let developer = String(cString: sqlite3_column_text(stmt, 2))
            let releaseDate = dateFormatter.date(from: String(cString: sqlite3_column_text(stmt, 3)))!
            let coverURL = String(cString: sqlite3_column_text(stmt, 4))
            let description = String(cString: sqlite3_column_text(stmt, 5))
            let genre = String(cString: sqlite3_column_text(stmt, 6))
            let platform = String(cString: sqlite3_column_text(stmt, 7))
            let category = Category.init(rawValue: String(cString: sqlite3_column_text(stmt, 8)))!

            //adding values to list
            let game = Game(title: title, developer: developer, releaseDate: releaseDate, coverURL: coverURL, description: description, genre: genre, platform: platform, category: category)
            
            switch category {
                case Category.playing:
                    gamesPlaying.append(game)
                case Category.finished:
                    gamesFinished.append(game)
                case Category.completed:
                    gamesCompleted.append(game)
                default:
                    gamesPlanned.append(game)
                }
        }
        tableView.reloadData()
   }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        dateFormatter.dateFormat = "yyyy"
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self,selector: #selector(saveToDatabase(_:)),name: UIApplication.willResignActiveNotification, object: nil)

        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("GameBacklog.sqlite")
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("error opening database")
        }
            
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS Games (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCGAR, developer VARCHAR, releaseDate VARCHAR, coverURL VARCHAR, description VARCHAR, genre VARCHAR, platform VARCHAR, category VARCHAR)", nil, nil, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("error creating table: \(errmsg)")
        }
    }


}


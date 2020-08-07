//
//  SearchViewController.swift
//  Game Backlog
//
//  Created by Mason Parry on 8/5/20.
//  Copyright © 2020 Mason Parry. All rights reserved.
//

import UIKit

struct SearchGame{
    var title: String = "New Game"
    var developer: String?
    var releaseDate: Date?
    var coverURL: String?
    var description: String?
    var genre: String?
    var platform: String?
    var category: Category = Category.planned
    var involvedCompanyIDs: [Int]?
    var coverID: Int?
    var genreIDs: [Int]?
    var platformIDs: [Int]?
}

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddGameProtocol{
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var games: [SearchGame]! = []
    var gameIndex: Int!
    var gameData: SearchGame!
    let dateFormatter = DateFormatter()
    let myGroup = DispatchGroup()
    let apikey = "45725bddf722eccd54489c37c83a8471"
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        gameData = games[indexPath.row]
        cell.textLabel?.text = gameData.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func addGame(_ game: Game, _ cover: UIImage?) {
        var imageDataDict = [String: Any]()
        imageDataDict["game"] = game
        imageDataDict["cover"] = cover
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "notificationName"), object: nil, userInfo: imageDataDict)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let view = segue.destination as! AddViewController
        var currentGame = SearchGame()
        view.delegate = self
        gameIndex = tableView.indexPathForSelectedRow?.row
        currentGame = games[gameIndex]
        view.game.title = currentGame.title
        view.game.developer = currentGame.developer ?? ""
        view.game.releaseDate = currentGame.releaseDate ?? Date()
        view.game.coverURL = currentGame.coverURL ?? ""
        view.game.description = currentGame.description ?? ""
        view.game.genre = currentGame.genre ?? ""
        view.game.platform = currentGame.platform ?? ""
        view.game.category = currentGame.category
    }
    
    func loadDefaultGames() {
        games.append(contentsOf: self.getDefaultGames())
        tableView.reloadData()
    }
    
    func getDefaultGames() -> [SearchGame]{
        var defaultGames = [SearchGame]()
        let url = URL(string: "https://api-v3.igdb.com/games")!
        var requestHeader = URLRequest.init(url: url)
        requestHeader.httpBody = "fields *; limit 25; sort popularity desc;".data(using: .utf8, allowLossyConversion: false)
        requestHeader.httpMethod = "POST"
        requestHeader.setValue(apikey, forHTTPHeaderField: "user-key")
        requestHeader.setValue("application/json", forHTTPHeaderField: "Accept")
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: requestHeader) { (data, response, error) in
            if let jsonObj = try? JSONSerialization.jsonObject(with: data!) as? [[ String : Any]]{
                var game = SearchGame()
                for obj in jsonObj {
                    if(obj.keys.contains("name")) {
                        game.title = (obj["name"] as! String)
                    }
                    if(obj.keys.contains("first_release_date")) {
                        let dateFormatterGet = DateFormatter()
                        dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss +HHmm"
                        let date = dateFormatterGet.string(from: Date(timeIntervalSince1970: (obj["first_release_date"] as! TimeInterval)))
                        game.releaseDate = self.dateFormatter.date(from: date)
                    }
                    if(obj.keys.contains("summary")) {
                        game.description = (obj["summary"] as! String)
                    }
                    if(obj.keys.contains("involved_companies")) {
                        game.involvedCompanyIDs = (obj["involved_companies"] as! [Int])
                    }
                    if(obj.keys.contains("cover")) {
                        game.coverID = (obj["cover"] as! Int)
                    }
                    if(obj.keys.contains("genres")) {
                        game.genreIDs = (obj["genres"] as! [Int])
                    }
                    if(obj.keys.contains("platforms")) {
                        game.platformIDs = (obj["platforms"] as! [Int])
                    }
                    defaultGames.append(game)
                }
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        return defaultGames
    }
    
    func getDeveloperIdsFrom(involvedCompaniesIds: [Int]) -> [Int] {
        var developerIds = [Int]()
        let companyIds = involvedCompaniesIds.map(String.init).joined(separator: ",")
        var requestHeader = URLRequest.init(url: URL(string: "https://api-v3.igdb.com/involved_companies")!)
        requestHeader.httpBody = "fields company,developer; where id = (\(companyIds));".data(using: .utf8, allowLossyConversion: false)
        requestHeader.httpMethod = "POST"
        requestHeader.setValue(apikey, forHTTPHeaderField: "user-key")
        requestHeader.setValue("application/json", forHTTPHeaderField: "Accept")
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: requestHeader) { (data, response, error) in
            if let jsonObj = try? JSONSerialization.jsonObject(with: data!) as? [[ String : Any]]{
                for obj in jsonObj {
                    if(obj["developer"] as? Bool == true) {
                        developerIds.append((obj["company"] as! Int))
                    }
                }
                semaphore.signal()
            }
        }
        task.resume()
        semaphore.wait()
        return developerIds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        loadDefaultGames()
        self.hideKeyboardWhenTappedAround() 
    }

}

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

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, AddGameProtocol{
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    var games: [SearchGame]! = []
    var gameIndex: Int!
    var gameData: SearchGame!
    let dateFormatter = DateFormatter()
    let myGroup = DispatchGroup()
    let apikey = IGDBAPIKEY
    
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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let search = searchBar.text!
        games.removeAll()
        games.append(contentsOf: self.getGamesWith(query: "fields *; search \"\(search)\"; limit 50;"))
        tableView.reloadData()
    }
    
    func addGame(_ game: Game, _ cover: UIImage?) {
        var imageDataDict = [String: Any]()
        imageDataDict["game"] = game
        imageDataDict["cover"] = cover
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "notificationName"), object: nil, userInfo: imageDataDict)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let view = segue.destination as! AddViewController
        var selectedGame = SearchGame()
        view.delegate = self
        gameIndex = tableView.indexPathForSelectedRow?.row
        selectedGame = games[gameIndex]
        
        //Get the rest of the game information from other APIs
        let currentGame = fillInDetailsFor(game: selectedGame)
        view.game.title = currentGame.title
        view.game.developer = currentGame.developer
        view.game.releaseDate = currentGame.releaseDate
        view.game.coverURL = currentGame.coverURL
        view.game.description = currentGame.description
        view.game.genre = currentGame.genre
        view.game.platform = currentGame.platform
        view.game.category = currentGame.category
    }
    
    func getGamesWith(query: String) -> [SearchGame]{
        var games = [SearchGame]()
        let url = URL(string: "https://api-v3.igdb.com/games")!
        var requestHeader = URLRequest.init(url: url)
        requestHeader.httpBody = query.data(using: .utf8, allowLossyConversion: false)
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
                        let dateUNIX = self.dateFormatter.string(from: Date(timeIntervalSince1970: obj["first_release_date"] as! TimeInterval))
                        game.releaseDate = self.dateFormatter.date(from: dateUNIX)
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
                    games.append(game)
                }
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        return games
    }
    
    func fillInDetailsFor(game: SearchGame) -> Game{
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        var newGame = Game(title: game.title, releaseDate: game.releaseDate, description: game.description)
        DispatchQueue.global().async {
            if(game.involvedCompanyIDs != nil) {
                let developerIDs = self.getDeveloperIdsFrom(involvedCompaniesIds: game.involvedCompanyIDs!)
                if(developerIDs.isEmpty == false){
                    newGame.developer = self.getDeveloperNameFrom(developerIDs: developerIDs)
                }
            }
            if(game.coverID != nil) {
                newGame.coverURL = self.getCoverURLFrom(coverID: game.coverID!)
            }
            if(game.genreIDs?.isEmpty == false) {
                newGame.genre = self.getGenreFrom(genreIDs: game.genreIDs!)
            }
            if(game.platformIDs?.isEmpty == false) {
                newGame.platform = self.getPlatformFrom(platformIDs: game.platformIDs!)
            }
            semaphore.signal()
        }
        semaphore.wait()
        return newGame
    }
    
    func getDeveloperIdsFrom(involvedCompaniesIds: [Int]) -> [Int] {
        var developerIds = [Int]()
        let companyIDs = involvedCompaniesIds.map(String.init).joined(separator: ",")
        var requestHeader = URLRequest.init(url: URL(string: "https://api-v3.igdb.com/involved_companies")!)
        requestHeader.httpBody = "fields company,developer; where id = (\(companyIDs));".data(using: .utf8, allowLossyConversion: false)
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
    
    func getDeveloperNameFrom(developerIDs: [Int]) -> String {
        var developerName = String()
        let companyIDs = developerIDs.map(String.init).joined(separator: ",")
        var requestHeader = URLRequest.init(url: URL(string: "https://api-v3.igdb.com/companies")!)
        requestHeader.httpBody = "fields name; where id = (\(companyIDs));".data(using: .utf8, allowLossyConversion: false)
        requestHeader.httpMethod = "POST"
        requestHeader.setValue(apikey, forHTTPHeaderField: "user-key")
        requestHeader.setValue("application/json", forHTTPHeaderField: "Accept")
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: requestHeader) { (data, response, error) in
            if let jsonObj = try? JSONSerialization.jsonObject(with: data!) as? [[ String : Any]]{
                for obj in jsonObj {
                    if(obj.keys.contains("name")) {
                        if(developerName.isEmpty) {
                            developerName = obj["name"] as! String
                        } else {
                            developerName.append(", \(obj["name"] as! String)")
                        }
                        
                    }
                }
                semaphore.signal()
            }
        }
        task.resume()
        semaphore.wait()
        return developerName
    }
    
    func getCoverURLFrom(coverID: Int) -> String {
        var coverURL = String("https:")
        var requestHeader = URLRequest.init(url: URL(string: "https://api-v3.igdb.com/covers")!)
        requestHeader.httpBody = "fields url; where id = (\(coverID));".data(using: .utf8, allowLossyConversion: false)
        requestHeader.httpMethod = "POST"
        requestHeader.setValue(apikey, forHTTPHeaderField: "user-key")
        requestHeader.setValue("application/json", forHTTPHeaderField: "Accept")
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: requestHeader) { (data, response, error) in
            if let jsonObj = try? JSONSerialization.jsonObject(with: data!) as? [[ String : Any]]{
                if(jsonObj[0].keys.contains("url")) {
                    coverURL.append(jsonObj[0]["url"] as! String)
                    coverURL = coverURL.replacingOccurrences(of: #"t_thumb"#, with: "t_cover_big", options: .regularExpression)
                }
                
                semaphore.signal()
            }
        }
        task.resume()
        semaphore.wait()
        return coverURL
    }
    
    func getGenreFrom(genreIDs: [Int]) -> String {
        var genre = String()
        let genres = genreIDs.map(String.init).joined(separator: ",")
        var requestHeader = URLRequest.init(url: URL(string: "https://api-v3.igdb.com/genres")!)
        requestHeader.httpBody = "fields name; where id = (\(genres));".data(using: .utf8, allowLossyConversion: false)
        requestHeader.httpMethod = "POST"
        requestHeader.setValue(apikey, forHTTPHeaderField: "user-key")
        requestHeader.setValue("application/json", forHTTPHeaderField: "Accept")
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: requestHeader) { (data, response, error) in
            if let jsonObj = try? JSONSerialization.jsonObject(with: data!) as? [[ String : Any]]{
                for obj in jsonObj {
                    if(obj.keys.contains("name")) {
                        if(genre.isEmpty) {
                            genre = obj["name"] as! String
                        } else {
                            genre.append(", \(obj["name"] as! String)")
                        }
                        
                    }
                }
                semaphore.signal()
            }
        }
        task.resume()
        semaphore.wait()
        return genre
    }
    
    func getPlatformFrom(platformIDs: [Int]) -> String {
        var platform = String()
        let platforms = platformIDs.map(String.init).joined(separator: ",")
        var requestHeader = URLRequest.init(url: URL(string: "https://api-v3.igdb.com/platforms")!)
        requestHeader.httpBody = "fields name; where id = (\(platforms));".data(using: .utf8, allowLossyConversion: false)
        requestHeader.httpMethod = "POST"
        requestHeader.setValue(apikey, forHTTPHeaderField: "user-key")
        requestHeader.setValue("application/json", forHTTPHeaderField: "Accept")
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: requestHeader) { (data, response, error) in
            if let jsonObj = try? JSONSerialization.jsonObject(with: data!) as? [[ String : Any]]{
                for obj in jsonObj {
                    if(obj.keys.contains("name")) {
                        if(platform.isEmpty) {
                            platform = obj["name"] as! String
                        } else {
                            platform.append(", \(obj["name"] as! String)")
                        }
                        
                    }
                }
                semaphore.signal()
            }
        }
        task.resume()
        semaphore.wait()
        return platform
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dateFormatter.dateFormat = "yyyy"
        
        self.hideKeyboardWhenTappedAround()
        tableView.keyboardDismissMode = .onDrag
        games.append(contentsOf: self.getGamesWith(query: "fields *; limit 25; sort popularity desc;"))
        tableView.reloadData()
    }

}

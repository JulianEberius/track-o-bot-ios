//
//  TrackOBot.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 07.09.15.
//  Copyright (c) 2015 Julian Eberius. All rights reserved.
//

import Foundation

class DateFormattingModel {

    static var inputDateFormatter:NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ"
        return formatter
    }
    
    static var outputDateFormatter:NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.MediumStyle
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.doesRelativeDateFormatting = true
        return formatter
    }

}

class HistoryPage {
    let games: [Game]!
    let totalCount: Int!
    let totalPages: Int!
    let page: Int!

    init(games: [Game], dict:NSDictionary) { // "meta" dict from the TrackOBot API
        self.page = dict["current_page"] as? Int
        self.totalCount = dict["total_items"] as? Int
        self.totalPages = dict["total_pages"] as? Int
        self.games = games
    }
}

enum GameMode : String {
    case Ranked = "ranked"
    case Casual = "casual"
    case Practice = "practice"
    case Arena = "arena"
    case Friendly = "friendly"
}

class Game : DateFormattingModel {

    let id: Int!
    let hero: String!
    let opponentsHero: String!
    let deckId: Int!
    let opponentsDeckId: Int!
    let won: Bool!
    let coin: Bool!
    let timeLabel: String!
    let mode: GameMode!
    let rank: Int?
    let legend: Int?

    init(id: Int?, hero: String?, opponentsHero: String?, deckId: Int?, opponentsDeckId: Int?, won:Bool?, coin:Bool?, added:NSDate? = nil, mode:GameMode = GameMode.Ranked, rank:Int? = nil, legend:Int? = nil) {
        self.id = id
        self.hero = hero
        self.opponentsHero = opponentsHero
        self.deckId = deckId
        self.opponentsDeckId = opponentsDeckId
        self.won = won
        self.coin = coin
        self.mode = mode
        self.rank = rank
        self.legend = legend
        if let d = added {
            self.timeLabel = Game.outputDateFormatter.stringFromDate(d)
        } else {
            self.timeLabel = nil
        }
    }

    /**
    - parameters:
        - dict: as returned by parsing the Track-O-Bot API response using NSJSONSerialization
    */
    convenience init(dict:NSDictionary) {
        let id = dict["id"] as? Int
        let hero = dict["hero"] as? String
        let opponentsHero = dict["opponent"] as? String
        let deckId = dict["hero_deck"] as? Int
        let opponentsDeckId = dict["opponent_deck"] as? Int
        let won = (dict["result"] as? String) == "win" ? true : false
        let coin = dict["coin"] as? Bool

        var added: NSDate? = nil
        if let ds = dict["added"] as? String {
            added = Game.inputDateFormatter.dateFromString(ds)
        }
        self.init(id: id, hero: hero, opponentsHero: opponentsHero, deckId: deckId, opponentsDeckId: opponentsDeckId, won: won, coin: coin, added: added)
    }
}

class Deck : DateFormattingModel {

    let id: Int!
    let hero: String!
    let name: String!

    init(id: Int?, hero: String?, name: String?) {
        self.id = id
        self.hero = hero
        self.name = name
    }

    /**
     - parameters:
     - dict: as returned by parsing the Track-O-Bot API response using NSJSONSerialization
     */
    convenience init(dict:NSDictionary) {
        let id = dict["id"] as? Int
        let name = dict["name"] as? String
        let hero = dict["hero"] as? String
        self.init(id: id, hero: hero, name: name)
    }
}

class User : NSObject, NSCoding {
    let username: String!
    let password: String!
    let domain: String!

    init(username: String, password: String, domain: String = "https://trackobot.com") {
        self.username = username
        self.password = password
        self.domain = domain
    }

    /**
     - parameters:
     - dict: as returned by parsing the Track-O-Bot API response using NSJSONSerialization
     */
    convenience init(dict:NSDictionary) {
        let username = dict["username"] as! String
        let password = dict["password"] as! String
        self.init(username: username, password: password, domain: TrackOBot.DOMAIN)
    }

    required init(coder decoder: NSCoder) {
        //Error here "missing argument for parameter name in call
        self.username = decoder.decodeObjectForKey("username") as! String
        self.password = decoder.decodeObjectForKey("password") as! String
        self.domain = decoder.decodeObjectForKey("domain") as! String
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.username, forKey: "username")
        coder.encodeObject(self.password, forKey: "password")
        coder.encodeObject(self.domain, forKey: "domain")
    }

}

class Stats {
    let wins: Int!
    let losses: Int!
    
    init(wins: Int?, losses: Int?) {
        self.wins = wins
        self.losses = losses
    }
}

class ByClassStats : Stats {
    let hero: String!
    
    init(hero: String?, wins: Int?, losses: Int?) {
        self.hero = hero
        super.init(wins: wins, losses: losses)
    }
}

class ByDeckStats : Stats {
    let deck: String!
    let deckId: Int?
    let heroId: Int?
    
    init(deckName: String?, deckId: Int?, heroId: Int?, wins: Int?, losses: Int?) {
        self.deck = deckName
        self.deckId = deckId
        self.heroId = heroId
        super.init(wins: wins, losses: losses)
    }
}


enum Result<T: Any, U: ErrorType> {
    case Success(T)
    case Failure(U)
}

enum TrackOBotAPIError : ErrorType {
    case CredentialsMissing
    case JsonFormattingFailed
    case JsonParsingFailed
    case NetworkError(error:NSError)
    case LoginFaild(error:String)
    case RequestFaild(error:String)
}

let HEROES = ["Warrior", "Shaman", "Rogue", "Paladin", "Hunter", "Druid", "Warlock", "Mage", "Priest"]
let HEROES_BY_TRACKOBOT_ID = [
    1: "Priest",
    2: "Rogue",
    3: "Mage",
    4: "Paladin",
    5: "Warrior",
    6: "Warlock",
    7: "Hunter",
    8: "Shaman",
    9: "Druid"
]
let RANK_UNKNOWN = 0 // as defined in the original TrackOBot
let LEGEND_UNKNOWN = 0 // as defined in the original TrackOBot

class TrackOBot : NSObject, NSURLSessionDelegate {
    static let instance = TrackOBot()
    static let DOMAIN = "trackobot.com"
    //static let DOMAIN = "localhost:3001"

    let USER = "user"
    let USERNAME = "username"
    let TOKEN = "token"

    let defaults = NSUserDefaults.standardUserDefaults()
    
    let createUserUrl = "https://\(DOMAIN)/users"
    let resultsUrl = "https://\(DOMAIN)/profile/results.json"
    let resultDeleteUrl = "https://\(DOMAIN)/profile/results/bulk_delete"
    let profileUrl = "https://\(DOMAIN)/profile.json"
    let decksUrl = "https://\(DOMAIN)/profile/settings/decks.json"
    let oneTimeAuthTokenUrl = "https://\(DOMAIN)/one_time_auth.json"
    
    let byClassResultsUrl = "https://\(DOMAIN)/profile/stats/classes.json"
    let byDeckResultsUrl = "https://\(DOMAIN)/profile/stats/decks.json"

    
    func storeUser(user:User) -> Void {
        let userData = NSKeyedArchiver.archivedDataWithRootObject(user)
        defaults.setObject(userData, forKey: USER)
    }

    func loadUser() -> User? {
        guard let data = defaults.dataForKey(USER) else {
            return nil
        }

        guard let user = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? User else {
            return nil
        }
        return user
    }


    func postResult(game:Game, onComplete: (Result<NSDictionary, TrackOBotAPIError>) -> Void) -> Void {
        var gameData = ["hero": game.hero, "opponent": game.opponentsHero,
                        "win": game.won, "coin": game.coin,
                        "mode": game.mode.rawValue] as [String: AnyObject]
        if let deck = game.deckId {
            gameData["deck_id"] = deck
        }
        if let opponentsDeck = game.opponentsDeckId {
            gameData["opponent_deck_id"] = opponentsDeck
        }
        if let rnk = game.rank {
            gameData["rank"] = rnk
        }
        if let legend = game.legend {
            gameData["legend"] = legend
        }
        
        let data = ["result": gameData]
        guard let json = try? NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions.init(rawValue: 0)) else {
            onComplete(Result.Failure(TrackOBotAPIError.JsonFormattingFailed))
            return
        }
        print("Sending: \(NSString(data: json, encoding: NSUTF8StringEncoding))")
        postRequest(resultsUrl, data: json, onComplete: onComplete)
    }
    
    func getResults(page: Int, onComplete: (Result<HistoryPage, TrackOBotAPIError>) -> Void) -> Void {
        let url = profileUrl + "?page=\(page)" // 1-based indices in API
        getRequest(url, onComplete: {
            (result) -> Void in
            switch result {
            case .Success(let dict):
                guard let history = dict["history"] as? [NSDictionary] else {
                    onComplete(Result.Failure(TrackOBotAPIError.JsonParsingFailed))
                    return
                }
                let games = history.map { d in Game(dict:d) }

                guard let meta = dict["meta"] as? NSDictionary else {
                    onComplete(Result.Failure(TrackOBotAPIError.JsonParsingFailed))
                    return
                }
                let historyPage = HistoryPage(games: games, dict: meta)
                
                onComplete(Result.Success(historyPage))
                break
            case .Failure(let err):
                onComplete(Result.Failure(err))
                break
            }
        })
    }

    func deleteResult(id: Int, onComplete: (Result<Bool, TrackOBotAPIError>) -> Void) -> Void {
        let url = "\(resultDeleteUrl)?result_ids[]=\(id)"
        deleteRequest(url, onComplete: onComplete)
    }

    func getDecks(onComplete: (Result<[[Deck]], TrackOBotAPIError>) -> Void) -> Void {
        getRequest(decksUrl, onComplete: {
        (result) -> Void in
            switch result {
            case .Success(let dict):
                guard let decksDicts = dict["decks"] as? [NSDictionary] else {
                    onComplete(Result.Failure(TrackOBotAPIError.JsonParsingFailed))
                    return
                }
                let decks  = HEROES.map {
                    (hero) in
                    decksDicts.filter { (d) in
                        d["hero"] as? String == hero
                    }.map { (d) in
                        Deck(id: d["id"] as? Int, hero: d["hero"] as? String, name: d["name"] as? String)
                    }
                }

                onComplete(Result.Success(decks))
                break
            case .Failure(let err):
                onComplete(Result.Failure(err))
                break
            }
        })
    }
    
    func getByClassStats(onComplete: (Result<[ByClassStats], TrackOBotAPIError>) -> Void) -> Void {
        getRequest(byClassResultsUrl, onComplete: {
            (result) -> Void in
            switch result {
            case .Success(let dict):
                guard let stats = dict["stats"]?["as_class"] as? NSDictionary else {
                    onComplete(Result.Failure(TrackOBotAPIError.JsonParsingFailed))
                    return
                }
                let byClassStats = HEROES.map { (hero) -> ByClassStats in
                    let heroStats = stats[hero] as! NSDictionary
                    return ByClassStats(hero: hero, wins: heroStats["wins"] as? Int, losses: heroStats["losses"] as? Int)
                }
                
                onComplete(Result.Success(byClassStats))
                break
            case .Failure(let err):
                onComplete(Result.Failure(err))
                break
            }
        })
    }
    
    func getVsClassStats(asClass: String, onComplete: (Result<[ByClassStats], TrackOBotAPIError>) -> Void) -> Void {
        getRequest("\(byClassResultsUrl)?as_hero=\(asClass.lowercaseString)", onComplete: {
            (result) -> Void in
            switch result {
            case .Success(let dict):
                guard let stats = dict["stats"]?["vs_class"] as? NSDictionary else {
                    onComplete(Result.Failure(TrackOBotAPIError.JsonParsingFailed))
                    return
                }
                let byClassStats = HEROES.map { (hero) -> ByClassStats in
                    let heroStats = stats[hero] as! NSDictionary
                    return ByClassStats(hero: hero, wins: heroStats["wins"] as? Int, losses: heroStats["losses"] as? Int)
                }
                
                onComplete(Result.Success(byClassStats))
                break
            case .Failure(let err):
                onComplete(Result.Failure(err))
                break
            }
        })
    }

    // TODO: abstract deck vs class stat functions (are basically copy-pasta now)
    func getByDeckStats(onComplete: (Result<[ByDeckStats], TrackOBotAPIError>) -> Void) -> Void {
        getRequest(byDeckResultsUrl, onComplete: {
            (result) -> Void in
            switch result {
            case .Success(let dict):
                guard let stats = dict["stats"]?["as_deck"] as? [String: NSDictionary] else {
                    onComplete(Result.Failure(TrackOBotAPIError.JsonParsingFailed))
                    return
                }
                let byDeckStats = stats.map { (d: String, deckStats: NSDictionary) in ByDeckStats(
                    deckName: d, deckId: deckStats["deck_id"] as? Int, heroId: deckStats["hero_id"] as? Int,
                    wins: deckStats["wins"] as? Int, losses: deckStats["losses"] as? Int) }

                onComplete(Result.Success(byDeckStats))
                break
            case .Failure(let err):
                onComplete(Result.Failure(err))
                break
            }
        })
    }

    func getVsDeckStats(asDeck: Int?, onComplete: (Result<[ByDeckStats], TrackOBotAPIError>) -> Void) -> Void {
        getRequest("\(byDeckResultsUrl)?as_deck=\(asDeck)", onComplete: {
            (result) -> Void in
            switch result {
            case .Success(let dict):
                guard let stats = dict["stats"]?["vs_deck"] as? [String: NSDictionary]  else {
                    onComplete(Result.Failure(TrackOBotAPIError.JsonParsingFailed))
                    return
                }
                let byDeckStats = stats.map { (d: String, deckStats: NSDictionary) in ByDeckStats(
                        deckName: d, deckId: deckStats["deck_id"] as? Int, heroId: deckStats["hero_id"] as? Int,
                        wins: deckStats["wins"] as? Int, losses: deckStats["losses"] as? Int)
                }

                onComplete(Result.Success(byDeckStats))
                break
            case .Failure(let err):
                onComplete(Result.Failure(err))
                break
            }
        })
    }


    func getOneTimeAuthToken(onComplete: (Result<NSDictionary, TrackOBotAPIError>) -> Void) -> Void {
        postRequest(oneTimeAuthTokenUrl, data: nil, onComplete: onComplete)
    }


    func createUser(onComplete: (Result<User, TrackOBotAPIError>) -> Void) -> Void {
        
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let urlRequest = NSMutableURLRequest(URL: NSURL(string: createUserUrl)!)
        urlRequest.HTTPMethod = "POST"

        let session = NSURLSession(configuration: config,
            delegate: nil, delegateQueue: NSOperationQueue.mainQueue())
        
        let task = session.dataTaskWithRequest(urlRequest){
            (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            let result = self.checkErrors(data, error: error)
            switch result {
            case .Success(let dict):
                guard let username = dict["username"] as? String, password = dict["password"] as? String else {
                    onComplete(Result.Failure(TrackOBotAPIError.RequestFaild(error: "Unexpected response to create user call: \(result)")))
                    return
                }
                let user = User(username: username, password: password, domain: TrackOBot.DOMAIN)
                onComplete(Result.Success(user))

                break
            case .Failure(let err):
                onComplete(Result.Failure(err))
                break
            }
        }
        
        task.resume()
    }

    private func checkErrors(data: NSData?, error: NSError?) -> Result<NSDictionary, TrackOBotAPIError> {
        guard error == nil else {
            return Result.Failure(TrackOBotAPIError.NetworkError(error: error!))
        }
        
        guard let result = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.init(rawValue: 0)) else {
            return Result.Failure(TrackOBotAPIError.JsonParsingFailed)
        }
        
        guard let dict = result as? NSDictionary else {
            return Result.Failure(TrackOBotAPIError.JsonParsingFailed)
        }
        
        if let apiError = dict["error"] as? String {
            if apiError == "You need to sign in or sign up before continuing." {
                return Result.Failure(TrackOBotAPIError.LoginFaild(error: apiError))
            }
            else {
                return Result.Failure(TrackOBotAPIError.RequestFaild(error: apiError))
            }
        }
        return Result.Success(dict)
    }
    
    private func postRequest(url: String, data: NSData?, onComplete: (Result<NSDictionary, TrackOBotAPIError>) -> Void) -> Void {
        guard let user = self.loadUser() else {
            onComplete(Result.Failure(TrackOBotAPIError.CredentialsMissing))
            return
        }

        guard let (session, urlRequest) = self.configureAuthenticatedSessionAndRequest(user, urlString: url) else {
            print("error creating request")
            return
        }

        urlRequest.HTTPMethod = "POST"
        if let d = data {
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.HTTPBody = d
        }

        let task = session.dataTaskWithRequest(urlRequest){
            (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in

            let result = self.checkErrors(data, error: error)
            switch result {
            case .Success(let dict):
                onComplete(Result.Success(dict))
                break
            case .Failure(let err):
                onComplete(Result.Failure(err))
                break
            }
        }
        task.resume()
    }
    
    private func getRequest(url: String, onComplete: (Result<NSDictionary, TrackOBotAPIError>) -> Void) -> Void {
        guard let user = self.loadUser() else {
            onComplete(Result.Failure(TrackOBotAPIError.CredentialsMissing))
            return
        }
        guard let (session, urlRequest) = self.configureAuthenticatedSessionAndRequest(user, urlString: url) else {
            print("error creating request")
            return
        }
        
        let task = session.dataTaskWithRequest(urlRequest){
            (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            let result = self.checkErrors(data, error: error)
            switch result {
            case .Success(let dict):
                onComplete(Result.Success(dict))
                break
            case .Failure(let err):
                onComplete(Result.Failure(err))
                break
            }
        }
        task.resume()

    }
    
    private func deleteRequest(url: String, onComplete: (Result<Bool, TrackOBotAPIError>) -> Void) -> Void {
        guard let user = self.loadUser() else {
            onComplete(Result.Failure(TrackOBotAPIError.CredentialsMissing))
            return
        }
        // set delegate to prevent following redirects
        guard let (session, urlRequest) = self.configureAuthenticatedSessionAndRequest(user, urlString: url, delegate: self) else {
                print("error creating request")
                return
        }
        
        urlRequest.HTTPMethod = "DELETE"
        
        let task = session.dataTaskWithRequest(urlRequest){
            (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            
            guard error == nil else {
                onComplete(Result.Failure(TrackOBotAPIError.NetworkError(error: error!)))
                return
            }
            
            onComplete(Result.Success(true))
        }
        task.resume()
    }
    
    private func configureAuthenticatedSessionAndRequest(user:User, urlString:String, delegate: NSURLSessionDelegate? = nil) -> (NSURLSession, NSMutableURLRequest)? {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let userPasswordString = "\(user.username):\(user.password)"
        let userPasswordData = userPasswordString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64EncodedCredential = userPasswordData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        let authString = "Basic \(base64EncodedCredential)"
        config.HTTPAdditionalHeaders = ["Authorization" : authString]

        let urlComponents = NSURLComponents.init(string: urlString)
        guard let url = urlComponents?.URL else {
            print("could not parse URL: \(urlString)")
            return nil
        }
        let urlRequest = NSMutableURLRequest(URL: url)
        urlRequest.HTTPMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        let session = NSURLSession(configuration: config,
            delegate: delegate, delegateQueue: NSOperationQueue.mainQueue())

        return (session, urlRequest)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest!) -> Void) {
        completionHandler(nil)
    }

    func readTrackOBotAccountDataFile(url:NSURL) -> User? {
        guard let path = url.path else {
            return nil
        }
        guard let data = NSFileManager.defaultManager().contentsAtPath(path) else {
            return nil
        }

        var pos = 0
        let username:String, password:String, domain:String
        do {
            (username, pos) = try TrackOBot.instance.readString(data, pos: pos)
            (password, pos) = try TrackOBot.instance.readString(data, pos: pos)
            (domain, pos) = try TrackOBot.instance.readString(data, pos: pos)
            return User(username: username, password: password, domain: domain)
        } catch TrackOBotError.DecodeError {
            return nil
        } catch {
            return nil
        }
    }
    
    func writeTrackOBotAccountDataFile(user:User) -> NSData {
        let md = NSMutableData()
        writeString(user.username, data: md)
        writeString(user.password, data: md)
        writeString("https://trackobot.com", data: md)
        return md
    }

    enum TrackOBotError : ErrorType {
        case DecodeError
    }

    /* reads a Swift String from a NSData object that was written by a QDataStream*/
    private func readString(data: NSData, pos: Int) throws -> (String, Int) {
        // read length of String (32bit)
        var i = [UInt32](count: 1, repeatedValue:0)
        if (pos + 4 > data.length) {
            throw TrackOBotError.DecodeError
        }

        data.getBytes(&i, range: NSRange(location: pos, length: 4))
        let len = Int(i[0].bigEndian) // in byte

        // fill string buffer, each character is 16 bit
        var strBuf = [UInt16](count: len / 2, repeatedValue:0)
        if (pos + 4 + len > data.length) {
            throw TrackOBotError.DecodeError
        }

        data.getBytes(&strBuf, range: NSRange(location: pos + 4, length: len))

        // update position
        let newPos = pos + 4 + len
        // convert to String
        let str = NSString(bytes: &strBuf, length: (len / 2)*sizeof(UInt16), encoding: NSUTF16BigEndianStringEncoding) as! String
        return (str, newPos)
    }
    
    
    
    private func writeString(str: String, data: NSMutableData) {
        let numBytes = str.utf16.count * 2
        let lenBytes = [UInt32(bigEndian: UInt32(numBytes))]
        data.appendData(NSData(bytes: lenBytes, length: 4))
        
        let strBytes = str.utf16.map { s in UInt16(bigEndian: s) }
        data.appendData(NSData(bytes: strBytes, length: numBytes))
        
    }
}

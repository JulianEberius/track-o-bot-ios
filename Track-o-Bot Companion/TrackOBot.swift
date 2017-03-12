//
//  TrackOBot.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 07.09.15.
//  Copyright (c) 2015 Julian Eberius.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//

import Foundation

class DateFormattingModel {

    static var inputDateFormatter:DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZ"
        return formatter
    }

    static var outputDateFormatter:DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = DateFormatter.Style.medium
        formatter.dateStyle = DateFormatter.Style.medium
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

class Game : DateFormattingModel, Equatable {

    let id: Int?
    let hero: String
    let opponentsHero: String
    let deck: String?
    let deckId: Int?
    let opponentsDeck: String?
    let opponentsDeckId: Int?
    let won: Bool
    let coin: Bool?
    let timeLabel: String?
    let mode: GameMode
    let rank: Int?
    let legend: Int?

    var deckName: String {
        get {
            return deck ?? "Other \(hero)"
        }
    }
    var opponentsDeckName: String {
        get {
            return opponentsDeck ?? "Other \(opponentsHero)"
        }
    }

    init(id: Int?, hero: String, opponentsHero: String, deck: String?, deckId:Int?, opponentsDeck: String?, opponentsDeckId: Int?, won:Bool, coin:Bool?, added:Date? = nil, mode:GameMode = GameMode.Ranked, rank:Int? = nil, legend:Int? = nil) {
        self.id = id
        self.hero = hero
        self.opponentsHero = opponentsHero.capitalized
        self.deck = deck
        self.opponentsDeck = opponentsDeck?.capitalized
        self.deckId = deckId
        self.opponentsDeckId = opponentsDeckId
        self.won = won
        self.coin = coin
        self.mode = mode
        self.rank = rank
        self.legend = legend
        if let d = added {
            self.timeLabel = Game.outputDateFormatter.string(from: d)
        } else {
            self.timeLabel = nil
        }
    }

    /**
    - parameters:
        - dict: as returned by parsing the Track-O-Bot API response using NSJSONSerialization
    */
    convenience init?(dict:NSDictionary) {
        guard let id = dict["id"] as? Int,
            let hero = dict["hero"] as? String,
            let opponentsHero = dict["opponent"] as? String
            else {
                return nil
        }
        let won = (dict["result"] as? String) == "win" ? true : false
        let deck = dict["hero_deck"] as? String
        let opponentsDeck = dict["opponent_deck"] as? String
        let coin = dict["coin"] as? Bool
        var added: Date? = nil
        if let ds = dict["added"] as? String {
            added = Game.inputDateFormatter.date(from: ds)
        }

        self.init(id: id, hero: hero, opponentsHero: opponentsHero, deck: deck, deckId: nil,
                  opponentsDeck: opponentsDeck, opponentsDeckId: nil, won: won, coin: coin, added: added)
    }
}

func ==(lhs:Game, rhs:Game) -> Bool {
    return lhs.hero == rhs.hero &&
            lhs.opponentsHero == rhs.opponentsHero &&
            lhs.deckId == rhs.deckId &&
            lhs.opponentsDeckId == rhs.opponentsDeckId &&
            lhs.coin == rhs.coin &&
            lhs.won == rhs.won &&
            lhs.mode == rhs.mode &&
            lhs.rank == rhs.rank &&
            lhs.legend == rhs.legend
}

class Deck : DateFormattingModel {

    let id: Int
    let hero: String
    let name: String
    let fullName: String

    init(id: Int, hero: String, name: String) {
        self.id = id
        self.hero = hero.capitalized
        self.name = name
        self.fullName = "\(self.name) \(self.hero)"
    }

    /**
     - parameters:
     - dict: as returned by parsing the Track-O-Bot API response using NSJSONSerialization
     */
    convenience init?(dict:NSDictionary) {
        guard let id = dict["id"] as? Int,
            let name = dict["name"] as? String,
            let hero = dict["hero"] as? String else {
                return nil
        }
        self.init(id: id, hero: hero, name: name)
    }
}

class User : NSObject, NSCoding {
    let username: String
    let password: String
    let domain: String

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
        self.username = decoder.decodeObject(forKey: "username") as! String
        self.password = decoder.decodeObject(forKey: "password") as! String
        self.domain = decoder.decodeObject(forKey: "domain") as! String
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.username, forKey: "username")
        coder.encode(self.password, forKey: "password")
        coder.encode(self.domain, forKey: "domain")
    }

}

class Stats {
    let wins: Int
    let losses: Int

    init(wins: Int, losses: Int) {
        self.wins = wins
        self.losses = losses
    }
}

class ByClassStats : Stats {
    let hero: String

    init(hero: String, wins: Int, losses: Int) {
        self.hero = hero.capitalized
        super.init(wins: wins, losses: losses)
    }
}

class ByDeckStats : Stats {
    let deck: String
    let deckId: Int?
    let hero: String

    init(deckName: String, deckId: Int?, hero: String, wins: Int, losses: Int) {
        self.deck = deckName
        self.deckId = deckId
        self.hero = hero.capitalized
        super.init(wins: wins, losses: losses)
    }
}


enum Result<T: Any, U: Error> {
    case success(T)
    case failure(U)
}

enum TrackOBotAPIError : Error {
    case credentialsMissing
    case jsonFormattingFailed
    case jsonParsingFailed
    case networkError(error:Error)
    case loginFailed(error:String)
    case requestFailed(error:String)
    case malformedUrl
    case internalError
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

class TrackOBot : NSObject, URLSessionDelegate {
    static let instance = TrackOBot()
    static let DOMAIN = "trackobot.com"
    //static let DOMAIN = "localhost:3001"

    let USER = "user"
    let USERNAME = "username"
    let TOKEN = "token"

    let defaults = UserDefaults.standard

    let createUserUrl = "https://\(DOMAIN)/users"
    let resultsUrl = "https://\(DOMAIN)/profile/results.json"
    let resultDeleteUrl = "https://\(DOMAIN)/profile/results"
    let profileUrl = "https://\(DOMAIN)/profile.json"
    let decksUrl = "https://\(DOMAIN)/profile/settings/decks.json"
    let oneTimeAuthTokenUrl = "https://\(DOMAIN)/one_time_auth.json"

    let byClassResultsUrl = "https://\(DOMAIN)/profile/stats/classes.json"
    let byDeckResultsUrl = "https://\(DOMAIN)/profile/stats/decks.json"


    func storeUser(_ user:User) -> Void {
        let userData = NSKeyedArchiver.archivedData(withRootObject: user)
        defaults.set(userData, forKey: USER)
    }

    func loadUser() -> User? {
        guard let data = defaults.data(forKey: USER) else {
            return nil
        }

        // needs to be set to read data storerd in early beta, when the app's name was still Track-o-Bot-Companion
        NSKeyedUnarchiver.setClass(User.self, forClassName: "Track_o_Bot_Companion.User")
        guard let user = NSKeyedUnarchiver.unarchiveObject(with: data) as? User else {
            return nil
        }
        return user
    }


    func postResult(_ game:Game, onComplete: @escaping (Result<NSDictionary, TrackOBotAPIError>) -> Void) -> Void {
        var gameData = ["hero": game.hero as AnyObject, "opponent": game.opponentsHero as AnyObject,
                        "win": game.won as AnyObject,
                        "mode": game.mode.rawValue as AnyObject] as [String: AnyObject]
        if let coin = game.coin {
            gameData["coin"] = coin as AnyObject?
        }
        if let deck = game.deckId {
            gameData["deck_id"] = deck as AnyObject?
        }
        if let opponentsDeck = game.opponentsDeckId {
            gameData["opponent_deck_id"] = opponentsDeck as AnyObject?
        }
        if let rnk = game.rank {
            gameData["rank"] = rnk as AnyObject?
        }
        if let legend = game.legend {
            gameData["legend"] = legend as AnyObject?
        }

        let data = ["result": gameData]
        guard let json = try? JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.init(rawValue: 0)) else {
            onComplete(Result.failure(TrackOBotAPIError.jsonFormattingFailed))
            return
        }
        postRequest(resultsUrl, data: json, onComplete: onComplete)
    }

    func getResults(_ page: Int, onComplete: @escaping (Result<HistoryPage, TrackOBotAPIError>) -> Void) -> Void {
        let url = profileUrl + "?page=\(page)" // 1-based indices in API
        getRequest(url, onComplete: {
            (result) -> Void in
            switch result {
            case .success(let dict):
                guard let history = dict["history"] as? [NSDictionary] else {
                    onComplete(Result.failure(TrackOBotAPIError.jsonParsingFailed))
                    return
                }
                let games = history.flatMap { d in Game(dict:d) }

                guard let meta = dict["meta"] as? NSDictionary else {
                    onComplete(Result.failure(TrackOBotAPIError.jsonParsingFailed))
                    return
                }
                let historyPage = HistoryPage(games: games, dict: meta)

                onComplete(Result.success(historyPage))
                break
            case .failure(let err):
                onComplete(Result.failure(err))
                break
            }
        })
    }

    func deleteResult(_ id: Int, onComplete: @escaping (Result<Bool, TrackOBotAPIError>) -> Void) -> Void {
        let url = "\(resultDeleteUrl)/\(id)"
        deleteRequest(url, onComplete: onComplete)
    }

    func getDecks(_ onComplete: @escaping (Result<[[Deck]], TrackOBotAPIError>) -> Void) -> Void {
        getRequest(decksUrl, onComplete: {
        (result) -> Void in
            switch result {
            case .success(let dict):
                guard let decksDicts = dict["decks"] as? [NSDictionary] else {
                    onComplete(Result.failure(TrackOBotAPIError.jsonParsingFailed))
                    return
                }
                let activeDecks = decksDicts.filter { (d) in (d["active"] as? Bool) ?? true }
                // TODO depends on result casing of hero names
                let decks  = HEROES.map { (hero) -> [Deck] in
                    return activeDecks.filter { (d) -> Bool in
                        d["hero"] as? String == hero
                        }.flatMap { Deck(dict:$0) }
                }

                onComplete(Result.success(decks))
                break
            case .failure(let err):
                onComplete(Result.failure(err))
                break
            }
        })
    }

    func getByClassStats(_ onComplete: @escaping (Result<[ByClassStats], TrackOBotAPIError>) -> Void) -> Void {
        getRequest(byClassResultsUrl, onComplete: {
            (result) -> Void in
            switch result {
            case .success(let dict):
                guard let statsDict = dict["stats"] as? NSDictionary,
                          let stats = statsDict["as_class"] as? NSDictionary else {
                    onComplete(Result.failure(TrackOBotAPIError.jsonParsingFailed))
                    return
                }
                let byClassStats = stats.flatMap { (heroKey,heroStatsValue) -> ByClassStats? in
                    guard let hero = heroKey as? String,
                        let heroStats = heroStatsValue as? NSDictionary,
                        let wins = heroStats["wins"] as? Int,
                        let losses = heroStats["losses"] as? Int else {
                            return nil
                    }
                    return ByClassStats(hero: hero, wins: wins, losses: losses)
                    }.sorted() { (a,b) in
                        HEROES.index(of: a.hero) ?? 0 < HEROES.index(of: b.hero) ?? 0
                    }


                onComplete(Result.success(byClassStats))
                break
            case .failure(let err):
                onComplete(Result.failure(err))
                break
            }
        })
    }

    func getVsClassStats(_ asClass: String, onComplete: @escaping (Result<[ByClassStats], TrackOBotAPIError>) -> Void) -> Void {
        getRequest("\(byClassResultsUrl)?as_hero=\(asClass.lowercased())", onComplete: {
            (result) -> Void in
            switch result {
            case .success(let dict):
                guard let statsDict = dict["stats"] as? NSDictionary,
                          let stats = statsDict["vs_class"] as? NSDictionary else {
                    onComplete(Result.failure(TrackOBotAPIError.jsonParsingFailed))
                    return
                }
                let byClassStats = stats.flatMap { (heroKey,heroStatsValue) -> ByClassStats? in
                    guard let hero = heroKey as? String,
                        let heroStats = heroStatsValue as? NSDictionary,
                        let wins = heroStats["wins"] as? Int,
                        let losses = heroStats["losses"] as? Int else {
                            return nil
                    }
                    return ByClassStats(hero: hero, wins: wins, losses: losses)
                }.sorted() { (a,b) in
                    HEROES.index(of: a.hero) ?? 0 < HEROES.index(of: b.hero) ?? 0
                }

                onComplete(Result.success(byClassStats))
                break
            case .failure(let err):
                onComplete(Result.failure(err))
                break
            }
        })
    }

    // TODO: abstract deck vs class stat functions (are basically copy-pasta now)
    func getByDeckStats(_ onComplete: @escaping (Result<[ByDeckStats], TrackOBotAPIError>) -> Void) -> Void {
        getRequest(byDeckResultsUrl, onComplete: {
            (result) -> Void in
            switch result {
            case .success(let dict):
                guard let statsDict = dict["stats"] as? NSDictionary,
                          let stats = statsDict["as_deck"] as? [String: NSDictionary] else {
                    onComplete(Result.failure(TrackOBotAPIError.jsonParsingFailed))
                    return
                }
                let byDeckStats = stats.flatMap { (d: String, deckStats: NSDictionary) -> ByDeckStats? in
                    guard let hero = deckStats["hero"] as? String,
                        let wins = deckStats["wins"] as? Int, let losses = deckStats["losses"] as? Int else {
                            return nil
                    }
                    let deckId: Int? = deckStats["deck_id"] as? Int
                    return ByDeckStats(deckName: d, deckId: deckId, hero: hero, wins: wins, losses: losses)
                }

                onComplete(Result.success(byDeckStats))
                break
            case .failure(let err):
                onComplete(Result.failure(err))
                break
            }
        })
    }

    func getVsDeckStats(_ asDeck: Int, onComplete: @escaping (Result<[ByDeckStats], TrackOBotAPIError>) -> Void) -> Void {
        getRequest("\(byDeckResultsUrl)?as_deck=\(asDeck)", onComplete: {
            (result) -> Void in
            switch result {
            case .success(let dict):
                guard let statsDict = dict["stats"] as? NSDictionary,
                          let stats = statsDict["vs_deck"] as? [String: NSDictionary] else {
                    onComplete(Result.failure(TrackOBotAPIError.jsonParsingFailed))
                    return
                }
                let byDeckStats = stats.flatMap { (d: String, deckStats: NSDictionary) -> ByDeckStats? in
                    guard let hero = deckStats["hero"] as? String,
                        let wins = deckStats["wins"] as? Int,
                        let losses = deckStats["losses"] as? Int else {
                            return nil
                    }
                    let deckId = deckStats["deck_id"] as? Int
                    return ByDeckStats(
                        deckName: d, deckId: deckId, hero: hero,
                        wins: wins, losses: losses)
                }

                onComplete(Result.success(byDeckStats))
                break
            case .failure(let err):
                onComplete(Result.failure(err))
                break
            }
        })
    }


    func getOneTimeAuthToken(_ onComplete: @escaping (Result<NSDictionary, TrackOBotAPIError>) -> Void) -> Void {
        postRequest(oneTimeAuthTokenUrl, data: nil, onComplete: onComplete)
    }


    func createUser(_ onComplete: @escaping (Result<User, TrackOBotAPIError>) -> Void) -> Void {
        let config = URLSessionConfiguration.default
        guard let url = URL(string: createUserUrl) else {
            onComplete(Result.failure(TrackOBotAPIError.malformedUrl))
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        let session = Foundation.URLSession(configuration: config,
            delegate: nil, delegateQueue: OperationQueue.main)

        let task = session.dataTask(with: urlRequest, completionHandler: {
            (data: Data?, response: URLResponse?, error: Error?) -> Void in

            let result = self.checkErrors(data, error: error)
            switch result {
            case .success(let dict):
                guard let username = dict["username"] as? String, let password = dict["password"] as? String else {
                    onComplete(Result.failure(TrackOBotAPIError.requestFailed(error: "Unexpected response to create user call: \(result)")))
                    return
                }
                let user = User(username: username, password: password, domain: TrackOBot.DOMAIN)
                onComplete(Result.success(user))

                break
            case .failure(let err):
                onComplete(Result.failure(err))
                break
            }
        })

        task.resume()
    }

    fileprivate func checkErrors(_ data: Data?, error: Error?) -> Result<NSDictionary, TrackOBotAPIError> {
        guard error == nil else {
            return Result.failure(TrackOBotAPIError.networkError(error: error!))
        }

        guard let result = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.init(rawValue: 0)) else {
            return Result.failure(TrackOBotAPIError.jsonParsingFailed)
        }

        guard let dict = result as? NSDictionary else {
            return Result.failure(TrackOBotAPIError.jsonParsingFailed)
        }

        if let apiError = dict["error"] as? String {
            if apiError == "You need to sign in or sign up before continuing." {
                return Result.failure(TrackOBotAPIError.loginFailed(error: apiError))
            }
            else {
                return Result.failure(TrackOBotAPIError.requestFailed(error: apiError))
            }
        }
        return Result.success(dict)
    }

    fileprivate func postRequest(_ url: String, data: Data?, onComplete: @escaping (Result<NSDictionary, TrackOBotAPIError>) -> Void) -> Void {
        guard let user = self.loadUser() else {
            onComplete(Result.failure(TrackOBotAPIError.credentialsMissing))
            return
        }

        guard var (session, urlRequest) = self.configureAuthenticatedSessionAndRequest(user, urlString: url) else {
            onComplete(Result.failure(TrackOBotAPIError.internalError))
            return
        }

        urlRequest.httpMethod = "POST"
        if let d = data {
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = d
        }

        let task = session.dataTask(with: urlRequest, completionHandler: {
            (data: Data?, response: URLResponse?, error: Error?) -> Void in

            let result = self.checkErrors(data, error: error)
            switch result {
            case .success(let dict):
                onComplete(Result.success(dict))
                break
            case .failure(let err):
                onComplete(Result.failure(err))
                break
            }
        })
        task.resume()
    }

    fileprivate func getRequest(_ url: String, onComplete: @escaping (Result<NSDictionary, TrackOBotAPIError>) -> Void) -> Void {
        guard let user = self.loadUser() else {
            onComplete(Result.failure(TrackOBotAPIError.credentialsMissing))
            return
        }
        guard let (session, urlRequest) = self.configureAuthenticatedSessionAndRequest(user, urlString: url) else {
            onComplete(Result.failure(TrackOBotAPIError.internalError))
            return
        }

        let task = session.dataTask(with: urlRequest, completionHandler: {
            (data: Data?, response: URLResponse?, error: Error?) -> Void in

            let result = self.checkErrors(data, error: error)
            switch result {
            case .success(let dict):
                onComplete(Result.success(dict))
                break
            case .failure(let err):
                onComplete(Result.failure(err))
                break
            }
        })
        task.resume()

    }

    fileprivate func deleteRequest(_ url: String, onComplete: @escaping (Result<Bool, TrackOBotAPIError>) -> Void) -> Void {
        guard let user = self.loadUser() else {
            onComplete(Result.failure(TrackOBotAPIError.credentialsMissing))
            return
        }
        // set delegate to prevent following redirects
        guard var (session, urlRequest) = self.configureAuthenticatedSessionAndRequest(user, urlString: url, delegate: self) else {
            onComplete(Result.failure(TrackOBotAPIError.internalError))
            return
        }

        urlRequest.httpMethod = "DELETE"

        let task = session.dataTask(with: urlRequest, completionHandler: {
            (data: Data?, response: URLResponse?, error: Error?) -> Void in

            guard error == nil else {
                onComplete(Result.failure(TrackOBotAPIError.networkError(error: error!)))
                return
            }

            onComplete(Result.success(true))
        })
        task.resume()
    }

    fileprivate func configureAuthenticatedSessionAndRequest(_ user:User, urlString:String, delegate: URLSessionDelegate? = nil) -> (Foundation.URLSession, URLRequest)? {
        let config = URLSessionConfiguration.default
        let userPasswordString = "\(user.username):\(user.password)"
        let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
        let base64EncodedCredential = userPasswordData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        let authString = "Basic \(base64EncodedCredential)"
        config.httpAdditionalHeaders = ["Authorization" : authString]

        let urlComponents = URLComponents.init(string: urlString)
        guard let url = urlComponents?.url else {
            return nil
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        let session = Foundation.URLSession(configuration: config,
            delegate: delegate, delegateQueue: OperationQueue.main)

        return (session, urlRequest)
    }

    func URLSession(_ session: Foundation.URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: (URLRequest!) -> Void) {
        completionHandler(nil)
    }

    func readTrackOBotAccountDataFile(_ url:URL) -> User? {
        guard let data = FileManager.default.contents(atPath: url.path) else {
            return nil
        }

        var pos = 0
        let username:String, password:String, domain:String
        do {
            (username, pos) = try TrackOBot.instance.readString(data, pos: pos)
            (password, pos) = try TrackOBot.instance.readString(data, pos: pos)
            (domain, pos) = try TrackOBot.instance.readString(data, pos: pos)
            return User(username: username, password: password, domain: domain)
        } catch TrackOBotError.decodeError {
            return nil
        } catch {
            return nil
        }
    }

    func writeTrackOBotAccountDataFile(_ user:User) -> Data {
        let md = NSMutableData()
        writeString(user.username, data: md)
        writeString(user.password, data: md)
        writeString("https://trackobot.com", data: md)
        return md as Data
    }

    enum TrackOBotError : Error {
        case decodeError
    }

    /* reads a Swift String from a NSData object that was written by a QDataStream*/
    fileprivate func readString(_ data: Data, pos: Int) throws -> (String, Int) {
        // read length of String (32bit)
        var i = [UInt32](repeating: 0, count: 1)
        if (pos + 4 > data.count) {
            throw TrackOBotError.decodeError
        }

        (data as NSData).getBytes(&i, range: NSRange(location: pos, length: 4))
        let len = Int(i[0].bigEndian) // in byte

        // fill string buffer, each character is 16 bit
        var strBuf = [UInt16](repeating: 0, count: len / 2)
        if (pos + 4 + len > data.count) {
            throw TrackOBotError.decodeError
        }

        (data as NSData).getBytes(&strBuf, range: NSRange(location: pos + 4, length: len))

        // update position
        let newPos = pos + 4 + len
        // convert to String
        let str = NSString(bytes: &strBuf, length: (len / 2)*MemoryLayout<UInt16>.size, encoding: String.Encoding.utf16BigEndian.rawValue) as! String
        return (str, newPos)
    }



    fileprivate func writeString(_ str: String, data: NSMutableData) {
        let numBytes = str.utf16.count * 2
        let lenBytes = [UInt32(bigEndian: UInt32(numBytes))]
        UnsafePointer<UInt32>(lenBytes).withMemoryRebound(to: UInt8.self, capacity: 4) {
            data.append(Data(bytes: $0, count: 4))
        }

        let strBytes = str.utf16.map { s in UInt16(bigEndian: s) }
        UnsafePointer<UInt16>(strBytes).withMemoryRebound(to: UInt8.self, capacity: numBytes) {
            data.append(Data(bytes: $0, count: numBytes))
        }
    }
}

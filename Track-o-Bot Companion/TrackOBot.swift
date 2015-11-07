//
//  TrackOBot.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 07.09.15.
//  Copyright (c) 2015 Julian Eberius. All rights reserved.
//

import Foundation


class Game {

    static var inputDateFormatter:NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
        return formatter
    }

    static var outputDateFormatter:NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.MediumStyle
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.doesRelativeDateFormatting = true
        return formatter
    }

    let hero: String!
    let opponentsHero: String!
    let won: Bool!
    let coin: Bool!
    let timeLabel: String!

    init(hero: String?, opponentsHero: String?, won:Bool?, coin:Bool?, added:NSDate? = nil) {
        self.hero = hero
        self.opponentsHero = opponentsHero
        self.won = won
        self.coin = coin
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
        let hero = dict["hero"] as? String
        let opponentsHero = dict["opponent"] as? String
        let won = (dict["result"] as? String) == "win" ? true : false
        let coin = dict["coin"] as? Bool

        var added: NSDate? = nil
        if let ds = dict["added"] as? String {
            added = Game.inputDateFormatter.dateFromString(ds)
        }
        self.init(hero: hero, opponentsHero: opponentsHero, won: won, coin: coin, added: added)
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
        self.init(username: username, password: password, domain: TrackOBot.instance.DEFAULT_DOMAIN)
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

class TrackOBot : NSObject {
    static let instance = TrackOBot()

    let defaults = NSUserDefaults.standardUserDefaults()
    let USER = "user"
    let USERNAME = "username"
    let TOKEN = "token"
    let DEFAULT_DOMAIN = "https://trackobot.com"

//    let resultsUrl = "https://trackobot.com/profile/results.json?username=%@&token=%@"
    let resultsUrl = "https://trackobot.com/profile/results.json"
//    let profileUrl = "https://trackobot.com/profile.json?username=%@&token=%@"
    let profileUrl = "https://trackobot.com/profile.json"
//    let oneTimeAuthTokenUrl = "https://trackobot.com/one_time_auth.json?username=%@&token=%@"
    let oneTimeAuthTokenUrl = "https://trackobot.com/one_time_auth.json"
    let createUserUrl = "https://trackobot.com/users"
//    let createUserUrl = "https://localhost:3001/users"
//    let resultsUrl = "https://localhost:3001/profile/results.json?username=%@&token=%@"
//    let profileUrl = "https://localhost:3001/profile.json?username=%@&token=%@"
//    let oneTimeAuthTokenUrl = "https://localhost:3001/one_time_auth.json?username=%@&token=%@"

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
        let data = ["result":
            ["hero": game.hero, "opponent": game.opponentsHero, "win": game.won, "coin": game.coin, "mode": "ranked"]]

        guard let json = try? NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions.init(rawValue: 0)) else {
            onComplete(Result.Failure(TrackOBotAPIError.JsonFormattingFailed))
            return
        }

        postRequest(resultsUrl, data: json, onComplete: onComplete)

    }

    func getOneTimeAuthToken(onComplete: (Result<NSDictionary, TrackOBotAPIError>) -> Void) -> Void {
        postRequest(oneTimeAuthTokenUrl, data: nil, onComplete: onComplete)
    }


    func createUser(onComplete: (Result<User, TrackOBotAPIError>) -> Void) -> Void {
        postRequest(createUserUrl, data: nil, onComplete: {
            (result) -> Void in
            switch result {
            case .Success(let dict):
                guard let username = dict["username"] as? String, password = dict["password"] as? String else {
                    onComplete(Result.Failure(TrackOBotAPIError.RequestFaild(error: "Unexpected response to create user call: \(result)")))
                    return
                }
                let user = User(username: username, password: password, domain: self.DEFAULT_DOMAIN)
                onComplete(Result.Success(user))
                break
            case .Failure(let err):
                onComplete(Result.Failure(err))
                break
            }
        })
    }

    func postRequest(url: String, data: NSData?, onComplete: (Result<NSDictionary, TrackOBotAPIError>) -> Void) -> Void {
        guard let user = self.loadUser() else {
            onComplete(Result.Failure(TrackOBotAPIError.CredentialsMissing))
            return
        }

        let (session, urlRequest) = self.configureAuthenticatedSessionAndRequest(user, url: url)
        urlRequest.HTTPMethod = "POST"
        if let d = data {
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.HTTPBody = d
        }

        let task = session.dataTaskWithRequest(urlRequest){
            (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in

            guard error == nil else {
                onComplete(Result.Failure(TrackOBotAPIError.NetworkError(error: error!)))
                return
            }

            guard let result = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.init(rawValue: 0)) else {
                onComplete(Result.Failure(TrackOBotAPIError.JsonParsingFailed))
                return
            }

            guard let dict = result as? NSDictionary else {
                onComplete(Result.Failure(TrackOBotAPIError.JsonParsingFailed))
                return
            }

            if let apiError = dict["error"] as? String {
                if apiError == "You need to sign in or sign up before continuing." {
                    onComplete(Result.Failure(TrackOBotAPIError.LoginFaild(error: apiError)))
                }
                else {
                    onComplete(Result.Failure(TrackOBotAPIError.RequestFaild(error: apiError)))
                }
                return
            }

            // everything worked out
            onComplete(Result.Success(dict))
        }
        task.resume()
    }

    func getResults(onComplete: (Result<[Game], TrackOBotAPIError>) -> Void) -> Void {
        getRequest(profileUrl, onComplete: {
            (result) -> Void in
            switch result {
            case .Success(let dict):
                guard let history = dict["history"] as? [NSDictionary] else {
                    onComplete(Result.Failure(TrackOBotAPIError.JsonParsingFailed))
                    return
                }
                let games = history.map { d in Game(dict:d) }
                onComplete(Result.Success(games))
                break
            case .Failure(let err):
                onComplete(Result.Failure(err))
                break
            }
        })
    }

    func getRequest(url: String, onComplete: (Result<NSDictionary, TrackOBotAPIError>) -> Void) -> Void {
        guard let user = self.loadUser() else {
            onComplete(Result.Failure(TrackOBotAPIError.CredentialsMissing))
            return
        }
        let (session, urlRequest) = self.configureAuthenticatedSessionAndRequest(user, url: url)

        let task = session.dataTaskWithRequest(urlRequest){
            (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in


            guard error == nil else {
                onComplete(Result.Failure(TrackOBotAPIError.NetworkError(error: error!)))
                return
            }

            guard let result = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.init(rawValue: 0)) else {
                onComplete(Result.Failure(TrackOBotAPIError.JsonParsingFailed))
                return
            }

            guard let dict = result as? NSDictionary else {
                onComplete(Result.Failure(TrackOBotAPIError.JsonParsingFailed))
                return
            }

            if let apiError = dict["error"] as? String {
                if apiError == "You need to sign in or sign up before continuing." {
                    onComplete(Result.Failure(TrackOBotAPIError.LoginFaild(error: apiError)))
                }
                else {
                    onComplete(Result.Failure(TrackOBotAPIError.RequestFaild(error: apiError)))
                }
                return
            }

            onComplete(Result.Success(dict))
        }
        task.resume()

    }

    func configureAuthenticatedSessionAndRequest(user:User, url:String) -> (NSURLSession, NSMutableURLRequest) {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let userPasswordString = "\(user.username):\(user.password)"
        let userPasswordData = userPasswordString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64EncodedCredential = userPasswordData!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        let authString = "Basic \(base64EncodedCredential)"
        config.HTTPAdditionalHeaders = ["Authorization" : authString]

        let urlRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        urlRequest.HTTPMethod = "GET"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")

        let session = NSURLSession(configuration: config,
            delegate: nil, delegateQueue: NSOperationQueue.mainQueue())

        return (session, urlRequest)
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

    enum TrackOBotError : ErrorType {
        case DecodeError
    }

    /* reads a Swift String from a NSData object that was written by a QDataStream */
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

}

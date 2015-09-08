//
//  TrackOBot.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 07.09.15.
//  Copyright (c) 2015 Julian Eberius. All rights reserved.
//

import Foundation

class TrackOBot {
    static let instance = TrackOBot()

    static let defaults = NSUserDefaults.standardUserDefaults()
    static let USERNAME = "username"
    static let TOKEN = "token"

    static let resultsUrl = "https://trackobot.com/profile/results.json?username=%@&token=%@"
//    static let resultsUrl = "http://127.0.0.1:5000?username=%@&token=%@"

    static func postResult(yourHero: String, opponentsHero: String, won: Bool, coin: Bool, onComplete: (NSDictionary?, NSError?) -> Void) -> Bool {

        if let username = defaults.stringForKey(USERNAME), token = defaults.stringForKey(TOKEN) {

            let data = ["result":
                ["hero": yourHero, "opponent": opponentsHero, "win": won, "coin": coin, "mode": "ranked"]]

            var postJSONError: NSError?
            let json = NSJSONSerialization.dataWithJSONObject(data, options: nil, error:  &postJSONError)
            println("serialized request data \(NSString(data: json!, encoding: NSUTF8StringEncoding))")

            let url = String(format:resultsUrl, username, token)
            var urlRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
            urlRequest.HTTPMethod = "POST"
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
            urlRequest.HTTPBody = json

            NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue(), completionHandler:{
                (response:NSURLResponse!, data: NSData!, error: NSError!) -> Void in

                if let anError = error
                {
                    onComplete(nil, anError)
                }
                else // no error returned by URL request
                {
                    // parse the result as json, since that's what the API provides
                    var jsonError: NSError?
                    let result = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: &jsonError) as! NSDictionary?
                    if let aJSONError = jsonError
                    {
                        onComplete(nil, aJSONError)
                    }
                    else
                    {
                        // now we have the post, let's just print it to prove we can access it
                        onComplete(result!, nil)
                    }
                }
            })
        }
        else {
            onComplete(nil, NSError(domain: NSURLErrorDomain, code: -1, userInfo: ["msg":"no credentials set"]))
        }
        return true
    }

}

//
//  TrackOBotViewController.swoft.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 29.10.15.
//  Copyright © 2015 Julian Eberius. All rights reserved.
//

import UIKit

class TrackOBotViewController: UIViewController {
    let defaults = NSUserDefaults.standardUserDefaults()

    @IBAction func logoutButtonTouchUp(sender: AnyObject) {
        defaults.removeObjectForKey(TrackOBot.instance.USER)
        self.performSegueWithIdentifier("to_login", sender: self)
    }

    @IBAction func openProfileTouchUp(sender: AnyObject) {
        TrackOBot.instance.getOneTimeAuthToken({
            (result) -> Void in
            switch result {
            case .Success(let dict):
                if let u = dict["url"] as? String {
                    let url = NSURL(string: u)
                    UIApplication.sharedApplication().openURL(url!)
                } else {
                    print("?!?: \(dict)")
                }
            case .Failure(let err):
                print("ERROR \(err)")
                // TODO: open Alert window
            }
        })
    }

    func newCredentialsAdded(user:User) {

    }
}
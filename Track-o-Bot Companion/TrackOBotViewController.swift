//
//  TrackOBotViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 29.10.15.
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

import UIKit

class TrackOBotViewController: UIViewController, UIPopoverPresentationControllerDelegate  {
    let defaults = NSUserDefaults.standardUserDefaults()

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }

    @IBAction func openProfileTouchUp(sender: UIBarButtonItem) {

        TrackOBot.instance.getOneTimeAuthToken({
            (result) -> Void in
            switch result {
            case .Success(let dict):
                if let u = dict["url"] as? String {
                    let url = NSURL(string: u)
                    UIApplication.sharedApplication().openURL(url!)
                } else {
                    self.alert("Error", message: "Received invalid login url data from trackobot.com: \(dict)")
                }
            case .Failure(let err):
                self.alert("Error", message: "Error receiving login url data from trackobot.com: \(err)")
            }
        })

    }

    func alert(title: String, message:String) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.Default, handler:nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }

    func newCredentialsAdded(user:User) {

    }
}
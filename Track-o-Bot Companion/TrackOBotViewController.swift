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

    @IBAction func logoutButtonTouchUp(sender: AnyObject) {
        defaults.removeObjectForKey(TrackOBot.instance.USER)
        self.performSegueWithIdentifier("to_login", sender: self)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }

    @IBAction func openProfileTouchUp(sender: UIBarButtonItem) {
        
        guard let storyboard = self.storyboard else {
            return
        }
        let controller = storyboard.instantiateViewControllerWithIdentifier("profileMenuController") as UIViewController
        controller.modalPresentationStyle = UIModalPresentationStyle.Popover
        if let popoverMenuViewController = controller.popoverPresentationController {
            popoverMenuViewController.permittedArrowDirections = .Any
            popoverMenuViewController.delegate = self
            popoverMenuViewController.barButtonItem = sender
        }

        presentViewController(
            controller,
            animated: true,
            completion: nil)

    }
    
    @IBAction func viewOnTrackOBotComTouchUp(sender: UIButton) {
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

    @IBAction func exportProfileTouchUp(sender: UIButton) {
        guard let user = TrackOBot.instance.loadUser() else {
            return
        }
        let exportData = TrackOBot.instance.writeTrackOBotAccountDataFile(user)
        
        let url = NSURL.fileURLWithPath(NSTemporaryDirectory().stringByAppendingString("accountData.track-o-bot"))
        exportData.writeToURL(url, atomically: true);
        
        
        let objectsToShare = [url]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = sender;
        }
        
        self.presentViewController(activityVC, animated: true, completion: nil)
    }

    func newCredentialsAdded(user:User) {
        
    }
}
//
//  MoreViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 22.06.16.
//  Copyright (c) 2016 Julian Eberius.
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
import UIKit

class MoreViewController: UITableViewController {

    let defaults = NSUserDefaults.standardUserDefaults()

    @IBOutlet weak var profileLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        guard let user = TrackOBot.instance.loadUser() else {
            profileLabel.text = "Not logged in"
            self.performSegueWithIdentifier("to_login", sender: self)
            return
        }
        profileLabel.text = "Logged in as: \(user.username)"
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == 0 else {
            return
        }
        switch indexPath.row {
        case 1:
            guard let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) else {
                return
            }
            exportProfile(cell)
            break
        case 2:
            guard let user = TrackOBot.instance.loadUser() else {
                // reaching this scree nwith no valid user would be an illegal state
                logout()
                return
            }
            let alertController = UIAlertController(title: nil, message: "Do you really want to log out of the account \"\(user.username)\"?", preferredStyle: .ActionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (_) in }
            alertController.addAction(cancelAction)
            let OKAction = UIAlertAction(title: "Logout", style: .Destructive) { (action) in self.logout() }
            alertController.addAction(OKAction)
            if let popoverController = alertController.popoverPresentationController {
                guard let cellView = tableView.cellForRowAtIndexPath(indexPath) else {
                    return
                }
                popoverController.sourceView = cellView
                popoverController.sourceRect = cellView.bounds
            }
            self.presentViewController(alertController, animated: true) { }
            break
        default:
            break
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    func logout() {
        defaults.removeObjectForKey(TrackOBot.instance.USER)
        self.performSegueWithIdentifier("to_login", sender: self)
    }

    func exportProfile(sender: UITableViewCell) {
        guard let user = TrackOBot.instance.loadUser() else {
            return
        }
        let exportData = TrackOBot.instance.writeTrackOBotAccountDataFile(user)

        let url = NSURL.fileURLWithPath(NSTemporaryDirectory().stringByAppendingString("accountData.track-o-bot"))
        exportData.writeToURL(url, atomically: true);

        let objectsToShare = [url]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
//        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Phone)
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = sender;
            popoverController.permittedArrowDirections = UIPopoverArrowDirection.Up
        }
//        navigationController?.presentViewController(activityVC, animated: true, completion: nil)
        self.presentViewController(activityVC, animated: true, completion: nil)
    }

}

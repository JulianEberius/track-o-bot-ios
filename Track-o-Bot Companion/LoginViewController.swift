//
//  LoginViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 27.10.15.
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

class LoginViewController: TrackOBotViewController, UIAlertViewDelegate {


    @IBOutlet weak var errorLabel: UILabel!

    @IBAction func accountCreateButtonTouchUp(sender: AnyObject) {
        TrackOBot.instance.createUser {
            (result) -> Void in
            switch result {
            case .Success(let user):
                TrackOBot.instance.storeUser(user)
                self.performSegueWithIdentifier("back_from_login", sender: self)
            case .Failure(let err):
                self.errorLabel.text = "Error creating user: \(err)"
                UIView.animateWithDuration(0.25, delay: 0.0, options:UIViewAnimationOptions.CurveEaseIn, animations: {
                    self.errorLabel.alpha = 1.0
                    }, completion:nil)
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.errorLabel.alpha = 0
    }

    override func newCredentialsAdded(user:User) {
        self.performSegueWithIdentifier("back_from_login", sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.errorLabel.alpha = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
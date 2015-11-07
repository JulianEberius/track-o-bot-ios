//
//  LoginViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 27.10.15.
//  Copyright © 2015 Julian Eberius. All rights reserved.
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
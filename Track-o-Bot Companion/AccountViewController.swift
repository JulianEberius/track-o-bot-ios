//
//  SecondViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 07.09.15.
//  Copyright (c) 2015 Julian Eberius. All rights reserved.
//

import UIKit

class AccountViewController: TrackOBotViewController, UITextFieldDelegate {

    override func newCredentialsAdded(user:User) {
        self.performSegueWithIdentifier("back_from_login", sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}


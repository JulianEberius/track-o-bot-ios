//
//  SecondViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 07.09.15.
//  Copyright (c) 2015 Julian Eberius. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var tokenField: UITextField!

    let defaults = NSUserDefaults.standardUserDefaults()

    override func viewDidLoad() {
        super.viewDidLoad()
        if let username = defaults.stringForKey(TrackOBot.USERNAME) {
            self.usernameField.text = username
        }
        if let token = defaults.stringForKey(TrackOBot.TOKEN) {
            self.tokenField.text = token
        }
    }

    func textFieldDidEndEditing(textField: UITextField) {
        if (textField == self.usernameField) {
            let username = textField.text
            defaults.setObject(username, forKey: TrackOBot.USERNAME)
        }
        else if (textField == self.tokenField) {
            let token = textField.text
            defaults.setObject(token, forKey: TrackOBot.TOKEN)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


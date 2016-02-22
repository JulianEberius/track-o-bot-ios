//
//  SettingsViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 08.09.15.
//  Copyright © 2015 Julian Eberius. All rights reserved.
//

import UIKit


class StatsViewController: TrackOBotViewController {
        
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // check login
        TrackOBot.instance.getDecks({
            (result) -> Void in
            switch result {
            case .Success:
                break
            case .Failure(let err):
                switch err {
                case .CredentialsMissing, .LoginFaild(_):
                    self.performSegueWithIdentifier("to_login", sender: self)
                default:
                    print("what")
                }
            }
        })
    }
    
    @IBAction func unwindFromLogin(unwindSegue: UIStoryboardSegue) {
        
    }


    
}

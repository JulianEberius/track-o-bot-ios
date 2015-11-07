    //
//  FirstViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 07.09.15.
//  Copyright (c) 2015 Julian Eberius. All rights reserved.
//

import UIKit

class AddGameViewController: TrackOBotViewController, UIPickerViewDelegate, UIPickerViewDataSource {


    @IBOutlet weak var heroPicker: UIPickerView!

    @IBOutlet weak var wonSwitch: UISwitch!
    @IBOutlet weak var coinSwitch: UISwitch!

    @IBOutlet weak var addGameButton: UIButton!

    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var sucessCheckmark: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    let heroes = ["Warrior", "Shaman", "Rogue", "Paladin", "Hunter", "Druid", "Warlock", "Mage", "Priest"]

    let HERO_PICKER = 0
    let OPPONENTS_HERO_PICKER = 1
    let SELECTED_HERO = "selected_hero"
    let SELECTED_OPPONENTS_HERO = "selected_opponents_hero"
    let DEFAULT_HERO = "Hunter" // its the center one, i'm sorry


    @IBAction func addGameButtonTouchUp(sender: UIButton) {
        let yourHero = self.heroes[self.heroPicker.selectedRowInComponent(HERO_PICKER)]
        let opponentsHero = self.heroes[self.heroPicker.selectedRowInComponent(OPPONENTS_HERO_PICKER)]

        let won = self.wonSwitch.on
        let coin = self.coinSwitch.on

        self.addGameButton.enabled = false
        self.activityIndicator.startAnimating()
        self.errorLabel.alpha = 0.0

        let game = Game(hero: yourHero, opponentsHero: opponentsHero, won: won, coin: coin)

        TrackOBot.instance.postResult(game, onComplete:{
            (result) -> Void in
            self.activityIndicator.stopAnimating()
            self.addGameButton.enabled = true

            switch result {
            case .Success:
                UIView.animateWithDuration(0.25, delay: 0.0, options:UIViewAnimationOptions.CurveEaseIn, animations: {
                    self.sucessCheckmark.alpha = 1.0
                    }, completion:nil)
                UIView.animateWithDuration(1.0, delay: 2.0, options:UIViewAnimationOptions.CurveEaseIn, animations: {
                    self.sucessCheckmark.alpha = 0.0
                    }, completion:nil)
            case .Failure(let error):
                print("finished request with ERROR: \(error)")
                UIView.animateWithDuration(0.25, delay: 0.0, options:UIViewAnimationOptions.CurveEaseIn, animations: {
                    self.errorLabel.alpha = 1.0
                    }, completion:nil)
            }
        })
    }

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 9
    }

// TODO: customize height and width for size classes
//    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
//        return 80
//    }
//
//    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
//        return 200
//    }

    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let hero = self.heroes[row]
        if let v = view as? HeroPickerItem {
            v.imageView.image = UIImage(named:hero)
            return v
        } else {
            let v = HeroPickerItem(frame: CGRectMake(0, 0, 120, 32))
            v.label.text = hero
            v.imageView.image = UIImage(named:hero)
            return v
        }
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            let hero = self.heroes[row]
            defaults.setObject(hero, forKey: SELECTED_HERO)
        }else if component == 1{
            let hero = self.heroes[row]
            defaults.setObject(hero, forKey: SELECTED_OPPONENTS_HERO)
        }
    }

    @IBAction func unwindFromLogin(unwindSegue: UIStoryboardSegue) {

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.addGameButton.enabled = true
        self.sucessCheckmark.alpha = 0
        self.errorLabel.alpha = 0

        let selectedHero = defaults.stringForKey(SELECTED_HERO) ?? DEFAULT_HERO
        let selectedOpponentsHero = defaults.stringForKey(SELECTED_OPPONENTS_HERO) ?? DEFAULT_HERO
        let selectedHeroRow = self.heroes.indexOf(selectedHero) ?? 0
        let selectedOpponentsHeroRow = self.heroes.indexOf(selectedOpponentsHero) ?? 0

        self.heroPicker.selectRow(selectedHeroRow, inComponent: HERO_PICKER, animated: false)
        self.heroPicker.selectRow(selectedOpponentsHeroRow, inComponent: OPPONENTS_HERO_PICKER, animated: false)
    }

    override func viewDidAppear(animated: Bool) {
        // check login
        TrackOBot.instance.getResults({
            (result) -> Void in
            switch result {
            case .Success(_):
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


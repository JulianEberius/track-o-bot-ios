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
    @IBOutlet weak var opponentPicker: UIPickerView!
    
    @IBOutlet weak var modeSwitch: UISegmentedControl!
    @IBOutlet weak var coinSwitch: UISegmentedControl!

    @IBOutlet weak var wonGameButton: UIButton!
    @IBOutlet weak var lostGameButton: UIButton!

    @IBOutlet weak var wonSucessCheckmark: UILabel!
    @IBOutlet weak var lostSucessCheckmark: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    let heroes = ["Warrior", "Shaman", "Rogue", "Paladin", "Hunter", "Druid", "Warlock", "Mage", "Priest"]
    var decks: [Deck] = []

    let HERO_PICKER = 0
    let DECK_PICKER = 1
//    let OPPONENTS_HERO_PICKER = 1
    let SELECTED_HERO = "selected_hero"
    let SELECTED_DECK = "selected_deck"
    let SELECTED_OPPONENTS_HERO = "selected_opponents_hero"
    let SELECTED_OPPONENTS_DECK = "selected_opponents_deck"
    let DEFAULT_HERO = "Hunter" // its the center one, i'm sorry

    @IBAction func wonGameButtonTouchUp(sender: UIButton) {
        saveGame(true);
    }

    @IBAction func lostGameButtonTouchUp(sender: UIButton) {
        saveGame(false);
    }
    
    func saveGame(won: Bool) {
        let yourHero = self.heroes[self.heroPicker.selectedRowInComponent(HERO_PICKER)]
        let opponentsHero = self.heroes[self.opponentPicker.selectedRowInComponent(HERO_PICKER)]

        let coin = self.coinSwitch.selectedSegmentIndex == 0
        let ranked = self.modeSwitch.selectedSegmentIndex == 0

        self.wonGameButton.enabled = false
        self.lostGameButton.enabled = false
        // self.activityIndicator.startAnimating()

        let game = Game(hero: yourHero, opponentsHero: opponentsHero, won: won, coin: coin)

        TrackOBot.instance.postResult(game, onComplete:{
            (result) -> Void in
            // self.activityIndicator.stopAnimating()
            self.wonGameButton.enabled = true
            self.lostGameButton.enabled = true
            let successCheckmark = won ? self.wonSucessCheckmark : self.lostSucessCheckmark
            switch result {
            case .Success:
                UIView.animateWithDuration(0.25, delay: 0.0, options:UIViewAnimationOptions.CurveEaseIn, animations: {
                    successCheckmark.alpha = 1.0
                    }, completion:nil)
                UIView.animateWithDuration(1.0, delay: 2.0, options:UIViewAnimationOptions.CurveEaseIn, animations: {
                    successCheckmark.alpha = 0.0
                    }, completion:nil)
            case .Failure(let err):
                let alert = UIAlertController.init(title: "Saving failed", message: "Could not save the game: \(err)", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true, completion: nil)
            }
        })
    }

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == HERO_PICKER {
            return 9
        }
        else {
            return 1
        }
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
        if (component == HERO_PICKER) {
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
        else
        {
            if let v = view as? UILabel {
                v.text = "Generic"
                return v
            } else {
                let v = UILabel(frame: CGRectMake(0, 0, 120, 32))
                v.text = "Generic"
                return v
            }
        }
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            let hero = self.heroes[row]
            if pickerView == heroPicker {
                defaults.setObject(hero, forKey: SELECTED_HERO)
            }
            else {
                defaults.setObject(hero, forKey: SELECTED_OPPONENTS_HERO)
            }
        }else if component == 1 {
            // let deck = self.decks[row]
            let deck = "Generic"
            if pickerView == heroPicker {
                defaults.setObject(deck, forKey: SELECTED_DECK)
            }
            else {
                defaults.setObject(deck, forKey: SELECTED_OPPONENTS_DECK)
            }
        }
    }

    @IBAction func unwindFromLogin(unwindSegue: UIStoryboardSegue) {

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.wonSucessCheckmark.alpha = 0
        self.lostSucessCheckmark.alpha = 0
//        self.addGameButton.enabled = true
//        self.errorLabel.alpha = 0

        let selectedHero = defaults.stringForKey(SELECTED_HERO) ?? DEFAULT_HERO
        let selectedDeck = defaults.stringForKey(SELECTED_DECK) ?? "Generic"
        let selectedOpponentsHero = defaults.stringForKey(SELECTED_OPPONENTS_HERO) ?? DEFAULT_HERO
        let selectedOpponentsDeck = defaults.stringForKey(SELECTED_OPPONENTS_DECK) ?? "Generic"

        let selectedHeroRow = self.heroes.indexOf(selectedHero) ?? 0
        let selectedDeckRow = 0
        let selectedOpponentsHeroRow = self.heroes.indexOf(selectedOpponentsHero) ?? 0
        let selectedOpponentsDeckRow = 0

        self.heroPicker.selectRow(selectedHeroRow, inComponent: HERO_PICKER, animated: false)
        self.heroPicker.selectRow(selectedDeckRow, inComponent: DECK_PICKER, animated: false)
        self.opponentPicker.selectRow(selectedOpponentsHeroRow, inComponent: HERO_PICKER, animated: false)
        self.opponentPicker.selectRow(selectedOpponentsDeckRow, inComponent: DECK_PICKER, animated: false)
        
    }

    override func viewDidAppear(animated: Bool) {
        // check login
        TrackOBot.instance.getDecks({
            (result) -> Void in
            switch result {
            case .Success(let decks):
                self.decks = decks
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


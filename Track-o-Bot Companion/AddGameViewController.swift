    //
//  FirstViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 07.09.15.
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

    
let HERO_PICKER = 0
let DECK_PICKER = 1

let SELECTED_HERO = "selected_hero"
let SELECTED_DECK = "selected_deck"
let SELECTED_OPPONENTS_HERO = "selected_opponents_hero"
let SELECTED_OPPONENTS_DECK = "selected_opponents_deck"
let SELECTED_RANK = "selected_rank"
    
let DEFAULT_HERO = "Hunter" // its the center one, i'm sorry
 
enum Player {
    case You
    case Opponent
}
    
class HeroAndDeckPickerViewController {
    
    let viewController: AddGameViewController
    let defaults: NSUserDefaults
    
    let pickerView: UIPickerView
    let player: Player
    let heroKey: String
    let deckKey: String
    
    init(viewController: AddGameViewController, pickerView: UIPickerView, player:Player) {
        self.viewController = viewController
        self.defaults = viewController.defaults
        
        self.pickerView = pickerView
        self.player = player
        
        switch self.player {
        case .You:
            heroKey = SELECTED_HERO
            deckKey = SELECTED_DECK
            break
        case .Opponent:
            heroKey = SELECTED_OPPONENTS_HERO
            deckKey = SELECTED_OPPONENTS_DECK
            break
        }
    }
    
    func selectedHero() -> String {
        return HEROES[pickerView.selectedRowInComponent(HERO_PICKER)]
    }
    
    func didSelectRow(row: Int, inComponent component: Int) {
        if component == 0 {
            let hero = HEROES[row]
            pickerView.reloadComponent(DECK_PICKER)
            var selectedDeck: String? = nil
            
            defaults.setObject(hero, forKey: heroKey)
            selectedDeck = defaults.stringForKey(deckKey+"_"+hero)
            
            let deckRow = deckRowFor(selectedDeck, andHeroRow: row)
            if let i = deckRow {
                pickerView.selectRow(i, inComponent: DECK_PICKER, animated: true)
            }
        }
        else if component == 1 {
            guard let (hero, deck) = selectedDeck(pickerView) else {
                return
            }
            defaults.setObject(deck, forKey: deckKey+"_"+hero)
        }
    }
    
    func update() {
        let selectedHero = defaults.stringForKey(heroKey) ?? DEFAULT_HERO
        let selectedDeck = defaults.stringForKey(deckKey+"_"+selectedHero) ?? nil
        
        let selectedHeroRow = HEROES.indexOf(selectedHero) ?? HEROES.count / 2
        let selectedDeckRow = deckRowFor(selectedDeck, andHeroRow: selectedHeroRow)
        
        pickerView.selectRow(selectedHeroRow, inComponent: HERO_PICKER, animated: false)
        pickerView.reloadComponent(DECK_PICKER)
        if let x = selectedDeckRow {
            pickerView.selectRow(x, inComponent: DECK_PICKER, animated: false)
        }
    }
    
    private func selectedDeck(pickerView: UIPickerView) -> (String, String)? {
        let selectedHeroRow = pickerView.selectedRowInComponent(HERO_PICKER)
        let selectedDeckRow = pickerView.selectedRowInComponent(DECK_PICKER)
        
        let hero = HEROES[selectedHeroRow]
        let decks = viewController.deckNames[selectedHeroRow]
        if decks.count == 0 || selectedDeckRow == 0 {
            return nil
        }
        
        return (hero, decks[selectedDeckRow - 1])
    }
    
    private func deckRowFor(selectedDeck: String?, andHeroRow heroRow: Int) -> Int? {
        guard let d = selectedDeck else {
            return nil
        }
        if let idx = viewController.deckNames[heroRow].indexOf(d) {
            return idx + 1
        }
        return nil
    }
    
}
    
class AddGameViewController: TrackOBotViewController, UIPickerViewDelegate, UIPickerViewDataSource {


    @IBOutlet weak var heroPicker: UIPickerView!
    @IBOutlet weak var opponentPicker: UIPickerView!
    
    @IBOutlet weak var literalRankLabel: UILabel!
    @IBOutlet weak var rankLabel: UILabel!
    @IBOutlet weak var rankStepper: UIStepper!
    
    @IBOutlet weak var modeSwitch: UISegmentedControl!
    @IBOutlet weak var coinSwitch: UISwitch!
    
    @IBOutlet weak var wonGameButton: UIButton!
    @IBOutlet weak var lostGameButton: UIButton!

    @IBOutlet weak var wonSucessCheckmark: UILabel!
    @IBOutlet weak var lostSucessCheckmark: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIStackView!
    
    @IBOutlet weak var youLabel: UILabel!
    @IBOutlet weak var opponentLabel: UILabel!

    private var lastCommittedGame: (Game, NSDate)? = nil
    
    // TODO: move to TrackOBot class
    var decks = Array(count: HEROES.count, repeatedValue: [Deck]())
    var deckNames = Array(count: HEROES.count, repeatedValue: [String]())

    var controllers = [UIPickerView: HeroAndDeckPickerViewController]()
    
    override func viewDidLayoutSubviews()
    {
        wonGameButton.layer.cornerRadius = 5
        wonGameButton.layer.borderWidth = 1
        wonGameButton.layer.borderColor = UIColor.brownColor().CGColor
        
        lostGameButton.layer.cornerRadius = 5
        lostGameButton.layer.borderWidth = 1
        lostGameButton.layer.borderColor = UIColor.brownColor().CGColor
    }


    @IBAction func wonGameButtonTouchUp(sender: UIButton) {
        saveGame(true);
    }

    @IBAction func lostGameButtonTouchUp(sender: UIButton) {
        saveGame(false);
    }
    

    @IBAction func modeChanged(sender: UISegmentedControl) {
        switch (sender.selectedSegmentIndex) {
        case 0:
            self.rankStepper.enabled = true
            self.rankStepper.tintColor = self.view.tintColor
            self.literalRankLabel.textColor = self.view.tintColor
            self.rankLabel.textColor = self.view.tintColor
            break;
        default:
            self.rankStepper.enabled = false
            self.rankStepper.tintColor = UIColor.grayColor()
            self.literalRankLabel.textColor = UIColor.grayColor()
            self.rankLabel.textColor = UIColor.grayColor()
            break;
        }
    }
    
    func saveGame(won: Bool) {
        let yourHeroIdx = self.heroPicker.selectedRowInComponent(HERO_PICKER)
        let yourHero = HEROES[yourHeroIdx]
        let opponentsHeroIdx = self.opponentPicker.selectedRowInComponent(HERO_PICKER)
        let opponentsHero = HEROES[opponentsHeroIdx]

        let deckIdx = self.heroPicker.selectedRowInComponent(DECK_PICKER)
        let yourDeckId:Int? = deckIdx > 0 ? self.decks[yourHeroIdx][deckIdx-1].id : nil
        let opponentsDeckIdx = self.opponentPicker.selectedRowInComponent(DECK_PICKER)
        let opponentsDeckId:Int? = opponentsDeckIdx > 0 ? self.decks[opponentsHeroIdx][opponentsDeckIdx-1].id : nil

        let coin = self.coinSwitch.on
        let mode = (self.modeSwitch.selectedSegmentIndex == 0) ? GameMode.Ranked : (self.modeSwitch.selectedSegmentIndex == 1 ) ? GameMode.Casual : GameMode.Arena;

        let rankStepperValue = Int(self.rankStepper.value)
        let rank: Int? = (mode == GameMode.Ranked && rankStepperValue > 0) ? rankStepperValue : nil
        // unsupported for now, as manual entry to cumbersome
        let legend: Int? = (mode == GameMode.Ranked && Int(self.rankStepper.value) == 0) ?  0 : nil

        let game = Game(id: nil, hero: yourHero, opponentsHero: opponentsHero, deck: nil, deckId: yourDeckId, opponentsDeck: nil, opponentsDeckId:  opponentsDeckId, won: won, coin: coin, mode: mode, rank: rank, legend: legend)

        if let (lastGame, lastGameTime) = self.lastCommittedGame where
            game == lastGame && NSDate().timeIntervalSinceDate(lastGameTime) < NSTimeInterval(7) {

            let alert = UIAlertController.init(title: "Possible duplicate game", message: "You saved the same result less than two minutes ago. Continue anyway?", preferredStyle: UIAlertControllerStyle.Alert)
            let okAction = UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.Default) { (action) in
                self.doSaveGame(game)
            }
            alert.addAction(okAction)
            let cancelAction = UIAlertAction.init(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            self.doSaveGame(game)
        }
    }

    func doSaveGame(game:Game) {
        self.wonGameButton.enabled = false
        self.lostGameButton.enabled = false
        // self.activityIndicator.startAnimating()

        TrackOBot.instance.postResult(game, onComplete:{
            (result) -> Void in
            // self.activityIndicator.stopAnimating()
            self.wonGameButton.enabled = true
            self.lostGameButton.enabled = true
            let successCheckmark = game.won == true ? self.wonSucessCheckmark : self.lostSucessCheckmark
            switch result {
            case .Success:
                // update UI
                UIView.animateWithDuration(0.25, delay: 0.0, options:UIViewAnimationOptions.CurveEaseIn, animations: {
                    successCheckmark.alpha = 1.0
                    }, completion:nil)
                UIView.animateWithDuration(1.0, delay: 2.0, options:UIViewAnimationOptions.CurveEaseIn, animations: {
                    successCheckmark.alpha = 0.0
                    }, completion:nil)
                // store the game to prevent accidental double commits
                self.lastCommittedGame = (game, NSDate())
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
            let deckCount = self.decks[pickerView.selectedRowInComponent(HERO_PICKER)].count
            if (deckCount == 0)
            {
              return 1 // for the "generic deck" label
            }
            else
            {
              return deckCount + 1
            }
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
            let hero = HEROES[row]
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
            let heroRow = pickerView.selectedRowInComponent(HERO_PICKER)
            let heroName = HEROES[heroRow]
            let deckNames = self.deckNames[heroRow]
            let deckName = ((deckNames.count > 0) && (row > 0)) ? deckNames[row - 1] : "Other \(heroName)"
            if let v = view as? UILabel {
                v.text = deckName
                return v
            } else {
                let v = UILabel(frame: CGRectMake(0, 0, 120, 32))
                v.text = deckName
                return v
            }
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        controllers[pickerView]?.didSelectRow(row, inComponent: component)

    }

    @IBAction func rankStepperValueChanged(sender: UIStepper) {
        let val = Int(sender.value)
        if (val == 0){
            rankLabel.text = "L"
        } else {
            rankLabel.text = "\(val)"
        }
        
        defaults.setInteger(val, forKey: SELECTED_RANK)
    }
    
    @IBAction func unwindFromLogin(unwindSegue: UIStoryboardSegue) {

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.wonSucessCheckmark.alpha = 0
        self.lostSucessCheckmark.alpha = 0
        
//        self.youLabel.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
//        self.opponentLabel.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))

        controllers[heroPicker] = HeroAndDeckPickerViewController(viewController: self, pickerView: heroPicker, player: Player.You)
        controllers[opponentPicker] = HeroAndDeckPickerViewController(viewController: self, pickerView: opponentPicker, player: Player.Opponent)
        
        let selectedRank = defaults.hasKey(SELECTED_RANK) ? defaults.integerForKey(SELECTED_RANK) : 25
        rankStepper.value = Double(selectedRank)
        rankStepperValueChanged(rankStepper)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // check login
        TrackOBot.instance.getDecks({
            (result) -> Void in
            switch result {
            case .Success(let decks):
                self.decks = decks
                self.deckNames = decks.map { hd in hd.map { d in d.name } }
                break
            case .Failure(let err):
                switch err {
                case .CredentialsMissing, .LoginFailed(_):
                    self.performSegueWithIdentifier("to_login", sender: self)
                default:
                    self.alert("Error retrieving decks", message: "Sorry, the list of available decks could not be retrieved from trackobot.com. If the error persists, please contact trackobot.ios@gmail.com.")
                }
            }

            self.updateUI()
        })
    }
    
    private func updateUI() {
        controllers[heroPicker]?.update()
        controllers[opponentPicker]?.update()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
    
extension NSUserDefaults {
    func hasKey(key: String) -> Bool {
        return objectForKey(key) != nil
    }
}




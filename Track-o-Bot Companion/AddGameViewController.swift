    //
//  FirstViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 07.09.15.
//  Copyright (c) 2015 Julian Eberius. All rights reserved.
//

import UIKit

    
let HERO_PICKER = 0
let DECK_PICKER = 1

let SELECTED_HERO = "selected_hero"
let SELECTED_DECK = "selected_deck"
let SELECTED_OPPONENTS_HERO = "selected_opponents_hero"
let SELECTED_OPPONENTS_DECK = "selected_opponents_deck"
    
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
        if decks.count == 0 {
            return nil
        }
        
        return (hero, decks[selectedDeckRow])
    }
    
    private func deckRowFor(selectedDeck: String?, andHeroRow heroRow: Int) -> Int? {
        guard let d = selectedDeck else {
            return nil
        }
        return viewController.deckNames[heroRow].indexOf(d)
    }
    
}
    
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
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIStackView!
    
    // TODO: move to TrackOBot
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
        
        if (contentView.bounds.height < scrollView.bounds.height) {
            let scrollViewBounds = scrollView.bounds
            
            var scrollViewInsets = UIEdgeInsetsZero
            scrollViewInsets.top = scrollViewBounds.size.height/2.0;
            scrollViewInsets.top -= contentView.bounds.size.height/2.0;
            
            scrollViewInsets.bottom = scrollViewBounds.size.height/2.0
            scrollViewInsets.bottom -= contentView.bounds.size.height/2.0;
            
            scrollView.contentInset = scrollViewInsets
        }
    }


    @IBAction func wonGameButtonTouchUp(sender: UIButton) {
        saveGame(true);
    }

    @IBAction func lostGameButtonTouchUp(sender: UIButton) {
        saveGame(false);
    }
    
    func saveGame(won: Bool) {
        let yourHero = HEROES[self.heroPicker.selectedRowInComponent(HERO_PICKER)]
        let opponentsHero = HEROES[self.opponentPicker.selectedRowInComponent(HERO_PICKER)]

        let coin = self.coinSwitch.selectedSegmentIndex == 0
        let mode = (self.modeSwitch.selectedSegmentIndex == 0) ? GameMode.Ranked : GameMode.Casual;

        self.wonGameButton.enabled = false
        self.lostGameButton.enabled = false
        // self.activityIndicator.startAnimating()

        let game = Game(id: nil, hero: yourHero, opponentsHero: opponentsHero, won: won, coin: coin, mode: mode)

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
            let deckCount = self.decks[pickerView.selectedRowInComponent(HERO_PICKER)].count
            if (deckCount == 0)
            {
              return 1 // for the "generic deck" label
            }
            else
            {
              return deckCount
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
            let deckNames = self.deckNames[pickerView.selectedRowInComponent(HERO_PICKER)]
            let deckName = deckNames.count > 0 ? deckNames[row] : "..."
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

    @IBAction func unwindFromLogin(unwindSegue: UIStoryboardSegue) {

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        controllers[heroPicker] = HeroAndDeckPickerViewController(viewController: self, pickerView: heroPicker, player: Player.You)
        controllers[opponentPicker] = HeroAndDeckPickerViewController(viewController: self, pickerView: opponentPicker, player: Player.Opponent)
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
                case .CredentialsMissing, .LoginFaild(_):
                    self.performSegueWithIdentifier("to_login", sender: self)
                default:
                    print("what")
                }
            }

            self.updateUI()
        })
    }
    
    private func updateUI() {
        self.wonSucessCheckmark.alpha = 0
        self.lostSucessCheckmark.alpha = 0
        
        controllers[heroPicker]?.update()
        controllers[opponentPicker]?.update()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


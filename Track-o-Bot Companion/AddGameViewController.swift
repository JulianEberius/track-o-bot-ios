//
//  FirstViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 07.09.15.
//  Copyright (c) 2015 Julian Eberius. All rights reserved.
//

import UIKit

class AddGameViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {


    @IBOutlet weak var heroPicker: UIPickerView!

    @IBOutlet weak var wonSwitch: UISwitch!
    @IBOutlet weak var coinSwitch: UISwitch!

    @IBOutlet weak var addGameButton: UIButton!

    @IBOutlet weak var sucessLabel: UILabel!

    let heroes = ["Warrior", "Shaman", "Rogue", "Paladin", "Hunter", "Druid", "Warlock", "Mage", "Priest"]
    let defaults = NSUserDefaults.standardUserDefaults()

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
        TrackOBot.postResult(yourHero, opponentsHero:opponentsHero, won:won, coin:coin, onComplete:{
            (res, err) -> Void in
            if let error = err {
                println("finished request with ERROR: \(error)")
            }
            else if let result = res {
                println("finished request, result:  \(result)")
                UIView.animateWithDuration(0.25, delay: 0.0, options:UIViewAnimationOptions.CurveEaseIn, animations: {
                    self.sucessLabel.alpha = 1.0
                    }, completion:nil)
                UIView.animateWithDuration(1.0, delay: 2.0, options:UIViewAnimationOptions.CurveEaseIn, animations: {
                    self.sucessLabel.alpha = 0.0
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

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return self.heroes[row]

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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addGameButton.enabled = true
        self.sucessLabel.alpha = 0

        let selectedHero = defaults.stringForKey(SELECTED_HERO) ?? DEFAULT_HERO
        let selectedOpponentsHero = defaults.stringForKey(SELECTED_OPPONENTS_HERO) ?? DEFAULT_HERO
        let selectedHeroRow = find(self.heroes, selectedHero) ?? 0
        let selectedOpponentsHeroRow = find(self.heroes, selectedOpponentsHero) ?? 0
        self.heroPicker.selectRow(selectedHeroRow, inComponent: HERO_PICKER, animated: false)
        self.heroPicker.selectRow(selectedOpponentsHeroRow, inComponent: OPPONENTS_HERO_PICKER, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


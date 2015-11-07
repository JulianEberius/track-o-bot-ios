//
//  HistoryViewController.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 08.09.15.
//  Copyright © 2015 Julian Eberius. All rights reserved.
//

import UIKit


class HistoryViewController: TrackOBotViewController, UITableViewDataSource, UITableViewDelegate {

    var games = [Game]()

    let WIN_COLOR = UIColor(red: 0, green: 1.0, blue: 0, alpha: 0.8)
    let LOSS_COLOR = UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.8)

    @IBOutlet weak var historyTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        refreshData()
    }
    
    @IBAction func unwindFromLogin(unwindSegue: UIStoryboardSegue) {
        
    }

    func refreshData() {
        TrackOBot.instance.getResults({
            (result) -> Void in
            switch result {
            case .Success(let games):
                self.games = games
                self.historyTableView.reloadData()
                self.historyTableView.flashScrollIndicators()
            case .Failure(let err):
                print("ERROR \(err)")
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.games.count;
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("matchCell", forIndexPath: indexPath) as! ResultTableViewCell
        let match = self.games[indexPath.item]
        cell.heroImageView.image = UIImage(named: "\(match.hero)")
        cell.opponentsHeroImageView.image = UIImage(named: "\(match.opponentsHero)")
        cell.heroLabel.text = match.hero
        cell.opponentsHeroLabel.text = match.opponentsHero
        if let won = match.won {
            if (won) {
                cell.winLabel.text = "Win"
                cell.winLabel.textColor = WIN_COLOR
            } else {
                cell.winLabel.text = "Loss"
                cell.winLabel.textColor = LOSS_COLOR
            }
        } else {
            cell.winLabel.text = ""
        }
        cell.timeLabel.text = match.timeLabel
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            self.games.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        default:
            break
        }
        
    }


    
}

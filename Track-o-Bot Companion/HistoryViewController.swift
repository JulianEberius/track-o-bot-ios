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
    var total_count: Int = 0
    var retrieved_pages: Int = 0
    var max_requested_idx : Int = 0
    var retrieving = false

    let WIN_COLOR = UIColor(red: 0, green: 1.0, blue: 0, alpha: 0.8)
    let LOSS_COLOR = UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.8)

    @IBOutlet weak var historyTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        resetView()
    }
    
    @IBAction func unwindFromLogin(unwindSegue: UIStoryboardSegue) {
        
    }
    
    func resetView() {
        self.historyTableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
        
        self.games = [Game]()
        self.total_count = 0
        self.retrieved_pages = 0
        self.max_requested_idx = 0
        self.retrieving = false
        
        retrievePage(1)
    }
    
    func retrieveNextPage() {
        retrievePage(self.retrieved_pages + 1)
    }

    func retrievePage(page: Int) {
        retrieving = true
        print("retrieving paged \(page)")
        TrackOBot.instance.getResults(page, onComplete: {
            (result) -> Void in
            self.retrieving = false
            switch result {
            case .Success(let historyPage):
                print("retrieved page \(page)")
                if (historyPage.page == self.retrieved_pages+1) {
                    print("adding games \(self.games.count) to \(self.games.count + historyPage.games.count) ")
                    self.games += historyPage.games
                    self.retrieved_pages = historyPage.page;
                }
                self.total_count = historyPage.totalCount
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
        return self.total_count;
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("matchCell", forIndexPath: indexPath) as! ResultTableViewCell
        if (indexPath.item >= self.games.count) {
            if (indexPath.item > max_requested_idx) {
                if (!retrieving) {
                    max_requested_idx = indexPath.item
                    self.retrieveNextPage()
                }
            }
            
            // "loading" cell
            cell.heroImageView.image = nil
            cell.opponentsHeroImageView.image = nil
            cell.heroLabel.text = ""
            cell.opponentsHeroLabel.text = ""
            cell.winLabel.text = "Loading"
            cell.timeLabel.text = ""
            return cell
        }
        else
        {
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
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true;
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch editingStyle {
        case .Delete:
            let game = self.games[indexPath.row]

            TrackOBot.instance.deleteResult(game.id, onComplete: {
                (result) -> Void in
                switch result {
                case .Success:
                    self.games.removeAtIndex(indexPath.row)
                    self.total_count -= 1
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
                case .Failure(let err):
                    print("ERROR \(err)")
                }
            })
            
        default:
            break
        }
    }
}

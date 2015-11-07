//
//  ResultTableViewCell.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 10.09.15.
//  Copyright © 2015 Julian Eberius. All rights reserved.
//

import UIKit

class ResultTableViewCell: UITableViewCell {

    @IBOutlet weak var heroImageView: UIImageView!
    @IBOutlet weak var opponentsHeroImageView: UIImageView!
    @IBOutlet weak var heroLabel: UILabel!
    @IBOutlet weak var opponentsHeroLabel: UILabel!
    @IBOutlet weak var winLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

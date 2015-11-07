//
//  HeroPickerItem.swift
//  Track-o-Bot Companion
//
//  Created by Julian Eberius on 11.09.15.
//  Copyright © 2015 Julian Eberius. All rights reserved.
//

import UIKit

class HeroPickerItem: UIView {
    
    let label: UILabel!
    let imageView: UIImageView!
    
    override init(frame: CGRect) {
        imageView = UIImageView(frame: CGRectMake(0, 0, 32, 32))
        label = UILabel(frame: CGRectMake(32, 0, frame.width-32, 32))
        
        super.init(frame: frame)
        
        self.addSubview(imageView)
        self.addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

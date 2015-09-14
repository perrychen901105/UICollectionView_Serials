//
//  FlickrPhotoCell.swift
//  FlickrSearch
//
//  Created by chenzhipeng on 9/14/15.
//  Copyright (c) 2015 PerryChen. All rights reserved.
//

import UIKit

class FlickrPhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selected = false
    }
    
    override var selected : Bool {
        didSet {
            self.backgroundColor = selected ? themeColor : UIColor.blackColor()
        }
    }
}

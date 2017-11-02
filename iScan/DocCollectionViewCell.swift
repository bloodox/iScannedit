//
//  DocCollectionViewCell.swift
//  iScan
//
//  Created by William Thompson on 2/10/17.
//  Copyright © 2017 William Thompson. All rights reserved.
//

import UIKit

class DocCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    var imageName: String! {
        didSet {
            imageView.image = UIImage(named: imageName)
        }
    }
}

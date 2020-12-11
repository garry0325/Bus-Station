//
//  NearbyBusesCollectionViewCell.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/12/10.
//

import UIKit

class NearbyBusesCollectionViewCell: UICollectionViewCell {
    
	var routeName: String = "" {
		didSet {
			routeNameLabel.text = routeName
		}
	}
	var plateNumber: String = "" {
		didSet {
			plateNumberLabel.setTitle(" " + plateNumber + " ", for: .normal)
		}
	}
	var distance: Int = -1 {
		didSet {
			if(distance >= 0) {
				distanceLabel.text = String(format: "%dm", distance)
			} else {
				distanceLabel.text = ""
			}
		}
	}
	@IBOutlet var routeNameLabel: UILabel!
	@IBOutlet var plateNumberLabel: UIButton!
	@IBOutlet var distanceLabel: UILabel!
	
	override func awakeFromNib() {
		plateNumberLabel.layer.cornerRadius = 3.0
		plateNumberLabel.layer.masksToBounds = true
		plateNumberLabel.layer.backgroundColor = PlateNumberBackgroundColor.cgColor
		plateNumberLabel.imageView?.contentMode = .scaleAspectFit
		plateNumberLabel.imageEdgeInsets = UIEdgeInsets(top: 3.0, left: 0.0, bottom: 3.0, right: 0.0)
		plateNumberLabel.titleLabel?.adjustsFontSizeToFitWidth = true
		plateNumberLabel.backgroundColor = PlateNumberBackgroundColor
		plateNumberLabel.titleLabel?.font = UIFont(name: "Roadgeek2005SeriesD", size: 12.0)
	}
	
}

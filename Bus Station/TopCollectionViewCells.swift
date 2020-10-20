//
//  StationListCollectionViewCell.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/19.
//

import UIKit

class StationListCollectionViewCell: UICollectionViewCell {
	@IBOutlet var stationLabel: UILabel!
	var stationName: String = "" {
		didSet {
			stationLabel.text = stationName
		}
	}
}

class BearingListCollectionViewCell: UICollectionViewCell {
	@IBOutlet var bearingLabel: UILabel!
	var bearingName: String = "" {
		didSet {
			bearingLabel.text = bearingName
		}
	}
}

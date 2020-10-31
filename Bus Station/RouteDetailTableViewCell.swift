//
//  RouteDetailTableViewCell.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/31.
//

import UIKit

class RouteDetailTableViewCell: UITableViewCell {

	var stopName = "" {
		didSet {
			stopNameLabel.text = stopName
		}
	}
	var eventType: BusStopLiveStatus.EventType = .Unknown {
		didSet {
			switch eventType {
			case .Arriving:
				busTowardsStopImage.isHidden = false
				busAtStopImage.isHidden = true
			case .Departing:
				busTowardsStopImage.isHidden = true
				busAtStopImage.isHidden = false
			default:
				busTowardsStopImage.isHidden = true
				busAtStopImage.isHidden = true
			}
		}
	}
	
	@IBOutlet var stopNameLabel: UILabel!
	@IBOutlet var busTowardsStopImage: UIImageView!
	@IBOutlet var busAtStopImage: UIImageView!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

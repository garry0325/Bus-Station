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
				busTowardsStopView.isHidden = false
				busAtStopView.isHidden = true
			case .Departing:
				busTowardsStopView.isHidden = true
				busAtStopView.isHidden = false
			default:
				busTowardsStopView.isHidden = true
				busAtStopView.isHidden = true
			}
		}
	}
	
	var isCurrentStop = false {
		didSet {
			currentStopIndicatorView.isHidden = !isCurrentStop
			routeNodeView.tintColor = isCurrentStop ? .systemBlue:.systemGray
		}
	}
	var isDepartureStop = false {
		didSet {
			routeLineUp.isHidden = isDepartureStop
		}
	}
	var isDestinationStop = false {
		didSet {
			routeLineBottom.isHidden = isDestinationStop
		}
	}
	
	@IBOutlet var stopNameLabel: UILabel!
	@IBOutlet var busTowardsStopView: UIImageView!
	@IBOutlet var busAtStopView: UIImageView!
	@IBOutlet var routeNodeView: UIImageView!
	@IBOutlet var currentStopIndicatorView: UIImageView!
	@IBOutlet var routeLineUp: UIImageView!
	@IBOutlet var routeLineBottom: UIImageView!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

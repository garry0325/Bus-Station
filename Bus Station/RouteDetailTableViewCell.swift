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
				plateTowardsStopLabel.isHidden = false
				plateAtStopLabel.isHidden = true
			case .Departing:
				busTowardsStopView.isHidden = true
				busAtStopView.isHidden = false
				plateTowardsStopLabel.isHidden = true
				plateAtStopLabel.isHidden = false
			default:
				busTowardsStopView.isHidden = true
				busAtStopView.isHidden = true
				plateTowardsStopLabel.isHidden = true
				plateAtStopLabel.isHidden = true
			}
		}
	}
	var plateNumber: String = "" {
		didSet {
			plateTowardsStopLabel.text = " " + plateNumber + " "
			plateAtStopLabel.text = " " + plateNumber + " "
		}
	}
	
	var isCurrentStop = false {
		didSet {
			currentStopIndicatorView.isHidden = !isCurrentStop
			stopNameLabel.font = isCurrentStop ? UIFont.systemFont(ofSize: 20.0, weight: .bold):UIFont.systemFont(ofSize: 17.0, weight: .regular)
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
	@IBOutlet var plateTowardsStopLabel: UILabel!
	@IBOutlet var plateAtStopLabel: UILabel!
	@IBOutlet var routeNodeView: UIImageView!
	@IBOutlet var currentStopIndicatorView: UIImageView!
	@IBOutlet var routeLineUp: UIImageView!
	@IBOutlet var routeLineBottom: UIImageView!
	
	override func awakeFromNib() {
        super.awakeFromNib()
		
		plateTowardsStopLabel.layer.cornerRadius = 3.0
		plateAtStopLabel.layer.cornerRadius = 3.0
		plateTowardsStopLabel.layer.masksToBounds = true
		plateAtStopLabel.layer.masksToBounds = true
		
		currentStopIndicatorView.tintColor = .white
		currentStopIndicatorView.layer.borderColor = UIColor.systemBlue.cgColor
		currentStopIndicatorView.layer.cornerRadius = currentStopIndicatorView.frame.width / 2
		currentStopIndicatorView.layer.borderWidth = 5.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}

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
			switch eventType {	// 0 Departing, 1 Arriving in actual situation
			case .Arriving:
				busAtStopView.isHidden = false
				busDepartStopView.isHidden = true
				plateAtStopLabel.isHidden = false
				plateDepartStopLabel.isHidden = true
			case .Departing:
				busAtStopView.isHidden = true
				busDepartStopView.isHidden = false
				plateAtStopLabel.isHidden = true
				plateDepartStopLabel.isHidden = false
			default:
				busAtStopView.isHidden = true
				busDepartStopView.isHidden = true
				plateAtStopLabel.isHidden = true
				plateDepartStopLabel.isHidden = true
			}
		}
	}
	var plateNumber: String = ""
	var information: String = ""
	var informationLabelColor: UIColor = RouteInformationLabelColors.gray
	
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
	
	var presentInformation = true {
		didSet {
			if(presentInformation) {
				if(information == "") {
					plateAtStopLabel.isHidden = true
					plateDepartStopLabel.isHidden = true
				}
				plateAtStopLabel.text = " " + information + " "
				plateDepartStopLabel.text = " " + information + " "
				plateAtStopLabel.backgroundColor = informationLabelColor
				plateDepartStopLabel.backgroundColor = informationLabelColor
				plateAtStopLabel.font = UIFont.systemFont(ofSize: 16.0)
				plateDepartStopLabel.font = UIFont.systemFont(ofSize: 16.0)
			}
			else {
				plateAtStopLabel.text = " " + plateNumber + " "
				plateDepartStopLabel.text = " " + plateNumber + " "
				plateAtStopLabel.backgroundColor = UIColor.lightGray
				plateDepartStopLabel.backgroundColor = UIColor.lightGray
				plateAtStopLabel.font = UIFont(name: "Roadgeek2005SeriesD", size: 17.0)
				plateDepartStopLabel.font = UIFont(name: "Roadgeek2005SeriesD", size: 17.0)
			}
		}
	}
	
	@IBOutlet var stopNameLabel: UILabel!
	@IBOutlet var busAtStopView: UIImageView!
	@IBOutlet var busDepartStopView: UIImageView!
	@IBOutlet var plateAtStopLabel: UILabel!
	@IBOutlet var plateDepartStopLabel: UILabel!
	@IBOutlet var routeNodeView: UIImageView!
	@IBOutlet var currentStopIndicatorView: UIImageView!
	@IBOutlet var routeLineUp: UIImageView!
	@IBOutlet var routeLineBottom: UIImageView!
	
	override func awakeFromNib() {
        super.awakeFromNib()
		
		plateAtStopLabel.layer.cornerRadius = 3.0
		plateDepartStopLabel.layer.cornerRadius = 3.0
		plateAtStopLabel.layer.masksToBounds = true
		plateDepartStopLabel.layer.masksToBounds = true
		plateAtStopLabel.layer.backgroundColor = UIColor.lightGray.cgColor
		plateDepartStopLabel.layer.backgroundColor = UIColor.lightGray.cgColor
		
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

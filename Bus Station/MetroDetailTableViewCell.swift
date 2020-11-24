//
//  MetroTableViewCell.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/11/24.
//

import UIKit

class MetroDetailTableViewCell: UITableViewCell {
	
	var stationName = "" {
		didSet {
			stationNameLabel.text = stationName
		}
	}
	var isCurrentStation = false {
		didSet {
			currentStationIndicatorView.isHidden = !isCurrentStation
			stationNameLabel.font = isCurrentStation ? UIFont.systemFont(ofSize: 20.0, weight: .bold):UIFont.systemFont(ofSize: 17.0, weight: .regular)
		}
	}
	var isDepartureStation = false {
		didSet {
			routeLineUp.isHidden = isDepartureStation
		}
	}
	var isDestinationStation = false {
		didSet {
			routeLineBottom.isHidden = isDestinationStation
		}
	}
	var lineColor: UIColor = RouteInformationLabelColors.gray {
		didSet {
			routeNodeView.tintColor = lineColor
			currentStationIndicatorView.tintColor = lineColor
			currentStationIndicatorView.layer.borderColor = lineColor.cgColor
			routeLineUp.backgroundColor = lineColor
			routeLineBottom.backgroundColor = lineColor
		}
	}
	
	@IBOutlet var stationNameLabel: UILabel!
	@IBOutlet var metroAtStopButton: UIButton!
	@IBOutlet var metroDepartStopButton: UIButton!
	@IBOutlet var infoAtStop: UILabel!
	@IBOutlet var infoDepartStop: UILabel!
	@IBOutlet var routeNodeView: UIImageView!
	@IBOutlet var currentStationIndicatorView: UIImageView!
	@IBOutlet var routeLineUp: UIImageView!
	@IBOutlet var routeLineBottom: UIImageView!
	
	
    override func awakeFromNib() {
        super.awakeFromNib()
        
		metroAtStopButton.isHidden = true
		metroDepartStopButton.isHidden = true
		infoAtStop.isHidden = true
		infoDepartStop.isHidden = true
		
		currentStationIndicatorView.layer.cornerRadius = currentStationIndicatorView.frame.width / 2
		currentStationIndicatorView.layer.borderWidth = 5.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

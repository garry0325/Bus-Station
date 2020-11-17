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
				busAtStopButton.isHidden = false
				busDepartStopButton.isHidden = true
				infoAtStop.isHidden = false
				infoDepartStop.isHidden = true
				plateAtStopLabel.isHidden = false
				plateDepartStopLabel.isHidden = true
			case .Departing:
				busAtStopButton.isHidden = true
				busDepartStopButton.isHidden = false
				infoAtStop.isHidden = true
				infoDepartStop.isHidden = false
				plateAtStopLabel.isHidden = true
				plateDepartStopLabel.isHidden = false
			default:
				busAtStopButton.isHidden = true
				busDepartStopButton.isHidden = true
				infoAtStop.isHidden = true
				infoDepartStop.isHidden = true
				plateAtStopLabel.isHidden = true
				plateDepartStopLabel.isHidden = true
		}
		}
	}
	var plateNumber: String = ""
	var vehicleType: BusStopLiveStatus.VehicleType = .General
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
	
	var selectedBusIndex = 0
	var mode: RouteDetailViewController.ContentMode = .ETAForCurrentStation {	// present information or plate number
		didSet {
			switch mode {
			case .ETAForCurrentStation:
				plateAtStopLabel.isHidden = true
				plateDepartStopLabel.isHidden = true
				
				if(information == "") {
					infoAtStop.isHidden = true
					infoDepartStop.isHidden = true
				}
				
				infoAtStop.text = " " + information + " "
				infoDepartStop.text = " " + information + " "
				infoAtStop.backgroundColor = informationLabelColor
				infoDepartStop.backgroundColor = informationLabelColor
				allStationETAModeIndicator.isHidden = true
				
			case .PlateNumber:
				infoAtStop.isHidden = true
				infoDepartStop.isHidden = true
				
				if(vehicleType == .Accessible) {
					plateAtStopLabel.setImage(UIImage(named: "disabled"), for: .normal)
					plateDepartStopLabel.setImage(UIImage(named: "disabled"), for: .normal)
				}
				else {
					plateAtStopLabel.setImage(nil, for: .normal)
					plateDepartStopLabel.setImage(nil, for: .normal)
				}
				
				plateAtStopLabel.setTitle(" " + plateNumber + " ", for: .normal)
				plateDepartStopLabel.setTitle(" " + plateNumber + " ", for: .normal)
				allStationETAModeIndicator.isHidden = true
				
			case .ETAForEveryStation:
				plateAtStopLabel.isHidden = true
				plateDepartStopLabel.isHidden = true
				infoAtStop.isHidden = (self.tag > selectedBusIndex) ? false:true
				infoDepartStop.isHidden = true
				
				infoAtStop.text = information
				infoAtStop.backgroundColor = allStationETAModeIndicator.tintColor
				allStationETAModeIndicator.isHidden = (self.tag != selectedBusIndex)
			}
		}
	}
	
	@IBOutlet var stopNameLabel: UILabel!
	@IBOutlet var busAtStopButton: UIButton!
	@IBOutlet var busDepartStopButton: UIButton!
	@IBOutlet var allStationETAModeIndicator: UIImageView!
	@IBOutlet var plateAtStopLabel: UIButton!
	@IBOutlet var plateDepartStopLabel: UIButton!
	@IBOutlet var infoAtStop: UILabel!
	@IBOutlet var infoDepartStop: UILabel!
	@IBOutlet var routeNodeView: UIImageView!
	@IBOutlet var currentStopIndicatorView: UIImageView!
	@IBOutlet var routeLineUp: UIImageView!
	@IBOutlet var routeLineBottom: UIImageView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		infoAtStop.layer.cornerRadius = 3.0
		infoDepartStop.layer.cornerRadius = 3.0
		infoAtStop.layer.masksToBounds = true
		infoDepartStop.layer.masksToBounds = true
		infoAtStop.layer.backgroundColor = UIColor.lightGray.cgColor
		infoDepartStop.layer.backgroundColor = UIColor.lightGray.cgColor
		infoAtStop.font = UIFont.boldSystemFont(ofSize: 16.0)
		infoDepartStop.font = UIFont.boldSystemFont(ofSize: 16.0)
		
		plateAtStopLabel.layer.cornerRadius = 3.0
		plateDepartStopLabel.layer.cornerRadius = 3.0
		plateAtStopLabel.layer.masksToBounds = true
		plateDepartStopLabel.layer.masksToBounds = true
		plateAtStopLabel.layer.backgroundColor = PlateNumberBackgroundColor.cgColor
		plateDepartStopLabel.layer.backgroundColor = PlateNumberBackgroundColor.cgColor
		
		plateAtStopLabel.imageView?.contentMode = .scaleAspectFit
		plateDepartStopLabel.imageView?.contentMode = .scaleAspectFit
		plateAtStopLabel.imageEdgeInsets = UIEdgeInsets(top: 3.0, left: 0.0, bottom: 3.0, right: 0.0)
		plateDepartStopLabel.imageEdgeInsets = UIEdgeInsets(top: 3.0, left: 0.0, bottom: 3.0, right: 0.0)
		plateAtStopLabel.titleLabel?.adjustsFontSizeToFitWidth = true
		plateDepartStopLabel.titleLabel?.adjustsFontSizeToFitWidth = true
		
		plateAtStopLabel.backgroundColor = PlateNumberBackgroundColor
		plateDepartStopLabel.backgroundColor = PlateNumberBackgroundColor
		plateAtStopLabel.titleLabel?.font = UIFont(name: "Roadgeek2005SeriesD", size: 16.0)
		plateDepartStopLabel.titleLabel?.font = UIFont(name: "Roadgeek2005SeriesD", size: 16.0)
		
		currentStopIndicatorView.tintColor = .white
		currentStopIndicatorView.layer.borderColor = UIColor.systemBlue.cgColor
		currentStopIndicatorView.layer.cornerRadius = currentStopIndicatorView.frame.width / 2
		currentStopIndicatorView.layer.borderWidth = 5.0
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		// Configure the view for the selected state
	}
	@IBAction func busAtStopButtonTapped(_ sender: UIButton) {
		NotificationCenter.default.post(name: NSNotification.Name("AllStationETA"), object: plateNumber)
	}
	
}

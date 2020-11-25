//
//  RouteTableViewCell.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/20.
//

import UIKit

class RouteTableViewCell: UITableViewCell {

	@IBOutlet var routeNameLabel: UILabel!
	@IBOutlet var informationLabel: UILabel!
	@IBOutlet var destinationLabel: UILabel!
	@IBOutlet var informationBackgroundView: UIView!
	
	var routeName = "" {
		didSet {
			routeNameLabel.text = routeName
		}
	}
	var information = "" {
		didSet {
			informationLabel.text = information
		}
	}
	var destination = "" {
		didSet {
			destinationLabel.text = destination
		}
	}
	var labelColor: UIColor = RouteInformationLabelColors.gray
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		informationLabel.layer.zPosition = 1
		// Initialization code
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)

		// Configure the view for the selected state
	}

}

class MetroRouteTableViewCell: UITableViewCell {
	
	@IBOutlet var lineNameLabel: UILabel!
	@IBOutlet var destinationLabel: UILabel!
	@IBOutlet var informationLabel: UILabel!
	@IBOutlet var informationBackgroundView: UIView!
	@IBOutlet var crowdnessIndicators: [UIImageView]!
	
	
	var currentStation: MetroArrival?
	
	var lineName = "" {
		didSet {
			lineNameLabel.text = lineName
		}
	}
	var information = "" {
		didSet {
			informationLabel.text = information
		}
	}
	var informationLabelColor: UIColor = RouteInformationLabelColors.gray {
		didSet {
			informationBackgroundView.backgroundColor = informationLabelColor
		}
	}
	var destination = "" {
		didSet {
			destinationLabel.text = destination
		}
	}
	var lineColor: UIColor = RouteInformationLabelColors.gray {
		didSet {
			lineNameLabel.backgroundColor = lineColor
		}
	}
	var lineLabelColor: UIColor = .white {
		didSet {
			lineNameLabel.textColor = lineLabelColor
		}
	}
	var crowdness: [Int]? {
		didSet {
			if(crowdness?.count == 6) {
				for i in 0..<crowdness!.count {
					switch crowdness![i] {
					case 1:
						crowdnessIndicators[i].tintColor = .systemGreen
					case 2:
						crowdnessIndicators[i].tintColor = .systemYellow
					case 3:
						crowdnessIndicators[i].tintColor = .systemOrange
					case 4:
						crowdnessIndicators[i].tintColor = .systemRed
					default:
						crowdnessIndicators[i].tintColor = .systemGray
					}
					crowdnessIndicators[i].isHidden = false
				}
			}
			else {
				for i in 0..<crowdnessIndicators.count {
					crowdnessIndicators[i].isHidden = true
				}
			}
		}
	}
	
	var estimatedArrival = 0
	var countdownSeconds = 0
	var status: MetroArrival.Status = .ServiceOver {
		didSet {
			switch status {
			case .Normal:
				if(estimatedArrival > 10) {
					informationLabel.text = String(format: "%d:%02d", estimatedArrival / 60, estimatedArrival % 60)
					countdownSeconds = estimatedArrival
				}
				else {
					information = "到站中"
				}
			case .Approaching:
				information = "到站中"
			case .Loading:
				information = "加載中"
			case .ServiceOver:
				information = "末班車已過"
			}
		}
	}
	var timer: Timer?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		informationLabel.layer.zPosition = 1
		
		informationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 23.0, weight: .regular)
		
		for crowdnessIndicator in crowdnessIndicators {
			crowdnessIndicator.isHidden = true
		}
		
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
			if(self.status == .Normal) {
				if(self.countdownSeconds > 10) {
					self.informationLabel.text = String(format: "%d:%02d", self.countdownSeconds / 60, self.countdownSeconds % 60)
					self.countdownSeconds = self.countdownSeconds - 1
				} else {
					self.informationLabel.text = "到站中"
					self.informationLabelColor = RouteInformationLabelColors.red
					self.countdownSeconds = 0
				}
			} 
		})
		// Initialization code
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)

		// Configure the view for the selected state
	}
	
	override func prepareForReuse() {
	}
}

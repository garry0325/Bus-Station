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

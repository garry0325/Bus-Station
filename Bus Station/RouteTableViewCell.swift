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
	@IBOutlet var informationBackgroundView: UIView!
	@IBOutlet var destinationLabel: UILabel!
	
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

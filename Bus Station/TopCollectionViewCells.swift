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
	
	override func awakeFromNib() {
		//let topShadow = EdgeShadowLayer(forView: self.contentView, edge: .Top, shadowRadius: 2.0, toColor: .white, fromColor: .black)
		//self.contentView.layer.addSublayer(topShadow)
	}
}

class BearingListCollectionViewCell: UICollectionViewCell {
	@IBOutlet var bearingLabel: UILabel!
	var bearingName: String = "" {
		didSet {
			bearingLabel.text = bearingName
		}
	}
	
	override func awakeFromNib() {
		
	}
}


public class EdgeShadowLayer: CAGradientLayer {

	public enum Edge {
		case Top
		case Left
		case Bottom
		case Right
	}

	public init(forView view: UIView,
				edge: Edge = Edge.Top,
				shadowRadius radius: CGFloat = 20.0,
				toColor: UIColor = UIColor.white,
				fromColor: UIColor = UIColor.black) {
		super.init()
		self.colors = [fromColor.cgColor, toColor.cgColor]
		self.shadowRadius = radius

		let viewFrame = view.frame

		switch edge {
			case .Top:
				startPoint = CGPoint(x: 0.5, y: 0.0)
				endPoint = CGPoint(x: 0.5, y: 1.0)
				self.frame = CGRect(x: 0.0, y: 0.0, width: viewFrame.width, height: shadowRadius)
			case .Bottom:
				startPoint = CGPoint(x: 0.5, y: 1.0)
				endPoint = CGPoint(x: 0.5, y: 0.0)
				self.frame = CGRect(x: 0.0, y: viewFrame.height - shadowRadius, width: viewFrame.width, height: shadowRadius)
			case .Left:
				startPoint = CGPoint(x: 0.0, y: 0.5)
				endPoint = CGPoint(x: 1.0, y: 0.5)
				self.frame = CGRect(x: 0.0, y: 0.0, width: shadowRadius, height: viewFrame.height)
			case .Right:
				startPoint = CGPoint(x: 1.0, y: 0.5)
				endPoint = CGPoint(x: 0.0, y: 0.5)
				self.frame = CGRect(x: viewFrame.width - shadowRadius, y: 0.0, width: shadowRadius, height: viewFrame.height)
		}
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

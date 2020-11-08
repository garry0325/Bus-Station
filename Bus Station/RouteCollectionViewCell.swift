//
//  RouteCollectionViewCell.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/28.
//

import UIKit

class RouteCollectionViewCell: UICollectionViewCell {
    
	@IBOutlet var routeListTableView: UITableView!
	
	var viewController = ViewController()
	
	override func awakeFromNib() {
		routeListTableView.delegate = viewController
		routeListTableView.dataSource = viewController
		
		routeListTableView.contentInset = UIEdgeInsets(top: 7.0, left: 0.0, bottom: 7.0, right: 0.0)
		//routeListTableView.setContentOffset(CGPoint(x: 0, y: CGFloat.greatestFiniteMagnitude), animated: false)
		routeListTableView.transform = CGAffineTransform(rotationAngle: -(CGFloat)(Double.pi))
	}
}

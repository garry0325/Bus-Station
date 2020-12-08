//
//  MapRouteViewController.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/12/8.
//

import UIKit
import MapKit

class MapRouteViewController: UIViewController {

	@IBOutlet var mapView: MKMapView!
	@IBOutlet var closeButton: UIButton!
	
	var currentStop: BusStop!
	var routeSequence = [BusStopLiveStatus]()
	
	@IBOutlet var closeButtonTrailingToSafeAreaConstraint: NSLayoutConstraint!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		// put the close button in the center if large screen
		if(self.view.frame.height > 750.0) {
			closeButtonTrailingToSafeAreaConstraint.isActive = false
			NSLayoutConstraint(item: closeButton!, attribute: .centerX, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
		}
		
		constructRouteSequence()
        // Do any additional setup after loading the view.
    }
    
	func constructRouteSequence() {
		for stop in routeSequence {
			let annotation = MKPointAnnotation()
			annotation.title = stop.stopName
			annotation.coordinate = stop.location.coordinate
			mapView.addAnnotation(annotation)
		}
	}

}

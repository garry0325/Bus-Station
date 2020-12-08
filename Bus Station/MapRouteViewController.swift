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
	var mapAnnotations = [StopAnnotation]()
	
	@IBOutlet var closeButtonTrailingToSafeAreaConstraint: NSLayoutConstraint!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		mapView.delegate = self
		
		// put the close button in the center if large screen
		if(self.view.frame.height > 750.0) {
			closeButtonTrailingToSafeAreaConstraint.isActive = false
			NSLayoutConstraint(item: closeButton!, attribute: .centerX, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
		}
		
		mapView.showsUserLocation = true
		constructRouteSequence()
        // Do any additional setup after loading the view.
    }
    
	func constructRouteSequence() {
		var routeLocations = [CLLocationCoordinate2D]()
		mapAnnotations = []
		
		for stop in routeSequence {
			let stopAnnotation = StopAnnotation(coordinate: stop.location.coordinate)
			stopAnnotation.title = stop.stopName
			stopAnnotation.glyphText = String(stop.stopSequence)
			stopAnnotation.sequence = stop.stopSequence
			
			mapAnnotations.append(stopAnnotation)
			routeLocations.append(stop.location.coordinate)
			
			if(stop.stopId == currentStop.stopId) {
				mapView.setRegion(MKCoordinateRegion(center: stop.location.coordinate, latitudinalMeters: 2000.0, longitudinalMeters: 2000.0), animated: false)
			}
		}
		
		mapView.addAnnotations(mapAnnotations)
		mapView.addOverlay(MKPolyline(coordinates: routeLocations, count: routeLocations.count))
	}

	@IBAction func closeMapRouteViewController(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}
}

extension MapRouteViewController: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let polylineRenderer = MKPolylineRenderer(overlay: overlay)
		polylineRenderer.strokeColor = .systemBlue
		polylineRenderer.lineWidth = 5
		
		return polylineRenderer
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if let temp = annotation as? StopAnnotation {
			var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Stop") as? MKMarkerAnnotationView
			if(annotationView == nil) {
				annotationView = MKMarkerAnnotationView(annotation: temp, reuseIdentifier: "Stop")
				annotationView?.glyphText = String(format: "%d", temp.sequence ?? 0)
				annotationView?.titleVisibility = .visible
			}
			return annotationView
		} else {
			return nil
		}
	}
}

class StopAnnotation: NSObject, MKAnnotation {
	var coordinate: CLLocationCoordinate2D
	var title: String?
	var glyphText: String?
	var sequence: Int?
	
	init(coordinate: CLLocationCoordinate2D) {
		self.coordinate = coordinate
	}
}

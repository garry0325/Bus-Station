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
	
	var busQuery = BusQuery()
	var currentStop: BusStop!
	var routeSequence = [BusStopLiveStatus]()
	var stopAnnotations = [StopAnnotation]()
	var busesLocation = [Bus]()
	var busAnnotations = [BusAnnotation]()
	var plateNumberToIndexDict = [String: Int]()
	
	var autoRefreshTimer = Timer()
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
		
		autoRefresh()
		autoRefreshTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(autoRefresh), userInfo: nil, repeats: true)
        // Do any additional setup after loading the view.
    }
	
	override func viewDidDisappear(_ animated: Bool) {
		autoRefreshTimer.invalidate()
	}
    
	func constructRouteSequence() {
		var routePolyline = [CLLocationCoordinate2D]()
		routePolyline = busQuery.queryBusRouteGeometry(busStop: currentStop)
		stopAnnotations = []
		
		for stop in routeSequence {
			let stopAnnotation = StopAnnotation(coordinate: stop.location.coordinate)
			stopAnnotation.title = stop.stopName
			stopAnnotation.glyphText = String(stop.stopSequence)
			stopAnnotation.sequence = stop.stopSequence
			
			stopAnnotations.append(stopAnnotation)
			
			if(stop.stopId == currentStop.stopId) {
				mapView.setRegion(MKCoordinateRegion(center: stop.location.coordinate, latitudinalMeters: 2000.0, longitudinalMeters: 2000.0), animated: false)
			}
		}
		
		mapView.addAnnotations(stopAnnotations)
		mapView.addOverlay(MKPolyline(coordinates: routePolyline, count: routePolyline.count))
	}
	
	@objc func autoRefresh() {
		DispatchQueue.global(qos: .background).async {
			self.busesLocation = self.busQuery.queryLiveBusesPosition(busStop: self.currentStop)
			
			for bus in self.busesLocation {
				if let index = self.plateNumberToIndexDict[bus.plateNumber] {
					DispatchQueue.main.async {
						self.busAnnotations[index].coordinate = bus.location.coordinate
					}
				} else {
					let busAnnotation = BusAnnotation(coordinate: bus.location.coordinate)
					busAnnotation.title = bus.plateNumber
					self.busAnnotations.append(busAnnotation)
					self.plateNumberToIndexDict[bus.plateNumber] = self.busAnnotations.count - 1
					DispatchQueue.main.async {
						self.mapView.addAnnotation(busAnnotation)
					}
				}
			}
		}
	}
	
	@IBAction func closeMapRouteViewController(_ sender: Any) {
		autoRefreshTimer.invalidate()
		dismiss(animated: true, completion: nil)
	}
}

extension MapRouteViewController: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let polylineRenderer = MKPolylineRenderer(overlay: overlay)
		polylineRenderer.strokeColor = .systemGray
		polylineRenderer.lineWidth = 5
		
		return polylineRenderer
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		if let temp = annotation as? StopAnnotation {
			var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Stop") as? MKMarkerAnnotationView
			annotationView = MKMarkerAnnotationView(annotation: temp, reuseIdentifier: "Stop")
			annotationView?.glyphText = String(format: "%d", temp.sequence ?? 0)
			annotationView?.titleVisibility = .visible
			return annotationView
		}
		else if let temp = annotation as? BusAnnotation {
			var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Bus") as? MKMarkerAnnotationView
			annotationView = MKMarkerAnnotationView(annotation: temp, reuseIdentifier: "Bus")
			annotationView?.glyphImage = UIImage(systemName: "bus")
			annotationView?.glyphTintColor = .white
			annotationView?.markerTintColor = .systemBlue
			annotationView?.titleVisibility = .visible
			annotationView?.displayPriority = .required
			return annotationView
		}
		else {
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

class BusAnnotation: NSObject, MKAnnotation {
	dynamic var coordinate: CLLocationCoordinate2D
	var title: String?
	var glyphText: String?
	var sequence: Int?
	
	init(coordinate: CLLocationCoordinate2D) {
		self.coordinate = coordinate
	}
}

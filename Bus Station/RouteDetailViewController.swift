//
//  RouteDetailViewController.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/29.
//

import UIKit
import MapKit

class RouteDetailViewController: UIViewController {

	var busStop: BusStop?
	
	@IBOutlet var routeNameLabel: UILabel!
	@IBOutlet var routeDestinationLabel: UILabel!
	@IBOutlet var informationLabel: UILabel!
	@IBOutlet var informationBackgroundView: UIView!
	
	@IBOutlet var routeDetailTableView: UITableView!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var mapButton: UIButton!
	@IBOutlet var closeButton: UIButton!
	@IBOutlet var closeButtonTrailingToSafeAreaConstraint: NSLayoutConstraint!
	
	// Map related variables
	@IBOutlet var mapView: MKMapView!
	var stopAnnotations = [StopAnnotation]()
	var routeOverlay = MKPolyline()
	var busesLocation = [Bus]()
	var busAnnotations = [BusAnnotation]()
	var plateNumberToIndexDict = [String: Int]()
	var plateNumberToETADict = [String: [Any]]()
	var mapAlreadyLoaded: Bool = false
	
	var information = "" {
		didSet {
			informationLabel.text = " " + information + " "
		}
	}
	var displayMode: DisplayMode = .Timetable {
		didSet {
			switch displayMode {
			case .Timetable:
				mapButton.setImage(UIImage(systemName: "map"), for: .normal)
				mapView.isHidden = true
				routeDetailTableView.isHidden = false
				mapAutoRefreshTimer?.invalidate()
				
			case .Map:
				mapButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
				
				if(mapAlreadyLoaded) {
					mapView.isHidden = false
					routeDetailTableView.isHidden = true
				}
				else {
					constructRouteSequence()
				}
				
				mapAutoRefresh()
				mapAutoRefreshTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(mapAutoRefresh), userInfo: nil, repeats: true)
			}
		}
	}
	var contentMode: ContentMode = .ETAForCurrentStation
	var selectedBusIndex = 0
	var plateNumberForAllStation: String = ""
	var listForETAForAllStation: Array<String> = []
	
	var busQuery = BusQuery()
	var liveStatusStops = [BusStopLiveStatus]()
	var autoScrollPosition: Int? {
		didSet {
			if(busStop?.stopId != "no") {
				autoScrollPosition = (autoScrollPosition ?? 0) - 4
				if(autoScrollPosition! < 0) {
					autoScrollPosition = 0
				}
			} else {
				autoScrollPosition = (autoScrollPosition ?? 0) + 4
				if(autoScrollPosition! >= liveStatusStops.count) {
					autoScrollPosition = liveStatusStops.count - 1
				}
			}
			
			routeDetailTableView.scrollToRow(at: IndexPath(row: autoScrollPosition!, section: 0), at: .middle, animated: false)
		}
	}
	
	var needAutoscroll = true
	var timetableAutoRefreshTimer: Timer?
	var mapAutoRefreshTimer: Timer?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if(busStop?.stopId != "no") {	// Recognize if is tapped from ordinary bus schedule or nearby bus
			let tap = UITapGestureRecognizer(target: self, action: #selector(switchInformationLabel))
			routeDetailTableView.addGestureRecognizer(tap)
		} else {
			contentMode = .ETAForEveryStation
		}
		
		mapView.delegate = self
		mapView.showsUserLocation = true
		
		routeDetailTableView.delegate = self
		routeDetailTableView.dataSource = self
		
		routeDetailTableView.contentInset = UIEdgeInsets(top: 50.0, left: 0.0, bottom: 150.0, right: 0.0)
		
		configureInformationLabel()
		
		informationLabel.layer.zPosition = 1
		
		
		// put the close button in the center if large screen
		if(self.view.frame.height > 750.0) {
			closeButtonTrailingToSafeAreaConstraint.isActive = false
			NSLayoutConstraint(item: closeButton!, attribute: .centerX, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
		}
		
		activityIndicator.startAnimating()
		
		timetableAutoRefresh()
		timetableAutoRefreshTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(timetableAutoRefresh), userInfo: nil, repeats: true)
		
		NotificationCenter.default.addObserver(self, selector: #selector(showAllStationETA), name: NSNotification.Name("AllStationETA"), object: nil)
	}
	deinit {
		NotificationCenter.default.removeObserver(self)
		
		mapView.removeAnnotations(stopAnnotations)
		mapView.removeAnnotations(busAnnotations)
		mapView.removeOverlay(routeOverlay)
		mapView.delegate = nil
		mapView = nil
		
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		// CRUCIAL BECAUSE WHEN VIEW IS CLOSED, THE TIMER KEEPS GOING CAUSING BAD_ACCESS
		timetableAutoRefreshTimer?.invalidate()
		mapAutoRefreshTimer?.invalidate()
	}
	
	func configureInformationLabel() {
		routeNameLabel.text = busStop?.routeName
		routeDestinationLabel.text = busStop?.destination
		information = busStop?.information ?? ""
		informationBackgroundView.backgroundColor = busStop?.informationLabelColor ?? RouteInformationLabelColors.gray
	}
	
	@IBAction func mapButtonTapped(_ sender: Any) {
		displayMode = (displayMode == .Timetable) ? .Map:.Timetable
        reloadMap()
	}
	
	@objc func timetableAutoRefresh() {
		DispatchQueue.global(qos: .background).async {
			self.liveStatusStops = self.busQuery.queryRealTimeBusLocation(busStop: self.busStop!)
			
			DispatchQueue.main.async {
				if(self.contentMode == .ETAForEveryStation) {
					self.organizeAllStationETA()
				}
				self.routeDetailTableView.reloadData()
				if(self.needAutoscroll) {
					if(self.busStop?.stopId != "no") {
						self.autoScrollPosition = self.liveStatusStops.firstIndex(where: { $0.isCurrentStop == true })
						self.needAutoscroll = false
					}
					else {
						// TODO: Destination name may not be the last stop name
						self.routeDestinationLabel.text = "往" + self.liveStatusStops.last!.stopName
						for i in 0..<self.liveStatusStops.count {
							if(self.liveStatusStops[i].plateNumber == self.busStop?.plateNumber) {
								self.autoScrollPosition = i
								break
							}
						}
						self.plateNumberForAllStation = self.busStop!.plateNumber
						self.contentMode = .ETAForEveryStation
						self.organizeAllStationETA()
					}
				}
				self.activityIndicator.stopAnimating()
				self.mapButton.isHidden = false
			}
			
			self.plateNumberToETADict = [:]
			for i in 0..<self.liveStatusStops.count {
				if(self.liveStatusStops[i].plateNumber != "") {
					self.plateNumberToETADict[self.liveStatusStops[i].plateNumber] = [self.liveStatusStops[i].information, self.liveStatusStops[i].informationLabelColor]
				}
			}
			if(self.mapAlreadyLoaded) {
                self.reloadMap()
			}
		}
		
		// updating the information label
		if(self.busStop?.stopId != "no") {
			DispatchQueue.global(qos: .background).async {
				if(self.busStop != nil) {
					self.busStop = self.busQuery.querySpecificBusArrival(busStop: self.busStop!)
				}
				
				DispatchQueue.main.async {
					self.configureInformationLabel()
				}
			}
		}
	}
	
	@objc func showAllStationETA(notification: Notification) {
		plateNumberForAllStation = notification.object as! String
		contentMode = .ETAForEveryStation
		organizeAllStationETA()
		routeDetailTableView.reloadData()
	}
	
	func organizeAllStationETA() {
		var temp = false
		var cumulativeETA = 0
		listForETAForAllStation = []
		
		for i in 0..<liveStatusStops.count {
			if(temp) {
				listForETAForAllStation.append(" \(Int(cumulativeETA/60))分 ")
				cumulativeETA = cumulativeETA + liveStatusStops[i].timeToTheNextStation
				continue
			}
			else if(plateNumberForAllStation == liveStatusStops[i].plateNumber &&
						i < liveStatusStops.count - 1) {
				selectedBusIndex = i
				cumulativeETA = liveStatusStops[i+1].estimatedArrival	// i+1 crashes when at terminal
				temp = true
			}
			listForETAForAllStation.append("")
		}
		
		if(temp == false) {	//	ignore the case when tapping on terminal station
			plateNumberForAllStation = ""
			selectedBusIndex = 0
			contentMode = .ETAForCurrentStation
		}
	}
	
	@objc func switchInformationLabel() {
		switch contentMode {
		case .ETAForCurrentStation:
			contentMode = .PlateNumber
		case .PlateNumber:
			contentMode = .ETAForCurrentStation
		case .ETAForEveryStation:
			contentMode = .ETAForCurrentStation
		}
		routeDetailTableView.reloadData()
	}
	
	@IBAction func closeRouteDetailViewController(_ sender: Any) {
		timetableAutoRefreshTimer?.invalidate()
		mapAutoRefreshTimer?.invalidate()
		dismiss(animated: true, completion: nil)
	}
    
    func reloadMap() {
        DispatchQueue.main.async {
            self.mapView.removeAnnotations(self.stopAnnotations)
            self.mapView.removeAnnotations(self.busAnnotations)
            self.mapView.addAnnotations(self.stopAnnotations)
            self.mapView.addAnnotations(self.busAnnotations)
        }
    }
}

extension RouteDetailViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.liveStatusStops.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DetailStop") as! RouteDetailTableViewCell
		
		cell.isCurrentStop = self.liveStatusStops[indexPath.row].isCurrentStop
		cell.isDepartureStop = self.liveStatusStops[indexPath.row].isDepartureStop
		cell.isDestinationStop = self.liveStatusStops[indexPath.row].isDestinationStop
		cell.stopName = self.liveStatusStops[indexPath.row].stopName
		cell.eventType = self.liveStatusStops[indexPath.row].eventType
		cell.plateNumber = self.liveStatusStops[indexPath.row].plateNumber
		cell.vehicleType = self.liveStatusStops[indexPath.row].vehicleType
		
		if(contentMode == .ETAForEveryStation) {
			cell.information = listForETAForAllStation[indexPath.row]
			cell.selectedBusIndex = selectedBusIndex
			cell.tag = indexPath.row
		}
		else {
			cell.information = self.liveStatusStops[indexPath.row].information
			cell.informationLabelColor = self.liveStatusStops[indexPath.row].informationLabelColor
		}
		
		cell.mode = contentMode
		
		return cell
	}
	/*
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let cell = cell as! RouteDetailTableViewCell
		
		if(cell.presentInformation == false) {
			return
		}
		var duration: Double?
		switch cell.informationLabelColor {
		case RouteInformationLabelColors.red:
			duration = 0.3
		case RouteInformationLabelColors.orange:
			duration = 0.6
		case RouteInformationLabelColors.green:
			duration = 0.0
			return
		default:
			duration = 0.0
			return
		}
		
		cell.plateAtStopLabel.alpha = 1.0
		cell.plateDepartStopLabel.alpha = 1.0
		UIView.animate(withDuration: duration!, delay: 0.0, options: [.autoreverse, .repeat], animations: {
			cell.plateAtStopLabel.alpha = 0
			cell.plateDepartStopLabel.alpha = 0
		}, completion: nil)
	}
	*/
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 35.0
	}
}

extension RouteDetailViewController: MKMapViewDelegate {
	
	func constructRouteSequence() {
		print("constructing route sequence")
		activityIndicator.startAnimating()
		DispatchQueue.global(qos: .background).async {
			var routePolyline = [CLLocationCoordinate2D]()
			routePolyline = self.busQuery.queryBusRouteGeometry(busStop: self.busStop!)
			self.stopAnnotations = []
			
			for stop in self.liveStatusStops {
				let stopAnnotation = StopAnnotation(coordinate: stop.location.coordinate)
				stopAnnotation.title = stop.stopName
				stopAnnotation.glyphText = String(stop.stopSequence)
				stopAnnotation.sequence = stop.stopSequence
				
				self.stopAnnotations.append(stopAnnotation)
				
				if(stop.stopId == self.busStop!.stopId && self.busStop!.stopId != "no") {
					DispatchQueue.main.async {
						self.mapView.setRegion(MKCoordinateRegion(center: stop.location.coordinate, latitudinalMeters: 2000.0, longitudinalMeters: 2000.0), animated: false)
					}
				} else if(stop.plateNumber == self.busStop!.plateNumber && self.busStop!.stopId == "no") {
					DispatchQueue.main.async {
						self.mapView.setRegion(MKCoordinateRegion(center: stop.location.coordinate, latitudinalMeters: 2000.0, longitudinalMeters: 2000.0), animated: false)
					}
				}
			}
			
			DispatchQueue.main.async {
				self.mapView.addAnnotations(self.stopAnnotations)
				
				self.routeOverlay = MKPolyline(coordinates: routePolyline, count: routePolyline.count)
				self.mapView.addOverlay(self.routeOverlay)
				
				self.mapView.isHidden = false
				self.routeDetailTableView.isHidden = true
				self.activityIndicator.stopAnimating()
				self.mapAlreadyLoaded = true
			}
		}
	}
	
	@objc func mapAutoRefresh() {
		DispatchQueue.global(qos: .background).async {
			self.busesLocation = self.busQuery.queryLiveBusesPosition(busStop: self.busStop!)
			
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
            
            if(contentMode == .ETAForEveryStation && listForETAForAllStation[(temp.sequence ?? 1) - 1] != ""){
                let etaLabel = UILabel(frame: CGRect(x: 0, y: 0.0, width: 50.0, height: 20.0))
                etaLabel.text = listForETAForAllStation[(temp.sequence ?? 1) - 1]
                etaLabel.textAlignment = .center
                etaLabel.backgroundColor = UIColor(red: 0.30, green: 0.67, blue: 0.97, alpha: 1.0)
                etaLabel.textColor = .white
                etaLabel.layer.cornerRadius = 3.0
                etaLabel.layer.masksToBounds = true
                etaLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16.0, weight: .semibold)
                etaLabel.sizeToFit()
                
                etaLabel.frame = CGRect(x: 13 - etaLabel.frame.size.width / 2, y: -28.0, width: etaLabel.frame.size.width, height: 20.0)
                
                let shadowView = UIView(frame: etaLabel.frame)
                shadowView.backgroundColor = UIColor(red: 0.30, green: 0.67, blue: 0.97, alpha: 1.0)
                shadowView.layer.cornerRadius = 3.0
                shadowView.layer.shadowRadius = 3.0
                shadowView.layer.shadowOpacity = 0.4
                shadowView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
                
                shadowView.clipsToBounds = false
                
                annotationView?.addSubview(shadowView)
                annotationView?.addSubview(etaLabel)
                annotationView?.canShowCallout = false
            } else {
                if(annotationView != nil) {
                    for view in annotationView!.subviews {
                        view.removeFromSuperview()
                    }
                }
            }
            
            
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
			
            if let informationAndItsColor = plateNumberToETADict[temp.title!] {
				if(informationAndItsColor[0] as? String != "" && contentMode != .ETAForEveryStation) {
					let etaLabel = UILabel(frame: CGRect(x: 0, y: 0.0, width: 50.0, height: 20.0))
					etaLabel.text = String(format: " %@ ", informationAndItsColor[0] as! CVarArg)
					etaLabel.textAlignment = .center
					etaLabel.backgroundColor = informationAndItsColor[1] as? UIColor
					etaLabel.textColor = .white
					etaLabel.layer.cornerRadius = 3.0
					etaLabel.layer.masksToBounds = true
					etaLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 16.0, weight: .semibold)
					etaLabel.sizeToFit()
					
					etaLabel.frame = CGRect(x: 13 - etaLabel.frame.size.width / 2, y: -28.0, width: etaLabel.frame.size.width, height: 20.0)
					
					let shadowView = UIView(frame: etaLabel.frame)
					shadowView.backgroundColor = informationAndItsColor[1] as? UIColor
					shadowView.layer.cornerRadius = 3.0
					shadowView.layer.shadowRadius = 3.0
					shadowView.layer.shadowOpacity = 0.4
					shadowView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
					
					shadowView.clipsToBounds = false
					
					annotationView?.addSubview(shadowView)
					annotationView?.addSubview(etaLabel)
					annotationView?.canShowCallout = false
                } else {
                    if(annotationView != nil) {
                        for view in annotationView!.subviews {
                            view.removeFromSuperview()
                        }
                    }
                }
            } else {
                if(annotationView != nil) {
                    for view in annotationView!.subviews {
                        view.removeFromSuperview()
                    }
                }
            }
			
			return annotationView
		}
		else {
			return nil
		}
	}
}

extension RouteDetailViewController {
	enum ContentMode {
		case ETAForCurrentStation
		case PlateNumber
		case ETAForEveryStation
	}
	
	enum DisplayMode {
		case Timetable
		case Map
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

class UIEdgeInsetLabel: UILabel {
	
	override func drawText(in rect: CGRect) {
		let edgeInset = UIEdgeInsets(top: 0.0, left: 2.0, bottom: 0.0, right: 2.0)
		
		super.drawText(in: rect.inset(by: edgeInset))
	}
}

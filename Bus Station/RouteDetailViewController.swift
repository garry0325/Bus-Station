//
//  RouteDetailViewController.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/29.
//

import UIKit

class RouteDetailViewController: UIViewController {

	var busStop: BusStop?
	
	@IBOutlet var routeNameLabel: UILabel!
	@IBOutlet var routeDestinationLabel: UILabel!
	@IBOutlet var informationLabel: UILabel!
	@IBOutlet var informationBackgroundView: UIView!
	
	@IBOutlet var routeDetailTableView: UITableView!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var closeButton: UIButton!
	@IBOutlet var closeButtonTrailingToSafeAreaConstraint: NSLayoutConstraint!
	
	
	var information = "" {
		didSet {
			informationLabel.text = " " + information + " "
		}
	}
	var contentMode: ContentMode = .ETAForCurrentStation
	var selectedBusIndex = 0
	var listForETAForAllStation: Array<String> = []
	
	var busQuery = BusQuery()
	var liveStatusStops = [BusStopLiveStatus]()
	var autoScrollPosition: Int? {
		didSet {
			autoScrollPosition = (autoScrollPosition ?? 0) - 4
			if(autoScrollPosition! < 0) {
				autoScrollPosition = 0
			}
			routeDetailTableView.scrollToRow(at: IndexPath(row: autoScrollPosition!, section: 0), at: .middle, animated: false)
		}
	}
	
	var needAutoscroll = true
	var autoRefreshTimer: Timer?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let tap = UITapGestureRecognizer(target: self, action: #selector(switchInformationLabel))
		routeDetailTableView.addGestureRecognizer(tap)
		
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
		
		autoRefresh()
		autoRefreshTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(autoRefresh), userInfo: nil, repeats: true)
		
		NotificationCenter.default.addObserver(self, selector: #selector(showAllStationETA), name: NSNotification.Name("AllStationETA"), object: nil)
	}
	deinit {
		NotificationCenter.default.removeObserver(self)
		print("closed")
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		// CRUCIAL BECAUSE WHEN VIEW IS CLOSED, THE TIMER KEEPS GOING CAUSING BAD_ACCESS
		autoRefreshTimer?.invalidate()
	}
	
	func configureInformationLabel() {
		routeNameLabel.text = busStop?.routeName
		routeDestinationLabel.text = busStop?.destination
		information = busStop?.information ?? ""
		informationBackgroundView.backgroundColor = busStop?.informationLabelColor ?? RouteInformationLabelColors.gray
	}
	
	@objc func autoRefresh() {
		print("autorefreshing \(String(describing: busStop?.routeName))")
		DispatchQueue.global(qos: .background).async {
			self.liveStatusStops = self.busQuery.queryRealTimeBusLocation(busStop: self.busStop!)
			
			DispatchQueue.main.async {
				self.routeDetailTableView.reloadData()
				if(self.needAutoscroll) {
					self.autoScrollPosition = self.liveStatusStops.firstIndex(where: { $0.isCurrentStop == true })
					self.needAutoscroll = false
				}
				self.activityIndicator.stopAnimating()
			}
		}
		
		// updating the information label
		DispatchQueue.global(qos: .background).async {
			if(self.busStop != nil) {
				self.busStop = self.busQuery.querySpecificBusArrival(busStop: self.busStop!)
			}
			
			DispatchQueue.main.async {
				self.configureInformationLabel()
			}
		}
	}
	
	@objc func showAllStationETA(notification: Notification) {
		let plateNumber = notification.object as! String
		var temp = false
		var cumulativeETA = 0
		
		listForETAForAllStation = []
		for i in 0..<liveStatusStops.count {
			if(temp) {
				listForETAForAllStation.append(" \(Int(cumulativeETA/60))分 ")
				cumulativeETA = cumulativeETA + liveStatusStops[i].timeToTheNextStation
				continue
			}
			else if(plateNumber == liveStatusStops[i].plateNumber) {
				selectedBusIndex = i
				cumulativeETA = liveStatusStops[i+1].estimatedArrival
				temp = true
			}
			listForETAForAllStation.append("")
		}
		
		contentMode = .ETAForEveryStation
		routeDetailTableView.reloadData()
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
		autoRefreshTimer?.invalidate()
		dismiss(animated: true, completion: nil)
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
			cell.informationLabelColor = RouteInformationLabelColors.green
			cell.presentAllStationETA = (indexPath.row > selectedBusIndex) ? true:false
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

extension RouteDetailViewController {
	enum ContentMode {
		case ETAForCurrentStation
		case PlateNumber
		case ETAForEveryStation
	}
}

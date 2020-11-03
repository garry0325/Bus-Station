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
	
	var information = "" {
		didSet {
			informationLabel.text = " " + information + " "
		}
	}
	var presentInformation = true
	
	var busQuery = BusQuery()
	var liveStatusStops = [BusStopLiveStatus]()
	var autoScrollPosition: Int? {
		didSet {
			routeDetailTableView.scrollToRow(at: IndexPath(row: autoScrollPosition ?? 0, section: 0), at: .middle, animated: false)
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
		
		routeDetailTableView.contentInset = UIEdgeInsets(top: 30.0, left: 0.0, bottom: 50.0, right: 0.0)
		
		configureInformationLabel()
		
		informationLabel.layer.zPosition = 1
		
		activityIndicator.startAnimating()
		
		autoRefresh()
		autoRefreshTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(autoRefresh), userInfo: nil, repeats: true)
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
	
	@objc func switchInformationLabel() {
		presentInformation = !presentInformation
		routeDetailTableView.reloadData()
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
		cell.information = self.liveStatusStops[indexPath.row].information
		cell.informationLabelColor = self.liveStatusStops[indexPath.row].informationLabelColor
		cell.presentInformation = presentInformation
		
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

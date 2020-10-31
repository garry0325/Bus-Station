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
	@IBOutlet var routeDetailTableView: UITableView!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	
	var busQuery = BusQuery()
	var liveStatusStops = [BusStopLiveStatus]()
	var autoScrollPosition: Int? {
		didSet {
			routeDetailTableView.scrollToRow(at: IndexPath(row: autoScrollPosition ?? 0, section: 0), at: .middle, animated: false)
		}
	}
	
	var autoRefreshTimer = Timer()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		routeDetailTableView.delegate = self
		routeDetailTableView.dataSource = self
		
		routeDetailTableView.contentInset = UIEdgeInsets(top: 7.0, left: 0.0, bottom: 10.0, right: 0.0)
		
		activityIndicator.startAnimating()
		
		autoRefresh()
		
		routeNameLabel.text = busStop?.routeName
		routeDestinationLabel.text = busStop?.destination
		
		autoRefreshTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(autoRefresh), userInfo: nil, repeats: true)
	}
	
	@objc func autoRefresh() {
		DispatchQueue.global(qos: .background).async {
			self.liveStatusStops = self.busQuery.queryRealTimeBusLocation(busStop: self.busStop!)
			
			DispatchQueue.main.async {
				self.routeDetailTableView.reloadData()
				self.autoScrollPosition = self.liveStatusStops.firstIndex(where: { $0.isCurrentStop == true })
				self.activityIndicator.stopAnimating()
			}
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
		
		if(cell.isCurrentStop) {
			let scaledTransform = cell.currentStopIndicatorView.transform.scaledBy(x: 2.0, y: 2.0)
			UIView.animate(withDuration: 1.5, delay: 0.0, options: [.repeat]) {
				cell.currentStopIndicatorView.transform = scaledTransform
				cell.currentStopIndicatorView.alpha = 0.0
			}
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 35.0
	}
}

//
//  MetroDetailViewController.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/11/24.
//

import UIKit

class MetroDetailViewController: UIViewController {
	
	var metroRouteTableViewCell: MetroRouteTableViewCell?
	
	@IBOutlet var stationNameLabel: UILabel!
	@IBOutlet var lineNameLabel: UILabel!
	@IBOutlet var destinationLabel: UILabel!
	@IBOutlet var informationLabel: UILabel!
	@IBOutlet var informationBackgroundView: UIView!
	@IBOutlet var metroDetailTableView: UITableView!
	
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var closeButton: UIButton!
	@IBOutlet var closeButtonTrailingToSafeAreaConstraint: NSLayoutConstraint!
	
	var metroStations = [MetroStation]()
	
	var busQuery = BusQuery()
	var autoRefreshTimer: Timer?
	var countdownTimer: Timer?
	var countdownSeconds = 0
	
    override func viewDidLoad() {
        super.viewDidLoad()

		metroDetailTableView.delegate = self
		metroDetailTableView.dataSource = self
		
		metroDetailTableView.contentInset = UIEdgeInsets(top: 50.0, left: 0.0, bottom: 150.0, right: 0.0)
		
		configureInformationLabel()
		
		// put the close button in the center if large screen
		if(self.view.frame.height > 750.0) {
			closeButtonTrailingToSafeAreaConstraint.isActive = false
			NSLayoutConstraint(item: closeButton!, attribute: .centerX, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
		}
		
		activityIndicator.startAnimating()
		
		constructMetroStationSequence()
		
		NotificationCenter.default.addObserver(self, selector: #selector(refreshETA), name: NSNotification.Name("MetroArrivals"), object: nil)
        
    }
	deinit {
		print("deinited metro detailvc")
		NotificationCenter.default.removeObserver(self)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		autoRefreshTimer?.invalidate()
		countdownTimer?.invalidate()
	}
    
	func configureInformationLabel() {
		stationNameLabel.text = metroRouteTableViewCell?.currentStation?.stationName
		lineNameLabel.text = metroRouteTableViewCell?.lineName
		lineNameLabel.textColor = metroRouteTableViewCell?.lineLabelColor
		lineNameLabel.backgroundColor = metroRouteTableViewCell?.lineColor
		
		destinationLabel.text = (metroRouteTableViewCell?.currentStation!.destinationName)!
		
		informationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 23.0, weight: .regular)
		countdownSeconds = (metroRouteTableViewCell?.currentStation!.estimatedArrival)!
		informationBackgroundView.backgroundColor = metroRouteTableViewCell?.currentStation?.informationLabelColor
		
		countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
			if(self.countdownSeconds > 120) {
				self.informationLabel.text = String(format: "%d:%02d", self.countdownSeconds / 60, self.countdownSeconds % 60)
				self.informationBackgroundView.backgroundColor = RouteInformationLabelColors.green
				self.countdownSeconds = self.countdownSeconds - 1
			} else if(self.countdownSeconds > 10) {
				self.informationLabel.text = String(format: "%d:%02d", self.countdownSeconds / 60, self.countdownSeconds % 60)
				self.informationBackgroundView.backgroundColor = RouteInformationLabelColors.orange
				self.countdownSeconds = self.countdownSeconds - 1
			} else {
				self.informationLabel.text = "到站中"
				self.informationBackgroundView.backgroundColor = RouteInformationLabelColors.red
			}
		})
	}
	
	func constructMetroStationSequence() {
		DispatchQueue.global(qos: .background).async {
			self.metroStations = self.busQuery.queryMetroStationSequence(currentStation: self.metroRouteTableViewCell!.currentStation!)
			
			DispatchQueue.main.async {
				self.metroDetailTableView.reloadData()
				// autoscroll
				self.activityIndicator.stopAnimating()
			}
		}
	}
	
	@objc func refreshETA(notification: Notification) {
		let metroArrivals = notification.object as! [MetroArrival]
		
		for metroArrival in metroArrivals {
			if(metroArrival.destinationName == metroRouteTableViewCell?.currentStation?.destinationName) {
				countdownSeconds = metroArrival.estimatedArrival
				informationBackgroundView.backgroundColor = metroArrival.informationLabelColor
				break
			}
		}
	}
	
	@IBAction func closeMetroDetailViewController(_ sender: Any) {
		autoRefreshTimer?.invalidate()
		countdownTimer?.invalidate()
		dismiss(animated: true, completion: nil)
	}
}

extension MetroDetailViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		metroStations.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DetailStation") as! MetroDetailTableViewCell
		
		cell.stationName = metroStations[indexPath.row].stationName
		cell.lineColor = metroRouteTableViewCell!.currentStation!.lineColor
		cell.isCurrentStation = metroStations[indexPath.row].isCurrentStation
		cell.isDepartureStation = metroStations[indexPath.row].isDepartureStation
		cell.isDestinationStation = metroStations[indexPath.row].isDestinationStation
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 35.0
	}
}

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
	@IBOutlet var crowdnessIndicators: [UIImageView]!
	@IBOutlet var crowdnessDirectionIndicator: UIImageView!
	
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
		constructCrowdnessIndicators()
		
		// put the close button in the center if large screen
		if(self.view.frame.height > 750.0) {
			closeButtonTrailingToSafeAreaConstraint.isActive = false
			NSLayoutConstraint(item: closeButton!, attribute: .centerX, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
		}
		
		activityIndicator.startAnimating()
		
		constructMetroStationSequence()
		
		//autoRefreshTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(updateMetroArrivals), userInfo: nil, repeats: true)
		NotificationCenter.default.addObserver(self, selector: #selector(refreshETA), name: NSNotification.Name("MetroArrivals"), object: nil)
        
    }
	deinit {
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
		
		countdownSeconds = (metroRouteTableViewCell?.currentStation!.estimatedArrival)!
		informationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 23.0, weight: .regular)
		updateInformationLabel()
		
		countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
			self.updateInformationLabel()
		})
	}
	
	func updateInformationLabel() {
		switch(self.metroRouteTableViewCell?.currentStation?.status) {
		case .Normal:
			if(self.countdownSeconds > 120) {
				self.informationLabel.text = String(format: "%d:%02d", self.countdownSeconds / 60, self.countdownSeconds % 60)
				self.informationBackgroundView.backgroundColor = RouteInformationLabelColors.green
				self.countdownSeconds = self.countdownSeconds - 1
			} else if(self.countdownSeconds >= 10) {
				self.informationLabel.text = String(format: "%d:%02d", self.countdownSeconds / 60, self.countdownSeconds % 60)
				self.informationBackgroundView.backgroundColor = RouteInformationLabelColors.orange
				self.countdownSeconds = self.countdownSeconds - 1
			} else {
				self.informationLabel.text = "到站中"
				self.informationBackgroundView.backgroundColor = RouteInformationLabelColors.red
			}
		case .Approaching:
			self.informationLabel.text = "到站中"
			self.informationBackgroundView.backgroundColor = RouteInformationLabelColors.red
		case .ServiceOver:
			self.informationLabel.text = "末班車已過"
			self.informationBackgroundView.backgroundColor = RouteInformationLabelColors.gray
		case .Loading:
			self.informationLabel.text = "加載中"
			self.informationBackgroundView.backgroundColor = RouteInformationLabelColors.gray
		default:
			break
		}
	}
	
	func constructMetroStationSequence() {
		DispatchQueue.global(qos: .background).async {
			self.metroStations = self.busQuery.queryMetroStationSequence(currentStation: self.metroRouteTableViewCell!.currentStation!)
			
			DispatchQueue.main.async {
				let autoscrollPosition = self.metroStations.firstIndex(where: { $0.isCurrentStation == true })
				self.metroDetailTableView.reloadData()
				self.metroDetailTableView.scrollToRow(at: IndexPath(row: autoscrollPosition!, section: 0), at: .middle, animated: false)
				self.activityIndicator.stopAnimating()
			}
		}
	}
	
	func constructCrowdnessIndicators() {
		DispatchQueue.main.async {
			if(self.metroRouteTableViewCell?.currentStation?.crowdness?.count == 6) {
				for i in 0..<6 {
					switch self.metroRouteTableViewCell?.currentStation?.crowdness![i] {
					case 1:
						self.crowdnessIndicators[i].tintColor = .systemGreen
					case 2:
						self.crowdnessIndicators[i].tintColor = .systemYellow
					case 3:
						self.crowdnessIndicators[i].tintColor = .systemOrange
					case 4:
						self.crowdnessIndicators[i].tintColor = .systemRed
					default:
						self.crowdnessIndicators[i].tintColor = .systemGray
					}
					self.crowdnessIndicators[i].isHidden = false
				}
				self.crowdnessDirectionIndicator.isHidden = false
			}
			else {
				for i in 0..<self.crowdnessIndicators.count {
					self.crowdnessIndicators[i].isHidden = true
				}
				self.crowdnessDirectionIndicator.isHidden = true
			}
		}
	}
	
	/*
	@objc func updateMetroArrivals() {
		DispatchQueue.global(qos: .background).async {
			
			
			DispatchQueue.main.async {
				
			}
		}
	}*/
	
	@objc func refreshETA(notification: Notification) {
		let metroArrivals = notification.object as! [MetroArrival]
		
		for metroArrival in metroArrivals {
			if(metroArrival.destinationName == metroRouteTableViewCell?.currentStation?.destinationName) {
				countdownSeconds = metroArrival.estimatedArrival
				metroRouteTableViewCell?.currentStation = metroArrival
				constructCrowdnessIndicators()
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

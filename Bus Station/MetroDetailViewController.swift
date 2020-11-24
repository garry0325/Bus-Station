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
	@IBOutlet var informationLabel: UILabel!
	@IBOutlet var informationBackgroundView: UIView!
	@IBOutlet var metroDetailTableView: UITableView!
	
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var closeButton: UIButton!
	@IBOutlet var closeButtonTrailingToSafeAreaConstraint: NSLayoutConstraint!
	
	var metroStations = [MetroStation]()
	
	var busQuery = BusQuery()
	var autoRefreshTimer: Timer?
	
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
		
		autoRefresh()
		autoRefreshTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(autoRefresh), userInfo: nil, repeats: true)
        
    }
    
	func configureInformationLabel() {
		stationNameLabel.text = metroRouteTableViewCell?.currentStation?.stationName
		lineNameLabel.text = metroRouteTableViewCell?.lineName
		lineNameLabel.textColor = metroRouteTableViewCell?.lineLabelColor
		lineNameLabel.backgroundColor = metroRouteTableViewCell?.lineColor
	}
	
	@objc func autoRefresh() {
		print("autorefreshing \(String(describing: metroRouteTableViewCell?.currentStation))")
		DispatchQueue.global(qos: .background).async {
			self.metroStations = self.busQuery.queryMetroStationSequence(currentStation: self.metroRouteTableViewCell!.currentStation!)
			
			DispatchQueue.main.async {
				self.metroDetailTableView.reloadData()
				// autoscroll
				self.activityIndicator.stopAnimating()
			}
		}
	}
	
	@IBAction func closeMetroDetailViewController(_ sender: Any) {
		autoRefreshTimer?.invalidate()
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

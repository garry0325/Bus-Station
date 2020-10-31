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
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		routeDetailTableView.delegate = self
		routeDetailTableView.dataSource = self
		
		activityIndicator.startAnimating()
		
		DispatchQueue.global(qos: .background).async {
			print("querying real time location")
			self.liveStatusStops = self.busQuery.queryRealTimeBusLocation(busStop: self.busStop!)
			print("queryed")
			DispatchQueue.main.async {
				self.routeDetailTableView.reloadData()
				self.activityIndicator.stopAnimating()
			}
		}
		
		routeNameLabel.text = busStop?.routeName
		routeDestinationLabel.text = busStop?.destination
    }
	
	
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension RouteDetailViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.liveStatusStops.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DetailStop") as! RouteDetailTableViewCell
		
		cell.stopName = self.liveStatusStops[indexPath.row].stopName
		cell.eventType = self.liveStatusStops[indexPath.row].eventType
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 40.0
	}
}

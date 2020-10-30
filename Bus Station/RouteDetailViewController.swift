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
	var stopLabels = [String]()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		routeDetailTableView.delegate = self
		routeDetailTableView.dataSource = self
		
		activityIndicator.startAnimating()
		print("route detail view did load \(String(describing: busStop?.routeName))")
		
		DispatchQueue.global(qos: .background).async {
			print("querying real time location")
			self.stopLabels = self.busQuery.queryRealTimeBusLocation(busStop: self.busStop!)
			print("queryed")
			DispatchQueue.main.async {
				self.routeDetailTableView.reloadData()
				self.activityIndicator.stopAnimating()
			}
		}
        // Do any additional setup after loading the view.
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
		return self.stopLabels.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DetailStop")
		
		cell?.textLabel?.text = self.stopLabels[indexPath.row]
		
		return cell!
	}
	
	
}

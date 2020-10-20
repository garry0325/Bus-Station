//
//  ViewController.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/19.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
	
	var locationManager = CLLocationManager()
	@IBOutlet var stationListCollectionView: UICollectionView!
	@IBOutlet var routeListTableView: UITableView!
	@IBOutlet var currentStationLabel: UILabel!
	@IBOutlet var currentStationBearingLabel: UILabel!
	
	var busQuery = BusQuery()
	var currentLocation = CLLocation()
	
	let greedyStations = ["1000523", "1991", "1000441"]
	var greedyIsUsed: Bool = false
	
	var currentStationNumber = 0 {
		didSet {
			currentStationLabel.text = stationListNames[currentStationNumber]
			currentStationBearing = stationList[currentStationNumber].bearing
		}
	}
	var stationListNames = [String]()
	var stationList = [BusStation]()
	var routeList = [BusStop]()
	var currentStationBearing = "" {
		didSet {
			switch currentStationBearing {
			case "E":
				currentStationBearingLabel.text = "往東"
			case "W":
				currentStationBearingLabel.text = "往西"
			case "S":
				currentStationBearingLabel.text = "往南"
			case "N":
				currentStationBearingLabel.text = "往北"
			case "SE":
				currentStationBearingLabel.text = "往東南"
			case "NE":
				currentStationBearingLabel.text = "往東北"
			case "SW":
				currentStationBearingLabel.text = "往西南"
			case "NW":
				currentStationBearingLabel.text = "往西北"
			default:
				currentStationBearingLabel.text = ""
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		UserDefaults.standard.set(["zh_TW"], forKey: "AppleLanguages")
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		
		stationListCollectionView.delegate = self
		stationListCollectionView.dataSource = self
		routeListTableView.delegate = self
		routeListTableView.dataSource = self
		
		checkLocationServicePermission()
		locationManager.startUpdatingLocation()
		
		_ = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(autoRefresh), userInfo: nil, repeats: true)
		
		// Do any additional setup after loading the view.
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		let userLocation: CLLocation = locations[locations.count-1]
		CLGeocoder().reverseGeocodeLocation(userLocation) { (placemark, error) in
			if(error != nil) {
				print("error")
			} else {
				if let placemark = placemark?[0] {
					var address = ""
					address = address + (placemark.postalCode ?? "")
					address = address + (placemark.subAdministrativeArea ?? "")
					address = address + (placemark.locality ?? "")
					
					print(address)
					self.locationManager.stopUpdatingLocation()
					
					self.currentLocation = userLocation
					self.queryNearbyStations(location: self.currentLocation)
				}
			}
		}
	}
	
	@IBAction func updateLocationButtonPressed(_ sender: Any) {
		locationManager.startUpdatingLocation()
	}
	
	@objc func autoRefresh() {
		queryNearbyStations(location: currentLocation)
	}
	
	func updatePanel() {
		stationListCollectionView.reloadData()
		routeListTableView.reloadData()
	}
	
	func queryNearbyStations(location: CLLocation) {
		DispatchQueue.global(qos: .background).async {
			self.stationList = self.busQuery.queryNearbyStations(location: location)
			var stationTemp = [String]()
			for station in self.stationList {
				stationTemp.append(station.stationName)
			}
			self.stationListNames = stationTemp
			
			DispatchQueue.main.async {
				let temp = self.currentStationNumber
				self.currentStationNumber = temp
				self.greedyCheck()
				self.updatePanel()
				
				let autoscroll = IndexPath(item: self.currentStationNumber, section: 0)
				self.stationListCollectionView.scrollToItem(at: autoscroll, at: .centeredHorizontally, animated: true)
				self.queryBusArrivals()
			}
		}
	}
	
	func queryBusArrivals() {
		DispatchQueue.global(qos: .background).async {
			self.routeList = self.busQuery.queryBusArrivals(station: self.stationList[self.currentStationNumber])
			
			DispatchQueue.main.async {
				self.updatePanel()
			}
		}
	}
	
	func checkLocationServicePermission() {
		locationManager.requestWhenInUseAuthorization()
		
		if(CLLocationManager.locationServicesEnabled() &&
			(locationManager.authorizationStatus == .authorizedAlways ||
				locationManager.authorizationStatus == .authorizedWhenInUse)){
			
			locationManager.startUpdatingLocation()
		}
		else {
			//locationButton.tintColor = .gray
			print("Location permission not granted")
			promptLocationServicePermission()
		}
	}
	
	func promptLocationServicePermission() {
		let locationServiceAlert = UIAlertController(title: "請開啟定位服務", message: "設定 > 隱私 > 定位服務", preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
		let settingsAction = UIAlertAction(title: "設定", style: .default, handler: {_ in
			guard let settingsLocationPermissionUrl = URL(string: UIApplication.openSettingsURLString) else {
				return
			}
			print(settingsLocationPermissionUrl)
			if UIApplication.shared.canOpenURL(settingsLocationPermissionUrl) {
				UIApplication.shared.open(settingsLocationPermissionUrl, completionHandler: { (success) in
					print("Settings opened: \(success)") // Prints true
				})
			}
		})
		
		locationServiceAlert.addAction(settingsAction)
		locationServiceAlert.addAction(cancelAction)
		
		present(locationServiceAlert, animated: true, completion: nil)
	}
	
	func greedyCheck() {
		if(!greedyIsUsed) {
			for greedy in greedyStations {
				for i in 0..<stationList.count {
					if(greedy == stationList[i].stationId) {
						currentStationNumber = i
						break
					}
				}
			}
			greedyIsUsed = true
		}
	}
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return stationListNames.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StationCell", for: indexPath) as! StationListCollectionViewCell
		
		if(currentStationNumber == indexPath.item) {
			cell.backgroundColor = UIColor(white: 0.45, alpha: 1.0)
			cell.stationLabel.textColor = UIColor(white: 1.0, alpha: 1.0)
		}
		else {
			cell.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
			cell.stationLabel.textColor = UIColor(white: 0.0, alpha: 1.0)
		}
		cell.clipsToBounds = true
		cell.layer.cornerRadius = cell.frame.height / 2
		
		cell.stationName = stationListNames[indexPath.item]
		
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		currentStationNumber = indexPath.item
		collectionView.reloadData()
		queryBusArrivals()
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		
		let height = stationListCollectionView.frame.height
		
		let size = NSString(string: stationListNames[indexPath.item]).boundingRect(with: CGSize(width: 1500.0, height: height), options: [.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font :UIFont.systemFont(ofSize: 15)], context: nil)
		
		return CGSize(width: size.size.width + 20.0, height: height)
	}
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return routeList.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell") as! RouteTableViewCell
		
		cell.routeName = routeList[indexPath.row].routeName
		cell.information = routeList[indexPath.row].information
		
		switch cell.information {
		case "進站中", "將到站":
			cell.informationBackgroundView.backgroundColor = UIColor(red: 255/255, green: 96/255, blue: 99/255, alpha: 1.0)
		case "2分", "3分", "4分":
			cell.informationBackgroundView.backgroundColor = UIColor(red: 255/255, green: 164/255, blue: 89/255, alpha: 1.0)
		case "尚未發車", "末班車已過":
			cell.informationBackgroundView.backgroundColor = UIColor(white: 0.75, alpha: 1.0)
		default:
			cell.informationBackgroundView.backgroundColor = UIColor(red: 89/255, green: 206/255, blue: 88/255, alpha: 1.0)
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 50.0
	}
}

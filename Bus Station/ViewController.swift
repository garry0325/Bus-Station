//
//  ViewController.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/19.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
	
	let locationDeviateThreshold = 40.0
	
	var locationManager = CLLocationManager()
	@IBOutlet var stationListCollectionView: UICollectionView!
	@IBOutlet var bearingListCollectionView: UICollectionView!
	@IBOutlet var routeListTableView: UITableView!
	@IBOutlet var currentStationLabel: UILabel!
	@IBOutlet var currentStationBearingLabel: UILabel!
	@IBOutlet var updateLocationButton: UIButton!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	
	// TODO: add substops
	// TODO: bus destination
	// TODO: station collectionview has bug in length
	
	var busQuery = BusQuery()
	var locationWhenPinned = CLLocation()
	var locationHasUpdated: Bool = false
	var autoRefreshTimer = Timer()
	
	let greedyStations = ["1000441", "1991", "1000523", "1000769"]
	
	var currentStationNumber = 0 {
		didSet {
			if(stationList.count > 0) {
				currentStationLabel.text = stationListNames[currentStationNumber]
			}
		}
	}
	var stationListNames = [String]()
	var stationList: Array<Array<BusStation>> = []
	var currentBearingNumber = 0 {
		didSet {
			currentStationBearingLabel.text = bearingListNames[currentStationNumber][currentBearingNumber]
		}
	}
	var bearingListNames: Array<Array<String>> = []
	
	var routeList = [BusStop]()
	var currentStationBearing = ""
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		UserDefaults.standard.set(["zh_TW"], forKey: "AppleLanguages")
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		
		stationListCollectionView.delegate = self
		stationListCollectionView.dataSource = self
		bearingListCollectionView.delegate = self
		bearingListCollectionView.dataSource = self
		routeListTableView.delegate = self
		routeListTableView.dataSource = self
		
		updateLocationAndStations()
		
		autoRefreshTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(autoRefresh), userInfo: nil, repeats: true)
		
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
					
					print("\(self.locationHasUpdated)\t\(address)")
					
					if(!self.locationHasUpdated)  {
						self.locationHasUpdated = true
						self.locationWhenPinned = userLocation
						self.updateLocationButton.tintColor = .blue
						self.queryNearbyStations(location: self.locationWhenPinned)
					}
					else {
						// check if current location is deviated from locationWhenPinned over 30m
						// if so, then dim the location button
						if(userLocation.distance(from: self.locationWhenPinned) > self.locationDeviateThreshold) {
							self.updateLocationButton.tintColor = .lightGray
						}
					}
				}
			}
		}
	}
	
	@IBAction func updateLocationButtonPressed(_ sender: Any) {
		presentActivityIndicator()
		updateLocationAndStations()
	}
	
	func updateLocationAndStations() {
		checkLocationServicePermissionAndStartUpdating()
		locationHasUpdated = false
	}
	
	@objc func autoRefresh() {
		if(stationList.count > 0) {
			queryBusArrivals()
		}
	}
	
	func updatePanel() {
		stationListCollectionView.reloadData()
		bearingListCollectionView.reloadData()
		routeListTableView.reloadData()
		dismissActivityIndicator()
	}
	
	func queryNearbyStations(location: CLLocation) {
		presentActivityIndicator()
		DispatchQueue.global(qos: .background).async {
			let unorganizedStationList = self.busQuery.queryNearbyStations(location: location)
			var stationTemp = [String]()
			for station in unorganizedStationList {
				stationTemp.append(station.stationName)
			}
			self.stationListNames = stationTemp
			
			if(unorganizedStationList.count == 0) {
				DispatchQueue.main.async {
					self.currentStationLabel.text = "附近沒有公車站"
					self.currentStationBearing = ""
					self.bearingListNames = []
					self.routeList = []
					self.updatePanel()
				}
			}
			else {
				var duplicates = Dictionary(grouping: unorganizedStationList, by: {$0.stationName})
				self.stationList = []
				self.stationListNames = []
				self.bearingListNames = []
				for i in 0..<unorganizedStationList.count {
					if let exist = duplicates[unorganizedStationList[i].stationName] {
						var stationTemp = [BusStation]()
						var bearingTemp = [String]()
						for station in exist {
							stationTemp.append(station)
							bearingTemp.append(station.bearing)
						}
						for j in 0..<bearingTemp.count {
							switch bearingTemp[j] {
							case "E":
								bearingTemp[j] = "往東"
							case "W":
								bearingTemp[j] = "往西"
							case "S":
								bearingTemp[j] = "往南"
							case "N":
								bearingTemp[j] = "往北"
							case "SE":
								bearingTemp[j] = "往東南"
							case "NE":
								bearingTemp[j] = "往東北"
							case "SW":
								bearingTemp[j] = "往西南"
							case "NW":
								bearingTemp[j] = "往西北"
							default:
								bearingTemp[j] = ""
							}
						}
						if(bearingTemp.count > 2) {
							var dir = ["往東": 0, "往西": 0, "往南": 0, "往北": 0, "往東南": 0, "往東北": 0, "往西南": 0, "往西北": 0, "": 0]
							for j in 0..<bearingTemp.count {
								let temp = bearingTemp[j]
								bearingTemp[j] = bearingTemp[j] + String(Character(UnicodeScalar(dir[bearingTemp[j]]! + 65)!))
								dir[temp] = dir[temp]! + 1
							}
						}
						else {	// check if there are stations that do not provide bearing
							var dir = 0
							for j in 0..<bearingTemp.count {
								if(bearingTemp[j] == "") {
									bearingTemp[j] = String(Character(UnicodeScalar(dir + 65)!))
									dir = dir + 1
								}
							}
						}
						self.stationList.append(stationTemp)
						self.bearingListNames.append(bearingTemp)
						self.stationListNames.append(unorganizedStationList[i].stationName)
						
						duplicates.removeValue(forKey: unorganizedStationList[i].stationName)
					}
				}
				
				DispatchQueue.main.async {
					self.currentStationNumber = 0
					self.currentBearingNumber = 0
					self.greedyCheck()
					self.updatePanel()
					
					self.queryBusArrivals()
					
					let autoscroll = IndexPath(item: self.currentStationNumber, section: 0)
					self.stationListCollectionView.scrollToItem(at: autoscroll, at: .centeredHorizontally, animated: true)
				}
			}
		}
	}
	
	func queryBusArrivals() {
		presentActivityIndicator()
		print(stationList[currentStationNumber][currentBearingNumber].stationId)
		DispatchQueue.global(qos: .background).async {
			self.routeList = self.busQuery.queryBusArrivals(station: self.stationList[self.currentStationNumber][self.currentBearingNumber])
			
			DispatchQueue.main.async {
				self.updatePanel()
			}
		}
	}
	
	func checkLocationServicePermissionAndStartUpdating() {
		locationManager.requestWhenInUseAuthorization()
		
		if(CLLocationManager.locationServicesEnabled() &&
			(locationManager.authorizationStatus == .authorizedAlways ||
				locationManager.authorizationStatus == .authorizedWhenInUse)){
			
			locationManager.startUpdatingLocation()
		}
		else {
			updateLocationButton.tintColor = .lightGray
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
	
	func presentActivityIndicator() {
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
	}
	func dismissActivityIndicator() {
		activityIndicator.isHidden = true
		activityIndicator.stopAnimating()
	}
	
	func greedyCheck() {
		for greedy in greedyStations {
			for i in 0..<stationList.count {
				for j in 0..<stationList[i].count {
					if(greedy == stationList[i][j].stationId) {
						currentStationNumber = i
						currentBearingNumber = j
						return
					}
				}
			}
		}
	}
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if(collectionView == stationListCollectionView) {
			return stationListNames.count
		}
		else {
			if(bearingListNames.count == 0) {
				return 0
			}
			else {
				return bearingListNames[currentStationNumber].count
			}
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if(collectionView == stationListCollectionView) {
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
		else {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BearingCell", for: indexPath) as! BearingListCollectionViewCell
			
			if(currentBearingNumber == indexPath.item) {
				cell.backgroundColor = UIColor(white: 0.45, alpha: 1.0)
				cell.bearingLabel.textColor = UIColor(white: 1.0, alpha: 1.0)
			}
			else {
				cell.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
				cell.bearingLabel.textColor = UIColor(white: 0.0, alpha: 1.0)
			}
			cell.clipsToBounds = true
			cell.layer.cornerRadius = 7.0
			
			cell.bearingName = bearingListNames[currentStationNumber][indexPath.item]
			
			return cell
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if(collectionView == stationListCollectionView) {
			currentStationNumber = indexPath.item
			currentBearingNumber = 0
			collectionView.reloadData()
			queryBusArrivals()
		}
		else {
			currentBearingNumber = indexPath.item
			collectionView.reloadData()
			queryBusArrivals()
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		
		
		if(collectionView == stationListCollectionView) {
			let height = stationListCollectionView.frame.height
			let size = NSString(string: stationListNames[indexPath.item]).boundingRect(with: CGSize(width: 1500.0, height: height), options: [.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font :UIFont.systemFont(ofSize: 15)], context: nil)
			
			return CGSize(width: size.size.width + 20.0, height: height)
		}
		else {
			let height = bearingListCollectionView.frame.height
			let size = NSString(string: bearingListNames[currentStationNumber][indexPath.item]).boundingRect(with: CGSize(width: 500.0, height: height), options: [.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font :UIFont.systemFont(ofSize: 15)], context: nil)
			
			return CGSize(width: size.size.width + 20.0, height: height)
		}
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
		case "尚未發車", "末班車已過", "今日未營運", "交管不停靠":
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

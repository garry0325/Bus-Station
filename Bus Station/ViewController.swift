//
//  ViewController.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/19.
//

import UIKit
import CoreData
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
	
	let locationDeviateThreshold = 40.0
	
	let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	var starredStations: Array<StarredStation> = []
	
	var locationManager = CLLocationManager()
	@IBOutlet var stationListCollectionView: UICollectionView!
	@IBOutlet var bearingListCollectionView: UICollectionView!
	@IBOutlet var routeCollectionView: UICollectionView!
	@IBOutlet var currentStationLabel: UILabel!
	@IBOutlet var currentStationBearingLabel: UILabel!
	@IBOutlet var updateLocationButton: UIButton!
	@IBOutlet var starButton: UIButton!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	
	// TODO: add substops
	// TODO: station collectionview has bug in length
	// TODO: combine buses from other cities
	// TODO: add queryBusesArrivals() on adjacent pages
	// TODO: haptic feedback when location is updated
	// TODO: make static enum
	// TODO: check far away location
	
	var busQuery = BusQuery()
	var locationWhenPinned = CLLocation()
	var locationHasUpdated: Bool = false
	var autoRefreshTimer = Timer()
	
	var currentStationNumber = 0 {
		didSet {
			if(stationList.count > 0 && currentStationNumber < bearingListNames.count && currentBearingNumber < bearingListNames[currentStationNumber].count) {
				currentStationLabel.text = stationListNames[currentStationNumber]
				currentStationBearingLabel.text = bearingListNames[currentStationNumber][currentBearingNumber]
				
				let item = bearingIndexToItem[currentStationNumber][currentBearingNumber]
				routeCollectionView.scrollToItem(at: IndexPath(item: item, section: 0), at: .centeredHorizontally, animated: true)
				
				updateStarredButton()
			}
			ViewController.stationNumberForDetailView = currentStationNumber
		}
	}
	var currentBearingNumber = 0 {
		didSet {
			if(currentStationNumber < bearingListNames.count && currentBearingNumber < bearingListNames[currentStationNumber].count) {
				
				currentStationLabel.text = stationListNames[currentStationNumber]
				currentStationBearingLabel.text = bearingListNames[currentStationNumber][currentBearingNumber]
				
				let item = bearingIndexToItem[currentStationNumber][currentBearingNumber]
				routeCollectionView.scrollToItem(at: IndexPath(item: item, section: 0), at: .centeredHorizontally, animated: true)
				
				
				updateStarredButton()
			}
			ViewController.bearingNumberForDetailView = currentBearingNumber
		}
	}
	var stationList: Array<Array<BusStation>> = []
	var stationListNames = [String]()
	var bearingListNames: Array<Array<String>> = []
	
	static var routeList: Array<Array<Array<BusStop>>> = []
	var bearingStationDict = [Int:Int]()
	var bearingIndexToItem: Array<Array<Int>> = []
	static var bearingItemToIndex: Array<Array<Int>> = []
	var bearingStationsCount = 0
	
	static var bearingNumberForDetailView = 0
	static var stationNumberForDetailView = 0
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		UserDefaults.standard.set(["zh_TW"], forKey: "AppleLanguages")
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		
		stationListCollectionView.delegate = self
		stationListCollectionView.dataSource = self
		bearingListCollectionView.delegate = self
		bearingListCollectionView.dataSource = self
		routeCollectionView.delegate = self
		routeCollectionView.dataSource = self
		
		stationListCollectionView.contentInset.right = 100	// compensate for the bug that the last cell will be covered due to not enough scrollable length
		
		fetchStarredStops()
		
		updateLocationAndStations()
		
		// Because when app is reopen from background, the animation stops
		NotificationCenter.default.addObserver(self, selector: #selector(backFromBackground), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(showRouteDetailVC), name: NSNotification.Name("Detail"), object: nil)
		autoRefreshTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(autoRefresh), userInfo: nil, repeats: true)
		
		
		// Do any additional setup after loading the view.
	}
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc func showRouteDetailVC(notification: Notification) {
		
		self.performSegue(withIdentifier: "RouteDetail", sender: notification.object)
		
		/*
		let routeDetailVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "RouteDetailStoryboard") as! RouteDetailViewController
		routeDetailVC.modalPresentationStyle = .popover
		
		let popover = routeDetailVC.popoverPresentationController
		popover?.delegate = self
		popover?.sourceView =  routeCollectionView.cellForItem(at: IndexPath(item: 0, section: 0))
		popover?.sourceRect = routeCollectionView.cellForItem(at: IndexPath(item: 0, section: 0))!.bounds
		popover?.permittedArrowDirections = .any
		routeDetailVC.preferredContentSize = CGSize(width: 200.0, height: 500.0)
		
		
		present(routeDetailVC, animated: true, completion: nil)
		*/
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		let userLocation: CLLocation = locations[locations.count-1]
		CLGeocoder().reverseGeocodeLocation(userLocation) { (placemark, error) in
			if(error != nil) {
				print("error \(String(describing: error?.localizedDescription))")
			} else {
				if let placemark = placemark?[0] {
					var address = ""
					address = address + (placemark.postalCode ?? "")
					address = address + (placemark.subAdministrativeArea ?? "")
					address = address + (placemark.locality ?? "")
					
					print("\(self.locationHasUpdated)\t\(address)")
					
					if(!self.locationHasUpdated)  {
						print("location has not updated")
						self.locationHasUpdated = true
						self.locationWhenPinned = userLocation
						self.updateLocationButton.tintColor = .blue
						self.queryNearbyStations(location: self.locationWhenPinned)
					}
					else {
						print("lcoation has updated")
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
	
	@IBAction func starButtonPressed(_ sender: Any) {
		if(currentStationNumber < stationList.count && currentBearingNumber < stationList[currentStationNumber].count) {
			let checkStarredStationId = stationList[currentStationNumber][currentBearingNumber].stationId
			if(!stationIsStarred(stationID: checkStarredStationId)) {
				starButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
				starButton.tintColor = .systemYellow
				
				let starred = StarredStation(context: self.context)
				starred.stationID = checkStarredStationId
				starredStations.append(starred)
				do {
					try self.context.save()
				} catch {
					print("Error saving starred station")
				}
			}
			else {
				starButton.setImage(UIImage(systemName: "star"), for: .normal)
				starButton.tintColor = .systemGray
				
				for i in 0..<starredStations.count {
					if(starredStations[i].stationID == checkStarredStationId) {
						self.context.delete(starredStations[i])
						do {
							try self.context.save()
						} catch {
							print("Error saving unstarred station")
						}
						starredStations.remove(at: i)
						break
					}
				}
			}
		}
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
		routeCollectionView.reloadData()
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
					self.currentStationBearingLabel.text = ""
					self.stationList = []
					ViewController.routeList = []
					self.stationListNames = []
					self.bearingListNames = []
					self.bearingStationsCount = 0
					self.bearingStationDict = [Int:Int]()
					self.bearingIndexToItem = []
					ViewController.bearingItemToIndex = []
					self.updatePanel()
				}
			}
			else {
				var duplicates = Dictionary(grouping: unorganizedStationList, by: {$0.stationName})
				self.stationList = []
				ViewController.routeList = []
				self.stationListNames = []
				self.bearingListNames = []
				self.bearingStationsCount = unorganizedStationList.count
				self.bearingStationDict = [Int:Int]()
				self.bearingIndexToItem = []
				ViewController.bearingItemToIndex = []
				var countForStation = 0
				var countForBearing = 0
				for i in 0..<unorganizedStationList.count {
					if let exist = duplicates[unorganizedStationList[i].stationName] {
						var stationTemp = [BusStation]()
						var bearingTemp = [String]()
						var routeTemp: Array<Array<BusStop>> = []
						var countForBearingOfEachStation = 0
						var countForIndexToItemOfEachStation = [Int]()
						for station in exist {
							stationTemp.append(station)
							bearingTemp.append(station.bearing)
							let routeTempTemp = [BusStop]()
							routeTemp.append(routeTempTemp)
							countForIndexToItemOfEachStation.append(countForBearing)
							countForBearing = countForBearing + 1
							ViewController.bearingItemToIndex.append([countForStation, countForBearingOfEachStation])
							countForBearingOfEachStation = countForBearingOfEachStation + 1
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
						ViewController.routeList.append(routeTemp)
						self.bearingStationDict[countForStation] = countForBearingOfEachStation
						self.bearingIndexToItem.append(countForIndexToItemOfEachStation)
						countForStation = countForStation + 1
						
						duplicates.removeValue(forKey: unorganizedStationList[i].stationName)
					}
				}
				DispatchQueue.main.async {
					self.routeCollectionView.reloadData()	// not sure why this, but otherwise first load will not make routeCollectionView autoscroll
					self.currentStationNumber = 0
					self.findStarredBearingStation()
					self.updatePanel()
					
					self.queryBusArrivals()
					
					self.stationListCollectionView.scrollToItem(at: IndexPath(item: self.currentStationNumber, section: 0), at: .centeredHorizontally, animated: true)
				}
			}
		}
	}
	
	func queryBusArrivals() {
		presentActivityIndicator()
		//print(stationList[currentStationNumber][currentBearingNumber].stationId)
		DispatchQueue.global(qos: .background).async {
			ViewController.routeList[self.currentStationNumber][self.currentBearingNumber] = self.busQuery.queryBusArrivals(station: self.stationList[self.currentStationNumber][self.currentBearingNumber])
			
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
	
	func fetchStarredStops() {
		do {
			starredStations = try (context.fetch(StarredStation.fetchRequest()) as? [StarredStation])!
			print("\(starredStations.count) starred stations")
		} catch {
			print("Error fetching starredStations")
		}
	}
	
	func updateStarredButton() {
		if(stationIsStarred(stationID: stationList[currentStationNumber][currentBearingNumber].stationId)) {
			starButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
			starButton.tintColor = .systemYellow
		}
		else {
			starButton.setImage(UIImage(systemName: "star"), for: .normal)
			starButton.tintColor = .systemGray
		}
	}
	
	func stationIsStarred(stationID: String) -> Bool{
		for i in 0..<starredStations.count {
			if(starredStations[i].stationID == stationList[currentStationNumber][currentBearingNumber].stationId) {
				return true
			}
		}
		
		return false
	}
	
	func findStarredBearingStation() {	// TODO: IMPROVE ALGORITHM
		for i in 0..<starredStations.count {
			for j in 0..<stationList[currentStationNumber].count {
				if(starredStations[i].stationID == stationList[currentStationNumber][j].stationId) {
					currentBearingNumber = j
					return
				}
			}
		}
		currentBearingNumber = 0
	}
	
	@objc func backFromBackground() {
		autoRefresh()
	}
	
	func presentActivityIndicator() {
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
	}
	func dismissActivityIndicator() {
		activityIndicator.isHidden = true
		activityIndicator.stopAnimating()
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		if(CLLocationManager.locationServicesEnabled() &&
			(locationManager.authorizationStatus == .authorizedAlways ||
				locationManager.authorizationStatus == .authorizedWhenInUse)){
			
			locationManager.startUpdatingLocation()
		}
	}
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if(collectionView == stationListCollectionView) {
			return stationListNames.count
		}
		else if(collectionView == bearingListCollectionView) {
			if(bearingListNames.count == 0) {
				return 0
			}
			else {
				return bearingListNames[currentStationNumber].count
			}
		}
		else {
			return bearingStationsCount
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
			//cell.clipsToBounds = true
			cell.layer.cornerRadius = cell.frame.height / 2
			
			cell.stationName = stationListNames[indexPath.item]
			
			return cell
		}
		else if(collectionView == bearingListCollectionView) {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BearingCell", for: indexPath) as! BearingListCollectionViewCell
			
			if(currentBearingNumber == indexPath.item) {
				cell.backgroundColor = UIColor(white: 0.45, alpha: 1.0)
				cell.bearingLabel.textColor = UIColor(white: 1.0, alpha: 1.0)
			}
			else {
				cell.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
				cell.bearingLabel.textColor = UIColor(white: 0.0, alpha: 1.0)
			}
			//cell.clipsToBounds = true
			cell.layer.cornerRadius = 5.0
			
			cell.bearingName = bearingListNames[currentStationNumber][indexPath.item]
			
			return cell
		}
		else {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RouteCollectionCell", for: indexPath) as! RouteCollectionViewCell
			
			cell.routeListTableView.tag = indexPath.item
			cell.routeListTableView.reloadData()
			
			return cell
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if(collectionView == stationListCollectionView) {
			currentStationNumber = indexPath.item
			findStarredBearingStation()
			collectionView.reloadData()
			queryBusArrivals()
		}
		else if(collectionView == bearingListCollectionView) {
			currentBearingNumber = indexPath.item
			collectionView.reloadData()
			queryBusArrivals()
		}
	}
	
	func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		
		let x = targetContentOffset.pointee.x
		
		if(scrollView == routeCollectionView.self) {
			let page = Int(x/routeCollectionView.frame.width)
			currentBearingNumber = ViewController.bearingItemToIndex[page][1]
			currentStationNumber = ViewController.bearingItemToIndex[page][0]
			queryBusArrivals()
			stationListCollectionView.reloadData()
			bearingListCollectionView.reloadData()
			stationListCollectionView.scrollToItem(at: IndexPath(item: currentStationNumber, section: 0), at: .centeredHorizontally, animated: true)
			bearingListCollectionView.scrollToItem(at: IndexPath(item: currentBearingNumber, section: 0), at: .centeredHorizontally, animated: true)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		
		if(collectionView == stationListCollectionView) {
			let height = stationListCollectionView.frame.height
			let size = NSString(string: stationListNames[indexPath.item]).boundingRect(with: CGSize(width: 1500.0, height: height), options: [.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font :UIFont.systemFont(ofSize: 15)], context: nil)
			
			return CGSize(width: size.size.width + 20.0, height: height - 6.0)
		}
		else if(collectionView == bearingListCollectionView) {
			let height = bearingListCollectionView.frame.height
			let size = NSString(string: bearingListNames[currentStationNumber][indexPath.item]).boundingRect(with: CGSize(width: 500.0, height: height), options: [.usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font :UIFont.systemFont(ofSize: 15)], context: nil)
			
			return CGSize(width: size.size.width + 20.0, height: height - 12.0)
		}
		else {
			return CGSize(width: routeCollectionView.frame.width, height: routeCollectionView.frame.height)
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		if(collectionView == stationListCollectionView || collectionView == bearingListCollectionView) {
			return UIEdgeInsets(top: 0.0, left: 7.0, bottom: 0.0, right: 5.0)
		}
		else {
			return UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
		}
	}
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		
		return ViewController.routeList[ViewController.bearingItemToIndex[tableView.tag][0]][ViewController.bearingItemToIndex[tableView.tag][1]].count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell") as! RouteTableViewCell
		cell.selectionStyle = .none
		let stationNumber = ViewController.bearingItemToIndex[tableView.tag][0]
		let bearingNumber = ViewController.bearingItemToIndex[tableView.tag][1]
		
		cell.routeName = ViewController.routeList[stationNumber][bearingNumber][indexPath.row].routeName
		cell.information = ViewController.routeList[stationNumber][bearingNumber][indexPath.row].information
		cell.destination = ViewController.routeList[stationNumber][bearingNumber][indexPath.row].destination
		cell.labelColor = ViewController.routeList[stationNumber][bearingNumber][indexPath.row].informationLabelColor
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		NotificationCenter.default.post(name: NSNotification.Name("Detail"), object: ViewController.routeList[ViewController.stationNumberForDetailView][ViewController.bearingNumberForDetailView][indexPath.row])
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let tempCell = cell as! RouteTableViewCell
		var colorOriginal: UIColor?
		var colorAnimating: UIColor?
		var animateDuration: TimeInterval?
		
		switch tempCell.labelColor {
		case RouteInformationLabelColors.red:
			colorOriginal = RouteInformationLabelColors.red
			colorAnimating = RouteInformationLabelColors.redAnimating
			animateDuration = 0.3
		case RouteInformationLabelColors.orange:
			colorOriginal = RouteInformationLabelColors.orange
			colorAnimating = RouteInformationLabelColors.orangeAnimating
			animateDuration = 0.8
		case RouteInformationLabelColors.green:
			colorOriginal = RouteInformationLabelColors.green
			colorAnimating = RouteInformationLabelColors.greenAnimating
			animateDuration = 1.5
		default:
			colorOriginal = RouteInformationLabelColors.gray
			colorAnimating = RouteInformationLabelColors.gray
			animateDuration = 1
		}
		
		tempCell.informationBackgroundView.backgroundColor = colorOriginal
		UIView.animate(withDuration: animateDuration!, delay: 0, options: [.autoreverse, .repeat], animations: {
			tempCell.informationBackgroundView.backgroundColor = colorAnimating
		}, completion: nil)
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 55.0
	}
}

extension ViewController: UIPopoverPresentationControllerDelegate {
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		segue.destination.modalPresentationStyle = .popover
		
		let destination = segue.destination as! RouteDetailViewController
		destination.busStop = sender as? BusStop
	}
	
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
	}
}

//
//  ViewController.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/19.
//

import UIKit
import CoreData
import CoreLocation
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport

class ViewController: UIViewController, CLLocationManagerDelegate {
	
	let locationDeviateThreshold = 40.0	// in meters
	
	let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	var starredStations: Array<StarredStation> = []
	var bannedStations: Array<BannedStation> = []
	var layoutPreferenceData: Array<UpSideUp> = []
	
	var locationManager = CLLocationManager()
	
	@IBOutlet var stationListCollectionView: UICollectionView!
	@IBOutlet var bearingListCollectionView: UICollectionView!
	@IBOutlet var routeCollectionView: UICollectionView!
	@IBOutlet var nearbyBusCollectionView: UICollectionView!
	@IBOutlet var stationTypeImage: UIImageView!
	@IBOutlet var currentStationLabel: UILabel!
	@IBOutlet var currentStationBearingLabel: UILabel!
	@IBOutlet var updateLocationButton: UIButton!
	@IBOutlet var starButton: UIButton!
	@IBOutlet var banButton: UIButton!
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var buttonActivityIndicator: UIActivityIndicatorView!
	
	@IBOutlet var adBannerView: GADBannerView!
	var displayAd = true
	var needAdData: Array<Ad> = []
	var adDisplayedSuccessfully = false {
		didSet {
			adBannerView.isHidden = !adDisplayedSuccessfully
			updateLayoutConstraintWithAd()
		}
	}
	var stationRadiusPreferenceData: Array<StationRadius> = []
	
	@IBOutlet var aboutButton: UIButton!
	
	@IBOutlet var whiteView: UIView!
	
	@IBOutlet var whiteViewToTopSafeAreaConstraintA: NSLayoutConstraint!
	@IBOutlet var bearingCollectionViewToRouteCollectionViewConstraintA: NSLayoutConstraint!
	@IBOutlet var routeCollectionViewToBottomConstraintA: NSLayoutConstraint!
	var whiteViewToBottomRouteCollectionViewConstraintB: NSLayoutConstraint?
	var bearingCollectionViewToBottomSafeAreaConstraintB: NSLayoutConstraint?
	var bearingCollectionViewToTopAdBannerConstraintB: NSLayoutConstraint?
	var routeCollectionViewToTopSafeAreaConstraintB: NSLayoutConstraint?
	
	var routeCollectionViewToTopAdBannerConstraintA: NSLayoutConstraint?
	@IBOutlet var updateButtonAtCenterConstraintA: NSLayoutConstraint!
	@IBOutlet var updateButtonToSafeAreaConstraintA: NSLayoutConstraint!
	var updateButtonToAdBannerConstraintA: NSLayoutConstraint?
	@IBOutlet var aboutButtonToSafeAreaConstraintA: NSLayoutConstraint!
	var aboutButtonToAdBannerConstraintA: NSLayoutConstraint?
	var updateButtonToWhiteViewTopConstraintB: NSLayoutConstraint?
	var updateButtonToTrailingConstraintB: NSLayoutConstraint?
	var aboutButtonToUpdateButtonVerticalSpacingConstraintB: NSLayoutConstraint?
	
	// TODO: add substops +
	// TODO: station collectionview has bug in length
	// TODO: combine buses from other cities
	// TODO: make static enum +
	// TODO: check far away location
	
	// TODO: connectivity issue warnings
	// TODO: Maokong Gondola support
	// TODO: Error in MetroDetailViewController at branch stations
	// TODO: change app store screenshots
	// TODO: when udpating location, it waits for autoRefresh refreshes
	
	// TODO: REMOVE UPSIDE DOWN
	
	var busQuery = BusQuery()
	var locationWhenPinned = CLLocation()
	var locationHasUpdated: Bool = false
	var autoRefreshTimer = Timer()
	var autoRefreshNearbyBusesTimer = Timer()
	var latestLocation = CLLocation()
	var isMoving: Bool = false
	
	var currentStationNumber = 0 {
		didSet {
			if(ViewController.stationList.count > 0 && currentStationNumber < bearingListNames.count && currentBearingNumber < bearingListNames[currentStationNumber].count) {
				
				switch ViewController.stationTypeList[self.currentStationNumber] {
				case .Bus:
					stationTypeImage.image = UIImage(systemName: "bus.fill")
					stationTypeImage.tintColor = labelStandardBlack
					currentStationLabel.textColor = labelStandardBlack
				case .Metro:
					stationTypeImage.image = UIImage(systemName: "tram.fill")
					stationTypeImage.tintColor = ViewController.stationList[currentStationNumber][0].lineColor
					currentStationLabel.textColor = ViewController.stationList[currentStationNumber][0].lineColor
				default:
					stationTypeImage.image = UIImage(systemName: "bus.fill")
				}
				currentStationLabel.text = stationListNames[currentStationNumber]
				currentStationBearingLabel.text = bearingListNames[currentStationNumber][currentBearingNumber]
				
				let item = bearingIndexToItem[currentStationNumber][currentBearingNumber]
				routeCollectionView.scrollToItem(at: IndexPath(item: item, section: 0), at: .centeredHorizontally, animated: true)
				
				updateStarredAndBannedButton()
			}
			else if(ViewController.stationTypeList[currentStationNumber] == .Metro) {
				stationTypeImage.image = UIImage(systemName: "tram.fill")
				stationTypeImage.tintColor = ViewController.stationList[currentStationNumber][0].lineColor
				currentStationLabel.textColor = ViewController.stationList[currentStationNumber][0].lineColor
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
				
				
				updateStarredAndBannedButton()
			}
			ViewController.bearingNumberForDetailView = currentBearingNumber
		}
	}
	static var stationList: Array<Array<Station>> = []
	var stationListNames = [String]()
	var bearingListNames: Array<Array<String>> = []
	
	static var routeList: Array<Array<Array<BusStop>>> = []
	static var metroRouteList: Array<MetroArrival> = []
	#warning("Consider remove the following")
	var bearingStationDict = [Int:Int]()
	var bearingIndexToItem: Array<Array<Int>> = []	// an array dictionary (currentStationNumber&currentBearingNumber -> target index of routeCollectionView) to give quick access to index of routeCollectionView for autoscroll
	static var bearingItemToIndex: Array<Array<Int>> = []	// an array dictionary (routeCollectionView item index -> currentStationNumber&currentBearingNumber) for left-right scrolling of collectionView
	var bearingStationsCount = 0	// for total number of cells in routeCollectionView
	static var stationTypeList: Array<Station.StationType> = []
	
	var nearbyBusesList = [Bus]()
	
	static var bearingNumberForDetailView = 0	// static version of currentBearingNumber
	static var stationNumberForDetailView = 0	// static version of currentStationNumber
	
	var feedbackGenerator = UINotificationFeedbackGenerator()
	
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
		nearbyBusCollectionView.delegate = self
		nearbyBusCollectionView.dataSource = self
		nearbyBusCollectionView.contentInset = UIEdgeInsets(top: 0.0, left: 15.0, bottom: 0.0, right: view.frame.width / 2 + 20)
		nearbyBusCollectionView.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
		
		stationListCollectionView.contentInset.right = 100	// compensate for the bug that the last cell will be covered due to not enough scrollable length
		
		#warning("maybe load the content first")
		fetchSavedSettings()
		
		applyAutoLayoutConstraints()
		
		self.adBannerView.isHidden = true
		self.adBannerView.delegate = self
		self.adBannerView.adUnitID = "ca-app-pub-5814041924860954/9661829499"
		self.adBannerView.rootViewController = self
		
		updateLocationAndStations()
		
		// Because when app is reopen from background, the animation stops
		NotificationCenter.default.addObserver(self, selector: #selector(backFromBackground), name: UIApplication.didBecomeActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(showRouteDetailVC), name: NSNotification.Name("Detail"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(saveNewLayoutPreference), name: NSNotification.Name("LayoutPreference"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(saveNewStationRadiusPreference), name: NSNotification.Name("StationRadiusPreference"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(removeAdSuccess), name: NSNotification.Name("RemoveAd"), object: nil)
		autoRefreshTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(autoRefresh), userInfo: nil, repeats: true)
		autoRefreshNearbyBuses()
		autoRefreshNearbyBusesTimer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(autoRefreshNearbyBuses), userInfo: nil, repeats: true)
		if(displayAd) {
			self.adBannerView.load(GADRequest())
		}
	}
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	func fetchSavedSettings() {
		if(checkInitial()) {
			presentWelcomeWarning()
		}
		fetchLayoutPreference()
		checkAdRemoval()
		fetchStarredAndBannedStops()
		fetchStationRadiusPreference()
	}
	
	@objc func showRouteDetailVC(notification: Notification) {
		self.performSegue(withIdentifier: "RouteDetail", sender: notification.object)
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
					
					//print("\(self.locationHasUpdated)\t\(address)")
					
					if(!self.locationHasUpdated)  {
						//print("location has not updated")
						self.locationHasUpdated = true
						self.locationWhenPinned = userLocation
						self.updateLocationButton.tintColor = .blue
						self.queryNearbyStations(location: self.locationWhenPinned)
					}
					else {
						//print("location has updated")
						// check if current location is deviated from locationWhenPinned over 30m
						// if so, then dim the location button
						if(userLocation.distance(from: self.locationWhenPinned) > self.locationDeviateThreshold) {
							self.updateLocationButton.tintColor = .lightGray
						}
					}
					
					// check if is moving to either show the nearbyBusesCollectionView
					self.isMoving = (userLocation.distance(from: self.latestLocation) > 5.0)
					self.latestLocation = userLocation
				}
			}
		}
	}
	
	@IBAction func updateLocationButtonPressed(_ sender: Any) {
		presentActivityIndicator()
		updateLocationAndStations()
	}
	
	@IBAction func starButtonPressed(_ sender: Any) {
		if(currentStationNumber < ViewController.stationList.count && currentBearingNumber < ViewController.stationList[currentStationNumber].count) {
			let checkStarredStationId = ViewController.stationList[currentStationNumber][currentBearingNumber].stationId
			if(!stationIsStarred(stationID: checkStarredStationId)) {
				starButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
				starButton.tintColor = .systemYellow
				
				modifyStarredandBannedContext(stationID: checkStarredStationId, starOrBan: 0, addOrRemove: 0)
				
				if(stationIsBanned(stationID: checkStarredStationId)) {
					banButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
					banButton.tintColor = .systemGray
					
					modifyStarredandBannedContext(stationID: checkStarredStationId, starOrBan: 1, addOrRemove: 1)
				}
			}
			else {
				starButton.setImage(UIImage(systemName: "star"), for: .normal)
				starButton.tintColor = .systemGray
				
				modifyStarredandBannedContext(stationID: checkStarredStationId, starOrBan: 0, addOrRemove: 1)
			}
		}
	}
	
	@IBAction func banButtonPressed(_ sender: Any) {
		if(currentStationNumber < ViewController.stationList.count && currentBearingNumber < ViewController.stationList[currentStationNumber].count) {
			let checkBannedStationId = ViewController.stationList[currentStationNumber][currentBearingNumber].stationId
			if(!stationIsBanned(stationID: checkBannedStationId)) {
				banButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
				banButton.tintColor = .systemPink
				
				modifyStarredandBannedContext(stationID: checkBannedStationId, starOrBan: 1, addOrRemove: 0)
				
				// remove the starred station if it is banned
				if(stationIsStarred(stationID: checkBannedStationId)) {
					starButton.setImage(UIImage(systemName: "star"), for: .normal)
					starButton.tintColor = .systemGray
					
					modifyStarredandBannedContext(stationID: checkBannedStationId, starOrBan: 0, addOrRemove: 1)
				}
			}
			else {
				banButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
				banButton.tintColor = .systemGray
				
				modifyStarredandBannedContext(stationID: checkBannedStationId, starOrBan: 1, addOrRemove: 1)
			}
		}
	}
	
	func updateLocationAndStations() {
		buttonActivityIndicator.startAnimating()
		updateLocationButton.isHidden = true
		checkLocationServicePermissionAndStartUpdating()
		locationHasUpdated = false
	}
	
	@objc func autoRefresh() {
		if(ViewController.stationList.count > 0) {
			queryArrivals()
		}
	}
	
	@objc func autoRefreshNearbyBuses() {
		DispatchQueue.global(qos: .background).async {
			self.nearbyBusesList = self.busQuery.queryNearbyBuses(location: self.latestLocation)
			
			DispatchQueue.main.async {
				self.nearbyBusCollectionView.isHidden = (self.nearbyBusesList.count == 0 || !self.isMoving)
				self.nearbyBusCollectionView.reloadData()
				self.nearbyBusCollectionView.scrollToItem(at: IndexPath(item: self.nearbyBusesList.count - 1, section: 0), at: .right, animated: false)
			}
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
			print("querying buses")
			let unorganizedStationList = self.busQuery.queryNearbyBusStations(location: location)
			print("buses done")
			print("querying mrt")
			let metroStationList = self.busQuery.queryNearbyMetroStatoins(location: location)
			print("mrt done")
			var stationTemp = [String]()
			for station in unorganizedStationList {
				stationTemp.append(station.stationName)
			}
			self.stationListNames = stationTemp
			
			if(unorganizedStationList.count == 0) {
				DispatchQueue.main.async {
					self.currentStationLabel.text = "附近沒有車站"
					self.currentStationBearingLabel.text = ""
					ViewController.stationList = []
					ViewController.routeList = []
					self.stationListNames = []
					self.bearingListNames = []
					self.bearingStationsCount = 0
					self.bearingStationDict = [Int:Int]()
					self.bearingIndexToItem = []
					ViewController.bearingItemToIndex = []
					ViewController.stationTypeList = []
					self.updatePanel()
					
					self.buttonActivityIndicator.stopAnimating()
					self.updateLocationButton.isHidden = false
				}
			}
			else {
				var duplicates = Dictionary(grouping: unorganizedStationList, by: {$0.stationName})
				ViewController.stationList = []
				ViewController.routeList = []
				self.stationListNames = []
				self.bearingListNames = []
				self.bearingStationsCount = unorganizedStationList.count
				self.bearingStationDict = [Int:Int]()
				self.bearingIndexToItem = []
				ViewController.bearingItemToIndex = []
				var countForStation = 0
				var countForBearing = 0
				ViewController.stationTypeList = []
				for i in 0..<unorganizedStationList.count {
					if let exist = duplicates[unorganizedStationList[i].stationName] {
						var stationTemp = [Station]()
						var bearingTemp = [String]()
						var routeTemp: Array<Array<BusStop>> = []
						var countForBearingOfCurrentStation = 0
						var countForIndexToItemOfEachStation = [Int]()
						for station in exist {
							stationTemp.append(station)
							bearingTemp.append(station.bearing)
							let routeTempTemp = [BusStop]()
							routeTemp.append(routeTempTemp)
							countForIndexToItemOfEachStation.append(countForBearing)
							countForBearing = countForBearing + 1
							ViewController.bearingItemToIndex.append([countForStation, countForBearingOfCurrentStation])
							countForBearingOfCurrentStation = countForBearingOfCurrentStation + 1
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
						ViewController.stationList.append(stationTemp)
						self.bearingListNames.append(bearingTemp)
						self.stationListNames.append(unorganizedStationList[i].stationName)
						ViewController.routeList.append(routeTemp)
						self.bearingStationDict[countForStation] = countForBearingOfCurrentStation
						self.bearingIndexToItem.append(countForIndexToItemOfEachStation)
						ViewController.stationTypeList.append(.Bus)
						countForStation = countForStation + 1
						
						duplicates.removeValue(forKey: unorganizedStationList[i].stationName)
					}
				}
				
				// insert Metro statoins
				for i in 0..<metroStationList.count {
					for j in 0..<ViewController.stationList.count {
						var metroStationIsCloser = true
						for k in 0..<ViewController.stationList[j].count {
							if(metroStationList[i].location.distance(from: self.locationWhenPinned) > ViewController.stationList[j][k].location.distance(from: self.locationWhenPinned)) {
								metroStationIsCloser = false
								break
							}
						}
						
						if(metroStationIsCloser) {
							let temp: Array<Station> = [metroStationList[i]]
							ViewController.stationList.insert(temp, at: j)
							self.stationListNames.insert(metroStationList[i].stationName, at: j)
							self.bearingListNames.insert(["捷運站"], at: j)
							ViewController.routeList.insert([], at: j)
							let last = (j == 0) ? 0:(self.bearingIndexToItem[j-1].last! + 1)
							self.bearingIndexToItem.insert([last], at: j)
							ViewController.stationTypeList.insert(.Metro, at: j)
							
							var insertStarted = false
							var index = 0
							while index < ViewController.bearingItemToIndex.count {
								if(!insertStarted && ViewController.bearingItemToIndex[index][0] == j) {
									ViewController.bearingItemToIndex.insert([j, 0], at: index)
									insertStarted = true
									index = index + 1
									continue
								}
								if(insertStarted) {
									ViewController.bearingItemToIndex[index][0] = ViewController.bearingItemToIndex[index][0] + 1
								}
								
								index = index + 1
							}
							for k in (j+1)..<ViewController.stationList.count {
								for l in 0..<self.bearingIndexToItem[k].count {
									self.bearingIndexToItem[k][l] = self.bearingIndexToItem[k][l] + 1
								}
							}
							
							self.bearingStationsCount = self.bearingStationsCount + 1
							break
						}
					}
				}
				
				DispatchQueue.main.async {
					self.routeCollectionView.reloadData()	// not sure why this, but otherwise first load will not make routeCollectionView autoscroll
					self.currentStationNumber = 0
					self.skipBannedBearingStation()
					self.findStarredBearingStation()
					self.updatePanel()
					
					self.queryArrivals()
					self.stationListCollectionView.scrollToItem(at: IndexPath(item: self.currentStationNumber, section: 0), at: .centeredHorizontally, animated: true)
					
					self.buttonActivityIndicator.stopAnimating()
					self.updateLocationButton.isHidden = false
					self.feedbackGenerator.notificationOccurred(.success)
				}
			}
		}
	}
	
	func queryArrivals() {
		presentActivityIndicator()
		//print(stationList[currentStationNumber][currentBearingNumber].stationId)
		DispatchQueue.global(qos: .background).async {
			if(ViewController.stationTypeList[self.currentStationNumber] == .Bus) {
				ViewController.routeList[self.currentStationNumber][self.currentBearingNumber] = self.busQuery.queryBusArrivals(station: ViewController.stationList[self.currentStationNumber][self.currentBearingNumber])
			}
			else {
				ViewController.metroRouteList = self.busQuery.queryMetroArrivals(metroStation: ViewController.stationList[self.currentStationNumber][0])
			}

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
	
	func checkInitial() -> Bool {
		var initialUse: Bool?
		do {
			let initial = try context.fetch(Initial.fetchRequest()) as! [Initial]
			if(initial.count > 0 && initial[initial.count - 1].notInitialUse == true) {
				initialUse = false
			}
			else {
				initialUse = true
			}
		} catch {
			print("Error fetching Initial")
			initialUse = true
		}
		
		return (initialUse ?? true) ? true:false
	}
	
	func presentWelcomeWarning() {
		DispatchQueue.main.async {
			let welcomeAlert = UIAlertController(title: "初次使用", message: "資料更新可能延誤，請注意實際交通狀況。本 App 不負任何責任。\n\n資料來源：交通部PTX平臺、台北捷運公司", preferredStyle: .alert)
			let okAction = UIAlertAction(title: "好的", style: .default, handler: {_ in
				let newInitial = Initial(context: self.context)
				newInitial.notInitialUse = true
				do {
					try self.context.save()
				} catch {
					print("Error saving Initial")
				}
				
				self.dismissActivityIndicator()
				self.locationManager.requestWhenInUseAuthorization()
			})
			welcomeAlert.addAction(okAction)
			self.present(welcomeAlert, animated: true, completion: nil)
		}
	}
	
	func fetchLayoutPreference() {
		do {
			layoutPreferenceData = try (context.fetch(UpSideUp.fetchRequest()) as? [UpSideUp])!
			if(layoutPreferenceData.count == 0) {
				upSideUpLayout = true
				let newLayoutPreference = UpSideUp(context: self.context)
				newLayoutPreference.upSideUp = upSideUpLayout
				try self.context.save()
			} else {
				upSideUpLayout = layoutPreferenceData.last!.upSideUp
				
				print("\(upSideUpLayout ? "UP":"DOWN") preference data count \(layoutPreferenceData.count)")
			}
		} catch {
			print("Error fetching layout preference")
		}
	}
	
	func fetchStarredAndBannedStops() {
		do {
			starredStations = try (context.fetch(StarredStation.fetchRequest()) as? [StarredStation])!
			print("\(starredStations.count) starred stations")
		} catch {
			print("Error fetching starredStations")
		}
		
		do {
			bannedStations = try (context.fetch(BannedStation.fetchRequest()) as? [BannedStation])!
			print("\(bannedStations.count) banned stations")
		} catch {
			print("Error fetching bannedStations")
		}
	}
	
	@objc func saveNewLayoutPreference() {
		updateLayoutConstraint()
		do {
			layoutPreferenceData = try context.fetch(UpSideUp.fetchRequest()) as! [UpSideUp]
			layoutPreferenceData.last!.upSideUp = upSideUpLayout
			try self.context.save()
		} catch {
			print("Error saving new layout preference")
		}
	}
	
	@objc func saveNewStationRadiusPreference() {
		do {
			stationRadiusPreferenceData = try context.fetch(StationRadius.fetchRequest()) as! [StationRadius]
			stationRadiusPreferenceData.last!.stationRadius = stationRadius
			try self.context.save()
		} catch {
			print("Error saving station radius preference")
		}
	}
	
	func modifyStarredandBannedContext(stationID: String, starOrBan: Int, addOrRemove: Int) {
		// 0 for star, 0 for add, 1 for ban, 1 for remove
		
		if(addOrRemove == 0) {
			if(starOrBan == 0) {
				let starred = StarredStation(context: self.context)
				starred.stationID = stationID
				starredStations.append(starred)
				do {
					try self.context.save()
				} catch {
					print("Error saving starred station")
				}
			}
			else if(starOrBan == 1) {
				let banned = BannedStation(context: self.context)
				banned.stationID = stationID
				bannedStations.append(banned)
				do {
					try self.context.save()
				} catch {
					print("Error saving banned station")
				}
			}
		}
		else if(addOrRemove == 1) {
			if(starOrBan == 0) {
				for i in 0..<starredStations.count {
					if(starredStations[i].stationID == stationID) {
						self.context.delete(starredStations[i])
						do {
							try self.context.save()
						} catch {
							print("Error deleting starred station")
						}
						starredStations.remove(at: i)
						break
					}
				}
			}
			else if(starOrBan == 1) {
				for i in 0..<bannedStations.count {
					if(bannedStations[i].stationID == stationID) {
						self.context.delete(bannedStations[i])
						do {
							try self.context.save()
						} catch {
							print("Error deleting banned station")
						}
						bannedStations.remove(at: i)
						break
					}
				}
			}
		}
	}
	
	func updateStarredAndBannedButton() {
		let stationId = ViewController.stationList[currentStationNumber][currentBearingNumber].stationId
		if(stationIsStarred(stationID: stationId)) {
			starButton.setImage(UIImage(systemName: "star.fill"), for: .normal)
			starButton.tintColor = .systemYellow
		}
		else {
			starButton.setImage(UIImage(systemName: "star"), for: .normal)
			starButton.tintColor = .systemGray
		}
		
		if(stationIsBanned(stationID: stationId)) {
			banButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
			banButton.tintColor = .systemPink
		}
		else {
			banButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
			banButton.tintColor = .systemGray
		}
	}
	
	func stationIsStarred(stationID: String) -> Bool {
		let stationId = ViewController.stationList[currentStationNumber][currentBearingNumber].stationId
		for i in 0..<starredStations.count {
			if(starredStations[i].stationID == stationId) {
				return true
			}
		}
		
		return false
	}
	
	func stationIsBanned(stationID: String) -> Bool {
		let stationId = ViewController.stationList[currentStationNumber][currentBearingNumber].stationId
		for i in 0..<bannedStations.count {
			if(bannedStations[i].stationID == stationId) {
				return true
			}
		}
		
		return false
	}
	
	func findStarredBearingStation() {	// TODO: IMPROVE ALGORITHM
		var bearingNumberForBackup: Int?
		for i in 0..<ViewController.stationList[currentStationNumber].count {
			if(starredStations.contains(where: {$0.stationID == ViewController.stationList[currentStationNumber][i].stationId})) {
				currentBearingNumber = i
				return
			}
			if(!bannedStations.contains(where: {$0.stationID == ViewController.stationList[currentStationNumber][i].stationId}) && bearingNumberForBackup == nil) {
				bearingNumberForBackup = i
			}
			
		}
		
		currentBearingNumber = ((bearingNumberForBackup == nil) ? 0:bearingNumberForBackup)!
	}
	
	func skipBannedBearingStation() {
		for i in 0..<ViewController.stationList.count {
			for j in 0..<ViewController.stationList[i].count {
				if(!bannedStations.contains(where: {$0.stationID == ViewController.stationList[i][j].stationId})) {
					currentStationNumber = i
					currentBearingNumber = j
					return
				}
			}
		}
		
		currentStationNumber = 0
		currentBearingNumber = 0
	}
	
	@objc func backFromBackground() {
		autoRefresh()
		autoRefreshNearbyBuses()
	}
	
	func presentActivityIndicator() {
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
	}
	func dismissActivityIndicator() {
		activityIndicator.isHidden = true
		activityIndicator.stopAnimating()
	}
	
	func fetchStationRadiusPreference() {
		do {
			stationRadiusPreferenceData = try context.fetch(StationRadius.fetchRequest()) as! [StationRadius]
			if(stationRadiusPreferenceData.count > 0) {
				stationRadius = stationRadiusPreferenceData.last!.stationRadius
				print("Station Radius \(stationRadius)m")
			}
			else {
				let newStationRadius = StationRadius(context: self.context)
				newStationRadius.stationRadius = stationRadius
				try self.context.save()
			}
		} catch {
			print("Error fetching station radius preference")
		}
	}
	
	func checkAdRemoval() {
		do {
			needAdData = try context.fetch(Ad.fetchRequest()) as! [Ad]
			if(needAdData.count > 0 && needAdData[needAdData.count - 1].needAd == false) {
				print("No need ad")
				displayAd = false
			}
			else {
				if(needAdData.count == 0) {
					let ad = Ad(context: self.context)
					ad.needAd = true
					try self.context.save()
				}
				print("Need Ad")
				displayAd = true
			}
		} catch {
			print("Error fetching or storing needAd")
			displayAd = true
		}
	}
	
	@objc func removeAdSuccess() {
		let msg = displayAd ? "移除廣告":"復原廣告"
		ErrorAlert.presentErrorAlert(title: msg, message: "")
		
		do {
			needAdData = try context.fetch(Ad.fetchRequest()) as! [Ad]
			needAdData[needAdData.count - 1].needAd = !displayAd
			try self.context.save()
		}
		catch {
			print("Error saving context remove ad")
		}
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		if(CLLocationManager.locationServicesEnabled() &&
			(locationManager.authorizationStatus == .authorizedAlways ||
				locationManager.authorizationStatus == .authorizedWhenInUse)){
			
			locationManager.startUpdatingLocation()
		}
	}
	
	func applyAutoLayoutConstraints() {

		self.whiteViewToBottomRouteCollectionViewConstraintB = NSLayoutConstraint(item: whiteView!, attribute: .top, relatedBy: .equal, toItem: routeCollectionView, attribute: .bottom, multiplier: 1.0, constant: 0.0)
		self.bearingCollectionViewToBottomSafeAreaConstraintB = NSLayoutConstraint(item: bearingListCollectionView!, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: -20.0)
		self.bearingCollectionViewToTopAdBannerConstraintB = NSLayoutConstraint(item: bearingListCollectionView!, attribute: .bottom, relatedBy: .equal, toItem: adBannerView, attribute: .top, multiplier: 1.0, constant: -20.0)
		self.routeCollectionViewToTopSafeAreaConstraintB = NSLayoutConstraint(item: routeCollectionView!, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1.0, constant: 0.0)
		
		self.routeCollectionViewToTopAdBannerConstraintA = NSLayoutConstraint(item: routeCollectionView!, attribute: .bottom, relatedBy: .equal, toItem: adBannerView, attribute: .top, multiplier: 1.0, constant: 0.0)
		self.updateButtonToAdBannerConstraintA = NSLayoutConstraint(item: updateLocationButton!, attribute: .bottom, relatedBy: .equal, toItem: adBannerView, attribute: .top, multiplier: 1.0, constant: -20.0)
		self.aboutButtonToAdBannerConstraintA = NSLayoutConstraint(item: aboutButton!, attribute: .bottom, relatedBy: .equal, toItem: adBannerView, attribute: .top, multiplier: 1.0, constant: -15.0)
		self.updateButtonToWhiteViewTopConstraintB = NSLayoutConstraint(item: updateLocationButton!, attribute: .bottom, relatedBy: .equal, toItem: whiteView, attribute: .top, multiplier: 1.0, constant: -40.0)
		self.updateButtonToTrailingConstraintB = NSLayoutConstraint(item: updateLocationButton!, attribute: .right, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .right, multiplier: 1.0, constant: -30.0)
		self.aboutButtonToUpdateButtonVerticalSpacingConstraintB = NSLayoutConstraint(item: aboutButton!, attribute: .bottom, relatedBy: .equal, toItem: updateLocationButton!, attribute: .top, multiplier: 1.0, constant: -10.0)
		
		updateLayoutConstraint()
	}
	
	@objc func updateLayoutConstraint() {
		
		if(upSideUpLayout) {
			NSLayoutConstraint.deactivate([whiteViewToBottomRouteCollectionViewConstraintB!, bearingCollectionViewToBottomSafeAreaConstraintB!, bearingCollectionViewToTopAdBannerConstraintB!, updateButtonToWhiteViewTopConstraintB!, updateButtonToTrailingConstraintB!, aboutButtonToUpdateButtonVerticalSpacingConstraintB!])
			
			NSLayoutConstraint.deactivate([routeCollectionViewToTopSafeAreaConstraintB!, routeCollectionViewToTopAdBannerConstraintA!, updateButtonToAdBannerConstraintA!, aboutButtonToAdBannerConstraintA!])
			
			NSLayoutConstraint.activate([whiteViewToTopSafeAreaConstraintA, bearingCollectionViewToRouteCollectionViewConstraintA, routeCollectionViewToBottomConstraintA, updateButtonAtCenterConstraintA, updateButtonToSafeAreaConstraintA, aboutButtonToSafeAreaConstraintA])

			whiteView.clipsToBounds = true
			bearingListCollectionView.clipsToBounds = false
		}
		else {
			NSLayoutConstraint.deactivate([whiteViewToTopSafeAreaConstraintA, bearingCollectionViewToRouteCollectionViewConstraintA, routeCollectionViewToBottomConstraintA, routeCollectionViewToTopAdBannerConstraintA!, updateButtonAtCenterConstraintA, updateButtonToSafeAreaConstraintA, updateButtonToAdBannerConstraintA!, aboutButtonToSafeAreaConstraintA, aboutButtonToAdBannerConstraintA!])
			
			NSLayoutConstraint.deactivate([bearingCollectionViewToTopAdBannerConstraintB!])
			
			NSLayoutConstraint.activate([whiteViewToBottomRouteCollectionViewConstraintB!, bearingCollectionViewToBottomSafeAreaConstraintB!, routeCollectionViewToTopSafeAreaConstraintB!, updateButtonToWhiteViewTopConstraintB!, updateButtonToTrailingConstraintB!, aboutButtonToUpdateButtonVerticalSpacingConstraintB!])
			
			whiteView.clipsToBounds = false
			bearingListCollectionView.clipsToBounds = true
		}
		
		updateLayoutConstraintWithAd()
		
		routeCollectionView.reloadData()
	}
	
	func updateLayoutConstraintWithAd() {
		if(upSideUpLayout) {
			routeCollectionViewToBottomConstraintA.isActive = !adDisplayedSuccessfully
			routeCollectionViewToTopAdBannerConstraintA?.isActive = adDisplayedSuccessfully
			updateButtonToSafeAreaConstraintA.isActive = !adDisplayedSuccessfully
			updateButtonToAdBannerConstraintA?.isActive = adDisplayedSuccessfully
			aboutButtonToSafeAreaConstraintA.isActive = !adDisplayedSuccessfully
			aboutButtonToAdBannerConstraintA?.isActive = adDisplayedSuccessfully
		} else {
			bearingCollectionViewToBottomSafeAreaConstraintB?.isActive = !adDisplayedSuccessfully
			bearingCollectionViewToTopAdBannerConstraintB?.isActive = adDisplayedSuccessfully
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
		else if(collectionView == routeCollectionView) {
			return bearingStationsCount
		}
		else {
			return nearbyBusesList.count
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		if(collectionView == stationListCollectionView) {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StationCell", for: indexPath) as! StationListCollectionViewCell
			
			if(ViewController.stationTypeList[indexPath.item] == .Bus) {
				if(currentStationNumber == indexPath.item) {
					cell.backgroundColor = UIColor(white: 0.45, alpha: 1.0)
					cell.stationLabel.textColor = UIColor(white: 1.0, alpha: 1.0)
				}
				else {
					cell.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
					cell.stationLabel.textColor = UIColor(white: 0.0, alpha: 1.0)
				}
			}
			else {
				if(currentStationNumber == indexPath.item) {
					cell.backgroundColor = ViewController.stationList[indexPath.item][0].lineColor
					cell.stationLabel.textColor = ViewController.stationList[indexPath.item][0].lineLabelColor
				}
				else {
					cell.backgroundColor = ViewController.stationList[indexPath.item][0].lineColorUnselected
					cell.stationLabel.textColor = ViewController.stationList[indexPath.item][0].lineLabelColor
				}
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
		else if(collectionView == routeCollectionView) {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RouteCollectionCell", for: indexPath) as! RouteCollectionViewCell
			
			cell.routeListTableView.tag = indexPath.item
			cell.routeListTableView.reloadData()
			
			return cell
		}
		else {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NearbyBuses", for: indexPath) as! NearbyBusesCollectionViewCell
			
			cell.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
			
			cell.routeName = nearbyBusesList[indexPath.row].routeName
			cell.plateNumber = nearbyBusesList[indexPath.row].plateNumber
			cell.distance = nearbyBusesList[indexPath.row].distance
			
			return cell
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if(collectionView == stationListCollectionView) {
			currentStationNumber = indexPath.item
			findStarredBearingStation()
			collectionView.reloadData()
			bearingListCollectionView.reloadData()
			queryArrivals()
		}
		else if(collectionView == bearingListCollectionView) {
			currentBearingNumber = indexPath.item
			collectionView.reloadData()
			queryArrivals()
		}
		else if(collectionView == nearbyBusCollectionView) {
			let busForNearbyBus = nearbyBusesList[indexPath.item]
			let busStopForNearbyBus = BusStop(stopId: "no", city: busForNearbyBus.city, routeId: busForNearbyBus.routeId, routeName: busForNearbyBus.routeName)
			busStopForNearbyBus.plateNumber = busForNearbyBus.plateNumber
			busStopForNearbyBus.direction = busForNearbyBus.direction
			
			NotificationCenter.default.post(name: NSNotification.Name("Detail"), object: busStopForNearbyBus)
		}
	}
	
	func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		
		let x = targetContentOffset.pointee.x
		
		if(scrollView == routeCollectionView.self) {
			let page = Int(x/routeCollectionView.frame.width)
			currentBearingNumber = ViewController.bearingItemToIndex[page][1]
			currentStationNumber = ViewController.bearingItemToIndex[page][0]
			queryArrivals()
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
		else if(collectionView == routeCollectionView) {
			return CGSize(width: routeCollectionView.frame.width, height: routeCollectionView.frame.height)
		}
		else {
			return CGSize(width: 100.0, height: 65.0)
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
		let stationNumber = ViewController.bearingItemToIndex[tableView.tag][0]
		let bearingNumber = ViewController.bearingItemToIndex[tableView.tag][1]
		if(ViewController.stationTypeList[stationNumber] == .Bus) {
			return ViewController.routeList[stationNumber][bearingNumber].count
		}
		else {
			return ViewController.metroRouteList.count
		}
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let stationNumber = ViewController.bearingItemToIndex[tableView.tag][0]
		let bearingNumber = ViewController.bearingItemToIndex[tableView.tag][1]
		
		if(ViewController.stationTypeList[stationNumber] == .Bus) {
			let cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell") as! RouteTableViewCell
			
			if(!upSideUpLayout) {
				cell.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi));
			}
			cell.routeName = ViewController.routeList[stationNumber][bearingNumber][indexPath.row].routeName
			cell.information = ViewController.routeList[stationNumber][bearingNumber][indexPath.row].information
			cell.destination = ViewController.routeList[stationNumber][bearingNumber][indexPath.row].destination
			cell.labelColor = ViewController.routeList[stationNumber][bearingNumber][indexPath.row].informationLabelColor
			
			return cell
		}
		else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "MetroCell") as! MetroRouteTableViewCell
			
			if(!upSideUpLayout) {
				cell.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi));
			}
			
			cell.destination = ViewController.metroRouteList[indexPath.row].destinationName
			cell.lineName = ViewController.metroRouteList[indexPath.row].lineName!
			cell.lineColor = ViewController.metroRouteList[indexPath.row].lineColor
			cell.lineLabelColor = ViewController.metroRouteList[indexPath.row].lineLabelColor
			cell.informationLabelColor = ViewController.metroRouteList[indexPath.row].informationLabelColor
			cell.estimatedArrival = ViewController.metroRouteList[indexPath.row].estimatedArrival
			cell.status = ViewController.metroRouteList[indexPath.row].status!
			
			if let crowdness = ViewController.metroRouteList[indexPath.row].crowdness {
				cell.crowdness = crowdness
			}
			else {
				cell.crowdness = [0]
			}
			
			cell.currentStation = ViewController.metroRouteList[indexPath.row]
			
			return cell
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if(ViewController.stationTypeList[ViewController.stationNumberForDetailView] == .Bus) {
			NotificationCenter.default.post(name: NSNotification.Name("Detail"), object: ViewController.routeList[ViewController.stationNumberForDetailView][ViewController.bearingNumberForDetailView][indexPath.row])
			print("sending \(Unmanaged.passUnretained(ViewController.routeList[ViewController.stationNumberForDetailView][ViewController.bearingNumberForDetailView][indexPath.row]).toOpaque())")
		} else {
			//performSegue(withIdentifier: "MetroDetail", sender: ViewController.metroRouteList[indexPath.row])
		}
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if(type(of: cell) == RouteTableViewCell.self) {
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
		else {
			
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 55.0
	}
}

extension ViewController: UIPopoverPresentationControllerDelegate {
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
		segue.destination.modalPresentationStyle = .popover
		
		if(segue.identifier == "RouteDetail") {
			let destination = segue.destination as! RouteDetailViewController
			destination.busStop = sender as? BusStop
		}
		else if(segue.identifier == "MetroDetail") {
			let destination = segue.destination as! MetroDetailViewController
			destination.metroRouteTableViewCell = sender as? MetroRouteTableViewCell
			// unknown reason that MetroDetailViewController shows before didSelect is called
		}
		else if(segue.identifier == "About") {
			let destination = segue.destination as! AboutViewController
			destination.preferredContentSize = CGSize(width: 350.0, height: 300.0)
			destination.popoverPresentationController?.delegate = self
		}

	}
	
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
	}
}

extension ViewController: GADBannerViewDelegate {
	
	func adViewWillPresentScreen(_ bannerView: GADBannerView) {
		print("Ad will present")
	}
	
	func adViewDidRecordImpression(_ bannerView: GADBannerView) {
		print("Ad impression recorded")
	}
	
	func adViewDidReceiveAd(_ bannerView: GADBannerView) {
		print("Ad loaded successfully")
		
		adDisplayedSuccessfully = true
	}
	
	func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
		print("Ad failed to load. \(error.localizedDescription) code: \(error.code)")
		adDisplayedSuccessfully = false
	}
}

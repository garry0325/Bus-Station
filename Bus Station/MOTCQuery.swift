//
//  MOTCQuery.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/19.
//

import Foundation
import CoreLocation
import CryptoKit

class BusQuery {
	let timeoutForRequest = 10.0
	let timeoutForResource = 15.0
    
    static let shared = BusQuery()
    
    let clientID = "garry0325-75250675-1b48-4617"
    let clientSecret = "c368a2ed-9b1f-4f3d-9df9-43d0511d0d7b"
    var token = ""
	
	var urlConfig = URLSessionConfiguration.default
	
	var nearbyStationWidth = 0.005	// in degree coordinates
	var nearbyStationHeight = 0.0035
	let nearbyBusesWidth = Double(100.0 / 100925)
	let nearbyBusesHeight = Double(100.0 / 110803)
	
	let queryCities = ["Taipei", "NewTaipei"]
	let queryMetroSystems = ["TRTC", "NTDLRT", "TYMC"] // TODO: test TYMC & NTDLRT
	
	let metroDateFormatter: DateFormatter
	
	init() {
		metroDateFormatter = DateFormatter()
		metroDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
		
		urlConfig.timeoutIntervalForRequest = timeoutForRequest
		urlConfig.timeoutIntervalForResource = timeoutForResource
	}
    
    func refreshToken() {
        let semaphore = DispatchSemaphore(value: 0)
        
        let tokenUrl = URL(string: "https://tdx.transportdata.tw/auth/realms/TDXConnect/protocol/openid-connect/token")!
        let data: Data = "grant_type=client_credentials&client_id=\(clientID)&client_secret=\(clientSecret)".data(using: .utf8)!
        
        var request = URLRequest(url: tokenUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        let session = URLSession(configuration: urlConfig)
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    ErrorAlert.presentErrorAlert(title: "Token錯誤", message: "取得Token時發生錯誤A")
                }
            }
            
            if let data = data, let response = response as? HTTPURLResponse {
                print("Token response \(response.statusCode)")
                do {
                    let tokenResponse = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                    self.token = tokenResponse["access_token"] as! String
                    
                    // save token
                    let savedAPI = try context.fetch(API.fetchRequest()) as! [API]
                    savedAPI[savedAPI.count - 1].token = self.token
                    savedAPI[savedAPI.count - 1].date = Date()
                    try context.save()
                } catch {
                    print("Error: \(error.localizedDescription)")
                    
                    DispatchQueue.main.async {
                        ErrorAlert.presentErrorAlert(title: "Token錯誤", message: "取得Token時發生錯誤\(response.statusCode)")
                    }
                }
            }
            
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
    }
	
	func queryNearbyBusStations(location: CLLocation) -> [Station] {
		self.updateStationRadius()
		
		let semaphore = DispatchSemaphore(value: 0)
		var request: URLRequest
		
		var stationDict = [String: Station]()
		
		let currentLatitude = location.coordinate.latitude
		let currentLongitude = location.coordinate.longitude
		
		let session = URLSession(configuration: urlConfig)
		
		for city in queryCities {
			let urlStation = URL(string: "https://tdx.transportdata.tw/api/basic/v2/Bus/Station/City/\(city)?$select=StationID%2C%20StationName%2C%20StationPosition%2C%20Stops&$filter=StationPosition%2FPositionLat%20ge%20\(currentLatitude - nearbyStationHeight)%20and%20StationPosition%2FPositionLat%20le%20\(currentLatitude + nearbyStationHeight)%20and%20StationPosition%2FPositionLon%20ge%20\(currentLongitude - nearbyStationWidth)%20and%20StationPosition%2FPositionLon%20le%20\(currentLongitude + nearbyStationWidth)&$format=JSON")!
			request = URLRequest(url: urlStation)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
			let task = session.dataTask(with: request) { (data, response, error) in
				if let error = error {
					self.presentErrorMessage(query: "station query", description: error.localizedDescription, code: nil)
				}
				else if let response = response as? HTTPURLResponse,
						let data = data {
					if(response.statusCode == 200) {
						let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
						for station in rawReturned! {
							let stationID = station["StationID"] as! String
							var temp = [BusStop]()
							let stops = station["Stops"] as! [[String: Any]]
							for stop in stops {
								let busStop = BusStop(stopId: stop["StopID"] as! String, city: city, routeId: stop["RouteID"] as! String, routeName: (stop["RouteName"] as! [String: String])["Zh_tw"]!)
								temp.append(busStop)
							}
							if(stationDict[stationID] == nil) {
								let stationPositionRaw = station["StationPosition"] as! [String: Any]
								let stationLocation = CLLocation(latitude: stationPositionRaw["PositionLat"] as! Double, longitude: stationPositionRaw["PositionLon"] as! Double)
								
								stationDict[stationID] = Station(stationName: (station["StationName"] as! [String: String])["Zh_tw"]!, stationId: stationID, stationType: .Bus)
								stationDict[stationID]!.location = stationLocation
								stationDict[stationID]!.stops = temp
							}
							else {
								stationDict[stationID]!.stops = stationDict[stationID]!.stops + temp
							}
						}
					}
					else {
						self.presentErrorMessage(query: "station query", description: "status code", code: response.statusCode)
					}
				}
				semaphore.signal()
			}
			task.resume()
			semaphore.wait()
		}
		
		var stationList: [Station] = []
		var stationIDs = [String]()
		for (stationID, station) in stationDict {
			stationList.append(station)
			stationIDs.append(stationID)
		}
		stationList.sort(by: {$0.location.distance(from: location) <= $1.location.distance(from: location)})
		print("共\(stationList.count)站")
		
		for city in queryCities {
			let stationIDQuery = "StationID eq '" + (stationIDs.joined(separator: "' or StationID eq '")) + "'"
			let urlStop = URL(string: String("https://tdx.transportdata.tw/api/basic/v2/Bus/Stop/City/\(city)?$select=StationID, Bearing&$filter=\(stationIDQuery)&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			request = URLRequest(url: urlStop)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
			let task = session.dataTask(with: request) { (data, response, error) in
				if let error = error {
					self.presentErrorMessage(query: "bearing query", description: error.localizedDescription, code: nil)
				}
				else if let response = response as? HTTPURLResponse,
						let data = data {
					if(response.statusCode == 200) {
						let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
						for station in rawReturned! {
							stationDict[station["StationID"] as! String]?.bearing = (station["Bearing"] ?? "") as! String	// Some station has no bearing
						}
					}
					else {
						self.presentErrorMessage(query: "bearing query", description: "status code", code: response.statusCode)
					}
				}
				semaphore.signal()
			}
			task.resume()
		}
		for _ in 0..<queryCities.count {
			semaphore.wait()
		}
		
		
		
		return stationList
		// list like [[BusStation], [BusStation]...] ordered by distance
	}
	
	func queryBusArrivals(station: Station) -> [BusStop] {
		let semaphore = DispatchSemaphore(value: 0)
		var request: URLRequest
		
		var stopsList = [BusStop]()
		var routeDict = [String: BusStop]()
		
		let session = URLSession(configuration: urlConfig)
		
		for city in queryCities {
			var stopIDs = [String]()
			for stop in station.stops {
				stopIDs.append(stop.stopId)
			}
			let stopIDQuery = "StopID eq '" + stopIDs.joined(separator: "' or StopID eq '") + "'"
			let urlEstimatedTimeOfArrival = URL(string: String("https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/\(city)?$select=StopID, RouteID, RouteName, Direction, EstimateTime, StopStatus&$filter=\(stopIDQuery)&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			request = URLRequest(url: urlEstimatedTimeOfArrival)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
			let task = session.dataTask(with: request) { (data, response, error) in
				if let error = error {
					self.presentErrorMessage(query: "N1 for main", description: error.localizedDescription, code: nil)
				}
				else if let response = response as? HTTPURLResponse,
						let data = data {
					if(response.statusCode == 200) {
						let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
						for route in rawReturned! {
							let busStopTemp = BusStop(stopId: route["StopID"] as! String, city: city, routeId: route["RouteID"] as! String, routeName: (route["RouteName"] as! [String: String])["Zh_tw"]!)
							busStopTemp.direction = route["Direction"] as! Int
							busStopTemp.estimatedArrival = (route["EstimateTime"] as? Int ?? -1)
							busStopTemp.stopStatus = BusStop.StopStatus(rawValue: route["StopStatus"] as! Int)!
							// should set the estimatedArrival first because the didSet in stopStatus needs this information to infer
							
							routeDict[busStopTemp.routeId] = busStopTemp
							stopsList.append(busStopTemp)
						}
					}
					else {
						self.presentErrorMessage(query: "N1 for main", description: "status code", code: response.statusCode)
					}
				}
				semaphore.signal()
			}
			task.resume()
		}
		
		for _ in 0..<queryCities.count {
			semaphore.wait()
		}
		
		// get departure & destination stop information based on direction
		for city in queryCities {
			var routeIDs = [String]()
			for stop in station.stops {
				routeIDs.append(stop.routeId)
			}
			let destinationQuery = "RouteID eq '" + routeIDs.joined(separator: "' or RouteID eq '") + "'"
			let urlRoute = URL(string: String("https://tdx.transportdata.tw/api/basic/v2/Bus/Route/City/\(city)?$select=RouteID, DepartureStopNameZh, DestinationStopNameZh, TicketPriceDescriptionZh&$filter=\(destinationQuery)&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			request = URLRequest(url: urlRoute)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
			let task = session.dataTask(with: request) { (data, response, error) in
				if let error = error {
					self.presentErrorMessage(query: "destination", description: error.localizedDescription, code: nil)
				}
				else if let response = response as? HTTPURLResponse,
						let data = data {
					if(response.statusCode == 200) {
						let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
						for destination in rawReturned! {
							let routeId = destination["RouteID"] as! String
                            
                            if let des = routeDict[routeId] {
                                des.destination = "往" + (routeDict[routeId]!.direction == 0 ? destination["DestinationStopNameZh"] as! String : destination["DepartureStopNameZh"] as! String)
                            }
							//routeDict[routeId]!.destination = "往" + (routeDict[routeId]!.direction == 0 ? destination["DestinationStopNameZh"] as! String : destination["DepartureStopNameZh"] as! String)
						}
					}
					else {
						self.presentErrorMessage(query: "destination", description: "status code", code: response.statusCode)
					}
				}
				semaphore.signal()
			}
			task.resume()
		}
		
		for _ in 0..<queryCities.count {
			semaphore.wait()
		}
		
		
		stopsList.sort{ (a, b) -> Bool in
			if(a.estimatedArrival == -1) {
				return false
			}
			else if(b.estimatedArrival == -1) {
				return true
			}
			else {
				return a.estimatedArrival <= b.estimatedArrival
			}
		}
		/*
		for stop in stopsList {
		print("\(stop.routeId)\t\(stop.routeName)\t\(stop.information)")
		}*/
        
		return stopsList
		// list of [[BusStop], [BusStop]...] ordered by estimatedArrival
	}
	
	func queryRealTimeBusLocation(busStop: BusStop) -> [BusStopLiveStatus] {
		var request: URLRequest
		
		let semaphore = DispatchSemaphore(value: 0)
		var busStopLiveStatus = [BusStopLiveStatus]()
		// because StopSequence might not be continuous, so two dicts are used
		var stopIDtoSequenceDict = [String: Int]()
		var sequenceToIndexDict = [Int: Int]()
		var sequenceIndexCount = 0
		var currentStopSequence: Int?
		var plateNumbertoIndexDict = [String: Int]()
		
		let session = URLSession(configuration: urlConfig)
		
		// get the stop sequence of a route first
		let urlStopOfRoute = URL(string: String("https://tdx.transportdata.tw/api/basic/v2/Bus/DisplayStopOfRoute/City/\(busStop.city)?$filter=RouteID eq '\(busStop.routeId)' and Direction eq \(busStop.direction)&$select=RouteID, Direction, Stops&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: urlStopOfRoute)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
		let task = session.dataTask(with: request) { (data, response, error) in
			if let error = error {
				self.presentErrorMessage(query: "All bus stops time", description: error.localizedDescription, code: nil)
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let stops = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])[0]["Stops"] as? [[String: Any]]
					var saveTime = true
					for stop in stops! {
						let stopSequence = stop["StopSequence"] as! Int
						busStopLiveStatus.append(BusStopLiveStatus(stopId: stop["StopID"] as! String, stopName: (stop["StopName"] as! [String: String])["Zh_tw"]!, sequence: stopSequence))
						
						busStopLiveStatus.last!.location = CLLocation(latitude: (stop["StopPosition"] as! [String: Any])["PositionLat"] as! Double, longitude: (stop["StopPosition"] as! [String: Any])["PositionLon"] as! Double)
						
						if(saveTime && busStopLiveStatus.last?.stopId == busStop.stopId) {
							busStopLiveStatus.last?.isCurrentStop = true
							currentStopSequence = busStopLiveStatus.count - 1
							saveTime = false
						}
						
						sequenceToIndexDict[stopSequence] = sequenceIndexCount
						stopIDtoSequenceDict[busStopLiveStatus.last!.stopId] = stopSequence
						sequenceIndexCount = sequenceIndexCount + 1
					}
					
					// TODO: CONSIDER REMOVE THIS BECAUSE SEQUENCE IS ALREADY PROVIDED
					busStopLiveStatus.sort(by: { $0.stopSequence < $1.stopSequence })
				}
				else {
					self.presentErrorMessage(query: "All bus stops time", description: "status code", code: response.statusCode)
				}
			}
			semaphore.signal()
		}
		task.resume()
		semaphore.wait()
		
		// then get RealTimeNearStop api (A2)
		let urlRealTimeNearStop = URL(string: String("https://tdx.transportdata.tw/api/basic/v2/Bus/RealTimeNearStop/City/\(busStop.city)?$filter=RouteID eq '\(busStop.routeId)' and Direction eq \(busStop.direction)&$select=PlateNumb, StopID, StopSequence, BusStatus, A2EventType&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: urlRealTimeNearStop)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
		let task2 = session.dataTask(with: request) { (data, response, error) in
			if let error = error {
				self.presentErrorMessage(query: "A2", description: error.localizedDescription, code: nil)
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let rawBuses = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
					
					for rawBus in rawBuses! {
						let sequence = rawBus["StopSequence"] as! Int
						let plateNumber = rawBus["PlateNumb"] as! String
						busStopLiveStatus[sequenceToIndexDict[sequence]!].plateNumber = plateNumber
						busStopLiveStatus[sequenceToIndexDict[sequence]!].busStatus = BusStopLiveStatus.BusStatus(rawValue: ((rawBus["BusStatus"] ?? 0) as! Int))!
						busStopLiveStatus[sequenceToIndexDict[sequence]!].eventType = BusStopLiveStatus.EventType(rawValue: (rawBus["A2EventType"] as! Int))!
						
						plateNumbertoIndexDict[plateNumber] = sequenceToIndexDict[sequence]
					}
					
					busStopLiveStatus[0].isDepartureStop = true
					busStopLiveStatus[busStopLiveStatus.count - 1].isDestinationStop = true
				}
				else {
					self.presentErrorMessage(query: "A2", description: "status code", code: response.statusCode)
				}
			}
			semaphore.signal()
		}
		task2.resume()
		semaphore.wait()
		
		// then get estimated arrival of those buses
		let urlEstimateTimeForAllStops = URL(string: String("https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/\(busStop.city)?$filter=RouteID eq '\(busStop.routeId)' and Direction eq \(busStop.direction)&$select=StopID, RouteID, EstimateTime, StopStatus&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: urlEstimateTimeForAllStops)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
		let task3 = session.dataTask(with: request) { (data, response, error) in
			if let error = error {
				self.presentErrorMessage(query: "N1 for detail", description: error.localizedDescription, code: nil)
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
					
					for stop in rawReturned! {
						let stopStatus = stop["StopStatus"] as! Int
						if(stopStatus == 0 || stopStatus == 1) {
							let estimate = (stop["EstimateTime"] ?? -1) as! Int
							busStopLiveStatus[sequenceToIndexDict[stopIDtoSequenceDict[stop["StopID"] as! String]!]!].estimatedArrival = estimate
						}
					}
				}
				else {
					self.presentErrorMessage(query: "N1 for detail", description: "status code", code: response.statusCode)
				}
			}
			semaphore.signal()
		}
		task3.resume()
		semaphore.wait()
		
		// first, calculate the time needed for bus to get to the next station
		for i in 0..<(busStopLiveStatus.count - 1) {
			let currentStationETA = busStopLiveStatus[i].estimatedArrival
			let nextStationETA = busStopLiveStatus[i+1].estimatedArrival
			if(currentStationETA <= nextStationETA) {
				busStopLiveStatus[i].timeToTheNextStation = nextStationETA - currentStationETA
			}
		}
		
		// calculate each bus to current station estimated arrival time
		if(busStop.stopId != "no") {
			let currentEstimatedArrival = busStopLiveStatus[currentStopSequence!].estimatedArrival
			var compensate = [currentEstimatedArrival]
			var first = true
			for i in (0...currentStopSequence!).reversed() {
				if(i == currentStopSequence && ((busStopLiveStatus[i].eventType == BusStopLiveStatus.EventType.Departing) || (busStopLiveStatus[i].eventType == BusStopLiveStatus.EventType.Arriving && busStopLiveStatus[i].estimatedArrival > 120))) {
					busStopLiveStatus[i].estimatedArrival = -1
					continue
				}
				if(busStopLiveStatus[i].plateNumber != "") {
					// if a stop has plateNumber, then get the max of estimatedArrival of its adjacent's
					var maxArrival = [Int]()
					if(i == 0) {
						if(busStopLiveStatus[i+1].plateNumber == "") {
							maxArrival.append(busStopLiveStatus[i+1].estimatedArrival)
						}
						maxArrival.append(busStopLiveStatus[i].estimatedArrival)
					} else if(i == currentStopSequence!) {
						if(busStopLiveStatus[i-1].plateNumber == "") {
							maxArrival.append(busStopLiveStatus[i-1].estimatedArrival)
						}
						maxArrival.append(busStopLiveStatus[i].estimatedArrival)
					} else {
						if(busStopLiveStatus[i+1].plateNumber == "") {
							maxArrival.append(busStopLiveStatus[i+1].estimatedArrival)
						}
						if(busStopLiveStatus[i-1].plateNumber == "") {
							maxArrival.append(busStopLiveStatus[i-1].estimatedArrival)
						}
						maxArrival.append(busStopLiveStatus[i].estimatedArrival)
					}
					compensate.append(maxArrival.max()!)
					
					if(!first) {
						var temp = 0
						for j in 0..<(compensate.count-1) {
							temp = temp + compensate[j]
						}
						busStopLiveStatus[i].estimatedArrival = temp
					}
					else {
						busStopLiveStatus[i].estimatedArrival = currentEstimatedArrival
						first = false
					}
				}
			}
			
			for i in (currentStopSequence!+1)..<busStopLiveStatus.count {
				busStopLiveStatus[i].estimatedArrival = -1
			}
		}
		
		// check vehicle type
		let plateNumbersArray = Array(plateNumbertoIndexDict.keys)
		let plateNumbersQuery = "PlateNumb eq '" + plateNumbersArray.joined(separator: "' or PlateNumb eq '") + "'"
		let urlVehicleType = URL(string: String("https://tdx.transportdata.tw/api/basic/v2/Bus/Vehicle/City/\(busStop.city)?$filter=\(plateNumbersQuery)&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: urlVehicleType)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
		let task4 = session.dataTask(with: request) { (data, response, error) in
			if let error = error {
				self.presentErrorMessage(query: "vehicle type", description: error.localizedDescription, code: nil)
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
					
					for vehicle in rawReturned! {
						let plate = vehicle["PlateNumb"] as! String
						let type = vehicle["VehicleType"] as! Int
						busStopLiveStatus[plateNumbertoIndexDict[plate]!].vehicleType = BusStopLiveStatus.VehicleType(rawValue: type)!
					}
				}
				else {
					self.presentErrorMessage(query: "vehicle type", description: "status code", code: response.statusCode)
				}
			}
			semaphore.signal()
		}
		task4.resume()
		semaphore.wait()
		
		return busStopLiveStatus
	}
	
	func querySpecificBusArrival(busStop: BusStop) -> BusStop? {
		var request: URLRequest
		
		let semaphore = DispatchSemaphore(value: 0)
		
		let session = URLSession(configuration: urlConfig)
		
		let urlStopOfRoute = URL(string: String("https://tdx.transportdata.tw/api/basic/v2/Bus/EstimatedTimeOfArrival/City/\(busStop.city)?$filter=RouteID eq '\(busStop.routeId)' and StopID eq '\(busStop.stopId)' and Direction eq \(busStop.direction)&$select=RouteID, Direction, StopStatus, EstimateTime&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: urlStopOfRoute)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
		let task = session.dataTask(with: request) { (data, response, error) in
			if let error = error {
				self.presentErrorMessage(query: "specific bus arrival", description: error.localizedDescription, code: nil)
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])[0]
					
					busStop.estimatedArrival = (rawReturned?["EstimateTime"] as? Int) ?? -1
					busStop.stopStatus = BusStop.StopStatus(rawValue: (rawReturned?["StopStatus"] as? Int) ?? -1)!
				}
				else {
					self.presentErrorMessage(query: "specific bus arrival", description: "status code", code: response.statusCode)
				}
			}
			semaphore.signal()
		}
		task.resume()
		semaphore.wait()
		
		return busStop
	}
	
	func queryNearbyMetroStations(location: CLLocation) -> [Station] {
		let semaphore = DispatchSemaphore(value: 0)
		var request: URLRequest
		
		let currentLatitude = location.coordinate.latitude
		let currentLongitude = location.coordinate.longitude
		
		var stationList = [Station]()
		
		let session = URLSession(configuration: urlConfig)
		
		for system in queryMetroSystems {
			let urlStation = URL(string: "https://tdx.transportdata.tw/api/basic/v2/Rail/Metro/Station/\(system)?$filter=StationPosition%2FPositionLat%20ge%20\(currentLatitude - nearbyStationHeight)%20and%20StationPosition%2FPositionLat%20le%20\(currentLatitude + nearbyStationHeight)%20and%20StationPosition%2FPositionLon%20ge%20\(currentLongitude - nearbyStationWidth)%20and%20StationPosition%2FPositionLon%20le%20\(currentLongitude + nearbyStationWidth)&$format=JSON")!
			request = URLRequest(url: urlStation)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
			let task = session.dataTask(with: request) { (data, response, error) in
				if let error = error {
					self.presentErrorMessage(query: "nearby metro", description: error.localizedDescription, code: nil)
				}
				else if let response = response as? HTTPURLResponse,
						let data = data {
					if(response.statusCode == 200) {
						let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
						for station in rawReturned! {
							let stationID = station["StationID"] as! String
							let stationName = (station["StationName"] as! [String: String])["Zh_tw"]!
							let stationPositionRaw = station["StationPosition"] as! [String: Any]
							let stationLocation = CLLocation(latitude: stationPositionRaw["PositionLat"] as! Double, longitude: stationPositionRaw["PositionLon"] as! Double)
							
							let newMetroStation = Station(stationName: stationName, stationId: stationID, stationType: .Metro)
							newMetroStation.location = stationLocation
							
							stationList.append(newMetroStation)
						}
					}
					else {
						self.presentErrorMessage(query: "nearby metro", description: "status code", code: response.statusCode)
					}
				}
				else {
					print("Error query nearby \(system)")
				}
				semaphore.signal()
			}
			task.resume()
		}
		
		for _ in 0..<queryMetroSystems.count {
			semaphore.wait()
		}
		
		var newStationList: [Station] = []
		let duplicates = Dictionary(grouping: stationList, by: {$0.stationName})
		for (stationName, station) in duplicates {
			let newStation = Station(stationName: stationName, stationId: station[0].stationId, stationType: .Metro)
			newStation.location = station.last!.location
			newStation.stationType = .Metro
			
			for i in 0..<station.count {
				newStation.stationIDsForMetro.append(station[i].stationId)
			}
			newStationList.append(newStation)
		}
		
		return newStationList
	}
	
	func queryMetroArrivals(metroStation: Station) -> [MetroArrival] {
		var metroArrivals = [MetroArrival]()
		var crowdnessCheck = false
		var nulled: Bool = true
		var trainNumberToIndexDict: [String: Int] = [:]
		
		let semaphore = DispatchSemaphore(value: 0)
		
		let urlMetroArrivals = URL(string: String("https://api.metro.taipei/metroapi/TrackInfo.asmx").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		let httpBody = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"\nxmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n<soap:Body><getTrackInfo xmlns=\"http://tempuri.org/\"><userName>garry0325@gmail.com</userName><passWord>U66A9vG2</passWord> </getTrackInfo>  </soap:Body></soap:Envelope>"
		
		let session = URLSession(configuration: urlConfig)
		
		var request = URLRequest(url: urlMetroArrivals)
		request.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
		request.httpBody = Data(httpBody.utf8)
		request.httpMethod = "POST"
		
		let task = session.dataTask(with: request) { (data, response, error) in
			if let error = error {
				self.presentErrorMessage(query: "metro arrivals", description: error.localizedDescription, code: nil)
			}
			else if let response = response as? HTTPURLResponse, let data = data {
				if(response.statusCode == 200) {
					let rawReturned = String(data: data, encoding: .utf8)?.components(separatedBy: "<?xml")[0]
					if(rawReturned == "null") {
						print("nulled")
						semaphore.signal()
						return
					}
					let metroArrivalsList = try? JSONSerialization.jsonObject(with: (rawReturned!.data(using: .utf8))!, options: []) as? [[String: String]]
					
					let nowTime = Date()
					
					var zhongxiaofuxing = 0
					let metroArrivalsRaw = metroArrivalsList!.filter({ $0["StationName"] ==  ((metroStation.stationName.last == "站") ? metroStation.stationName:metroStation.stationName + "站") })
					for metroArrival in metroArrivalsRaw {
						let sourceTime = self.metroDateFormatter.date(from: metroArrival["NowDateTime"]!)!
						let elapsedTime = nowTime.timeIntervalSince(sourceTime)
						var estimatedArrival = -1
						var status: MetroArrival.Status = .Normal
						
						if(metroArrival["CountDown"]!.contains(":")) {
							let countDownRaw = metroArrival["CountDown"]?.split(separator: ":")
							estimatedArrival = Int(countDownRaw![0])! * 60 + Int(countDownRaw![1])! - Int(elapsedTime)
						} else if(metroArrival["CountDown"]! == "列車進站") {
							estimatedArrival = 0
							status = .Approaching
						} else if(metroArrival["CountDown"]! == "資料擷取中") {
							estimatedArrival = 0
							status = .Loading
						} else {
							estimatedArrival = 0
							status = .ServiceOver
						}
						
						let stationName = metroArrival["StationName"]!
						let destination = String(metroArrival["DestinationName"]!.prefix(metroArrival["DestinationName"]!.count - 1))
						
						metroArrivals.append(MetroArrival(stationName: stationName, destinationName: "往" + destination, estimatedArrival: estimatedArrival))
						
						// Resolve ZhongXiaoFuXing station's two lines but toward same destination
						if(destination == "南港展覽館") {
							if(metroStation.stationName == "忠孝復興") {
								metroArrivals.last?.line = MetroDestinationToLineDict[destination]![zhongxiaofuxing]
								zhongxiaofuxing = 1
							}
							else if(WenHuStations.contains(metroStation.stationName)) {
								metroArrivals.last?.line = MetroDestinationToLineDict[destination]![0]
							}
							else {
								metroArrivals.last?.line = MetroDestinationToLineDict[destination]![1]
							}
						}
						else if(destination == "北投" && metroStation.stationName == "新北投") {
							metroArrivals.last?.line = MetroDestinationToLineDict[destination]![1]
						}
						else {
							metroArrivals.last!.line = MetroDestinationToLineDict[destination]![0]
						}
						
						metroArrivals.last?.status = status
						metroArrivals.last?.trainNumber = metroArrival["TrainNumber"]!
						
						// check if Blue Line exists
						if(metroArrivals.last?.line == .BL) {
							crowdnessCheck = true
						}
					}
					
				}
				else {
					self.presentErrorMessage(query: "nearby metro", description: "status code", code: response.statusCode)
				}
			}
			nulled = false
			semaphore.signal()
		}
		
		repeat {
			task.resume()
			semaphore.wait()
		} while nulled
		
		metroArrivals.sort(by: { $0.lineName! >= $1.lineName! })
		
		// check BanNan line crowdness
		if(crowdnessCheck) {
			for i in 0..<metroArrivals.count {
				if(metroArrivals[i].line == .BL && metroArrivals[i].trainNumber != "") {
					trainNumberToIndexDict[metroArrivals[i].trainNumber!] = i
				}
			}
			let urlCrowdness = URL(string: String("https://api.metro.taipei/metroapi/CarWeight.asmx").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			let httpBodyCrowdness = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n<soap:Body> <getCarWeightByInfo xmlns=\"http://tempuri.org/\"><userName>garry0325@gmail.com</userName>   <passWord>U66A9vG2</passWord></getCarWeightByInfo> </soap:Body></soap:Envelope>"
			
			
			var requestCrowdness = URLRequest(url: urlCrowdness)
			requestCrowdness.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
			requestCrowdness.httpBody = Data(httpBodyCrowdness.utf8)
			requestCrowdness.httpMethod = "POST"
			
			let taskCrowdness = session.dataTask(with: requestCrowdness) { (data, response, error) in
				if let error = error {
					self.presentErrorMessage(query: "metro crowdness", description: error.localizedDescription, code: nil)
				}
				else if let response = response as? HTTPURLResponse, let data = data {
					if(response.statusCode == 200) {
						let rawReturned = String(data: data, encoding: .utf8)?.components(separatedBy: "[")
						if(rawReturned?.count == 1) {	// crowndess is unavailable, maybe service over
							semaphore.signal()
							return
						}
						
						let rawCarWeight = "[" + (rawReturned?[1].components(separatedBy: "]")[0])!.replacingOccurrences(of: "\\", with: "") + "]"
						
						let carWeightInfo = try? JSONSerialization.jsonObject(with: (rawCarWeight.data(using: .utf8))!, options: []) as? [[String: String]]
						
						for car in carWeightInfo! {
							let trainNumber = car["TrainNumber"]!
							var crowdnessArray = [Int]()
							if let index = trainNumberToIndexDict[trainNumber] {
								crowdnessArray.append(Int(car["Car1"]!)!)
								crowdnessArray.append(Int(car["Car2"]!)!)
								crowdnessArray.append(Int(car["Car3"]!)!)
								crowdnessArray.append(Int(car["Car4"]!)!)
								crowdnessArray.append(Int(car["Car5"]!)!)
								crowdnessArray.append(Int(car["Car6"]!)!)
								
								metroArrivals[index].crowdness = crowdnessArray
								//print("\(metroArrivals[index].destinationName) \(metroArrivals[index].crowdness)")
							}
						}
						
					}
					else {
						self.presentErrorMessage(query: "nearby metro", description: "status code", code: response.statusCode)
					}
				}
				semaphore.signal()
			}
			taskCrowdness.resume()
			semaphore.wait()
		}
		
		NotificationCenter.default.post(name: NSNotification.Name("MetroArrivals"), object: metroArrivals)
		
		
		return metroArrivals
	}
	
	func queryMetroStationSequence(currentStation: MetroArrival) -> [MetroStation] {
		let semaphore = DispatchSemaphore(value: 0)
		
		var metroStations = [MetroStation]()
		
		var request: URLRequest
		
		let session = URLSession(configuration: urlConfig)
		
		var metroLine = currentStation.line
		if(metroLine == .Gb) {
			metroLine = .G
		} else if(metroLine == .Rb) {
			metroLine = .R
		}
		
		let urlStopOfRoute = URL(string: String("https://tdx.transportdata.tw/api/basic/v2/Rail/Metro/StationOfLine/TRTC?$filter=LineNo eq '\(metroLine!.rawValue)'").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: urlStopOfRoute)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
		let task = session.dataTask(with: request) { (data, response, error) in
			if let error = error {
				self.presentErrorMessage(query: "metro station sequence", description: error.localizedDescription, code: nil)
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let stations = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])[0]["Stations"] as? [[String: Any]]
					
					for station in stations! {
						let stationName = (station["StationName"] as! [String: String])["Zh_tw"]!
						if(stationName == "小碧潭" || stationName == "新北投") {
							continue
						}
						
						let stationID = Int((station["StationID"] as! String).suffix(2))!
						if(currentStation.destinationName == "往蘆洲") {
							if(13 <= stationID && stationID <= 21) {
								continue
							}
						}
						if(currentStation.destinationName == "往迴龍") {
							if(stationID > 30) {
								continue
							}
						}
						if(currentStation.destinationName == "往南勢角") {
							if(HuiLongStations.contains(currentStation.stationName)) {
								if(stationID > 30) {
									continue
								}
							}
							else if(LuzhouStations.contains(currentStation.stationName)) {
								if(stationID >= 13 && stationID <= 21) {
									continue
								}
							}
							else {
								if(stationID > 30) {
									continue
								}
							}
						}
						metroStations.append(MetroStation(stationName: stationName, sequence: station["Sequence"] as! Int))
						if(((stationName.last == "站") ? stationName:stationName + "站") == currentStation.stationName) {
							metroStations.last?.isCurrentStation = true
						}
					}
					
					switch currentStation.destinationName {
					case "往象山", "往大安", "往南勢角", "往大坪林", "往動物園", "往頂埔", "往亞東醫院", "往新店", "往台電大樓":
						metroStations.reverse()
					default:
						break
					}
					
					metroStations.first!.isDepartureStation = true
					metroStations.last!.isDestinationStation = true
				}
				else {
					self.presentErrorMessage(query: "metro station sequence", description: "status code", code: response.statusCode)
				}
			}
			semaphore.signal()
		}
		
		task.resume()
		semaphore.wait()
		
		return metroStations
	}
	
	func queryLiveBusesPosition(busStop: BusStop) -> [Bus] {
		var request: URLRequest
		
		let semaphore = DispatchSemaphore(value: 0)
		var buses = [Bus]()
		
		let session = URLSession(configuration: urlConfig)
		
		let urlBusLocation = URL(string: String("https://tdx.transportdata.tw/api/basic/v2/Bus/RealTimeByFrequency/City/\(busStop.city)?$filter=RouteID eq '\(busStop.routeId)' and Direction eq \(busStop.direction)&$select=PlateNumb, RouteID, RouteName, Direction, BusPosition, Speed, Azimuth, BusStatus&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: urlBusLocation)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
		let task = session.dataTask(with: request) { (data, response, error) in
			if let error = error {
				self.presentErrorMessage(query: "Bus realtime location", description: error.localizedDescription, code: nil)
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let rawReturned = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
					
					for rawBus in rawReturned! {
						let bus = Bus(routeId: busStop.routeId, routeName: busStop.routeName, plateNumber: rawBus["PlateNumb"] as! String)
						bus.direction = rawBus["Direction"] as! Int
						bus.location = CLLocation(latitude: (rawBus["BusPosition"] as! [String: Any])["PositionLat"] as! Double, longitude: (rawBus["BusPosition"] as! [String: Any])["PositionLon"] as! Double)
						bus.speed = rawBus["Speed"] as! Int
						bus.azimuth = rawBus["Azimuth"] as! Int
						bus.busStatus = BusStopLiveStatus.BusStatus(rawValue: rawBus["BusStatus"] as! Int)!
						
						buses.append(bus)
					}
				}
				else {
					self.presentErrorMessage(query: "Bus real time location", description: "status code", code: response.statusCode)
				}
			}
			semaphore.signal()
		}
		
		task.resume()
		semaphore.wait()
		
		return buses
	}
	
	func queryBusRouteGeometry(busStop: BusStop) -> [CLLocationCoordinate2D] {
		var request: URLRequest
		
		let semaphore = DispatchSemaphore(value: 0)
		var route = [CLLocationCoordinate2D]()
		
		let session = URLSession(configuration: urlConfig)
		
		let urlBusLocation = URL(string: String("https://tdx.transportdata.tw/api/basic/v2/Bus/Shape/City/\(busStop.city)?$select=RouteID, RouteName, Geometry&$filter=RouteID eq '\(busStop.routeId)'&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: urlBusLocation)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
		let task = session.dataTask(with: request) { (data, response, error) in
			if let error = error {
				self.presentErrorMessage(query: "Bus route geometry", description: error.localizedDescription, code: nil)
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])[0]
					
					let coordinates = ((rawReturned!["Geometry"] as! String).split(separator: "("))[1].split(separator: ",")
					for i in stride(from: 0, to: coordinates.count-1, by: 1) {
						let coordinate = coordinates[i].split(separator: " ")
						route.append(CLLocation(latitude: Double(coordinate[1])!, longitude: Double(coordinate[0])!).coordinate)
					}
				}
				else {
					self.presentErrorMessage(query: "Bus route geometry", description: "status code", code: response.statusCode)
				}
			}
			semaphore.signal()
		}
		
		task.resume()
		semaphore.wait()
		
		return route
	}
	
	func queryNearbyBuses(location: CLLocation) -> [Bus] {
		var request: URLRequest
		
		let semaphore = DispatchSemaphore(value: 0)
		var nearbyBuses = [Bus]()
		
		let session = URLSession(configuration: urlConfig)
		
		for city in queryCities {
			let urlNearbyBuses = URL(string: String("https://tdx.transportdata.tw/api/basic/v2/Bus/RealTimeByFrequency/City/\(city)?$select=PlateNumb, RouteID, RouteName, Direction, BusPosition&$filter=BusPosition/PositionLat ge \(location.coordinate.latitude - nearbyBusesHeight) and BusPosition/PositionLat le \(location.coordinate.latitude + nearbyBusesHeight) and BusPosition/PositionLon ge \(location.coordinate.longitude - nearbyBusesWidth) and BusPosition/PositionLon le \(location.coordinate.longitude + nearbyBusesWidth)&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			request = URLRequest(url: urlNearbyBuses)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
			let task = session.dataTask(with: request) { (data, response, error) in
				if let error = error {
					self.presentErrorMessage(query: "Nearby buses", description: error.localizedDescription, code: nil)
				}
				else if let response = response as? HTTPURLResponse,
						let data = data {
					if(response.statusCode == 200) {
						let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
						
						for rawBus in rawReturned! {
							let bus = Bus(routeId: rawBus["RouteID"] as! String, routeName: (rawBus["RouteName"] as! [String: String])["Zh_tw"]!, plateNumber: rawBus["PlateNumb"] as! String)
							bus.location = CLLocation(latitude: (rawBus["BusPosition"] as! [String: Any])["PositionLat"] as! Double, longitude: (rawBus["BusPosition"] as! [String: Any])["PositionLon"] as! Double)
							bus.direction = rawBus["Direction"] as! Int
							bus.distance = Int(bus.location.distance(from: location))
							bus.city = city
							
							nearbyBuses.append(bus)
						}
						
					}
					else {
						self.presentErrorMessage(query: "Nearby buses", description: "status code", code: response.statusCode)
					}
				}
				semaphore.signal()
			}
			task.resume()	// consider start simultaneously
			semaphore.wait()
		}
		
		// reversed sorting because the collectionView is reversed
		nearbyBuses.sort(by: { $0.distance >= $1.distance })
		
		return nearbyBuses
	}
	
    func queryBeaconInformation(major: NSNumber, minor: NSNumber) -> String{
        var mrtStationCode = "error"
        let semaphore = DispatchSemaphore(value: 0)

        let urlMetroBeacon = URL(string: String("https://ws.metro.taipei/TRTCBeaconBE/BeaconControl.asmx/GetBeaconInfo").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        let httpBody = String(format: "{\"username\":\"garry0325@gmail.com\",\"password\":\"U66A9vG2\",\"beacon\":{\"UUID\":\"%@\",\"MAJOR\":\"%d\",\"MINOR\":\"%d\"}}", mrtBeaconUUID.uuidString, major as! Int, minor as! Int)

        let session = URLSession(configuration: urlConfig)

        var request = URLRequest(url: urlMetroBeacon)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(httpBody.utf8)
        request.httpMethod = "POST"
        let task = session.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse, let data = data {
                if(response.statusCode == 200) {
                    let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [String: Any])
                    if let returnedBeaconValid = rawReturned!["d"] as? [String: String] {
                        mrtStationCode = returnedBeaconValid["SID"] ?? "error"
                    }
                }
            }
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()
        
        return mrtStationCode
    }
	
	func presentErrorMessage(query: String, description: String, code: Int?) {
		DispatchQueue.main.async {
			if let code = code {
				print("Network error \(code): \(query)")
				if(code != 414) {	// Response code 414 due to too many stations, url too long
					ErrorAlert.presentErrorAlert(title: "網路錯誤 \(code)", message: "請稍後再試")
				}
			} else {
				print("Network error: \(query), \(description)")
				ErrorAlert.presentErrorAlert(title: "網路錯誤", message: "網路連線不穩 請稍後再試")
			}
		}
	}
	
	func updateStationRadius() {
		nearbyStationWidth = Double(stationRadius / 100925)
		nearbyStationHeight = Double(stationRadius / 110803)
	}
}

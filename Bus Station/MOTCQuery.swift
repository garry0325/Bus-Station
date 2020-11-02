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
	private let appID = "1baabcfdb12a4d88bd4b19c7a2c3fd23"
	private let appKey = "4hYdvDltMul8kJTyx2CbciPeM1k"
	
	private var authTimeString: String!
	private var authorization: String!
	private var key: SymmetricKey!
	private let authorizationDateFormatter: DateFormatter
	
	let nearbyStationWidth = 0.005
	let nearbyStationHeight = 0.0035
	
	let queryCities = ["Taipei", "NewTaipei"]
	
	init() {
		authorizationDateFormatter = DateFormatter()
		authorizationDateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ww zzz"
		authorizationDateFormatter.locale = Locale(identifier: "en_US")
		authorizationDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
	}
	
	func queryNearbyStations(location: CLLocation) -> [BusStation] {
		self.prepareAuthorizations()
		
		let semaphore = DispatchSemaphore(value: 0)
		var request: URLRequest
		
		var stationDict = [String: BusStation]()
		
		let currentLatitude = location.coordinate.latitude
		let currentLongitude = location.coordinate.longitude
		
		for city in queryCities {
			let urlStation = URL(string: "https://ptx.transportdata.tw/MOTC/v2/Bus/Station/City/\(city)?$select=StationID%2C%20StationName%2C%20StationPosition%2C%20Stops&$filter=StationPosition%2FPositionLat%20ge%20\(currentLatitude - nearbyStationHeight)%20and%20StationPosition%2FPositionLat%20le%20\(currentLatitude + nearbyStationHeight)%20and%20StationPosition%2FPositionLon%20ge%20\(currentLongitude - nearbyStationWidth)%20and%20StationPosition%2FPositionLon%20le%20\(currentLongitude + nearbyStationWidth)&$format=JSON")!
			request = URLRequest(url: urlStation)
			request.setValue(authTimeString, forHTTPHeaderField: "x-date")
			request.setValue(authorization, forHTTPHeaderField: "Authorization")
			let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
				if let error = error {
					print("Error: \(error.localizedDescription)")
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
								
								stationDict[stationID] = BusStation(stationName: (station["StationName"] as! [String: String])["Zh_tw"]!, stationId: stationID, location: stationLocation, stops: temp)
							}
							else {
								stationDict[stationID]!.stops = stationDict[stationID]!.stops + temp
							}
						}
					}
					else {
						print("Station query response status code: \(response.statusCode)")
					}
				}
				semaphore.signal()
			}
			task.resume()
			semaphore.wait()
		}
		
		var stationList: [BusStation] = []
		var stationIDs = [String]()
		for (stationID, station) in stationDict {
			stationList.append(station)
			stationIDs.append(stationID)
		}
		stationList.sort(by: {$0.location.distance(from: location) <= $1.location.distance(from: location)})
		print("共\(stationList.count)站")
		
		for city in queryCities {
			let stationIDQuery = "StationID eq '" + (stationIDs.joined(separator: "' or StationID eq '")) + "'"
			let urlStop = URL(string: String("https://ptx.transportdata.tw/MOTC/v2/Bus/Stop/City/\(city)?$select=StationID, Bearing&$filter=\(stationIDQuery)&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			request = URLRequest(url: urlStop)
			request.setValue(authTimeString, forHTTPHeaderField: "x-date")
			request.setValue(authorization, forHTTPHeaderField: "Authorization")
			let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
				if let error = error {
					print("Error: \(error.localizedDescription)")
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
						print("Bearing query response status code \(response.statusCode)")
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
	
	func queryBusArrivals(station: BusStation) -> [BusStop] {
		self.prepareAuthorizations()
		
		let semaphore = DispatchSemaphore(value: 0)
		var request: URLRequest
		
		var stopsList = [BusStop]()
		var routeDict = [String: BusStop]()
		
		for city in queryCities {
			var stopIDs = [String]()
			for stop in station.stops {
				stopIDs.append(stop.stopId)
			}
			let stopIDQuery = "StopID eq '" + stopIDs.joined(separator: "' or StopID eq '") + "'"
			let urlEstimatedTimeOfArrival = URL(string: String("https://ptx.transportdata.tw/MOTC/v2/Bus/EstimatedTimeOfArrival/City/\(city)?$select=StopID, RouteID, RouteName, Direction, EstimateTime, StopStatus&$filter=\(stopIDQuery)&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			request = URLRequest(url: urlEstimatedTimeOfArrival)
			request.setValue(authTimeString, forHTTPHeaderField: "x-date")
			request.setValue(authorization, forHTTPHeaderField: "Authorization")
			let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
				if let error = error {
					print("Error: \(error.localizedDescription)")
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
						print("N1 for main response status code \(response.statusCode)")
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
			let urlRoute = URL(string: String("https://ptx.transportdata.tw/MOTC/v2/Bus/Route/City/\(city)?$select=RouteID, DepartureStopNameZh, DestinationStopNameZh, TicketPriceDescriptionZh&$filter=\(destinationQuery)&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			request = URLRequest(url: urlRoute)
			request.setValue(authTimeString, forHTTPHeaderField: "x-date")
			request.setValue(authorization, forHTTPHeaderField: "Authorization")
			let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
				if let error = error {
					print("Error: \(error.localizedDescription)")
				}
				else if let response = response as? HTTPURLResponse,
						let data = data {
					if(response.statusCode == 200) {
						let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
						for destination in rawReturned! {
							let routeId = destination["RouteID"] as! String
							routeDict[routeId]!.destination = "往" + (routeDict[routeId]!.direction == 0 ? destination["DestinationStopNameZh"] as! String : destination["DepartureStopNameZh"] as! String)
						}
					}
					else {
						print("Destination response status code \(response.statusCode)")
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
		self.prepareAuthorizations()
		var request: URLRequest
		
		let semaphore = DispatchSemaphore(value: 0)
		var busStopLiveStatus = [BusStopLiveStatus]()
		var stopIDtoSeqDict = [String: Int]()
		var currentStopSequence: Int?
		
		// get the stop sequence of a route first
		let urlStopOfRoute = URL(string: String("https://ptx.transportdata.tw/MOTC/v2/Bus/StopOfRoute/City/\(busStop.city)?$filter=RouteID eq '\(busStop.routeId)' and Direction eq \(busStop.direction)&$select=RouteID, Direction, Stops&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: urlStopOfRoute)
		request.setValue(authTimeString, forHTTPHeaderField: "x-date")
		request.setValue(authorization, forHTTPHeaderField: "Authorization")
		let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
			if let error = error {
				print("Error: \(error.localizedDescription)")
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let rawStops = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])[0]["Stops"] as? [[String: Any]]
					
					var saveTime = true
					for stop in rawStops! {
						busStopLiveStatus.append(BusStopLiveStatus(stopId: stop["StopID"] as! String, stopName: (stop["StopName"] as! [String: String])["Zh_tw"]!, sequence: stop["StopSequence"] as! Int))
						
						if(saveTime && busStopLiveStatus.last?.stopId == busStop.stopId) {
							busStopLiveStatus.last?.isCurrentStop = true
							currentStopSequence = busStopLiveStatus.count - 1
							saveTime = false
						}
						
						stopIDtoSeqDict[busStopLiveStatus.last!.stopId] = busStopLiveStatus.count - 1
					}
					// TODO: CONSIDER REMOVE THIS BECAUSE SEQUENCE IS ALREADY PROVIDED
					busStopLiveStatus.sort(by: { $0.stopSequence < $1.stopSequence })
				}
				else {
					print("All bus stops time response status code \(response.statusCode)")
				}
			}
			semaphore.signal()
		}
		task.resume()
		semaphore.wait()
		
		// then get RealTimeNearStop api (A2)
		let urlRealTimeNearStop = URL(string: String("https://ptx.transportdata.tw/MOTC/v2/Bus/RealTimeNearStop/City/\(busStop.city)?$filter=RouteID eq '\(busStop.routeId)' and Direction eq \(busStop.direction)&$select=PlateNumb, StopID, StopSequence, BusStatus, A2EventType&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: urlRealTimeNearStop)
		request.setValue(authTimeString, forHTTPHeaderField: "x-date")
		request.setValue(authorization, forHTTPHeaderField: "Authorization")
		let task2 = URLSession.shared.dataTask(with: request) { (data, response, error) in
			if let error = error {
				print("Error: \(error.localizedDescription)")
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let rawBuses = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
					
					for rawBus in rawBuses! {
						let sequence = rawBus["StopSequence"] as! Int - 1
						busStopLiveStatus[sequence].plateNumber = (rawBus["PlateNumb"] as! String)
						busStopLiveStatus[sequence].busStatus = BusStopLiveStatus.BusStatus(rawValue: ((rawBus["BusStatus"] ?? 0) as! Int))!
						busStopLiveStatus[sequence].eventType = BusStopLiveStatus.EventType(rawValue: (rawBus["A2EventType"] as! Int))!
					}
					
					busStopLiveStatus[0].isDepartureStop = true
					busStopLiveStatus[busStopLiveStatus.count - 1].isDestinationStop = true
				}
				else {
					print("A2 response status code \(response.statusCode)")
				}
			}
			semaphore.signal()
		}
		task2.resume()
		semaphore.wait()
		
		// then get estimated arrival of those buses
		let urlEstimateTimeForAllStops = URL(string: String("https://ptx.transportdata.tw/MOTC/v2/Bus/EstimatedTimeOfArrival/City/\(busStop.city)?$filter=RouteID eq '\(busStop.routeId)' and Direction eq \(busStop.direction)&$select=StopID, RouteID, EstimateTime, StopStatus&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: urlEstimateTimeForAllStops)
		request.setValue(authTimeString, forHTTPHeaderField: "x-date")
		request.setValue(authorization, forHTTPHeaderField: "Authorization")
		let task3 = URLSession.shared.dataTask(with: request) { (data, response, error) in
			if let error = error {
				print("Error: \(error.localizedDescription)")
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])
					
					for stop in rawReturned! {
						let stopStatus = stop["StopStatus"] as! Int
						if(stopStatus == 0 || stopStatus == 1) {
							let estimate = (stop["EstimateTime"] ?? -1) as! Int
							busStopLiveStatus[stopIDtoSeqDict[stop["StopID"] as! String]!].estimatedArrival = estimate
						}
					}
				}
				else {
					print("N1 for detail status code \(response.statusCode)")
				}
			}
			semaphore.signal()
		}
		task3.resume()
		semaphore.wait()
		
		let currentEstimatedArrival = busStopLiveStatus[currentStopSequence!].estimatedArrival
		var compensate = [currentEstimatedArrival]
		var first = true
		for i in 0...currentStopSequence! {
			print("\(busStopLiveStatus[i].estimatedArrival)\t\(busStopLiveStatus[i].stopName)")
		}
		for i in (0...currentStopSequence!).reversed() {
			if(i == currentStopSequence && ((busStopLiveStatus[i].eventType == BusStopLiveStatus.EventType.Departing) || (busStopLiveStatus[i].eventType == BusStopLiveStatus.EventType.Arriving && busStopLiveStatus[i].estimatedArrival > 120))) {
				busStopLiveStatus[i].estimatedArrival = -1
				continue
			}
			if(busStopLiveStatus[i].plateNumber != "") {
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
		
		for i in currentStopSequence!..<busStopLiveStatus.count {
			busStopLiveStatus[i].estimatedArrival = -1
		}
		return busStopLiveStatus
	}
	
	func querySpecificBusArrival(busStop: BusStop) -> BusStop? {
		self.prepareAuthorizations()
		var request: URLRequest
		
		let semaphore = DispatchSemaphore(value: 0)
		var newBusStop: BusStop?
		
		let urlStopOfRoute = URL(string: String("https://ptx.transportdata.tw/MOTC/v2/Bus/EstimatedTimeOfArrival/City/\(busStop.city)?$filter=RouteID eq '\(busStop.routeId)' and StopID eq '\(busStop.stopId)' and Direction eq \(busStop.direction)&$select=RouteID, Direction, StopStatus, EstimateTime&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: urlStopOfRoute)
		request.setValue(authTimeString, forHTTPHeaderField: "x-date")
		request.setValue(authorization, forHTTPHeaderField: "Authorization")
		let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
			if let error = error {
				print("Error: \(error.localizedDescription)")
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					let rawReturned = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])[0]
					
					newBusStop = BusStop(stopId: busStop.stopId, city: busStop.city, routeId: busStop.routeId, routeName: busStop.routeName)
					newBusStop!.direction = busStop.direction
					newBusStop?.destination = busStop.destination
					newBusStop?.estimatedArrival = (rawReturned?["EstimateTime"] as? Int) ?? -1
					newBusStop?.stopStatus = BusStop.StopStatus(rawValue: (rawReturned?["StopStatus"] as? Int) ?? -1)!
				}
				else {
					print("Specific bus arrival response status code \(response.statusCode)")
				}
			}
			semaphore.signal()
		}
		task.resume()
		semaphore.wait()
		
		return newBusStop ?? nil
	}
	
	func prepareAuthorizations() {
		self.authTimeString = authorizationDateFormatter.string(from: Date())
		self.key = SymmetricKey(data: Data(self.appKey.utf8))
		let hmac = HMAC<SHA256>.authenticationCode(for: Data(String(format: "x-date: %@", self.authTimeString).utf8), using: key)
		let base64HmacString = Data(hmac).base64EncodedString()
		self.authorization = "hmac username=\"\(self.appID)\", algorithm=\"hmac-sha256\", headers=\"x-date\", signature=\"\(base64HmacString)\""
	}
}

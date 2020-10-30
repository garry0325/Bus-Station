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
			let url = URL(string: "https://ptx.transportdata.tw/MOTC/v2/Bus/Station/City/\(city)?$select=StationID%2C%20StationName%2C%20StationPosition%2C%20Stops&$filter=StationPosition%2FPositionLat%20ge%20\(currentLatitude - nearbyStationHeight)%20and%20StationPosition%2FPositionLat%20le%20\(currentLatitude + nearbyStationHeight)%20and%20StationPosition%2FPositionLon%20ge%20\(currentLongitude - nearbyStationWidth)%20and%20StationPosition%2FPositionLon%20le%20\(currentLongitude + nearbyStationWidth)&$format=JSON")!
			request = URLRequest(url: url)
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
			let url = URL(string: String("https://ptx.transportdata.tw/MOTC/v2/Bus/Stop/City/\(city)?$select=StationID, Bearing&$filter=\(stationIDQuery)&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			request = URLRequest(url: url)
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
			let url = URL(string: String("https://ptx.transportdata.tw/MOTC/v2/Bus/EstimatedTimeOfArrival/City/\(city)?$select=StopID, RouteID, RouteName, Direction, EstimateTime, StopStatus&$filter=\(stopIDQuery)&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			request = URLRequest(url: url)
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
							busStopTemp.stopStatus = route["StopStatus"] as! Int
							
							routeDict[busStopTemp.routeId] = busStopTemp
							stopsList.append(busStopTemp)
						}
					}
					else {
						print("Estimate time response status code \(response.statusCode)")
					}
				}
				semaphore.signal()
			}
			task.resume()
		}
		
		for _ in 0..<queryCities.count {
			semaphore.wait()
		}
		
		for city in queryCities {
			var routeIDs = [String]()
			for stop in station.stops {
				routeIDs.append(stop.routeId)
			}
			let destinationQuery = "RouteID eq '" + routeIDs.joined(separator: "' or RouteID eq '") + "'"
			let url = URL(string: String("https://ptx.transportdata.tw/MOTC/v2/Bus/Route/City/\(city)?$select=RouteID, DepartureStopNameZh, DestinationStopNameZh, TicketPriceDescriptionZh&$filter=\(destinationQuery)&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
			request = URLRequest(url: url)
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
		
		for stop in stopsList {
			print("\(stop.routeId)\t\(stop.routeName)\t\(stop.information)")
		}
		
		return stopsList
		// list of [[BusStop], [BusStop]...] ordered by estimatedArrival
	}
	
	func queryRealTimeBusLocation(busStop: BusStop) -> [String] {
		self.prepareAuthorizations()
		var request: URLRequest
		
		let semaphore = DispatchSemaphore(value: 0)
		var stopsLabels = [String]()
		
		// get all the stops of a route first
		let url = URL(string: String("https://ptx.transportdata.tw/MOTC/v2/Bus/StopOfRoute/City/\(busStop.city)?$filter=RouteID eq '\(busStop.routeId)' and Direction eq \(busStop.direction)&$select=RouteID, Direction, Stops&$format=JSON").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
		request = URLRequest(url: url)
		request.setValue(authTimeString, forHTTPHeaderField: "x-date")
		request.setValue(authorization, forHTTPHeaderField: "Authorization")
		let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
			if let error = error {
				print("Error: \(error.localizedDescription)")
			}
			else if let response = response as? HTTPURLResponse,
					let data = data {
				if(response.statusCode == 200) {
					var rawStops = try? (JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]])[0]["Stops"] as? [[String: Any]]
					rawStops!.sort(by: { ($0["StopSequence"] as! Int) < ($1["StopSequence"] as! Int) })
					
					for stop in rawStops! {
						print("\((stop["StopName"] as! [String: String])["Zh_tw"]!)")
						stopsLabels.append((stop["StopName"] as! [String: String])["Zh_tw"]!)
					}
				}
				else {
					print("All bus stops time response status code \(response.statusCode)")
				}
			}
			semaphore.signal()
		}
		task.resume()
		semaphore.wait()
		
		return stopsLabels
	}
	
	func prepareAuthorizations() {
		self.authTimeString = authorizationDateFormatter.string(from: Date())
		self.key = SymmetricKey(data: Data(self.appKey.utf8))
		let hmac = HMAC<SHA256>.authenticationCode(for: Data(String(format: "x-date: %@", self.authTimeString).utf8), using: key)
		let base64HmacString = Data(hmac).base64EncodedString()
		self.authorization = "hmac username=\"\(self.appID)\", algorithm=\"hmac-sha256\", headers=\"x-date\", signature=\"\(base64HmacString)\""
	}
}

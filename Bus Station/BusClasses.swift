//
//  BusClasses.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/19.
//

import Foundation
import CoreLocation

class BusStation {
	let stationName: String
	let stationId: String
	let location: CLLocation
	var bearing: String = ""
	var stops: [BusStop]
	
	init(stationName: String, stationId: String, location: CLLocation, stops: [BusStop]) {
		self.stationName	= stationName
		self.stationId		= stationId
		self.location		= location
		self.stops			= stops
	}
}

class BusStop {
	let stopId: String
	let city: String
	let routeId: String
	let routeName: String
	var direction: Int = -1
	var destination: String = ""
	var estimatedArrival: Int = -1
	var stopStatus: Int = -1 {
		didSet {
			switch stopStatus {
			case 0:
				if(estimatedArrival < 30) {
					information = "進站中"
				}
				else if(estimatedArrival < 120) {
					information = "將到站"
				}
				else {
					information = "\(estimatedArrival / 60)分"
				}
			case 1:
				if(estimatedArrival == -1) {
					information = "尚未發車"
				}
				else {
					information = "\(estimatedArrival / 60)分"
				}
			case 2:
				information = "交管不停靠"
			case 3:
				information = "末班車已過"
			case 4:
				information = "今日未營運"
			default:
				break
			}
		}
	}
	var information: String = ""
	
	init(stopId: String, city: String, routeId: String, routeName: String) {
		self.stopId = stopId
		self.city = city
		self.routeId = routeId
		self.routeName = routeName
	}
}

class BusStopLiveStatus {
	let stopId: String
	let stopName: String
	var stopSequence = -1
	var plateNumber = ""
	var busStatus: BusStatus = BusStatus.Error
	var eventType: EventType = EventType.Unknown
	
	var isCurrentStop = false
	var isDepartureStop = false
	var isDestinationStop = false
	
	init(stopId: String, stopName: String, sequence: Int) {
		self.stopId = stopId
		self.stopName = stopName
		self.stopSequence = sequence
	}
	
	enum BusStatus: Int {
		case Normal			= 0
		case Accident		= 1
		case Malfunction	= 2
		case TrafficJam		= 3
		case Emergency		= 4
		case FillingUp		= 5
		case Unknown		= 90
		case UnknownDir		= 91
		case Deviate		= 98
		case OutOfService	= 99
		case Full			= 100
		case Chartered		= 101
		case Error			= 255
	}
	
	enum EventType: Int {
		case Departing		= 0
		case Arriving		= 1
		case Unknown		= -1
	}
}

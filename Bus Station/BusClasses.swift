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
	let routeName: String
	var direction: Int = -1
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
	
	init(stopId: String, city: String, routeName: String) {
		self.stopId = stopId
		self.city = city
		self.routeName = routeName
	}
}

//
//  BusClasses.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/19.
//

import Foundation
import UIKit
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
	var stopStatus: StopStatus = .Unknown {
		didSet {
			switch stopStatus {
			case .Normal:
				if(estimatedArrival < 30) {
					information = Information.Arriving
					informationLabelColor = RouteInformationLabelColors.red
				}
				else if(estimatedArrival < 120) {
					information = Information.Approaching
					informationLabelColor = RouteInformationLabelColors.red
				}
				else if(estimatedArrival < 300) {
					information = "\(estimatedArrival / 60)\(Information.Incoming)"
					informationLabelColor = RouteInformationLabelColors.orange
				}
				else {
					information = "\(estimatedArrival / 60)\(Information.Incoming)"
					informationLabelColor = RouteInformationLabelColors.green
				}
			case .NotDeparted:
				if(estimatedArrival == -1) {
					information = Information.NotDeparted
					informationLabelColor = RouteInformationLabelColors.gray
				}
				else {
					information = "\(estimatedArrival / 60)\(Information.Incoming)"
					informationLabelColor = RouteInformationLabelColors.green
				}
			case .TrafficRegulation:
				information = Information.TrafficRegulation
				informationLabelColor = RouteInformationLabelColors.gray
			case .OutService:
				information = Information.OutService
				informationLabelColor = RouteInformationLabelColors.gray
			case .NoServiceToday:
				information = Information.NoServiceToday
				informationLabelColor = RouteInformationLabelColors.gray
			default:
				break
			}
		}
	}
	var information: String = ""
	var informationLabelColor: UIColor = RouteInformationLabelColors.gray
	
	init(stopId: String, city: String, routeId: String, routeName: String) {
		self.stopId = stopId
		self.city = city
		self.routeId = routeId
		self.routeName = routeName
	}
	
	enum StopStatus: Int {
		case Normal				= 0
		case NotDeparted		= 1
		case TrafficRegulation	= 2
		case OutService			= 3
		case NoServiceToday		= 4
		case Unknown			= -1
	}
	
	enum Information {
		static let Arriving				= "進站中"
		static let Approaching			= "將到站"
		static let Incoming				= "分"
		static let NotDeparted			= "尚未發車"
		static let TrafficRegulation	= "交管不停靠"
		static let OutService			= "末班車已過"
		static let NoServiceToday		= "今日未營運"
	}
}

class BusStopLiveStatus {
	let stopId: String
	let stopName: String
	var stopSequence = -1
	var plateNumber = ""
	var busStatus: BusStatus = BusStatus.Error
	var eventType: EventType = EventType.Unknown
	
	var estimatedArrival: Int = -1	// not the estimated arrival time to stopId
	{
		didSet {
			if(estimatedArrival == -1) {
				information = ""
				informationLabelColor = RouteInformationLabelColors.gray
			}
			else if(estimatedArrival < 30) {
				information = Information.Arriving
				informationLabelColor = RouteInformationLabelColors.red
			}
			else if(estimatedArrival < 120) {
				information = Information.Approaching
				informationLabelColor = RouteInformationLabelColors.red
			}
			else if(estimatedArrival < 300) {
				information = "\(estimatedArrival / 60)\(Information.Incoming)"
				informationLabelColor = RouteInformationLabelColors.orange
			}
			else {
				information = "\(estimatedArrival / 60)\(Information.Incoming)"
				informationLabelColor = RouteInformationLabelColors.green
			}
		}
	}
	var information: String = ""
	var informationLabelColor: UIColor = RouteInformationLabelColors.gray
	
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
	
	enum Information {
		static let Arriving				= "進站中"
		static let Approaching			= "將到站"
		static let Incoming				= "分"
		static let NotDeparted			= "尚未發車"
		static let TrafficRegulation	= "交管不停靠"
		static let OutService			= "末班車已過"
		static let NoServiceToday		= "今日未營運"
	}
}

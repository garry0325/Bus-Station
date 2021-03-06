//
//  BusClasses.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/19.
//

import Foundation
import UIKit
import CoreLocation

class Station {
	var stationName: String = ""
	var stationId: String = ""
	var stationType: StationType = .Error {
		didSet {
			if(stationType == .Metro) {
				if(stationId.hasPrefix(Line.BR.rawValue)) {
					line = .BR
					lineColor = MetroLineColors.BR
					lineColorUnselected = MetroLineColors.BRs
					lineLabelColor = .white
				} else if (stationId.hasPrefix(Line.R.rawValue)) {
					line = .R
					lineColor = MetroLineColors.R
					lineColorUnselected = MetroLineColors.Rs
					lineLabelColor = .white
				} else if (stationId.hasPrefix(Line.G.rawValue)) {
					line = .G
					lineColor = MetroLineColors.G
					lineColorUnselected = MetroLineColors.Gs
					lineLabelColor = .white
				} else if (stationId.hasPrefix(Line.O.rawValue)) {
					line = .O
					lineColor = MetroLineColors.O
					lineColorUnselected = MetroLineColors.Os
					lineLabelColor = .white
				} else if (stationId.hasPrefix(Line.BL.rawValue)) {
					line = .BL
					lineColor = MetroLineColors.BL
					lineColorUnselected = MetroLineColors.BLs
					lineLabelColor = .white
				} else if (stationId.hasPrefix(Line.Y.rawValue)) {
					line = .Y
					lineColor = MetroLineColors.Y
					lineColorUnselected = MetroLineColors.Ys
					lineLabelColor = .black
				} else if (stationId.hasPrefix(Line.A.rawValue)) {
					line = .A
					lineColor = MetroLineColors.A
					lineColorUnselected = MetroLineColors.As
					lineLabelColor = .white
				} else if (stationId.hasPrefix(Line.LG.rawValue)) {
					line = .LG
					lineColor = MetroLineColors.LG
					lineColorUnselected = MetroLineColors.LGs
					lineLabelColor = .black
				} else if (stationId.hasPrefix(Line.SB.rawValue)) {
					line = .SB
					lineColor = MetroLineColors.SB
					lineColorUnselected = MetroLineColors.SBs
					lineLabelColor = .white
				}
			}
		}
	}
	var location: CLLocation = CLLocation()
	
	var bearing: String = ""
	var stops: [BusStop] = []
	
	var stationIDsForMetro: [String] = []
	var line: Line	= .Z
	var lineColor: UIColor = MetroLineColors.Z
	var lineColorUnselected: UIColor = MetroLineColors.Z
	var lineLabelColor: UIColor = UIColor.white
	
	init(stationName: String, stationId: String, stationType: StationType) {
		self.stationName = stationName
		self.stationId = stationId
		self.stationType = stationType
	}
	
	enum StationType: Int {
		case Bus	= 1
		case Metro	= 2
		case Error	= 0
	}
	
	enum Line: String {
		case BR	= "BR"
		case R	= "R"
		case G	= "G"
		case O	= "O"
		case BL	= "BL"
		case Y	= "Y"
		case A	= "A"
		case LG	= "LG"
		case SB	= "SB"
		
		case Gb = "Gb"
		case Rb	= "Rb"
		
		case Z	= "Z"	// unknown line
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
	
	var plateNumber: String = ""
	
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
		static let Arriving				= "到站中"
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
	var location: CLLocation = CLLocation()
	var plateNumber = ""
	var vehicleType: VehicleType = VehicleType.General
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
	var timeToTheNextStation = 90
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
	
	enum VehicleType: Int {
		case General	= 0
		case Accessible	= 1
		case Rehabus	= 2
		case Small		= 3
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
		static let Arriving				= "到站中"
		static let Approaching			= "將到站"
		static let Incoming				= "分"
		static let NotDeparted			= "尚未發車"
		static let TrafficRegulation	= "交管不停靠"
		static let OutService			= "末班車已過"
		static let NoServiceToday		= "今日未營運"
	}
}

class Bus {
	var routeId: String
	var routeName: String
	var plateNumber: String
	var direction: Int = -1
	var location: CLLocation = CLLocation()
	var speed: Int = 0
	var azimuth: Int = -1
	var busStatus: BusStopLiveStatus.BusStatus = .Unknown
	var distance: Int = -1
	var city: String = ""
	
	init(routeId: String, routeName: String, plateNumber: String) {
		self.routeId = routeId
		self.routeName = routeName
		self.plateNumber = plateNumber
	}
}

class MetroArrival {
	let stationName: String
	let destinationName: String
	let estimatedArrival: Int
	var trainNumber: String?
	var crowdness: [Int]?
	var line: Station.Line? {
		didSet {
			switch line {
			case .BR:
				lineName = " 文湖線 "
				lineColor = MetroLineColors.BR
				lineLabelColor = .white
			case .R:
				lineName = " 淡水信義線 "
				lineColor = MetroLineColors.R
				lineLabelColor = .white
			case .G:
				lineName = " 松山新店線 "
				lineColor = MetroLineColors.G
				lineLabelColor = .white
			case .O:
				lineName = " 中和新蘆線 "
				lineColor = MetroLineColors.O
				lineLabelColor = .white
			case .BL:
				lineName = " 板南線 "
				lineColor = MetroLineColors.BL
				lineLabelColor = .white
			case .Y:
				lineName = " 環狀線 "
				lineColor = MetroLineColors.Y
				lineLabelColor = .black
			case .Gb:
				lineName = " 小碧潭支線 "
				lineColor = MetroLineColors.Gb
				lineLabelColor = .black
			case .Rb:
				lineName = " 新北投支線 "
				lineColor = MetroLineColors.Rb
				lineLabelColor = .white
			case .A:
				lineName = " 機場線 "
				lineColor = MetroLineColors.A
				lineLabelColor = .white
			case .LG:
				lineName = " 萬大-中和-樹林線 "
				lineColor = MetroLineColors.LG
				lineLabelColor = .black
			case .SB:
				lineName = " 民生汐止線 "
				lineColor = MetroLineColors.SB
				lineLabelColor = .white
			default:
				break
			}
		}
	}
	var lineName: String?
	var lineColor: UIColor = MetroLineColors.Z
	var lineLabelColor: UIColor = UIColor.white
	var informationLabelColor: UIColor = RouteInformationLabelColors.gray
	var status: Status? {
		didSet {
			switch status {
			case .Normal:
				if(estimatedArrival > 120) {
					informationLabelColor = RouteInformationLabelColors.green
				}
				else if(estimatedArrival >= 10) {
					informationLabelColor = RouteInformationLabelColors.orange
				}
				else {
					informationLabelColor = RouteInformationLabelColors.red
				}
			case .Approaching:
				informationLabelColor = RouteInformationLabelColors.red
			case .Loading:
				informationLabelColor = RouteInformationLabelColors.gray
			case .ServiceOver:
				informationLabelColor = RouteInformationLabelColors.gray
			default:
				informationLabelColor = RouteInformationLabelColors.gray
			}
		}
	}
	
	init(stationName: String, destinationName: String, estimatedArrival: Int) {
		self.stationName = stationName
		self.destinationName = destinationName
		self.estimatedArrival = estimatedArrival
	}
	
	enum Status {
		case Normal
		case Approaching
		case ServiceOver
		case Loading
	}
}

class MetroStation {
	let stationName: String
	let sequence: Int
	
	var isCurrentStation: Bool = false
	var isDepartureStation: Bool = false
	var isDestinationStation: Bool = false
	
	init(stationName: String, sequence: Int) {
		self.stationName = stationName
		self.sequence = sequence
	}
}

class MetroLivePosition {
	let stationName: String
	let destinationName: String
	let estimatedArrival: Int
	var status: MetroArrival.Status?
	
	init(stationName: String, destinationName: String, estimatedArrival: Int) {
		self.stationName = stationName
		self.destinationName = destinationName
		self.estimatedArrival = estimatedArrival
	}
}

//
//  Constants.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/28.
//

import Foundation
import UIKit

let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

enum RouteInformationLabelColors {
	static let red =	UIColor(red: 255/255, green: 96/255, blue: 96/255, alpha: 1.0)
	static let orange =	UIColor(red: 255/255, green: 164/255, blue: 89/255, alpha: 1.0)
	static let green =	UIColor(red: 89/255, green: 206/255, blue: 88/255, alpha: 1.0)
	static let gray =	UIColor(white: 0.75, alpha: 1.0)
	
	static let redAnimating =		UIColor(red: 255/255, green: 134/255, blue: 134/255, alpha: 1.0)
	static let orangeAnimating =	UIColor(red: 255/255, green: 197/255, blue: 107/255, alpha: 1.0)
	static let greenAnimating =		UIColor(red: 98/255, green: 227/255, blue: 97/255, alpha: 1.0)
}

enum MetroLineColors {
	static let BR	= UIColor(red: 181/255, green: 122/255, blue: 37/255, alpha: 1.0)
	static let R	= UIColor(red: 217/255, green: 0/255, blue: 35/255, alpha: 1.0)
	static let G	= UIColor(red: 16/255, green: 117/255, blue: 71/255, alpha: 1.0)
	static let O	= UIColor(red: 245/255, green: 168/255, blue: 24/255, alpha: 1.0)
	static let BL	= UIColor(red: 10/255, green: 89/255, blue: 174/255, alpha: 1.0)
	static let Y	= UIColor(red: 254/255, green: 219/255, blue: 0/255, alpha: 1.0)
	static let A	= UIColor(red: 130/255, green: 70/255, blue: 175/255, alpha: 1.0)
	
	static let Gb 	= UIColor(red: 214/255, green: 222/255, blue: 33/255, alpha: 1.0)
	static let Rb	= UIColor(red: 246/255, green: 152/255, blue: 158/255, alpha: 1.0)
	
	static let LG	= UIColor(red: 162/255, green: 234/255, blue: 133/255, alpha: 1.0)
	static let SB	= UIColor(red: 0/255, green: 177/255, blue: 242/255, alpha: 1.0)
	
	static let Z	= RouteInformationLabelColors.gray
	
	// for unselected colors
	static let BRs	= UIColor(hue: 35/359, saturation: 0.50, brightness: 0.85, alpha: 1.0)
	static let Rs	= UIColor(hue: 359/359, saturation: 0.50, brightness: 1.00, alpha: 1.0)
	static let Gs	= UIColor(hue: 153/359, saturation: 0.45, brightness: 0.78, alpha: 1.0)
	static let Os	= UIColor(hue: 39/359, saturation: 0.50, brightness: 0.96, alpha: 1.0)
	static let BLs	= UIColor(hue: 211/359, saturation: 0.50, brightness: 0.85, alpha: 1.0)
	static let Ys	= UIColor(hue: 52/359, saturation: 0.50, brightness: 1.00, alpha: 1.0)
	static let As	= UIColor(hue: 274/359, saturation: 0.25, brightness: 0.90, alpha: 1.0)
	
	static let LGs	= UIColor(red: 194/255, green: 255/255, blue: 159/255, alpha: 1.0)
	static let SBs	= UIColor(red: 0/255, green: 211/255, blue: 255/255, alpha: 1.0)
}

let PlateNumberBackgroundColor = UIColor(red: 0.0, green: 96/255, blue: 17/255, alpha: 1.0)

let labelStandardBlack = UIColor(named: "Black")
let labelStandardWhite = UIColor(named: "White")

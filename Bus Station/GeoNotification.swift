//
//  GeoNotification.swift
//  Bus Station
//
//  Created by Garry Yeung on 2021/3/21.
//

import UIKit
import CoreLocation

class GeoNotificationResponder: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?
	let locationManager = CLLocationManager()
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		print("GeoNotificationResponder Class scene loaded")
		locationManager.delegate = self
		locationManager.requestAlwaysAuthorization()
	}
}

extension GeoNotificationResponder: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
		print("Entered region triggered.")
		if region is CLCircularRegion {
			handleEvent(for: region)
		}
	}
	
	// deleted
	func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
		print("Exit region triggered.")
		if region is CLCircularRegion {
			handleEvent(for: region)
		}
	}
	// deleted
	
	func handleEvent(for region: CLRegion) {
		// Show an alert if application is active
		print("handle event for \(region.identifier)")
		if UIApplication.shared.applicationState == .active {	// TODO: nothing to do when active
			print("(Active) in GeoNotificationResponder")
			//guard let message = region.identifier else { return }
			//ErrorAlert.presentErrorAlert(title: "", message: message)
		} else {
			print("(Inactive or Background) in GeoNotificationResponder")
			// Otherwise present a local notification
			let stationName = region.identifier
			let notificationContent = UNMutableNotificationContent()
			notificationContent.title = stationName
			notificationContent.body = "測試中"
			notificationContent.sound = .default
			let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)	// TODO: nil to deliver right away
			let request = UNNotificationRequest(
				identifier: "GettingInMRTStation",
				content: notificationContent,
				trigger: trigger)
			UNUserNotificationCenter.current().add(request) { error in
				if let error = error {
					print("Error: \(error)")
				}
			}
		}
	}
}

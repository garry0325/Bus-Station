//
//  SceneDelegate.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/10/19.
//

import UIKit
import CoreLocation
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {

	var window: UIWindow?
    let locationManager = CLLocationManager()
    

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        
        locationManager.delegate = self
        UNUserNotificationCenter.current().delegate = self
        
		guard let _ = (scene as? UIWindowScene) else { return }
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
		// Release any resources associated with this scene that can be re-created the next time the scene connects.
		// The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
	}

	func sceneWillResignActive(_ scene: UIScene) {
		// Called when the scene will move from an active state to an inactive state.
		// This may occur due to temporary interruptions (ex. an incoming phone call).
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as the scene transitions from the background to the foreground.
		// Use this method to undo the changes made on entering the background.
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.

		// Save changes in the application's managed object context when the application transitions to the background.
		(UIApplication.shared.delegate as? AppDelegate)?.saveContext()
	}

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(for: region)
        }
    }
    
    func handleEvent(for region: CLRegion) {
        // Show an alert if application is active
        print("handle event for \(region.identifier)")
        if UIApplication.shared.applicationState == .active {
            //print("(Active) in GeoNotificationResponder")
        } else {
            // Query MRT arrival time
            queryMRTandPushGeoNotification(stationName: region.identifier)
        }
    }
    
    func queryMRTandPushGeoNotification(stationName: String) {
        let queryingMrtStation = MRTStationsByLine[geoStationsIndex[stationName]![0][0]][geoStationsIndex[stationName]![0][1]][0] as! Station
        let mrtArrivals = BusQuery.shared.queryMetroArrivals(metroStation: queryingMrtStation)
        
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "捷運" + queryingMrtStation.stationName + ((queryingMrtStation.stationName.last == "站") ? "":"站")
        
        var notificationBody = ""
        for mrtArrival in mrtArrivals {
            var information = ""
            switch mrtArrival.status {
            case .Normal:
                if(mrtArrival.estimatedArrival > 10) {
                    information = String(format: "%2d : %02d", mrtArrival.estimatedArrival / 60, mrtArrival.estimatedArrival % 60)
                }
                else {
                    information = "到站中"
                }
            case .Approaching:
                information = "到站中"
            case .Loading:
                information = "加載中"
            case .ServiceOver:
                information = "末班車已過"
            default:
                information = "加載中"
            }
            let padding = 7 - mrtArrival.destinationName.count
            let spaces = String(repeating: "　", count: (padding > 0) ? padding:1)
            
            notificationBody = notificationBody + String(format: "→ %@%@%@\n", mrtArrival.destinationName, spaces, information)
        }
        notificationBody.removeLast()
        notificationContent.body = notificationBody
        notificationContent.sound = .default
        notificationContent.userInfo = ["station": queryingMrtStation.stationName]
        notificationContent.categoryIdentifier = "GeoNotificationCategory"
        let request = UNNotificationRequest(
            identifier: "GettingInMRTStation",
            content: notificationContent,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false))
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "ReloadGeoNotification":
            queryMRTandPushGeoNotification(stationName: response.notification.request.content.userInfo["station"] as! String)
        default:
            break
        }
        
        completionHandler()
    }
}


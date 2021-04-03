//
//  AboutViewController.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/11/7.
//

import UIKit
import CoreLocation
import UserNotifications

class AboutViewController: UIViewController, CLLocationManagerDelegate {
    
    let stationRadiusSliderScale: Float = 10.0
    
    @IBOutlet var stationRadiusLabel: UILabel!
    @IBOutlet var stationRadiusSlider: UISlider!
    @IBOutlet var geoNotificationSwitch: UISwitch!
    var desireGeoNotificationCapability: Bool = false
    @IBOutlet var warningLabel: UILabel!
    @IBOutlet var versionLabel: UILabel!
    var stationRadiusTemporary = stationRadius {
        didSet {
            stationRadiusLabel.text = "周圍車站半徑 \(String(numberFormatter.string(from: NSNumber(value: stationRadiusTemporary))!))m"
        }
    }
    
    let numberFormatter = NumberFormatter()
    
    var count = 0
    var rightCount = 0
    let pattern = [1,1,2,1,0,1,2,2,0,1,1,2,1,0,1,2,2,0]
    var countForRadius = 0
    var rightCountForRadius = 0
    let patternForRadius = [2,1,0,1,0,1,2,1,1,2]
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        desireGeoNotificationCapability = geoNotificationCapablility
        checkNotificationAndLocationPermission()
        
        numberFormatter.numberStyle = .decimal
        
        stationRadiusTemporary = stationRadius
        stationRadiusSlider.value = stationRadius / stationRadiusSliderScale
        
        geoNotificationSwitch.isOn = geoNotificationCapablility
        
        versionLabel.text = "版本：" + (Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)
        
        stationRadiusLabel.textColor = labelStandardBlack
        warningLabel.textColor = labelStandardBlack
        versionLabel.textColor = labelStandardBlack
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stationRadius = stationRadiusTemporary
        geoNotificationCapablility = geoNotificationSwitch.isOn
        NotificationCenter.default.post(name: NSNotification.Name("StationRadiusPreference"), object: nil)
    }
    
    @IBAction func stationRadiusSliderChanged(_ sender: UISlider) {
        stationRadiusTemporary = Float(Int(sender.value)) * stationRadiusSliderScale
    }
    
    @IBAction func geoNotificationSwitched(_ sender: UISwitch) {
        print("GeoNotification Switched \(sender.isOn ? "ON":"OFF")")
        
        if(sender.isOn) {
            desireGeoNotificationCapability = true
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                print("Notification \(granted ? "":"NOT") granted")
                if let error = error {
                    print("Notification Permission failed with the following error: \(error)")
                    geoNotificationCapablility = false
                }
                
                if(granted) {
                    print("Granted")
                    
                    print("\(self.locationManager.authorizationStatus)")
                    if(!CLLocationManager.locationServicesEnabled() || self.locationManager.authorizationStatus != .authorizedAlways) {
                        print("Location permission not granted or authorization is not always")
                        
                        let locationServiceAlert = UIAlertController(title: "請開啟always定位服務", message: "設定 > 隱私 > 定位服務", preferredStyle: .alert)
                        // TODO: CHECK the message is correct
                        let okAction = UIAlertAction(title: "好的", style: .default, handler: nil)
                        locationServiceAlert.addAction(okAction)
                        
                        DispatchQueue.main.async {
                            self.geoNotificationSwitch.setOn(false, animated: true)
                            self.present(locationServiceAlert, animated: true, completion: nil)
                            
                            self.locationManager.requestAlwaysAuthorization()
                        }
                        geoNotificationCapablility = false
                        return
                    }
                }
                else {
                    let notificationServiceAlert = UIAlertController(title: "請允許傳送通知", message: "設定 > 通知 > 臺北即時站牌", preferredStyle: .alert)
                    // TODO: CHECK the message is correct
                    let okAction = UIAlertAction(title: "好的", style: .default, handler: {_ in
                        
                    })
                    notificationServiceAlert.addAction(okAction)
                    
                    DispatchQueue.main.async {
                        self.geoNotificationSwitch.setOn(false, animated: true)
                        self.present(notificationServiceAlert, animated: true, completion: nil)
                    }
                    
                    geoNotificationCapablility = false
                }
            }
        }
    }
    
    @IBAction func removeAdPressed(_ sender: UIButton) {
        if(count < pattern.count) {
            if(sender.tag == pattern[count]) {
                rightCount = rightCount + 1
            }
        }
        count = count + 1
        
        if(rightCount == pattern.count) {
            self.dismiss(animated: true, completion: nil)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RemoveAd"), object: nil)
        }
        
        if(countForRadius < patternForRadius.count) {
            if(sender.tag == patternForRadius[countForRadius]) {
                rightCountForRadius = rightCountForRadius + 1
            }
        }
        countForRadius = countForRadius + 1
        
        if(rightCountForRadius == patternForRadius.count) {
            stationRadiusSlider.maximumValue = 300
        }
    }
    
    func checkNotificationAndLocationPermission() {
        let center = UNUserNotificationCenter.current()
        if(geoNotificationCapablility) {
            if(CLLocationManager.locationServicesEnabled() && locationManager.authorizationStatus == .authorizedAlways) {
                center.getNotificationSettings { (granted) in
                    if(granted.authorizationStatus != .authorized) {
                        geoNotificationCapablility = false
                        
                        DispatchQueue.main.async {
                            self.geoNotificationSwitch.setOn(false, animated: true)
                        }
                    }
                }
            }
            else {
                geoNotificationCapablility = false
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("location authorization changed")
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { (granted) in
            if(granted.authorizationStatus == .authorized && self.locationManager.authorizationStatus == .authorizedAlways && self.desireGeoNotificationCapability) {
                DispatchQueue.main.async {
                    self.geoNotificationSwitch.setOn(true, animated: true)
                }
                geoNotificationCapablility = true
            }
        }
    }
}

//
//  AboutViewController.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/11/7.
//

import UIKit

class AboutViewController: UIViewController {
	
	let stationRadiusSliderScale: Float = 10.0

	@IBOutlet var upSideUpSwitch: UISwitch!
	@IBOutlet var stationRadiusLabel: UILabel!
	@IBOutlet var stationRadiusSlider: UISlider!
	@IBOutlet var versionLabel: UILabel!
	var stationRadiusTemporary = stationRadius {
		didSet {
			stationRadiusLabel.text = "周圍車站半徑 \(String(numberFormatter.string(from: NSNumber(value: stationRadiusTemporary))!))m"
		}
	}
	
	let numberFormatter = NumberFormatter()
	
	var count = 0
	var rightCount = 0
	let pattern = [1,1,2,1,0,1,2,2,0]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		numberFormatter.numberStyle = .decimal
		
		upSideUpSwitch.setOn(!upSideUpLayout, animated: true)
		stationRadiusTemporary = stationRadius
		stationRadiusSlider.value = stationRadius / stationRadiusSliderScale
		versionLabel.text = "版本：" + (Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		stationRadius = stationRadiusTemporary
		NotificationCenter.default.post(name: NSNotification.Name("StationRadiusPreference"), object: nil)
	}
	
	@IBAction func upSideUpSwitched(_ sender: UISwitch) {
		upSideUpLayout = !upSideUpSwitch.isOn
		NotificationCenter.default.post(name: NSNotification.Name("LayoutPreference"), object: nil)
	}
	
	@IBAction func stationRadiusSliderChanged(_ sender: UISlider) {
		stationRadiusTemporary = Float(Int(sender.value)) * stationRadiusSliderScale
	}
	
	@IBAction func removeAdPressed(_ sender: UIButton) {
		print("removeAd \(sender.tag)")
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
	}
}

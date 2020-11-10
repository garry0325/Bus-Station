//
//  AboutViewController.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/11/7.
//

import UIKit

class AboutViewController: UIViewController {

	@IBOutlet var versionLabel: UILabel!
	@IBOutlet var upSideUpSwitch: UISwitch!
	
	var count = 0
	var rightCount = 0
	let pattern = [1,1,2,1,0,1,2,2,0]
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		upSideUpSwitch.setOn(!upSideUpLayout, animated: true)
		versionLabel.text = "版本：" + (Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)
	}
	
	@IBAction func upSideUpSwitched(_ sender: UISwitch) {
		upSideUpLayout = !upSideUpSwitch.isOn
		NotificationCenter.default.post(name: NSNotification.Name("LayoutPreference"), object: nil)
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

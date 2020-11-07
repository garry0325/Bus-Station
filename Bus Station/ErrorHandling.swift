//
//  ErrorHandling.swift
//  Bus Station
//
//  Created by Garry Yeung on 2020/11/07.
//  Copyright © 2020 Garry Yeung. All rights reserved.
//

import Foundation
import UIKit
import Network

class NetworkConnection {
	static let shared = NetworkConnection()
	
	let monitor = NWPathMonitor()
	private var status: NWPath.Status = .requiresConnection
	var isReachable: Bool { status == .satisfied }
	var isReachableOnCellular: Bool = true
	
	func startMonitoring() {
		monitor.pathUpdateHandler = { [weak self] path in
					self?.status = path.status
					self?.isReachableOnCellular = path.isExpensive

					if path.status == .satisfied {
						// post connected notification
					} else {
						print("No connection.")
						DispatchQueue.main.async {
							ErrorAlert.presentErrorAlert(title: "網路錯誤", message: "請檢查是否開啟網路")
						}
					}
				}
		
		let queue = DispatchQueue(label: "NetworkConnection")
		monitor.start(queue: queue)
	}
	
	func stopMonitoring() {
		monitor.cancel()
	}
}


class ErrorAlert {
	class func presentErrorAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
		alert.addAction(ok)
		
		UIApplication.shared.windows.first?.rootViewController!.present(alert, animated: true, completion: nil)
	}
}

//
//  GeoStationPickerViewController.swift
//  Bus Station
//
//  Created by Garry Sinica on 2021/4/3.
//

import UIKit

class GeoStationPickerViewController: UIViewController {

    @IBOutlet weak var pickerTableView: UITableView!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var closeButtonTrailingToSafeAreaConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerTableView.delegate = self
        pickerTableView.dataSource = self
        
        pickerTableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 150.0, right: 0.0)
        
        // put the close button in the center if large screen
        if(self.view.frame.height > 750.0) {
            closeButtonTrailingToSafeAreaConstraint.isActive = false
            NSLayoutConstraint(item: closeButton!, attribute: .centerX, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .centerX, multiplier: 1.0, constant: 0.0).isActive = true
        }

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
	
	func generateGeoNotificationStations() {
		geoNotificationStations = []
		for line in 0..<stationRecorder.count {
			for station in 0..<stationRecorder[line].count {
				let stationName = (MRTStationsByLine[line][station][0] as! Station).stationName
				if(stationRecorder[line][station] && !geoNotificationStations.contains(stationName)) {
					geoNotificationStations.append(stationName)
				}
			}
		}
		print(geoNotificationStations)
	}
    
	override func viewDidDisappear(_ animated: Bool) {
		generateGeoNotificationStations()
	}
	
    @IBAction func closeGeoStationPickerViewController(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension GeoStationPickerViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return MRTLineOrder.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MRTStationsByLine[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return MRTLineOrder[section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GeoStation") as! GeoStationTableViewCell
        let stationName = (MRTStationsByLine[indexPath.section][indexPath.row][0] as! Station).stationName
		
        cell.stationNameLabel.text = stationName
		cell.checkmarkImageView.isHidden = !stationRecorder[indexPath.section][indexPath.row]
        
        return cell
    }
    
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let selectedStationName = (MRTStationsByLine[indexPath.section][indexPath.row][0] as! Station).stationName
		let originallySelected = stationRecorder[indexPath.section][indexPath.row]
		
		if(!originallySelected && selectedCount >= maximumGeoStationCount) {
			print("maximum stations reached")
		}
		else {
			if(originallySelected) {
				selectedCount = selectedCount - 1
			}
			else {
				selectedCount = selectedCount + 1
			}
			
			if(repeatedStations.contains(selectedStationName)) {
				for index in geoStationsIndex[selectedStationName]! {
					stationRecorder[index[0]][index[1]] = !originallySelected
				}
			}
			else {
				stationRecorder[indexPath.section][indexPath.row] = !stationRecorder[indexPath.section][indexPath.row]
			}
		}
		
		tableView.reloadData()
	}
	
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 40.0))
        
		let label = UILabel()
		label.frame = CGRect.init(x: 0, y: 0, width: headerView.frame.width, height: headerView.frame.height)
		label.font = .boldSystemFont(ofSize: 20.0)
		label.textAlignment = .center
		label.text = MRTLineOrder[section]
		
        switch section {
        case 0:
            headerView.backgroundColor = MetroLineColors.BR
			label.textColor = .white
        case 1:
            headerView.backgroundColor = MetroLineColors.R
			label.textColor = .white
        case 2:
            headerView.backgroundColor = MetroLineColors.G
			label.textColor = .white
        case 3:
            headerView.backgroundColor = MetroLineColors.O
			label.textColor = .white
        case 4:
            headerView.backgroundColor = MetroLineColors.BL
			label.textColor = .white
        case 5:
            headerView.backgroundColor = MetroLineColors.Y
			label.textColor = .black
        default:
            headerView.backgroundColor = MetroLineColors.Z
			label.textColor = .white
        }
		
        headerView.addSubview(label)
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 35.0
    }
}


class GeoStationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var stationNameLabel: UILabel!
    @IBOutlet weak var checkmarkImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Initialization code
    }
    
}

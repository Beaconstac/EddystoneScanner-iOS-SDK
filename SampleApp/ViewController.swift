//
//  ViewController.swift
//  SampleApp
//
//  Created by Amit Prabhu on 28/11/17.
//  Copyright © 2017 Amit Prabhu. All rights reserved.
//

import UIKit
import EddystoneScanner
import UserNotifications

class ViewController: UIViewController {
    
    let scanner = EddystoneScanner.Scanner()
    var timer : Timer?
    
    var beaconList = [Beacon]()

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        scanner.startScanning()
        scanner.delegate = self
        
        self.tableView.tableFooterView = UIView(frame: .zero)
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization.
        }
    }
}

extension ViewController: UITableViewDataSource {
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let beacon = beaconList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: BeaconTableViewCell.cellIdentifier) as! BeaconTableViewCell
        cell.configureCell(for: beacon)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beaconList.count
    }
}

extension ViewController: ScannerDelegate {
    
    func didUpdateScannerState(scanner: EddystoneScanner.Scanner, state: State) {
        print(state)
    }
    
    // MARK: EddystoneScannerDelegate callbacks
    func didFindBeacon(scanner: EddystoneScanner.Scanner, beacon: Beacon) {
        DispatchQueue.main.async {
            self.beaconList.append(beacon)
            self.tableView.reloadData()
        }
    }
    
    func didLoseBeacon(scanner: EddystoneScanner.Scanner, beacon: Beacon) {
        DispatchQueue.main.async {
            guard let index = self.beaconList.firstIndex(of: beacon) else {
                return
            }
            self.beaconList.remove(at: index)
            self.tableView.reloadData()
        }
    }
    
    func didUpdateBeacon(scanner: EddystoneScanner.Scanner, beacon: Beacon) {
        DispatchQueue.main.async {
            guard let index = self.beaconList.firstIndex(of: beacon) else {
                self.beaconList.append(beacon)
                self.tableView.reloadData()
                return
            }
            self.beaconList[index] = beacon
        }
    }
}

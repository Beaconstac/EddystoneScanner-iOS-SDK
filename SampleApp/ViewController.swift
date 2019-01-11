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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTableView), userInfo: nil, repeats: true)
    }
    
    @objc func updateTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer?.invalidate()
        timer = nil
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
        beaconList.append(beacon)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func didLoseBeacon(scanner: EddystoneScanner.Scanner, beacon: Beacon) {
        guard let index = beaconList.index(of: beacon) else {
            return
        }
        beaconList.remove(at: index)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func didUpdateBeacon(scanner: EddystoneScanner.Scanner, beacon: Beacon) {
        guard let index = beaconList.index(of: beacon) else {
            beaconList.append(beacon)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            return
        }
        beaconList[index] = beacon
    }
}

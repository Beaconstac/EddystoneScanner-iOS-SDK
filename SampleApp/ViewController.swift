//
//  ViewController.swift
//  SampleApp
//
//  Created by Amit Prabhu on 28/11/17.
//  Copyright © 2017 Amit Prabhu. All rights reserved.
//

import UIKit
import EddystoneScanner

class ViewController: UIViewController {
    
    let scanner = BeaconScanner()

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        scanner.startScanning()
        scanner.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let beacon = scanner.nearbyBeacons[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: BeaconTableViewCell.cellIdentifier) as! BeaconTableViewCell
        cell.beaconName.text = beacon.beaconID.description
        cell.eddystoneURL.text = beacon.eddystoneURL?.absoluteString
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scanner.nearbyBeacons.count
    }
}

extension ViewController: BeaconScannerDelegate {
    func didFindBeacon(beaconScanner: BeaconScanner, beacon: Beacon) {
        print("Found beacon ", beacon.description, beacon.eddystoneURL?.absoluteString)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func didLoseBeacon(beaconScanner: BeaconScanner, beacon: Beacon) {
        print("Lost beacon ", beacon.description, beacon.eddystoneURL?.absoluteString)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func didUpdateBeacon(beaconScanner: BeaconScanner, beacon: Beacon) {
        guard let eddystoneURL = beacon.eddystoneURL else {
            return
        }
        
        if eddystoneURL.absoluteString.contains("xp") {
//            print("Beacon updated ", beacon.eddystoneURL!.absoluteString)
        }
    }
}

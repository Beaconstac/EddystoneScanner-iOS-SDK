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
    
    let scanner = EddystoneScanner()

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        scanner.startScanning()
        scanner.delegate = self
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // Enable or disable features based on authorization.
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: UITableViewDataSource {
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let nearbyBeacons = scanner.nearbyBeacons
        let index = nearbyBeacons.index(nearbyBeacons.startIndex, offsetBy: indexPath.row)
        
        let beacon = nearbyBeacons[index]
        let cell = tableView.dequeueReusableCell(withIdentifier: BeaconTableViewCell.cellIdentifier) as! BeaconTableViewCell
        cell.beaconName.text = beacon.beaconID.description
        cell.eddystoneURL.text = beacon.eddystoneURL?.absoluteString
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scanner.nearbyBeacons.count
    }
}

extension ViewController: EddystoneScannerDelegate {
    func sendLocalNotification(beaconID: String, eddystoneURL: String) {
        let notif = UNMutableNotificationContent()
        notif.title = beaconID
        notif.subtitle = eddystoneURL
        notif.body = "I liked it!!!!"
        
        let notifTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: "myNotification", content:  notif, trigger: notifTrigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
            if error != nil{
                debugPrint(error!)
            }
        }
    }
    
    // MARK: EddystoneScannerDelegate callbacks
    func didFindBeacon(scanner: EddystoneScanner, beacon: Beacon) {
        debugPrint("Found beacon ", beacon.description, beacon.eddystoneURL?.absoluteString)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func didLoseBeacon(scanner: EddystoneScanner, beacon: Beacon) {
        debugPrint("Lost beacon ", beacon.description, beacon.eddystoneURL?.absoluteString)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func didUpdateBeacon(scanner: EddystoneScanner, beacon: Beacon) {
        guard let eddystoneURL = beacon.eddystoneURL else {
            return
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        self.sendLocalNotification(beaconID: beacon.beaconID.description, eddystoneURL: eddystoneURL.absoluteString)
    }
}

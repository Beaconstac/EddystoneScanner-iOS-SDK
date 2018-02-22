//
//  BeaconTableViewCell.swift
//  SampleApp
//
//  Created by Amit Prabhu on 12/12/17.
//  Copyright © 2017 Amit Prabhu. All rights reserved.
//

import UIKit
import EddystoneScanner

extension String {
    func inserting(separator: String, every n: Int) -> String {
        var result: String = ""
        let characters = Array(self)
        stride(from: 0, to: characters.count, by: n).forEach {
            result += String(characters[$0..<min($0+n, characters.count)])
            if $0+n < characters.count {
                result += separator
            }
        }
        return result
    }
}

class BeaconTableViewCell: UITableViewCell {
    
    static let cellIdentifier = "beaconTabelViewCellIdentifier"

    @IBOutlet weak var rssi: UILabel!
    @IBOutlet weak var beaconName: UILabel!
    @IBOutlet weak var batteryView: UIView!
    
    @IBOutlet weak var beaconMac: UILabel!
    
    @IBOutlet weak var beaconNamespace: UILabel!
    @IBOutlet weak var beaconInstance: UILabel!
    @IBOutlet weak var eddystoneURL: UILabel!
    
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var txPower: UILabel!
    @IBOutlet weak var advInt: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    internal func configureCell(for beacon: Beacon) {
        self.rssi.text = "\(beacon.filteredRSSI) dBM"
        self.beaconName.text = beacon.name ?? ""
        
        var batteryAmount: Float = 0
        if let batteryPercentage = beacon.telemetry?.batteryPercentage {
            batteryAmount = Float((batteryPercentage > 100) ? 100 : batteryPercentage) / 100.0
        }
        setBatteryLevel(batteryLevel: batteryAmount)
        self.batteryView.backgroundColor = batteryColor(forGreenAmount: batteryAmount)
        
        self.beaconMac.text = beacon.beaconID.instance.hexString.inserting(separator: ":", every: 2)
        
        self.beaconNamespace.text = "Namespace: \(beacon.beaconID.namespace.hexString)"
        self.beaconInstance.text = "Instance: \(beacon.beaconID.instance.hexString)"
        self.eddystoneURL.text = beacon.eddystoneURL?.absoluteString
        
        self.temperature.text = "NA"
        if let temp = beacon.telemetry?.temperature {
            self.temperature.text = "\(temp) °C"
        }
        
        self.txPower.text = "Tx: \(beacon.txPower)"
        
        self.advInt.text = "TI: NA"
        if let advInt = beacon.telemetry?.advInt {
            self.advInt.text = "TI: \(advInt)ms"
        }
    }

    internal func batteryColor(forGreenAmount greenAmount: Float) -> UIColor {
        return UIColor(hue: CGFloat(greenAmount)/3, saturation: 1.0, brightness: 0.8, alpha: 1.0)
    }
    
    internal func setBatteryLevel(batteryLevel: Float) {
        var frame = self.batteryView.frame
        
        frame.size.width = CGFloat(40 * batteryLevel)
        self.batteryView.frame = frame
    }
}

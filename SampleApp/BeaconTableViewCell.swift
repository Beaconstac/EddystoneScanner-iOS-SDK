//
//  BeaconTableViewCell.swift
//  SampleApp
//
//  Created by Amit Prabhu on 12/12/17.
//  Copyright © 2017 Amit Prabhu. All rights reserved.
//

import UIKit
import EddystoneScanner

class BeaconTableViewCell: UITableViewCell {
    
    static let cellIdentifier = "beaconTabelViewCellIdentifier"

    @IBOutlet weak var beaconNamespace: UILabel!
    @IBOutlet weak var beaconInstance: UILabel!
    @IBOutlet weak var eddystoneURL: UILabel!
    
    @IBOutlet weak var rssi: UILabel!
    @IBOutlet weak var voltage: UILabel!
    @IBOutlet weak var temperature: UILabel!
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
        self.beaconNamespace.text = beacon.beaconID.namespace.hexString
        self.beaconInstance.text = beacon.beaconID.instance.hexString
        
        self.eddystoneURL.text = beacon.eddystoneURL?.absoluteString
        
        self.rssi.text = "\(beacon.filterredRSSI) dBM"
        self.voltage.text = "\(beacon.telemetry?.batteryPercentage ?? 0)"
        self.temperature.text = "\(beacon.telemetry?.temperature ?? 0) C"
        self.advInt.text = "\(beacon.telemetry?.advInt ?? 0)"
        
    }

}

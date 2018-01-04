//
//  BeaconTableViewCell.swift
//  SampleApp
//
//  Created by Amit Prabhu on 12/12/17.
//  Copyright © 2017 Amit Prabhu. All rights reserved.
//

import UIKit

class BeaconTableViewCell: UITableViewCell {
    
    static let cellIdentifier = "beaconTabelViewCellIdentifier"

    @IBOutlet weak var beaconName: UILabel!
    @IBOutlet weak var eddystoneURL: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

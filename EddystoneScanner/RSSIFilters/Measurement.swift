//
//  Measurement.swift
//  EddystoneScanner
//
//  Created by Sachin Vas on 26/02/18.
//  Copyright © 2018 Amit Prabhu. All rights reserved.
//

import Foundation

internal class Measurement: Comparable, Hashable {
    
    var hashValue: Int {
        return rssi.hashValue ^ timeStamp.hashValue
    }
    
    static func <(lhs: Measurement, rhs: Measurement) -> Bool {
        return lhs.rssi < rhs.rssi
    }
    
    static func ==(lhs: Measurement, rhs: Measurement) -> Bool {
        return lhs.rssi == rhs.rssi
    }
    
    var rssi: Int
    var timeStamp: TimeInterval
    
    init(_ rssi: Int, timeStamp: TimeInterval) {
        self.rssi = rssi
        self.timeStamp = timeStamp
    }
}

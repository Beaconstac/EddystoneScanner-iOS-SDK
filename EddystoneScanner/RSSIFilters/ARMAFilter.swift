//
//  ARMAFilter.swift
//  EddystoneScanner
//
//  Created by Sachin Vas on 22/02/18.
//  Copyright © 2018 Amit Prabhu. All rights reserved.
//

import Foundation

// https://github.com/AltBeacon/android-beacon-library/blob/master/src/main/java/org/altbeacon/beacon/service/ArmaRssiFilter.java

class ArmaFilter: SignalFilter {
    
    var filterType: FilterType
    let sArmaCoefficient: Float
    
    var filteredRSSI: Float
    
    required init(_ filterType: FilterType, processNoise: Float, mesaurementNoise: Float) {
        sArmaCoefficient = processNoise
        filteredRSSI = mesaurementNoise
        self.filterType = filterType
    }
    
    func onRange(_ rssi: Float) {
        if Int(filteredRSSI) == BAD_SIG {
            filteredRSSI = rssi == 0 ? Float(BAD_SIG) : rssi
        }
        if rssi == 0 {
        } else {
            filteredRSSI = filteredRSSI - sArmaCoefficient * (filteredRSSI - rssi)
        }
    }
    
    func onOutOfRange() {
        filteredRSSI = Float(BAD_SIG)
    }
    
    func calculateRSSI() -> Float {
        return filteredRSSI
    }
}


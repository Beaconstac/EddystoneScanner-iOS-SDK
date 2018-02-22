//
//  RSSIFilter.swift
//  EddystoneScanner
//
//  Created by Sachin Vas on 22/02/18.
//  Copyright © 2018 Amit Prabhu. All rights reserved.
//

import Foundation

let BAD_SIG = -100;

enum FilterType {
    case Kalman
    case Arma
}

protocol SignalFilter {
    var filterType: FilterType {get}
    init(_ filterType: FilterType, processNoise: Float, mesaurementNoise: Float)
    func onRange(_ rssi: Float)
    func onOutOfRange()
    func calculateRSSI() -> Float
}

class RSSIFilter: SignalFilter {
    
    var filterType: FilterType {
        return _filter.filterType
    }
    
    private var _filter: SignalFilter
    
    required init(_ filterType: FilterType, processNoise: Float, mesaurementNoise: Float) {
        if filterType == .Arma {
            _filter = ArmaFilter(filterType, processNoise: processNoise, mesaurementNoise: mesaurementNoise)
        } else {
            _filter = KalmanFilter(filterType, processNoise: processNoise, mesaurementNoise: mesaurementNoise)
        }
    }
    
    func onRange(_ rssi: Float) {
        _filter.onRange(rssi)
    }
    
    func onOutOfRange() {
        _filter.onOutOfRange()
    }
    
    func calculateRSSI() -> Float {
        return _filter.calculateRSSI()
    }
}


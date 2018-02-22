//
//  KalmanFilter.swift
//  EddystoneScanner
//
//  Created by Amit Prabhu on 25/01/18.
//  Copyright © 2018 Amit Prabhu. All rights reserved.
//

import Foundation

///
/// KalmanFilter
///
/// Implements the Kalman filter as described wonderfully by
/// Wouter Bulten @ https://www.wouterbulten.nl/blog/tech/kalman-filters-explained-removing-noise-from-rssi-signals/
internal class KalmanFilter: SignalFilter {
    
    var filterType: FilterType
    
    private var _filteredRSSI: Float?
    
    /// Process noise
    private let R: Float
    
    /// Measurement noise
    private let Q: Float
    
    /// State vector
    private let A: Float
    
    /// Control vector
    private let B: Float
    
    /// Measurement vector
    private let C: Float
    
    /// Last calculated value
    private var x: Float?
    
    private var cov: Float = 0
    
    /**
     * Create 1-dimensional kalman filter
     */
    required init(_ filterType: FilterType, processNoise: Float, mesaurementNoise: Float) {
        self.filterType = .Kalman
        self.R = processNoise
        self.Q = mesaurementNoise
        self.A = 1
        self.B = 0
        self.C = 1
    }
    
    /**
     Filters the data based on kalman filter algorithm
     
     - Parameter z: The incoming data
     - Parameter u: Control
     */
    func onRange(_ rssi: Float) {
        guard let x = _filteredRSSI else {
            self._filteredRSSI = (1 / self.C) * rssi
            self.cov = (1 / self.C) * self.Q * (1 / self.C)
            return
        }
        
        // Compute prediction
        let predX = (self.A * x) + (self.B * 0)
        let predCov = ((self.A * self.cov) * self.A) + self.R
        
        // Kalman gain
        let K = predCov * self.C * (1 / ((self.C * predCov * self.C) + self.Q))
        
        // Correction
        self.x = predX + K * (rssi - (self.C * predX))
        self.cov = predCov - (K * self.C * predCov)
    }
    
    func onOutOfRange() {
        _filteredRSSI = nil
    }
    
    func calculateRSSI() -> Float {
        return _filteredRSSI ?? 0
    }
}

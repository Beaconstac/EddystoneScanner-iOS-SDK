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
internal class KalmanFilter: RSSIFilterDelegate {

    /// Stores the filter type
    internal let filterType: RSSIFilterType = .kalman
    
    /// Filtered RSSI value
    internal var filteredRSSI: Int?
    
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
    internal required init(processNoise: Float, mesaurementNoise: Float) {
        self.R = processNoise
        self.Q = mesaurementNoise
        self.A = 1
        self.B = 0
        self.C = 1
    }
    
    /**
     Calculates the filterred RSSI for incoming RSSI value
     
     - Parameter z: The incoming data
     */
    internal func calculate(forRSSI rssi: Int) {
        guard let x = filteredRSSI else {
            self.filteredRSSI = Int((1 / self.C) * Float(rssi))
            self.cov = (1 / self.C) * self.Q * (1 / self.C)
            return
        }
        
        // Compute prediction
        let predX = (self.A * Float(x)) + (self.B * 0)
        let predCov = ((self.A * self.cov) * self.A) + self.R
        
        // Kalman gain
        let K = predCov * self.C * (1 / ((self.C * predCov * self.C) + self.Q))
        
        // Correction
        self.x = predX + K * (Float(rssi) - (self.C * predX))
        self.cov = predCov - (K * self.C * predCov)
    }
}

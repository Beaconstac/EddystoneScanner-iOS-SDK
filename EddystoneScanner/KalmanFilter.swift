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
internal class KalmanFilter {
    
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
    internal init(r: Float=1, q: Float=1, a: Float=1, b: Float=0, c: Float=1) {
        self.R = r
        self.Q = q
        self.A = a
        self.B = b
        self.C = c
    }
    
    /**
     Filters the data based on kalman filter algorithm
     
     - Parameter z: The incoming data
     - Parameter u: Control
     */
    internal func filter(_ z: Float, u: Float=0) -> Float {
        guard let x = self.x else {
            self.x = (1 / self.C) * z
            self.cov = (1 / self.C) * self.Q * (1 / self.C)
            return self.x!
        }
        
        // Compute prediction
        let predX = (self.A * x) + (self.B * u)
        let predCov = ((self.A * self.cov) * self.A) + self.R
        
        // Kalman gain
        let K = predCov * self.C * (1 / ((self.C * predCov * self.C) + self.Q))
        
        // Correction
        self.x = predX + K * (z - (self.C * predX))
        self.cov = predCov - (K * self.C * predCov)
        
        return self.x!
    }
}

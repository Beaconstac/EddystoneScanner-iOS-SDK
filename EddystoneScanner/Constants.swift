//
//  Constants.swift
//  EddystoneScanner
//
//  Created by Amit Prabhu on 10/01/18.
//  Copyright © 2018 Amit Prabhu. All rights reserved.
//

import Foundation

///
/// Constants
///
/// Keeps track of all the constants used in the project
///
internal class Constants {
    static let BEACON_OPERATION_QUEUE_LABEL = "com.eddystonescanner.queue.blescanner"
    static let DISPATCH_TIMER_QUEUE_LABEL = "com.eddystonescanner.queue.dispatchtimer"
    
    // Kalman filter constants
    static let KALMAN_FILTER_PROCESS_NOISE: Float = 0.008
    static let KALMAN_FILTER_MEASUREMENT_NOISE: Float = 1.0
}

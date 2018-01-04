//
//  DispatchTimer.swift
//  NearbyReplica
//
//  Created by Amit Prabhu on 30/11/17.
//  Copyright © 2017 Amit Prabhu. All rights reserved.
//

import Foundation

internal protocol DispatchTimerProtocol {
    func timerCalled(dispatchTimer: DispatchTimer?)
}

class DispatchTimer {
    
    private var sourceTimer: DispatchSourceTimer?
    private let queue: DispatchQueue
    
    public let repeatingInterval: Double
    public var delegate: DispatchTimerProtocol?
    
    init(repeatingInterval: Double = 60.0) {
        queue = DispatchQueue(label: "com.nearbyreplica.dispatchtimer.queue")
        sourceTimer = DispatchSource.makeTimerSource(queue: queue)
        
        self.repeatingInterval = repeatingInterval
    }
    
    internal func startTimer() {
        sourceTimer?.schedule(deadline: .now(), repeating: repeatingInterval, leeway: .seconds(10))
        sourceTimer?.setEventHandler { [weak self] in
            self?.delegate?.timerCalled(dispatchTimer: self)
        }
        sourceTimer?.resume()
    }
    
    internal func stopTimer() {
        self.sourceTimer?.cancel()
        self.sourceTimer = nil
    }
    
}

//
//  Telemetry.swift
//  EddystoneScanner
//
//  Created by Amit Prabhu on 14/01/18.
//  Copyright © 2018 Amit Prabhu. All rights reserved.
//

import Foundation

///
/// Struct that handles the beacon telemtry data
/// Specs https://github.com/google/eddystone/blob/master/eddystone-tlm/tlm-plain.md
///
public struct Telemetry {
    
    /// Telemetry data version
    public let version: String
    
    /// Battery voltage is the current battery charge in millivolts
    public var voltage: UInt?
    
    /// Beacon temperature is the temperature in degrees Celsius sensed by the beacon. If not supported the value will be -128.
    public var temperature: Float?
    
    /// ADV_CNT is the running count of advertisement frames of all types emitted by the beacon since power-up or reboot, useful for monitoring performance metrics that scale per broadcast frame
    public var advCount: UInt?
    
    /// SEC_CNT is a 0.1 second resolution counter that represents time since beacon power-up or reboot
    public var uptime: Float?
    
    /// Calculates the advertising interval of the beacon in milliseconds
    /// Assumes the beacon is transmitting all 3 eddystone packets (UID, URL and TLM frames)
    public lazy var advInt: Float {
        guard let uptime = self.uptime,
            let advCount = self.advCount else {
                return 0
        }
        
        let numberOFFramesPerBeacon = 3
        return (numberOFFramesPerBeacon * 1000) / (Float(advCount) / uptime)
    }
    
    internal init?(tlmFrameData: Data) {
        guard let frameBytes = Telemetry.validateTLMFrameData(tlmFrameData: tlmFrameData) else {
            debugPrint("Failed to iniatialize the telemtry object")
            return nil
        }
        
        self.version = String(format: "%02X", frameBytes[1])
        self.parseTLMFrameData(frameBytes: frameBytes)
    }
    
    /**
     Update the telemetry object for the new telemtry frame data
     
     - Parameter tlmFrameData: The raw TLM frame data
     */
    internal mutating func update(tlmFrameData: Data) {
        guard let frameBytes = Telemetry.validateTLMFrameData(tlmFrameData: tlmFrameData) else {
            debugPrint("Failed to update telemetry data")
            return
        }
        self.parseTLMFrameData(frameBytes: frameBytes)
    }
    
    /**
     Validate the TLM frame data
     
     - Parameter tlmFrameData: The raw TLM frame data
     */
    private static func validateTLMFrameData(tlmFrameData: Data) -> [UInt8]? {
        let frameBytes = Array(tlmFrameData) as [UInt8]
        
        // The length of the frame should be 14
        guard frameBytes.count == 14 else {
            debugPrint("Corrupted telemetry frame")
            return nil
        }
        return frameBytes
    }
    
    /**
     Parse the TLM frame data
     
     - Parameter frameBytes: The `UInt8` byte array
     */
    private mutating func parseTLMFrameData(frameBytes: [UInt8]) {
        self.voltage = bytesToUInt(byteArray: frameBytes[2..<4])!
        self.temperature = Float(frameBytes[4]) + Float(frameBytes[5])/256
        self.advCount = bytesToUInt(byteArray: frameBytes[6..<10])!
        self.uptime = Float(bytesToUInt(byteArray: frameBytes[10..<14])!) / 10.0
    }
}

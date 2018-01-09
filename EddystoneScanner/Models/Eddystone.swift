//
//  EddystoneHelper.swift
//  NearbyReplica
//
//  Created by Amit Prabhu on 28/11/17.
//  Copyright © 2017 Amit Prabhu. All rights reserved.
//

import Foundation
import CoreBluetooth

///
/// BeaconID
///
/// Uniquely identifies an Eddystone compliant beacon.
///
public class BeaconID: CustomStringConvertible, Equatable {
    
    /**
     Beacon type.
     
     - eddystone: 10 bytes namespace + 6 bytes instance = 16 byte ID.
     - eddystoneEID: 8 byte ID
     */
    public enum BeaconType {
        case eddystone
        case eddystoneEID
    }
    
    public let beaconType: BeaconType
    
    ///
    /// The raw beaconID data. This is typically printed out in hex format.
    ///
    public let beaconID: [UInt8]
    
    ///
    /// Hexadecimal equvivalent of the beaconID
    ///
    public lazy var hexBeaconID: String = {
        var hexString = ""
        for byte in self.beaconID {
            var s = String(byte, radix:16, uppercase: false)
            if s.count == 1 {
                s = "0" + s
            }
            hexString += s
        }
        return hexString
    }()
    
    ///
    /// Base64 encoded string of the byte beacon ID data
    ///
    public lazy var beaconAdvertisedId: String = {
        let data = Data(bytes: self.beaconID)
        return data.base64EncodedString()
    }()
    
    
    internal init(beaconType: BeaconType, beaconID: [UInt8]) {
        self.beaconID = beaconID
        self.beaconType = beaconType
    }
    
    /// MARK: CustomStringConvertible protocol requirments
    public var description: String {
        return self.hexBeaconID
    }
    
    /// MARK: Equatable protocol requirments
    public static func == (lhs: BeaconID, rhs: BeaconID) -> Bool {
        return
            lhs.beaconID == rhs.beaconID &&
                lhs.beaconType == rhs.beaconType
    }
}

/**
 BLE frame type.
 
 - unknown: Unknown frame.
 - uid: UID frame.
 - telemetry: Telemetry frame.
 - eid: EID frame.
 - url: URL frame.
 */
internal enum EddystoneFrameType {
    case unknown, uid, telemetry, eid, url
}

/// Class containing static functions with Eddystone helper class methods
internal class Eddystone {
    
    internal static let EddystoneUIDFrameTypeID: UInt8 = 0x00
    internal static let EddystoneURLFrameTypeID: UInt8 = 0x10
    internal static let EddystoneTLMFrameTypeID: UInt8 = 0x20
    internal static let EddystoneEIDFrameTypeID: UInt8 = 0x30
    internal static let ServiceUUID: CBUUID = CBUUID(string: "FEAA")
    
    /**
     Get Frametype from the adverstiment data of a BLE device.
     
     - Parameter advertisementFrameList: The framelist returned from the CBCentralManager didDiscoverPerfipheral
     */
    internal class func frameTypeForFrame(advertisementFrameList: [NSObject : AnyObject]) -> EddystoneFrameType {
            guard let frameData = advertisementFrameList[Eddystone.ServiceUUID] as? Data, frameData.count > 1 else {
                return .unknown
            }
            
            let frameBytes = Array(frameData) as [UInt8]
            
            let frameByte = frameBytes[0]
            if frameByte == Eddystone.EddystoneUIDFrameTypeID {
                return .uid
            } else if frameByte == Eddystone.EddystoneTLMFrameTypeID {
                return .telemetry
            } else if frameByte == Eddystone.EddystoneEIDFrameTypeID {
                return .eid
            } else if frameByte == Eddystone.EddystoneURLFrameTypeID {
                return .url
            }
            return .unknown
    }
    
    /**
     Returns telemetry data braodcasted by the beacon. Check the frameType using `Beacon.frameTypeForFrame` as being
     `.telemetry` before calling this function
     
     - Parameter advertisementFrameList: The framelist returned from the CBCentralManager didDiscoverPerfipheral
     */
    internal class func telemetryDataForFrame(advertisementFrameList: [NSObject : AnyObject]) -> Data? {
        return advertisementFrameList[Eddystone.ServiceUUID] as? Data
    }
    
    /**
     Returns the eddystone URL braodcasted by the beacon. Check the frameType using `Beacon.frameTypeForFrame` as being
     `.url` before calling this function
     
     - Parameter frameData: The frame data returned from the CBCentralManager didDiscoverPeripheral
     */
    internal class func parseURLFromFrame(advertisementFrameList: [NSObject : AnyObject]) -> URL? {
        guard let frameData = advertisementFrameList[Eddystone.ServiceUUID] as? Data, frameData.count > 1 else {
            return nil
        }
        
        let frameBytes = Array(frameData) as [UInt8]
        guard let URLPrefix = URLPrefixFromByte(schemeID: frameBytes[2]) else {
            return nil
        }
        
        var output = URLPrefix
        for i in 3..<frameBytes.count {
            if let encoded = encodedStringFromByte(charVal: frameBytes[i]) {
                output.append(encoded)
            }
        }
        
        return URL(string: output)
    }
    
    private class func URLPrefixFromByte(schemeID: UInt8) -> String? {
        switch schemeID {
        case 0x00:
            return "http://www."
        case 0x01:
            return "https://www."
        case 0x02:
            return "http://"
        case 0x03:
            return "https://"
        default:
            return nil
        }
    }
    
    private class func encodedStringFromByte(charVal: UInt8) -> String? {
        switch charVal {
        case 0x00:
            return ".com/"
        case 0x01:
            return ".org/"
        case 0x02:
            return ".edu/"
        case 0x03:
            return ".net/"
        case 0x04:
            return ".info/"
        case 0x05:
            return ".biz/"
        case 0x06:
            return ".gov/"
        case 0x07:
            return ".com"
        case 0x08:
            return ".org"
        case 0x09:
            return ".edu"
        case 0x0a:
            return ".net"
        case 0x0b:
            return ".info"
        case 0x0c:
            return ".biz"
        case 0x0d:
            return ".gov"
        default:
            return String(data: Data([charVal]), encoding: .utf8)
        }
    }
    
    
}

//
//  EddystoneBeaconID.swift
//  EddystoneScanner
//
//  Created by Amit Prabhu on 10/01/18.
//  Copyright © 2018 Amit Prabhu. All rights reserved.
//

import Foundation

/**
 Beacon type.
 
 - eddystone: 10 bytes namespace + 6 bytes instance = 16 byte ID.
 - eddystoneEID: 8 byte ID
 */
public enum EddystoneBeaconType {
    case eddystone
    case eddystoneEID
}

///
/// EddystoneBeaconID
///
/// Uniquely identifies an Eddystone compliant beacon.
///
public class EddystoneBeaconID {
    
    public let beaconType: EddystoneBeaconType
    
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
    
    /**
     Internal initialiser
     
     - Parameter beaconType: BeaconType
     - Parameter beaconID: BeaconID
     */
    internal init(beaconType: EddystoneBeaconType, beaconID: [UInt8]) {
        self.beaconID = beaconID
        self.beaconType = beaconType
    }
}


extension EddystoneBeaconID: CustomStringConvertible {
    // MARK: CustomStringConvertible protocol requirments
    public var description: String {
        return self.hexBeaconID
    }
}

extension EddystoneBeaconID: Equatable {
    // MARK: Equatable protocol requirments
    public static func == (lhs: EddystoneBeaconID, rhs: EddystoneBeaconID) -> Bool {
        return
            lhs.beaconID == rhs.beaconID &&
                lhs.beaconType == rhs.beaconType
    }
}

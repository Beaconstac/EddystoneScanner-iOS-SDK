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
public enum BeaconType {
    case eddystone
    case eddystoneEID
}

///
/// EddystoneBeaconID
///
/// Uniquely identifies an Eddystone compliant beacon.
///
public struct BeaconID {
    
    public let beaconType: BeaconType
    
    ///
    /// unique 16-byte Beacon ID composed of a 10-byte namespace and a 6-byte instance
    /// Get hexString by doing beaconID.hexString
    ///
    public let beaconID: [UInt8]
    
    ///
    /// 10 byte raw namespace data
    ///
    public var namespace: ArraySlice<UInt8> {
        return beaconID[..<10]
    }
    
    ///
    /// 6 byte raw namespace data
    ///
    public var instance: ArraySlice<UInt8> {
        return beaconID[10..<16]
    }
    
    ///
    /// Base64 encoded string of the byte beacon ID data
    ///
    public var beaconAdvertisedId: String {
        return beaconID.data.base64EncodedString()
    }
    
    /**
     Internal initialiser
     
     - Parameter beaconType: BeaconType
     - Parameter beaconID: BeaconID
     */
    internal init(beaconType: BeaconType, beaconID: [UInt8]) {
        self.beaconID = beaconID
        self.beaconType = beaconType
    }
}


extension BeaconID: CustomStringConvertible {
    // MARK: CustomStringConvertible protocol requirments
    public var description: String {
        return beaconID.hexString
    }
}

extension BeaconID: Equatable {
    // MARK: Equatable protocol requirments
    public static func == (lhs: BeaconID, rhs: BeaconID) -> Bool {
        return lhs.beaconID == rhs.beaconID &&
                lhs.beaconType == rhs.beaconType
    }
}

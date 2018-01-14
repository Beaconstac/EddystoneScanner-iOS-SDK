//
//  Util.swift
//  EddystoneScanner
//
//  Created by Amit Prabhu on 14/01/18.
//  Copyright © 2018 Amit Prabhu. All rights reserved.
//

import Foundation

extension Collection where Iterator.Element == UInt8 {
    var data: Data {
        return Data(self)
    }
    var hexString: String {
        return map{ String(format: "%02X", $0) }.joined()
    }
}

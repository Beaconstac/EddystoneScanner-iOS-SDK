//
//  SafeDictionary.swift
//  EddystoneScanner
//
//  Created by Amit Prabhu on 11/01/18.
//  Copyright © 2018 Amit Prabhu. All rights reserved.
//

import Foundation

///
/// Safe Dictionary
///
/// Thread safe generic dictionary class in swift
/// Methods and properties are similar to that of the generic Dictionary class
/// Example: let a = SafeDictionary<String, Int>(identifier: "a")
///
public class SafeDictionary<K:Hashable, V: Any> {
    private let queue: DispatchQueue
    private var dict = [K:V]()
    
    public init(identifier: String) {
        queue = DispatchQueue(label: "com.safedictionary.\(Date().timeIntervalSince1970).\(identifier)", attributes: .concurrent)
    }
    
    public subscript(key: K) -> V? {
        get {
            return queue.sync {
                return dict[key]
            }
        }
        set {
            queue.async(flags: .barrier) {
                self.dict[key] = newValue
            }
        }
    }
}

extension SafeDictionary {
    // MARK: Mutable methods
    public func removeValue(forKey key: K) {
        queue.async(flags: .barrier) {
            self.dict[key] = nil
        }
    }
}

extension SafeDictionary {
    // MARK: Immutable methods
    public var keys: Dictionary<K, V>.Keys {
        return queue.sync {
            return dict.keys
        }
    }
    
    public var values: Dictionary<K, V>.Values {
        return queue.sync {
            return dict.values
        }
    }
}

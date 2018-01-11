//
//  SafeDictionary.swift
//  EddystoneScanner
//
//  Created by Amit Prabhu on 11/01/18.
//  Copyright © 2018 Amit Prabhu. All rights reserved.
//

import Foundation

public class SafeDictionary<K:Hashable, V: Any> {
    private let queue: DispatchQueue
    private var dict = [K:V]()
    
    init(identifier: String) {
        queue = DispatchQueue(label: "com.safedictionary.\(Date().timeIntervalSince1970).\(identifier)", attributes: .concurrent)
    }
    
    subscript(key: K) -> V? {
        get {
            return queue.sync {
                return dict[key]
            }
        }
        set {
            queue.async(flags: .barrier) { [unowned self] in
                self.dict[key] = newValue
            }
        }
    }
    
    
}

// Example usage
let a = SafeDictionary<String, Int>(identifier: "a")

//
//  SafeArray.swift
//  EddystoneScanner
//
//  Created by Amit Prabhu on 11/01/18.
//  Copyright © 2018 Amit Prabhu. All rights reserved.
//

import Foundation

///
/// Safe Array
///
/// Thread safe generic array class in swift
/// Methods and properties are similar to that of the generic Array class
/// Example: let a = SafeArray<Int>(identifier: "a")
///
public class SafeArray<E: Any> {
    private let queue: DispatchQueue
    private var array = [E]()
    
    public init(identifier: String) {
        queue = DispatchQueue(label: "com.safearray.\(Date().timeIntervalSince1970).\(identifier)", attributes: .concurrent)
    }
    
    public subscript(index: Int) -> E {
        get {
            return queue.sync {
                return array[index]
            }
        }
        set {
            queue.async(flags: .barrier) {
                self.array.insert(newValue, at: index)
            }
        }
    }
}

extension SafeArray {
    // MARK: Mutable methods
    public func append(value: E) {
        queue.async(flags: .barrier) {
            self.array.append(value)
        }
    }
    
    func remove(at index: Int) {
        queue.async(flags: .barrier) {
            self.array.remove(at: index)
        }
    }
}

extension SafeArray {
    // MARK: Immutable methods
    func filter(_ isIncluded: (E) -> Bool) -> [E] {
        return queue.sync {
            return self.array.filter(isIncluded)
        }
    }
}

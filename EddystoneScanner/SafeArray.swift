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
                self.array[index] = newValue
            }
        }
    }
}

extension SafeArray {
    // MARK: Mutable methods
    public func append(_ newElement: E) {
        queue.async(flags: .barrier) {
            self.array.append(newElement)
        }
    }
    
    public func remove(at index: Int) {
        queue.async(flags: .barrier) {
            self.array.remove(at: index)
        }
    }
    
    public func filterInPlace(_ isIncluded: @escaping (E) -> Bool) {
        queue.async(flags: .barrier) {
            let originalArray = self.array
            self.array = [E]()
            for element in originalArray {
                if isIncluded(element) {
                    self.array.append(element)
                }
            }
        }
    }
}

extension SafeArray {
    // MARK: Immutable properties
    public var count: Int {
        get {
            return queue.sync {
                return self.array.count
            }
        }
    }
    
    // MARK: Immutable methods
    public func index(where predicate: (E) -> Bool) -> Int? {
        return queue.sync {
            return self.array.index(where: predicate)
        }
    }
}

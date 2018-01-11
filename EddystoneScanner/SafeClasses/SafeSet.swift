//
//  SafeSet.swift
//  EddystoneScanner
//
//  Created by Amit Prabhu on 11/01/18.
//  Copyright © 2018 Amit Prabhu. All rights reserved.
//

import Foundation

///
/// Safe Set
///
/// Thread safe generic set class in swift
/// Methods and properties are similar to that of the generic Set class
/// Example: let a = SafeSet<String>(identifier: "a")
///
public class SafeSet<E: Hashable> {
    private let queue: DispatchQueue
    private var set: Set<E> = []
    
    public init(identifier: String) {
        queue = DispatchQueue(label: "com.safeset.\(Date().timeIntervalSince1970).\(identifier)", attributes: .concurrent)
    }
}

extension SafeSet {
    // MARK: Mutable methods
    public func insert(_ newMember: E) {
        queue.async(flags: .barrier) {
            self.set.insert(newMember)
        }
    }
    
    public func remove(_ member: E) {
        queue.async(flags: .barrier) {
            self.set.remove(member)
        }
    }
    
}

extension SafeSet {
    // MARK: Immutable properties
    public var isEmpty: Bool {
        get {
            return queue.sync {
                return set.isEmpty
            }
        }
    }
    
    public var count: Int {
        get {
            return queue.sync {
                return set.count
            }
        }
    }
    
    // MARK: Immutable methods
    public func contains(_ member: E) -> Bool {
        return queue.sync {
            return set.contains(member)
        }
    }
}

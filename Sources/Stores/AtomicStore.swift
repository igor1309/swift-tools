//
//  AtomicStore.swift
//  swift-tools
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Synchronization

/// A tiny thread-safe container that serializes access to its value behind a `Mutex`.
@available(iOS 18.0, macOS 15.0, *)
public final class AtomicStore<Value> {
    
    private let valueMutex: Mutex<Value>
    
    /// Creates an atomic store whose initial value becomes visible to every reader immediately.
    public init(initialValue: Value) {
        
        valueMutex = Mutex(initialValue)
    }
    
    /// Returns the current value as a snapshot taken while holding the mutex.
    public func get() -> Value {
        
        valueMutex.withLock { $0 }
    }
    
    /// Replaces the stored value atomically and publishes it once the mutex unlocks.
    public func set(_ newValue: Value) {
        
        valueMutex.withLock { $0 = newValue }
    }
    
    /// Executes `body` with read-only access to the current value while holding the mutex.
    /// - Parameter body: A closure that inspects, but should not mutate, the provided value.
    /// - Returns: Whatever `body` produces.
    @discardableResult
    public func withValue<Result>(
        _ body: (Value) throws -> Result
    ) rethrows -> Result {
        
        try valueMutex.withLock { try body($0) }
    }
    
    /// Executes `body` with mutable access to the stored value while holding the mutex.
    /// Use this for read-modify-write sequences that must remain atomic.
    public func mutate(
        _ body: (inout Value) throws -> Void
    ) rethrows {
        
        try valueMutex.withLock { value in try body(&value) }
    }
}

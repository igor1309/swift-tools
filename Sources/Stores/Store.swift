//
//  Store.swift
//  swift-vortex
//
//  Created by Igor Malyarov on 03.06.2025.
//

import Foundation

public protocol Store {
    
    func insert(
        _ data: Data,
        forKey key: String
    ) async throws
    
    func retrieve(
        key: String
    ) async throws -> Data
}

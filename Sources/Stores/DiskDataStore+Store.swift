//
//  DiskDataStore+Store.swift
//  swift-tools
//
//  Created by Igor Malyarov on 12.11.2025.
//

import Foundation

extension DiskDataStore: Store {

    public func insert(
        _ data: Data,
        forKey key: String
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            insert(data, forKey: key) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func retrieve(
        key: String
    ) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            retrieve(key: key) { result in
                continuation.resume(with: result)
            }
        }
    }
}

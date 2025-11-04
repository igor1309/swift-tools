//
//  DiskDataStore+load.swift
//  swift-tools
//
//  Created by Igor Malyarov on 04.11.2025.
//

import Foundation

public extension DiskDataStore {

    func load(key: String) async throws -> Data {

        try await withCheckedThrowingContinuation { continuation in
            retrieve(key: key) { result in
                continuation.resume(with: result)
            }
        }
    }
}

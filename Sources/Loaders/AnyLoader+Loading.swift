//
//  AnyLoader+Loading.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

public extension AnyLoader {
    /// Creates an `AnyLoader` that wraps a `Loading` conforming type.
    init(_ loading: any Loading<Request, Response>) {
        self.init { try await loading.load($0) }
    }
}

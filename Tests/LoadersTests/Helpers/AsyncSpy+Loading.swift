//
//  AsyncSpy+Loading.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

import Loaders

extension AsyncSpy: Loading {
    func load(_ request: Payload) async throws -> Response {
        return try await call(payload: request)
    }
}

extension AsyncSpy {
    func load<S, E: Error>(_ request: Payload) async throws -> S where Response == Result<S, E> {
        return try await call(payload: request).get()
    }
}

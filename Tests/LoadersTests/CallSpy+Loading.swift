//
//  CallSpy+Loading.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

import Loaders

extension CallSpy: Loading {
    func load(_ request: Payload) async throws -> Response {
        let response = call(payload: request)
        try await Task.sleep(for: .milliseconds(100))
        return response
    }
}

extension CallSpy {
    func load<S, E: Error>(_ request: Payload) async throws -> S where Response == Result<S, E> {
        return try await load(request).get()
    }
}

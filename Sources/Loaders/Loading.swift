//
//  Loading.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

/// A protocol for types that can load a `Response` from a `Request`.
public protocol Loading<Request, Response> {
    associatedtype Request
    associatedtype Response

    func load(_ request: Request) async throws -> Response
}

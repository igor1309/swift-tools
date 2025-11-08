//
//  AnyLoader.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

/// A type-erased wrapper that forwards loading operations to any `Loader` closure.
public struct AnyLoader<Request, Response> {
    private let loader: Loader<Request, Response>

    /// Creates an `AnyLoader` that wraps the given loader closure.
    public init(_ loader: @escaping Loader<Request, Response>) {
        self.loader = loader
    }
}

extension AnyLoader: Loading {
    /// Loads a `Response` for the given `Request` by forwarding to the wrapped loader.
    public func load(_ request: Request) async throws -> Response {
        try await loader(request)
    }
}

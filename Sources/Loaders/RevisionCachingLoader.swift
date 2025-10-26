//
//  RevisionCachingLoader.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

import Foundation

// TODO: FIX DOCS ON DEV COMPLETION
/// A decorator that adds caching behavior to an underlying loader.
///
/// `RevisionCachingLoader` forwards load requests to an underlying loader and caches successful responses.
/// If the underlying loader fails, the cache is not invoked.
public struct RevisionCachingLoader<Request, Response> {
    private let loader: Loader
    private let cache: Cache

    /// Creates a caching loader with the given loader and cache.
    ///
    /// - Parameters:
    ///   - loader: The underlying loader to forward requests to.
    ///   - cache: The cache to store successful responses.
    public init(
        loader: @escaping Loader,
        cache: @escaping Cache
    ) {
        self.loader = loader
        self.cache = cache
    }

    public typealias Loader = Loaders.Loader<Request, Response>
    public typealias Cache = (Request, Response) -> Void
}

extension RevisionCachingLoader: Loading {
    /// Loads a response for the given request, caching successful results.
    ///
    /// Forwards the request to the underlying loader. On success, caches the response
    /// before returning it. On failure, propagates the error without caching.
    public func load(_ request: Request) async throws -> Response {
        let response = try await loader(request)
        cache(request, response)
        return response
    }
}

//
//  CachingLoader.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

import Foundation

/// A decorator that adds caching behavior to any loader abstraction.
///
/// `CachingLoader` forwards load requests to an underlying `Loading` conformer and caches
/// successful responses. If the underlying loader fails, the cache is not invoked. A convenience
/// initializer accepts plain loader closures and automatically wraps them into `AnyLoader`.
public struct CachingLoader<Request, Response> {
    private let loading: any Loading
    private let cache: Cache

    /// Creates a caching loader backed by any `Loading` conformer.
    ///
    /// - Parameters:
    ///   - loading: The underlying loader abstraction to forward requests to.
    ///   - cache: The async cache that stores successful responses.
    public init(
        loading: any Loading,
        cache: @escaping Cache
    ) {
        self.loading = loading
        self.cache = cache
    }

    public typealias Loading = Loaders.Loading<Request, Response>
    public typealias Cache = (Request, Response) async -> Void
}

extension CachingLoader {
    
    /// Creates a caching loader backed by a loader closure.
    ///
    /// - Parameters:
    ///   - loader: The closure that produces responses for incoming requests.
    ///   - cache: The async cache that stores successful responses.
    public init(
        loader: @escaping Loader,
        cache: @escaping Cache
    ) {
        self.init(loading: AnyLoader(loader), cache: cache)
    }

    public typealias Loader = Loaders.Loader<Request, Response>
}

extension CachingLoader: Loading {
    /// Loads a response for the given request, caching successful results.
    ///
    /// Forwards the request to the underlying loader. On success, caches the response
    /// before returning it. On failure, propagates the error without caching.
    public func load(_ request: Request) async throws -> Response {
        let response = try await loading.load(request)
        await cache(request, response)
        return response
    }
}

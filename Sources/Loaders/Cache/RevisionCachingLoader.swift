//
//  RevisionCachingLoader.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

import Foundation

/// A decorator that adds revision-aware caching behavior to any loader abstraction.
///
/// `RevisionCachingLoader` forwards load requests to an underlying `Loading` conformer and
/// conditionally caches successful responses based on revision comparison. The `shouldCache`
/// closure decides whether a response should be cached, enabling strategies like ETags or
/// version-based caching. If the underlying loader fails, neither `shouldCache` nor `cache`
/// are invoked. A convenience initializer accepts plain loader closures and wraps them into `AnyLoader`.
public struct RevisionCachingLoader<Request, Response: RevisionProviding> {
    private let loading: any Loading
    private let cache: Cache
    private let shouldCache: ShouldCache
    
    /// Creates a caching loader backed by any `Loading` conformer.
    ///
    /// - Parameters:
    ///   - loading: The underlying loader abstraction to forward requests to.
    ///   - cache: The async cache that stores successful responses.
    ///   - shouldCache: Decides whether to cache based on the request and response revision.
    public init(
        loading: any Loading,
        cache: @escaping Cache,
        shouldCache: @escaping ShouldCache
    ) {
        self.loading = loading
        self.cache = cache
        self.shouldCache = shouldCache
    }
    
    public typealias Loading = Loaders.Loading<Request, Response>
    public typealias Cache = (Request, Response) async -> Void
    public typealias ShouldCache = (Request, Response.Revision) -> Bool
}

extension RevisionCachingLoader {
    /// Creates a caching loader backed by a loader closure.
    ///
    /// - Parameters:
    ///   - loader: The closure that produces responses for incoming requests.
    ///   - cache: The async cache that stores successful responses.
    ///   - shouldCache: Decides whether to cache based on the request and response revision.
    public init(
        loader: @escaping Loader,
        cache: @escaping Cache,
        shouldCache: @escaping ShouldCache
    ) {
        self.init(loading: AnyLoader(loader), cache: cache, shouldCache: shouldCache)
    }
    
    public typealias Loader = Loaders.Loader<Request, Response>
}

extension RevisionCachingLoader: Loading {
    /// Loads a response for the given request, conditionally caching successful results.
    ///
    /// Forwards the request to the underlying loader. On success, consults `shouldCache` with
    /// the request and response revision. If `shouldCache` returns `true`, caches the response
    /// before returning it. On failure, propagates the error without consulting `shouldCache` or caching.
    public func load(_ request: Request) async throws -> Response {
        let response = try await loading.load(request)
        if shouldCache(request, response.revision) {
            await cache(request, response)
        }
        return response
    }
}

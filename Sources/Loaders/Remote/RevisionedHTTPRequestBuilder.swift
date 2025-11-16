//
//  PromptsHTTPRequestBuilder.swift
//  swift-tools
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Foundation

public struct RevisionedHTTPRequestBuilder {
    
    private let endpoint: URL
    private let method: String
    private let cachePolicy: URLRequest.CachePolicy
    private let timeoutInterval: TimeInterval
    private let headersProvider: HeadersProvider
    
    public init(
        endpoint: URL,
        method: String = "GET",
        cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData,
        timeoutInterval: TimeInterval = 60,
        headersProvider: @escaping HeadersProvider = { [:] }
    ) {
        self.endpoint = endpoint
        self.method = method
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
        self.headersProvider = headersProvider
    }

    public typealias HeadersProvider = () -> [String: String]
}

extension RevisionedHTTPRequestBuilder: RevisionedHTTPRequestBuilding {
    public func makeRequest(revision: Revision?) throws -> URLRequest {
        var request = URLRequest(url: endpoint, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        request.httpMethod = method
        headersProvider().forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if let revision {
            request.setValue(revision, forHTTPHeaderField: "If-None-Match")
        }
        return request
    }
}

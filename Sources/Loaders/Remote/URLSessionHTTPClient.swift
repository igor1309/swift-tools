//
//  URLSessionHTTPClient.swift
//  swift-tools
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Foundation

public final class URLSessionHTTPClient {
    private let session: URLSession
    
    public init(session: URLSession) {
        self.session = session
    }
}

extension URLSessionHTTPClient: Loading {
    public func load(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await get(with: request)
    }
}

public extension URLSessionHTTPClient {
    func get(with request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.invalidResponse
        }
        return (data, httpResponse)
    }
    
    enum Error: Swift.Error, Equatable {
        case invalidResponse
    }
}

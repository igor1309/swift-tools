//
//  HTTPRemoteLoader.swift
//  WriterAssistant
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Foundation

public final class HTTPRemoteLoader<T> {
    private let httpClient: any HTTPClient
    private let process: Process
    
    public init(
        httpClient: any HTTPClient,
        process: @escaping Process
    ) {
        self.httpClient = httpClient
        self.process = process
    }
    
    public typealias Process = ((Data, HTTPURLResponse)) throws -> T
}

extension HTTPRemoteLoader: Loading {
    public func load(_ request: URLRequest) async throws -> T {
        let response = try await httpClient.get(with: request)
        return try process(response)
    }
}

//
//  RevisionedHTTPRequestAdapter.swift
//  swift-tools
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Foundation

public typealias Revision = String

public protocol RevisionedHTTPRequestBuilding {
    func makeRequest(revision: Revision?) throws -> URLRequest
}

public final class RevisionedHTTPRequestAdapter<Output> {
    private let requestBuilder: any RevisionedHTTPRequestBuilding
    private let httpLoader: any Loading<URLRequest, Output>
    
    public init(
        requestBuilder: any RevisionedHTTPRequestBuilding,
        httpLoader: any Loading<URLRequest, Output>
    ) {
        self.requestBuilder = requestBuilder
        self.httpLoader = httpLoader
    }
}

extension RevisionedHTTPRequestAdapter: Loading {
    public func load(_ revision: Revision?) async throws -> Output {
        let request = try requestBuilder.makeRequest(revision: revision)
        return try await httpLoader.load(request)
    }
}

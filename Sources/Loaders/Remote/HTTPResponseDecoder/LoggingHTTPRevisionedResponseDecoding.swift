//
//  LoggingHTTPRevisionedResponseDecoding.swift
//  swift-tools
//
//  Created by Igor Malyarov on 16.11.2025.
//

import Foundation

/// Logs failures that occur while decoding revision-aware HTTP responses.
public final class LoggingHTTPRevisionedResponseDecoding {
    private let decoratee: any HTTPRevisionedResponseDecoding
    private let log: Log

    public init(
        decoratee: any HTTPRevisionedResponseDecoding,
        log: @escaping Log
    ) {
        self.decoratee = decoratee
        self.log = log
    }

    public typealias Log = (String) -> Void
}

extension LoggingHTTPRevisionedResponseDecoding: HTTPRevisionedResponseDecoding {
    public func processRevisioned<T>(_ data: Data, _ response: HTTPURLResponse) throws -> DecodedResponse<T> where T: Decodable {
        do {
            return try decoratee.processRevisioned(data, response)
        } catch {
            log("HTTP revisioned response decoding failed: \(error)")
            throw error
        }
    }
}

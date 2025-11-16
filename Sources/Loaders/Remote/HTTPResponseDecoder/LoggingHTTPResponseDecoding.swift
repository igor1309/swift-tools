//
//  LoggingHTTPResponseDecoding.swift
//  swift-tools
//
//  Created by Igor Malyarov on 16.11.2025.
//

import Foundation

/// Logs failures that occur while decoding plain HTTP responses.
public final class LoggingHTTPResponseDecoding {
    private let decoratee: any HTTPResponseDecoding
    private let log: Log

    public init(
        decoratee: any HTTPResponseDecoding,
        log: @escaping Log
    ) {
        self.decoratee = decoratee
        self.log = log
    }

    public typealias Log = (String) -> Void
}

extension LoggingHTTPResponseDecoding: HTTPResponseDecoding {
    public func process<T>(_ data: Data, _ response: HTTPURLResponse) throws -> T where T: Decodable {
        do {
            return try decoratee.process(data, response)
        } catch {
            log("HTTP response decoding failed: \(error)")
            throw error
        }
    }
}

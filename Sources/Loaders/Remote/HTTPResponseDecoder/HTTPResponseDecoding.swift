//
//  HTTPResponseDecoding.swift
//  swift-tools
//
//  Created by Igor Malyarov on 16.11.2025.
//

import Foundation

/// Decodes plain HTTP responses that do not participate in revision tracking.
public protocol HTTPResponseDecoding {
    /// Decodes HTTP response data into a typed value, throwing when the HTTP status code indicates an error. Does not support 304 (not modified) responses.
    func process<T: Decodable>(_ data: Data, _ response: HTTPURLResponse) throws -> T
}

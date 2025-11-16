//
//  HTTPRevisionedResponseDecoding.swift
//  swift-tools
//
//  Created by Igor Malyarov on 16.11.2025.
//

import Foundation

/// Decodes HTTP responses that carry revision metadata (for example ETag or Last-Modified headers) into typed payloads.
public protocol HTTPRevisionedResponseDecoding {
    /// Transforms raw response data plus revision metadata into a typed `DecodedResponse`, throwing when the HTTP status code indicates an error or a revision header is missing.
    func processRevisioned<T: Decodable>(_ data: Data, _ response: HTTPURLResponse) throws -> DecodedResponse<T>
}

//
//  DecodedResponse.swift
//  Modules
//
//  Created by Igor Malyarov on 09.11.2025.
//

/// Represents the outcome of decoding an HTTP response, either surfacing fresh content or signaling cached data is still valid.
public enum DecodedResponse<Value> {
    /// Indicates that the server reported no content changes since the last known revision.
    case notModified
    /// Carries the decoded payload along with revision metadata for downstream caching.
    case response(RevisionedResponse<Value>)
}

extension DecodedResponse: Equatable where Value: Equatable {}

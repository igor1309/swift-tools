//
//  RevisionedResponse.swift
//  Modules
//
//  Created by Igor Malyarov on 09.11.2025.
//

/// Wraps a decoded value together with its optional `ETag` so clients can reason about revisions.
public struct RevisionedResponse<Value> {
    public let etag: String?
    public let value: Value
    
    /// Creates a revision-aware response by pairing the server-provided `ETag` with the decoded value.
    public init(etag: String?, value: Value) {
        self.etag = etag
        self.value = value
    }
}

extension RevisionedResponse: Equatable where Value: Equatable {}

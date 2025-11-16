//
//  HTTPResponseDecoder.swift
//  Modules
//
//  Created by Igor Malyarov on 09.11.2025.
//

import Foundation

/// Decodes HTTP responses into typed payloads while translating HTTP status codes into domain errors.
public final class HTTPResponseDecoder {
    private let decoder: JSONDecoder
    
    public init(decoder: JSONDecoder = .init()) {
        self.decoder = decoder
    }
}

public extension HTTPResponseDecoder {
    enum Error: Swift.Error {
        /// Server returned a 4xx status code other than 401, 403, or 404.
        case clientError
        /// Server returned 403 Forbidden.
        case forbidden
        /// Response body could not be decoded as the expected type.
        case invalidData
        /// Server returned 404 Not Found.
        case notFound
        /// Server returned a 5xx status code.
        case serverError
        /// Server returned 401 Unauthorized.
        case unauthorized
        /// Server returned a status code not explicitly handled by this decoder.
        case unexpectedStatusCode
    }
}

extension HTTPResponseDecoder: HTTPRevisionedResponseDecoding {
    /// Transforms raw response data and metadata into a typed `DecodedResponse`, throwing when the HTTP status code indicates an error.
    public func processRevisioned<T: Decodable>(_ data: Data, _ response: HTTPURLResponse) throws -> DecodedResponse<T> {
        switch response.statusCode {
        case .notFoundStatusCode:
            throw Error.notFound
        case .unauthorizedStatusCode:
            throw Error.unauthorized
        case .forbiddenStatusCode:
            throw Error.forbidden
        case ClosedRange<Int>.clientErrorStatusCodeRange:
            throw Error.clientError
        case ClosedRange<Int>.serverErrorStatusCodeRange:
            throw Error.serverError
        case .notModifiedStatusCode:
            return .notModified
        case .okStatusCode:
            return try .response(mapOkResponse(data, response))
        default:
            throw Error.unexpectedStatusCode
        }
    }
}

extension HTTPResponseDecoder: HTTPResponseDecoding {
    /// Decodes HTTP response data into a typed value, throwing when the HTTP status code indicates an error. Does not support 304 (not modified) responses.
    public func process<T: Decodable>(_ data: Data, _ response: HTTPURLResponse) throws -> T {
        switch response.statusCode {
        case .notFoundStatusCode:
            throw Error.notFound
        case .unauthorizedStatusCode:
            throw Error.unauthorized
        case .forbiddenStatusCode:
            throw Error.forbidden
        case ClosedRange<Int>.clientErrorStatusCodeRange:
            throw Error.clientError
        case ClosedRange<Int>.serverErrorStatusCodeRange:
            throw Error.serverError
        case .okStatusCode:
            return try mapOkResponse(data, response).value
        default:
            throw Error.unexpectedStatusCode
        }
    }
}

// MARK: - Helpers

private extension HTTPResponseDecoder {
    /// Maps a successful HTTP response body into a typed value and captures the associated `ETag` for revision tracking.
    func mapOkResponse<T: Decodable>(_ data: Data, _ response: HTTPURLResponse) throws -> RevisionedResponse<T> {
        let etag = response.value(forHTTPHeaderField: "ETag")
        do {
            let value = try decoder.decode(T.self, from: data)
            return .init(etag: etag, value: value)
        } catch {
            throw Error.invalidData
        }
    }
}

private extension ClosedRange<Int> {
    
    static var clientErrorStatusCodeRange: Self { 400...499 }
    static var serverErrorStatusCodeRange: Self { 500...599 }
}

private extension Int {
    static let okStatusCode = 200
    static let notModifiedStatusCode = 304
    static let notFoundStatusCode = 404
    static let unauthorizedStatusCode = 401
    static let forbiddenStatusCode = 403
}

//
//  ResponseDecoder.swift
//  swift-tools
//
//  Created by Igor Malyarov on 10.11.2025.
//

import Foundation
import Loaders
import Testing

class ResponseDecoderTests: TestContext {
    
    typealias SUT = HTTPResponseDecoder
    
    func makeSUT(
        decoder: JSONDecoder = .init(),
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> SUT {
        let sut = SUT(decoder: decoder)
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        return sut
    }
    
    struct Value: Codable, Equatable {
        let value: String
    }
    
    func makeValue(_ value: String = anyMessage()) -> Value {
        .init(value: value)
    }
    
    func makeValueData(_ value: Value) -> Data {
        let encoder = JSONEncoder()
        return try! encoder.encode(value)
    }
    
    func makeHTTPURLResponse(statusCode: Int, headers: [String: String]? = nil) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headers
        )!
    }
    
    static var etagValues: [String?] {
        [nil, anyMessage()]
    }
    
    static var clientErrorStatusCodes: [Int] {
        [400, 422, 429, 499]
    }
    
    static var serverErrorStatusCodes: [Int] {
        [500, 501, 502, 503, 504, 599]
    }
    
    static var unexpectedStatusCodes: [Int] {
        [100, 101, 201, 202, 204, 300, 301, 302, 303, 307, 308]
    }
    
    let okStatusCode = 200
    let notModifiedStatusCode = 304
    let unauthorizedStatusCode = 401
    let forbiddenStatusCode = 403
    let notFoundStatusCode = 404
}

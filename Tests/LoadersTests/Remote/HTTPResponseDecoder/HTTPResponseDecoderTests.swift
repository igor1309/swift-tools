//
//  HTTPResponseDecoderTests.swift
//  Modules
//
//  Created by Igor Malyarov on 25.10.2025.
//

import Foundation
import Loaders
import Testing

final class HTTPResponseDecoderTests: ResponseDecoderTests {

    @Test(arguments: etagValues)
    func test_process_returnsDecodedResponse_on200WithValidJSON(etag: String?) throws {
        let expectedValue = makeValue()
        let payload = makeValueData(expectedValue)
        
        try expectProcessToResponse(value: expectedValue, etag: etag, data: payload)
    }

    @Test
    func test_process_throwsUnexpectedStatus_on304() throws {
        expectProcessToThrow(.unexpectedStatusCode, statusCode: notModifiedStatusCode)
    }

    @Test(arguments: clientErrorStatusCodes)
    func test_process_throwsClientError_onOther4xx(statusCode: Int) {
        expectProcessToThrow(.clientError, statusCode: statusCode)
    }

    @Test
    func test_process_throwsNotFound_on404() {
        expectProcessToThrow(.notFound, statusCode: notFoundStatusCode)
    }

    @Test
    func test_process_throwsUnauthorized_on401() {
        expectProcessToThrow(.unauthorized, statusCode: unauthorizedStatusCode)
    }

    @Test
    func test_process_throwsForbidden_on403() {
        expectProcessToThrow(.forbidden, statusCode: forbiddenStatusCode)
    }

    @Test(arguments: serverErrorStatusCodes)
    func test_process_throwsServerError_on5xx(statusCode: Int) {
        expectProcessToThrow(.serverError, statusCode: statusCode)
    }

    @Test(arguments: unexpectedStatusCodes)
    func test_process_throwsUnexpectedStatus_onUnhandledStatusCode(statusCode: Int) {
        expectProcessToThrow(.unexpectedStatusCode, statusCode: statusCode)
    }

    @Test
    func test_process_throwsInvalidData_on200WithInvalidJSON() {
        expectProcessToThrow(.invalidData, data: .invalidJSON, statusCode: okStatusCode)
    }

    // MARK: - Helpers
    
    private typealias Response = Value

    private func process(
        data: Data,
        response: HTTPURLResponse
    ) throws -> Response {
        try makeSUT().process(data, response)
    }

    private func expectProcessToResponse(
        value expectedValue: Value,
        etag: String?,
        data: Data,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let httpResponse = makeHTTPURLResponse(
            statusCode: okStatusCode,
            headers: etag.map { ["ETag": $0] }
        )
        let response = try process(data: data, response: httpResponse)

        #expect(response == expectedValue, sourceLocation: sourceLocation)
    }

    private func expectProcessToResponse(
        _ expectedResponse: Response,
        data: Data,
        statusCode: Int,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        let httpResponse = makeHTTPURLResponse(statusCode: statusCode)
        let response = try process(data: data, response: httpResponse)
        #expect(response == expectedResponse, sourceLocation: sourceLocation)
    }

    private func expectProcessToThrow(
        _ error: SUT.Error,
        data: Data = .emptyData,
        statusCode: Int,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let httpResponse = makeHTTPURLResponse(statusCode: statusCode)
        #expect(throws: error, sourceLocation: sourceLocation) {
            _ = try self.process(data: data, response: httpResponse)
        }
    }
}

private extension Data {
    static let emptyData: Self = .init()
    static let invalidJSON: Self = .init("invalid json".utf8)
}

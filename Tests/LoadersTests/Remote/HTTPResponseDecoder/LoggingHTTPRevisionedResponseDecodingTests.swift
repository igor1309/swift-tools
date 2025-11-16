//
//  LoggingHTTPRevisionedResponseDecodingTests.swift
//  swift-toolsTests
//
//  Created by Igor Malyarov on 16.11.2025.
//

import Loaders
import Foundation
import Loaders
import Testing

final class LoggingHTTPRevisionedResponseDecodingTests: TestContext {

    @Test func test_init_shouldNotCallCollaborators() {
        let (_, decorateeSpy, loggerSpy) = makeSUT()

        #expect(decorateeSpy.payloads.isEmpty)
        #expect(loggerSpy.callCount == 0)
    }

    @Test func test_processRevisioned_shouldCallDecoratee() throws {
        let (sut, decorateeSpy, _) = makeSUT()

        let _: DecodedResponse<Sample> = try sut.processRevisioned(makeData(), makeResponse())

        #expect(decorateeSpy.payloads.count == 1)
    }

    @Test func test_processRevisioned_shouldReturnDecorateeResult() throws {
        let expectedResponse = makeDecodedResponse()
        let (sut, _, _) = makeSUT(stubs: [.success(expectedResponse)])

        let response: DecodedResponse<Sample> = try sut.processRevisioned(makeData(), makeResponse())

        #expect(response == expectedResponse)
    }

    @Test func test_processRevisioned_shouldPropagateDecorateeError() {
        let expectedError = anyNSError()
        let (sut, _, _) = makeSUT(stubs: [.failure(expectedError)])

        #expect(throws: expectedError) {
            let _: DecodedResponse<Sample> = try sut.processRevisioned(self.makeData(), self.makeResponse())
        }
    }

    @Test func test_processRevisioned_shouldLogDecorateeError() {
        let expectedError = anyNSError()
        let (sut, _, loggerSpy) = makeSUT(stubs: [.failure(expectedError)])

        let _: DecodedResponse<Sample>? = try? sut.processRevisioned(makeData(), makeResponse())

        #expect(loggerSpy.payloads == ["HTTP revisioned response decoding failed: \(expectedError)"])
    }

    @Test func test_processRevisioned_shouldNotLog_whenDecorateeSucceeds() throws {
        let (sut, _, loggerSpy) = makeSUT()

        let _: DecodedResponse<Sample> = try sut.processRevisioned(makeData(), makeResponse())

        #expect(loggerSpy.callCount == 0)
    }

    // MARK: - Helpers

    private typealias SUT = LoggingHTTPRevisionedResponseDecoding
    private typealias DecorateeSpy = RevisionedDecodingSpy
    private typealias LoggerSpy = CallSpy<String, Void>

    private func makeSUT(
        stubs: [DecorateeSpy.Stub]? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (
        sut: SUT,
        decorateeSpy: DecorateeSpy,
        loggerSpy: LoggerSpy
    ) {
        let decorateeSpy = DecorateeSpy(stubs: stubs ?? [.success(makeDecodedResponse())])
        let loggerSpy = LoggerSpy(stubs: .init(repeating: (), count: 2))
        let sut = SUT(decoratee: decorateeSpy, log: loggerSpy.call)

        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        trackForMemoryLeaks(decorateeSpy, sourceLocation: sourceLocation)
        trackForMemoryLeaks(loggerSpy, sourceLocation: sourceLocation)

        return (sut, decorateeSpy, loggerSpy)
    }

    private func makeDecodedResponse() -> DecodedResponse<Sample> {
        .response(.init(etag: "etag", value: Sample(value: 42)))
    }

    private func makeData() -> Data {
        Data("{}".utf8)
    }

    private func makeResponse(statusCode: Int = 200) -> HTTPURLResponse {
        guard let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        ) else {
            preconditionFailure("Unable to build HTTPURLResponse")
        }
        return response
    }
}

private struct Sample: Codable, Equatable {
    let value: Int
}

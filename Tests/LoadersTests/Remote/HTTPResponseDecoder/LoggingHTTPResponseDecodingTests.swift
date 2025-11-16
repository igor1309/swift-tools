//
//  LoggingHTTPResponseDecodingTests.swift
//  swift-toolsTests
//
//  Created by Igor Malyarov on 16.11.2025.
//

import Loaders
import Foundation
import Testing

final class LoggingHTTPResponseDecodingTests: TestContext {

    @Test func test_init_shouldNotCallCollaborators() {
        let (_, decorateeSpy, loggerSpy) = makeSUT()

        #expect(decorateeSpy.payloads.isEmpty)
        #expect(loggerSpy.callCount == 0)
    }

    @Test func test_process_shouldCallDecoratee() throws {
        let (sut, decorateeSpy, _) = makeSUT()

        let _: Sample = try sut.process(makeData(), makeResponse())

        #expect(decorateeSpy.payloads.count == 1)
    }

    @Test func test_process_shouldReturnDecorateeResult() throws {
        let expectedValue = Sample(value: "value")
        let (sut, _, _) = makeSUT(stubs: [.success(expectedValue)])

        let output: Sample = try sut.process(makeData(), makeResponse())

        #expect(output == expectedValue)
    }

    @Test func test_process_shouldPropagateDecorateeError() {
        let expectedError = anyNSError()
        let (sut, _, _) = makeSUT(stubs: [.failure(expectedError)])

        #expect(throws: expectedError) {
            let _: Sample = try sut.process(self.makeData(), self.makeResponse())
        }
    }

    @Test func test_process_shouldLogDecorateeError() {
        let expectedError = anyNSError()
        let (sut, _, loggerSpy) = makeSUT(stubs: [.failure(expectedError)])

        _ = try? sut.process(makeData(), makeResponse()) as Sample

        #expect(loggerSpy.payloads == ["HTTP response decoding failed: \(expectedError)"])
    }

    @Test func test_process_shouldNotLog_whenDecorateeSucceeds() throws {
        let (sut, _, loggerSpy) = makeSUT()

        _ = try sut.process(makeData(), makeResponse()) as Sample

        #expect(loggerSpy.callCount == 0)
    }

    // MARK: - Helpers

    private typealias SUT = LoggingHTTPResponseDecoding
    private typealias DecorateeSpy = HTTPResponseDecodingSpy
    private typealias LoggerSpy = CallSpy<String, Void>

    private func makeSUT(
        stubs: [DecorateeSpy.Stub]? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (
        sut: SUT,
        decorateeSpy: DecorateeSpy,
        loggerSpy: LoggerSpy
    ) {
        let decorateeSpy = DecorateeSpy(stubs: stubs ?? [.success(Sample(value: "stub"))])
        let loggerSpy = LoggerSpy(stubs: .init(repeating: (), count: 2))
        let sut = SUT(decoratee: decorateeSpy, log: loggerSpy.call)

        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        trackForMemoryLeaks(decorateeSpy, sourceLocation: sourceLocation)
        trackForMemoryLeaks(loggerSpy, sourceLocation: sourceLocation)

        return (sut, decorateeSpy, loggerSpy)
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
    let value: String
}

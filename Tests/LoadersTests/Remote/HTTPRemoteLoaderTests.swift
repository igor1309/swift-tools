//
//  HTTPRemoteLoaderTests.swift
//  swift-toolsTests
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Loaders
import Foundation
import Testing

final class HTTPRemoteLoaderTests: TestContext {
    
    @Test func test_init_shouldNotCallCollaborators_onInitialization() async throws {
        let (_, httpClientSpy, processSpy) = makeSUT()
        #expect(httpClientSpy.callCount == 0)
        #expect(processSpy.callCount == 0)
    }
    
    @Test func test_load_shouldForwardRequest_onLoadCall() async throws {
        let request = makeRequest()
        let payload = makeHTTPPayload()
        let (sut, httpClientSpy, _) = makeSUT(httpClientStub: [.success(payload)])
        _ = try await load(sut, request: request)
        #expect(httpClientSpy.payloads == [request])
    }
    
    @Test func test_load_shouldPropagateClientError_onClientFailure() async throws {
        let request = makeRequest()
        let expectedError = anyNSError()
        let (sut, _, _) = makeSUT(httpClientStub: [.failure(expectedError)])
        await #expect(throws: expectedError) { try await self.load(sut, request: request) }
    }
    
    @Test func test_load_shouldNotInvokeProcess_onClientFailure() async throws {
        let request = makeRequest()
        let expectedError = anyNSError()
        let (sut, _, processSpy) = makeSUT(httpClientStub: [.failure(expectedError)])
        _ = await #expect(throws: expectedError) { try await self.load(sut, request: request) }
        #expect(processSpy.callCount == 0)
    }
    
    @Test func test_load_shouldDeliverProcessedValue_onSuccessfulResponse() async throws {
        let request = makeRequest()
        let expectedResponse = makeResponse()
        let (sut, _, _) = makeSUT(processStub: [.success(expectedResponse)])
        let response = try await load(sut, request: request)
        #expect(response == expectedResponse)
    }
    
    @Test func test_load_shouldPropagateProcessError_onProcessingFailure() async throws {
        let request = makeRequest()
        let expectedError = anyNSError()
        let (sut, _, _) = makeSUT(processStub: [.failure(expectedError)])
        await #expect(throws: expectedError) { try await self.load(sut, request: request) }
    }
    
    @Test func test_load_shouldForwardResponseTupleToProcess_onSuccessfulResponse() async throws {
        let request = makeRequest()
        let payload = makeHTTPPayload()
        let (sut, _, processSpy) = makeSUT(httpClientStub: [.success(payload)])
        _ = try await load(sut, request: request)
        #expect(processSpy.payloads.map(\.0) == [payload.0])
        #expect(processSpy.payloads.map(\.1.url) == [payload.1.url])
        #expect(processSpy.payloads.map(\.1.statusCode) == [payload.1.statusCode])
    }
    
    // MARK: - Helpers
    
    private typealias SUT = HTTPRemoteLoader<Response>
    private typealias HTTPClientSpy = AsyncSpyOf<URLRequest, (Data, HTTPURLResponse)>
    private typealias ProcessResult = Result<Response, Error>
    private typealias ProcessSpy = CallSpy<(Data, HTTPURLResponse), ProcessResult>
    
    private func makeSUT(
        httpClientStub: [HTTPClientSpy.Stub]? = nil,
        processStub: [ProcessResult]? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (
        sut: SUT,
        httpClientSpy: HTTPClientSpy,
        processSpy: ProcessSpy
    ) {
        let httpClientSpy = HTTPClientSpy(stubs: httpClientStub ?? [.success(makeHTTPPayload())])
        let processSpy = ProcessSpy(stubs: processStub ?? [.success(makeResponse())])
        let sut = SUT(httpClient: httpClientSpy) { payload in
            try processSpy.call(payload: payload).get()
        }
        
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        trackForMemoryLeaks(httpClientSpy, sourceLocation: sourceLocation)
        trackForMemoryLeaks(processSpy, sourceLocation: sourceLocation)
        
        return (sut, httpClientSpy, processSpy)
    }
    
    private struct Response: Equatable {
        let value: String
    }
    
    private func makeResponse(
        _ value: String = anyMessage()
    ) -> Response {
        return .init(value: value)
    }
    
    @discardableResult
    private func load(
        _ sut: SUT,
        request: URLRequest? = nil
    ) async throws -> Response {
        try await sut.load(request ?? makeRequest())
    }
    
    private func makeRequest(
        url: URL? = nil
    ) -> URLRequest {
        return .init(url: url ?? makeURL())
    }
    
    private func makeHTTPPayload(
        data: Data? = nil,
        response: HTTPURLResponse? = nil
    ) -> (Data, HTTPURLResponse) {
        return (data ?? makeData(), response ?? makeHTTPURLResponse())
    }
    
    private func makeData() -> Data {
        return .init(anyMessage().utf8)
    }
    
    private func makeHTTPURLResponse(
        statusCode: Int = 200,
        url: URL? = nil
    ) -> HTTPURLResponse {
        return .init(url: url ?? makeURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
    
    private func makeURL() -> URL {
        return .init(string: "https://example.com/\(UUID().uuidString)")!
    }
}

//
//  URLSessionHTTPClientTests.swift
//  swift-tools
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Foundation
import Loaders
import Testing

@MainActor
final class URLSessionHTTPClientTests: TestContext {
    
    @Test func test_get_shouldPerformRequestWithProvidedRequest() async throws {
        let token = UUID().uuidString
        let requestURL = anyURL()
        let request = taggedRequest(url: requestURL, token: token)
        let payload = makeHTTPPayload(response: makeHTTPURLResponse(url: requestURL))
        let sut = makeSUT()
        
        URLProtocolStub.stub(data: payload.data, response: payload.response, error: nil, token: token)
        async let observedRequest = observeRequest(token: token)
        
        _ = try await sut.get(with: request)
        
        let capturedRequest = await observedRequest
        #expect(capturedRequest.url == request.url)
        #expect(capturedRequest.httpMethod == request.httpMethod)
        #expect(capturedRequest.allHTTPHeaderFields == request.allHTTPHeaderFields)
    }
    
    @Test func test_get_shouldPropagateTransportError() async {
        let token = UUID().uuidString
        let expectedError = anyNSError()
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError, token: token)
        let sut = makeSUT()
        let request = taggedRequest(token: token)
        
        do {
            _ = try await sut.get(with: request)
            #expect(Bool(false), "Expected request to throw")
        } catch {
            let nsError = error as NSError
            #expect(nsError.domain == expectedError.domain)
            #expect(nsError.code == expectedError.code)
        }
    }
    
    @Test func test_get_shouldFailWithInvalidResponseError_onNonHTTPResponse() async {
        let token = UUID().uuidString
        let response = nonHTTPURLResponse()
        URLProtocolStub.stub(data: makeData(), response: response, error: nil, token: token)
        let sut = makeSUT()
        
        await #expect(throws: URLSessionHTTPClient.Error.invalidResponse) {
            _ = try await sut.get(with: self.taggedRequest(token: token))
        }
    }
    
    @Test func test_get_shouldDeliverDataAndResponse_onHTTPURLResponse() async throws {
        let token = UUID().uuidString
        let requestURL = anyURL()
        let expectedPayload = makeHTTPPayload(response: makeHTTPURLResponse(url: requestURL))
        URLProtocolStub.stub(data: expectedPayload.data, response: expectedPayload.response, error: nil, token: token)
        let sut = makeSUT()
        
        let (data, response) = try await sut.get(with: taggedRequest(url: requestURL, token: token))
        
        #expect(data == expectedPayload.data)
        #expect(response.url == expectedPayload.response.url)
        #expect(response.statusCode == expectedPayload.response.statusCode)
    }
    
    @Test func test_get_shouldDeliverEmptyData_onHTTPURLResponseWithoutBody() async throws {
        let token = UUID().uuidString
        let requestURL = anyURL()
        let response = makeHTTPURLResponse(url: requestURL)
        URLProtocolStub.stub(data: nil, response: response, error: nil, token: token)
        let sut = makeSUT()
        
        let (data, httpResponse) = try await sut.get(with: taggedRequest(url: requestURL, token: token))
        
        #expect(data.isEmpty)
        #expect(httpResponse.url == response.url)
        #expect(httpResponse.statusCode == response.statusCode)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        addTeardownBlock {
            URLProtocolStub.removeStub()
            session.invalidateAndCancel()
        }
        
        return sut
    }
    
    private func observeRequest(token: String) async -> URLRequest {
        await withCheckedContinuation { continuation in
            URLProtocolStub.observeRequests(token: token) { request in
                URLProtocolStub.removeRequestObserver(token: token)
                continuation.resume(returning: request)
            }
        }
    }
    
    private func taggedRequest(
        url: URL? = nil,
        httpMethod: String = "GET",
        token: String
    ) -> URLRequest {
        var request = URLRequest(url: url ?? anyURL())
        request.httpMethod = httpMethod
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        return URLProtocolStub.tagging(request, token: token)
    }
    
    private func makeHTTPPayload(
        data: Data? = nil,
        response: HTTPURLResponse? = nil
    ) -> (data: Data, response: HTTPURLResponse) {
        return (data ?? anyData(), response ?? makeHTTPURLResponse())
    }
    
    private func makeData() -> Data {
        Data(anyMessage().utf8)
    }
    
    private func makeHTTPURLResponse(
        statusCode: Int = 200,
        url: URL? = nil
    ) -> HTTPURLResponse {
        return .init(url: url ?? anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponse(
        url: URL? = nil
    ) -> URLResponse {
        return .init(url: url ?? anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
}

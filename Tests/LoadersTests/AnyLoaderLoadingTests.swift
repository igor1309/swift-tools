//
//  AnyLoaderLoadingTests.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

import Loaders
import Testing

// MARK: - Tests

@Suite final class AnyLoaderLoadingTests: AnyLoaderCommonTests {

    @Test func test_init_shouldNotCallLoader() {
        #expect(makeSUT().spy.callCount == 0)
    }
    
    @Test func test_load_shouldForwardRequest() async throws {
        let request = makeRequest()
        let (sut, spy) = makeSUT()
        
        _ = try? await load(sut, request)
        
        #expect(spy.payloads == [request])
    }
    
    @Test func test_load_shouldPropagateError_whenLoaderThrows() async throws {
        let request = makeRequest()
        let error = makeFailure()
        let sut = SUT { _ in throw error }
        
        await #expect(throws: Failure.self) {
            _ = try await self.load(sut, request)
        }
    }
    
    @Test func test_load_shouldReturnResponse_whenLoaderSucceeds() async throws {
        let request = makeRequest()
        let expectedResponse = makeResponse()
        let (sut, _) = makeSUT(stubs: [.success(expectedResponse)])
        
        let receivedResponse = try await load(sut, request)
        
        #expect(receivedResponse == expectedResponse)
    }
    
    @Test func test_load_shouldHandleDistinctSequentialRequests() async throws {
        let firstRequest = makeRequest("first-request")
        let secondRequest = makeRequest("second-request")
        let expectedResponses = [
            makeResponse("first-response"),
            makeResponse("second-response")
        ]
        let (sut, spy) = makeSUT(stubs: expectedResponses.map(Result<Response, Error>.success))

        let firstResponse = try await load(sut, firstRequest)
        let secondResponse = try await load(sut, secondRequest)
        
        #expect(spy.payloads == [firstRequest, secondRequest])
        #expect([firstResponse, secondResponse] == expectedResponses)
    }

    // MARK: - Helpers

    private func makeSUT(
        stubs: [Result<Response, Error>]? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (
        sut: SUT,
        spy: LoaderSpy
    ) {
        let spy = LoaderSpy(stubs: stubs ?? [.success(makeResponse())])
        let sut = SUT(spy)
        trackForMemoryLeaks(spy, sourceLocation: sourceLocation)
        return (sut, spy)
    }
}

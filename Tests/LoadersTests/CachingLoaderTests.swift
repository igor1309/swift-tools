//
//  CachingLoaderTests.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

import Loaders
import Testing

// MARK: - Tests

@Suite final class CachingLoaderTests: AnyLoaderCommonTests {
    
    @Test func test_init_shouldNotCallCollaborators() async throws {
        let (_, loaderSpy, cacheSpy) = makeSUT()

        #expect(loaderSpy.callCount == 0)
        #expect(cacheSpy.callCount == 0)
    }
    
    @Test func test_load_shouldForwardRequest() async throws {
        let request = makeRequest()
        let (sut, loaderSpy, _) = makeSUT()

        _ = try? await load(sut, request)

        #expect(loaderSpy.payloads == [request])
    }
    
    @Test func test_load_shouldPropagateError_onUnderlyingLoaderFailure() async throws {
        let request = makeRequest()
        let error = makeFailure()
        let (sut, _,_) = makeSUT(loadStub: .failure(error))

        await #expect(throws: Failure.self) {
            _ = try await self.load(sut, request)
        }
    }
    
    @Test func test_load_shouldReturnResponse_onSuccessfulLoad() async throws {
        let request = makeRequest()
        let expectedResponse = makeResponse()
        let (sut, _,_) = makeSUT(loadStub: .success(expectedResponse))

        let receivedResponse = try await load(sut, request)

        #expect(receivedResponse == expectedResponse)
    }
    
    @Test func test_load_shouldNotInvokeCache_onUnderlyingLoaderFailure() async throws {
        let (sut, _, cacheSpy) = makeSUT(loadStub: .failure(makeFailure()))

        _ = try? await load(sut, makeRequest())

        #expect(cacheSpy.callCount == 0)
    }

    @Test func test_load_shouldInvokeCache_onSuccessfulLoad() async throws {
        let request = makeRequest()
        let response = makeResponse()
        let (sut, _, cacheSpy) = makeSUT(loadStub: .success(response))

        _ = try await load(sut, request)

        #expect(cacheSpy.payloads.map(\.0) == [request])
        #expect(cacheSpy.payloads.map(\.1) == [response])
    }
    
    // MARK: - Helpers
    
    private typealias SUT = CachingLoader<Request, Response>
    private typealias LoaderSpy = AsyncSpy<Request, Result<Response, Error>>
    private typealias CacheSpy = CallSpy<(Request, Response), Void>
    
    @discardableResult
    private func load(
        _ sut: SUT,
        _ request: Request
    ) async throws -> Response {
        try await sut.load(request)
    }
    
    private func makeSUT(
        loadStub: Result<Response, Error>? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (
        sut: SUT,
        loaderSpy: LoaderSpy,
        cacheSpy: CacheSpy
    ) {
        let loaderSpy = LoaderSpy(stubs: [loadStub ?? .success(makeResponse())])
        let cacheSpy = CacheSpy()
        let sut = SUT(
            loader: loaderSpy.load,
            cache: cacheSpy.call
        )
        trackForMemoryLeaks(loaderSpy, sourceLocation: sourceLocation)
        trackForMemoryLeaks(cacheSpy, sourceLocation: sourceLocation)
        return (sut, loaderSpy, cacheSpy)
    }
}

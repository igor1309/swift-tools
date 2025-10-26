//
//  RevisionCachingLoaderTests.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

import Loaders
import Testing

// MARK: - Tests

@Suite final class RevisionCachingLoaderTests: AnyLoaderCommonTests {

    // TODO: ADD MISSING COLLABORATORS IF ANY
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

    @Test func test_load_shouldInvokeCache_whenNoRevisionCached() async throws {
        let request = makeRequest()
        let response = makeResponse()
        let (sut, _, cacheSpy) = makeSUT(loadStub: .success(response))

        _ = try await load(sut, request)

        #expect(cacheSpy.payloads.map(\.0) == [request])
        #expect(cacheSpy.payloads.map(\.1) == [response])
    }

    @Test func test_load_shouldInvokeCache_whenRevisionDiffers() async throws {}

    @Test func test_load_shouldNotInvokeCache_whenRevisionMatches() async throws {}

    // MARK: - Helpers

    private typealias SUT = RevisionCachingLoader<Request, Response>
    private typealias LoaderSpy = CallSpy<Request, Result<Response, Error>>
    private typealias CacheSpy = CallSpy<(Request, Response), Void>

    @discardableResult
    private func load(
        _ sut: SUT,
        _ request: Request
    ) async throws -> Response {
        try await sut.load(request)
    }

    private func makeSUT(
        loadStub: Result<Response, Error>? = nil
    ) -> (
        sut: SUT,
        loaderSpy: LoaderSpy,
        cacheSpy: CacheSpy
    ) {
        let loaderSpy = LoaderSpy(stubs: [loadStub ?? .success(makeResponse())])
        let cacheSpy = CacheSpy()
        let sut = SUT(
            loader: { try await loaderSpy.load($0).get() },
            cache: cacheSpy.call
        )
        trackForMemoryLeaks(loaderSpy)
        trackForMemoryLeaks(cacheSpy)
        return (sut, loaderSpy, cacheSpy)
    }
}

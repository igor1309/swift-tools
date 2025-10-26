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

    @Test func test_init_shouldNotCallCollaborators() async throws {
        let (_, loaderSpy, cacheSpy, shouldCacheSpy) = makeSUT()

        #expect(loaderSpy.callCount == 0)
        #expect(cacheSpy.callCount == 0)
        #expect(shouldCacheSpy.callCount == 0)
    }

    @Test func test_load_shouldForwardRequest() async throws {
        let request = makeRequest()
        let (sut, loaderSpy, _,_) = makeSUT()

        _ = try? await load(sut, request)

        #expect(loaderSpy.payloads == [request])
    }

    @Test func test_load_shouldPropagateError_onUnderlyingLoaderFailure() async throws {
        let request = makeRequest()
        let error = makeFailure()
        let (sut, _,_,_) = makeSUT(loadStub: .failure(error))

        await #expect(throws: Failure.self) {
            _ = try await self.load(sut, request)
        }
    }

    @Test func test_load_shouldReturnResponse_onSuccessfulLoad() async throws {
        let request = makeRequest()
        let expectedResponse = makeResponse()
        let (sut, _,_,_) = makeSUT(loadStub: .success(expectedResponse))

        let receivedResponse = try await load(sut, request)

        #expect(receivedResponse == expectedResponse)
    }

    @Test func test_load_shouldNotInvokeCache_onUnderlyingLoaderFailure() async throws {
        let (sut, _, cacheSpy, _) = makeSUT(loadStub: .failure(makeFailure()))

        _ = try? await load(sut, makeRequest())

        #expect(cacheSpy.callCount == 0)
    }

    @Test func test_load_shouldNotAskShouldCache_onUnderlyingLoaderFailure() async throws {
        let (sut, _,_, shouldCacheSpy) = makeSUT(loadStub: .failure(makeFailure()))

        _ = try? await load(sut, makeRequest())

        #expect(shouldCacheSpy.callCount == 0)
    }

    @Test func test_load_shouldAskShouldCacheWithRequestAndRevision_onSuccessfulLoad() async throws {
        let request = makeRequest()
        let response = makeResponse()
        let (sut, _,_, shouldCacheSpy) = makeSUT(loadStub: .success(response))

        _ = try await load(sut, request)

        #expect(shouldCacheSpy.payloads.map(\.0) == [request])
        #expect(shouldCacheSpy.payloads.map(\.1) == [response.revision])
    }

    @Test func test_load_shouldInvokeCache_whenNoRevisionCached() async throws {
        let request = makeRequest()
        let response = makeResponse()
        let (sut, _, cacheSpy, _) = makeSUT(loadStub: .success(response), revisionDiffers: true)

        _ = try await load(sut, request)

        #expect(cacheSpy.payloads.map(\.0) == [request])
        #expect(cacheSpy.payloads.map(\.1) == [response])
    }

    @Test func test_load_shouldInvokeCache_whenRevisionDiffers() async throws {
        let request = makeRequest()
        let response = makeResponse()
        let (sut, _, cacheSpy, _) = makeSUT(loadStub: .success(response), revisionDiffers: true)

        _ = try await load(sut, request)

        #expect(cacheSpy.payloads.map(\.0) == [request])
        #expect(cacheSpy.payloads.map(\.1) == [response])
    }

    @Test func test_load_shouldNotInvokeCache_whenRevisionMatches() async throws {
        let request = makeRequest()
        let response = makeResponse()
        let (sut, _, cacheSpy, _) = makeSUT(loadStub: .success(response), revisionDiffers: false)

        _ = try await load(sut, request)

        #expect(cacheSpy.callCount == 0)
    }
    
    @Test func test_load_shouldInvokeCache_onDependencySignaledRevisionChange() async throws {
        let request = makeRequest()
        let initialResponse = makeResponse("initial-revision")
        let updatedResponse = makeResponse("updated-revision")
        let (sut, _, cacheSpy, shouldCacheSpy) = makeSUT(
            loadStubs: [.success(initialResponse), .success(updatedResponse)],
            shouldCacheStubs: [false, true]
        )

        _ = try await load(sut, request)
        _ = try await load(sut, request)

        #expect(shouldCacheSpy.payloads.map(\.1) == [initialResponse.revision, updatedResponse.revision])
        #expect(cacheSpy.payloads.map(\.0) == [request])
        #expect(cacheSpy.payloads.map(\.1) == [updatedResponse])
    }

    // MARK: - Helpers

    private typealias SUT = RevisionCachingLoader<Request, Response>
    private typealias LoaderSpy = CallSpy<Request, Result<Response, Error>>
    private typealias CacheSpy = CallSpy<(Request, Response), Void>
    private typealias ShouldCacheSpy = CallSpy<(Request, Response.Revision), Bool>

    @discardableResult
    private func load(
        _ sut: SUT,
        _ request: Request
    ) async throws -> Response {
        try await sut.load(request)
    }

    private func makeSUT(
        loadStub: Result<Response, Error>? = nil,
        revisionDiffers shouldCacheStub: Bool = true,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (
        sut: SUT,
        loaderSpy: LoaderSpy,
        cacheSpy: CacheSpy,
        shouldCacheSpy: ShouldCacheSpy
    ) {
        return makeSUT(loadStubs: [loadStub ?? .success(makeResponse())], shouldCacheStubs: [shouldCacheStub], sourceLocation: sourceLocation)
    }

    private func makeSUT(
        loadStubs: [Result<Response, Error>],
        shouldCacheStubs: [Bool],
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (
        sut: SUT,
        loaderSpy: LoaderSpy,
        cacheSpy: CacheSpy,
        shouldCacheSpy: ShouldCacheSpy
    ) {
        let loaderSpy = LoaderSpy(stubs: loadStubs)
        let cacheSpy = CacheSpy()
        let shouldCacheSpy = ShouldCacheSpy(stubs: shouldCacheStubs)
        let sut = SUT(
            loader: { try await loaderSpy.load($0).get() },
            cache: cacheSpy.call,
            shouldCache: shouldCacheSpy.call
        )
        trackForMemoryLeaks(loaderSpy, sourceLocation: sourceLocation)
        trackForMemoryLeaks(cacheSpy, sourceLocation: sourceLocation)
        trackForMemoryLeaks(shouldCacheSpy, sourceLocation: sourceLocation)
        return (sut, loaderSpy, cacheSpy, shouldCacheSpy)
    }
}

extension AnyLoaderCommonTests.Response: RevisionProviding {
    var revision: String { value }
}

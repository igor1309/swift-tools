//
//  RevisionedHTTPRequestAdapterTests.swift
//  WriterAssistantTests
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Foundation
import Loaders
import Testing

final class RevisionedHTTPRequestAdapterTests: TestContext {
    
    @Test(arguments: [Revision?.none, anyMessage()])
    func test_load_shouldRequestBuilderWithRevision(revision: Revision?) async throws {
        let (sut, builderSpy, _) = makeSUT()
        _ = try await sut.load(revision)
        #expect(builderSpy.payloads == [revision])
    }
    
    @Test(arguments: [Revision?.none, anyMessage()])
    func test_load_shouldForwardRequestToHTTPLoader(revision: Revision?) async throws {
        let expectedRequest = makeRequest()
        let (sut, _, httpSpy) = makeSUT(builderStub: .success(expectedRequest))
        _ = try await sut.load(revision)
        #expect(httpSpy.payloads == [expectedRequest])
    }
    
    @Test(arguments: [Revision?.none, anyMessage()])
    func test_load_shouldPropagateBuilderErrors(revision: Revision?) async {
        let expectedError = anyNSError()
        let (sut, _, httpSpy) = makeSUT(builderStub: .failure(expectedError), httpStubs: [])
        await #expect(throws: expectedError) { try await sut.load(revision) }
        #expect(httpSpy.payloads.isEmpty)
    }
    
    @Test(arguments: [Revision?.none, anyMessage()])
    func test_load_shouldPropagateHTTPLoaderErrors(revision: Revision?) async {
        let expectedError = anyNSError()
        let (sut, _, _) = makeSUT(httpStubs: [.failure(expectedError)])
        await #expect(throws: expectedError) { try await sut.load(revision) }
    }
    
    @Test(arguments: [Revision?.none, anyMessage()])
    func test_load_shouldPropagateHTTPLoaderOutput(revision: Revision?) async throws {
        let expectedResponse = makeOutput()
        let (sut, _, _) = makeSUT(httpStubs: [.success(expectedResponse)])
        let response = try await sut.load(revision)
        #expect(response == expectedResponse)
    }
    
    // MARK: - Helpers
    
    private typealias SUT = RevisionedHTTPRequestAdapter<Output>
    private typealias BuilderSpy = CallSpy<Revision?, Result<URLRequest, Error>>
    private typealias HTTPLoaderSpy = AsyncSpyOf<URLRequest, Output>
    
    private func makeSUT(
        builderStub: Result<URLRequest, Error>? = nil,
        httpStubs: [Result<Output, Error>]? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (
        sut: SUT,
        builderSpy: BuilderSpy,
        httpSpy: HTTPLoaderSpy
    ) {
        let builderSpy = BuilderSpy(stubs: [builderStub ?? .success(makeRequest())])
        let httpSpy = HTTPLoaderSpy(stubs: httpStubs ?? [.success(makeOutput())])
        let sut = SUT(requestBuilder: builderSpy, httpLoader: httpSpy)
        
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        trackForMemoryLeaks(builderSpy, sourceLocation: sourceLocation)
        trackForMemoryLeaks(httpSpy, sourceLocation: sourceLocation)
        
        return (sut, builderSpy, httpSpy)
    }
    
    private func makeRequest(url: URL? = nil) -> URLRequest {
        return .init(url: url ?? anyURL())
    }
    
    private struct Output: Equatable {
        let value: String
    }
    
    private func makeOutput(
        _ value: String = anyMessage()
    ) -> Output {
        return .init(value: value)
    }
}

extension CallSpy: RevisionedHTTPRequestBuilding where Payload == Revision?, Response == Result<URLRequest, Error> {
    func makeRequest(revision: Revision?) throws -> URLRequest {
        try call(payload: revision).get()
    }
}

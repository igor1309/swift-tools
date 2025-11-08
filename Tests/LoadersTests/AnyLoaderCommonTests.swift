//
//  AnyLoaderCommonTests.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

import Loaders
import Testing

@Suite class AnyLoaderCommonTests: TestContext {
    
    typealias SUT = AnyLoader<Request, Response>
    typealias LoaderSpy = AsyncSpyOf<Request, Response>
    
    @discardableResult
    func load(
        _ sut: SUT,
        _ request: Request
    ) async throws -> Response {
        try await sut.load(request)
    }
    
    struct Request: Equatable {
        let value: String
    }
    
    func makeRequest(
        _ value: String = anyMessage()
    ) -> Request {
        return .init(value: value)
    }
    
    struct Response: Equatable {
        let value: String
    }
    
    func makeResponse(
        _ value: String = anyMessage()
    ) -> Response {
        return .init(value: value)
    }
    
    struct Failure: Error, Equatable {
        let value: String
    }
    
    func makeFailure(
        _ value: String = anyMessage()
    ) -> Failure {
        return .init(value: value)
    }
}

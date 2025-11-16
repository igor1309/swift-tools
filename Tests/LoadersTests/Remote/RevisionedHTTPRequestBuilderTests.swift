//
//  RevisionedHTTPRequestBuilderTests.swift
//  swift-toolsTests
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Foundation
import Loaders
import Testing

final class RevisionedHTTPRequestBuilderTests: TestContext {
    
    @Test func test_makeRequest_shouldSetURLMethodAndHeaders() throws {
        let endpoint = URL(string: "https://example.com/prompts.json")!
        let headers = ["X-Test": "value"]
        let sut = makeSUT(
            endpoint: endpoint,
            method: "GET",
            headersProvider: { headers }
        )
        
        let request = try sut.makeRequest(revision: nil)
        
        #expect(request.url == endpoint)
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "X-Test") == "value")
        #expect(request.value(forHTTPHeaderField: "If-None-Match") == nil)
    }
    
    @Test func test_makeRequest_shouldInjectRevisionHeader() throws {
        let sut = makeSUT(endpoint: anyURL())
        let revision = anyMessage()
        let request = try sut.makeRequest(revision: revision)
        #expect(request.value(forHTTPHeaderField: "If-None-Match") == revision)
    }
    
    // MARK: - Helpers

    private typealias SUT = RevisionedHTTPRequestBuilder

    private func makeSUT(
        endpoint: URL,
        method: String = "GET",
        headersProvider: @escaping () -> [String: String] = { [:] }
    ) -> SUT {
        return .init(endpoint: endpoint, method: method, headersProvider: headersProvider)
    }
}

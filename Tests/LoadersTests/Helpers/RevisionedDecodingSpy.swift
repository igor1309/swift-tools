//
//  RevisionedDecodingSpy.swift
//  swift-tools
//
//  Created by Igor Malyarov on 16.11.2025.
//

import Foundation
import Loaders

final class RevisionedDecodingSpy {
    private(set) var payloads: [(data: Data, response: HTTPURLResponse)] = []
    private(set) var stubs: [Stub]

    init(stubs: [Stub] = []) {
        self.stubs = stubs
    }

    enum Stub {
        case result(Result<Any, Error>)
        case handler((Data, HTTPURLResponse) throws -> Any)
        case prompts(etag: String?, prompts: [String])
        case notModified

        static func success<T>(_ response: DecodedResponse<T>) -> Stub {
            .result(.success(response))
        }

        static func failure(_ error: Error) -> Stub {
            .result(.failure(error))
        }
    }

    func enqueueSuccess<T>(_ response: DecodedResponse<T>) {
        stubs.append(.success(response))
    }

    func enqueueFailure(_ error: Error) {
        stubs.append(.failure(error))
    }

    func enqueueHandler(_ handler: @escaping (Data, HTTPURLResponse) throws -> Any) {
        stubs.append(.handler(handler))
    }
}

extension RevisionedDecodingSpy: HTTPRevisionedResponseDecoding {
    func processRevisioned<T>(_ data: Data, _ response: HTTPURLResponse) throws -> DecodedResponse<T> where T: Decodable {
        payloads.append((data, response))
        guard !stubs.isEmpty else {
            preconditionFailure("Missing stub for RevisionedDecodingSpy")
        }
        
        let stub = stubs.removeFirst()
        let anyResponse: Any
        
        switch stub {
        case .result(let result):
            anyResponse = try result.get()
        case .handler(let handler):
            anyResponse = try handler(data, response)
        case .prompts(let etag, let prompts):
            return try Self.makePromptsResponse(etag: etag, prompts: prompts)
        case .notModified:
            return .notModified
        }

        guard let typedResponse = anyResponse as? DecodedResponse<T> else {
            preconditionFailure("RevisionedDecodingSpy stub type mismatch: \(type(of: anyResponse)) cannot be cast to DecodedResponse<\(T.self)>")
        }

        return typedResponse
    }

    private static func makePromptsResponse<T>(
        etag: String?,
        prompts: [String]
    ) throws -> DecodedResponse<T> where T: Decodable {
        let payload = PromptsPayload(prompts: prompts)
        let data = try JSONEncoder().encode(payload)
        let decodedValue = try JSONDecoder().decode(T.self, from: data)
        return .response(.init(etag: etag, value: decodedValue))
    }
}

private struct PromptsPayload: Codable {
    let prompts: [String]
}

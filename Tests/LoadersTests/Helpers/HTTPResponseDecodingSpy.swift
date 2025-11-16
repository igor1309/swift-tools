//
//  HTTPResponseDecodingSpy.swift
//  swift-tools
//
//  Created by Igor Malyarov on 16.11.2025.
//

import Foundation
import Loaders

final class HTTPResponseDecodingSpy {
    private(set) var payloads: [(data: Data, response: HTTPURLResponse)] = []
    private var stubs: [Stub]
    
    init(stubs: [Stub]) {
        self.stubs = stubs
    }
    
    enum Stub {
        case result(Result<Any, Error>)
        case handler((Data, HTTPURLResponse) throws -> Any)
        
        static func success<T>(_ value: T) -> Stub where T: Decodable {
            .result(.success(value))
        }
        
        static func failure(_ error: Error) -> Stub {
            .result(.failure(error))
        }
    }
}

extension HTTPResponseDecodingSpy: HTTPResponseDecoding {
    func process<T>(_ data: Data, _ response: HTTPURLResponse) throws -> T where T: Decodable {
        payloads.append((data, response))
        guard !stubs.isEmpty else {
            preconditionFailure("HTTPResponseDecodingSpy missing stub")
        }

        let stub = stubs.removeFirst()
        let output: Any

        switch stub {
        case .result(let result):
            output = try result.get()
        case .handler(let handler):
            output = try handler(data, response)
        }

        guard let typed = output as? T else {
            preconditionFailure("HTTPResponseDecodingSpy expected \(T.self) but got \(type(of: output))")
        }

        return typed
    }
}

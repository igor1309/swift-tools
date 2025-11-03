//
//  AsyncSpy.swift
//
//
//  Created by Igor Malyarov on 03.11.2025.
//

final class AsyncSpy<Payload, Response> {
    
    private(set) var payloads = [Payload]()
    private var stubs: [Response]
    
    init(stubs: [Response] = []) {
        
        self.stubs = stubs
    }
}

extension AsyncSpy {
    
    var callCount: Int { payloads.count }
    
    func call(payload: Payload) async throws -> Response {
        
        try await Task.sleep(for: .milliseconds(100))
        payloads.append(payload)
        return stubs.removeFirst()
    }
}

extension AsyncSpy where Payload == Void {
    
    func call() async throws -> Response {
        
        return try await self.call(payload: ())
    }
}

extension AsyncSpy where Response == Void {
    
    convenience init() {
        
        self.init(stubs: [()])
    }
}

extension AsyncSpy {
    
    func call<A, B>(_ a: A, _ b: B) async throws -> Response
    where Payload == (A, B) {
        
        return try await self.call(payload: (a, b))
    }
    
    func call<A, B, C>(_ a: A, _ b: B, _ c: C) async throws -> Response
    where Payload == (A, B, C) {
        
        return try await self.call(payload: (a, b, c))
    }
}

extension AsyncSpy where Response == Result<Void, Error> {
    
    func call(payload: Payload) async throws -> Void {
        
        return try await call(payload: payload).get()
    }
    
    func call<A, B>(_ a: A, _ b: B) async throws -> Void
    where Payload == (A, B) {
        
        return try await self.call(payload: (a, b))
    }
}

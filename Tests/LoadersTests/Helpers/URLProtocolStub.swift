//
//  URLProtocolStub.swift
//  swift-tools
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Foundation

final class URLProtocolStub: URLProtocol {
    
    private struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }
    
    private static var stub: Stub?
    private static var tokenizedStubs: [String: Stub] = [:]
    private static var requestObserver: ((URLRequest) -> Void)?
    private static var tokenizedObservers: [String: (URLRequest) -> Void] = [:]
    private static let tokenKey = "URLProtocolStub.token"
    private static let queue = DispatchQueue(label: "URLProtocolStub.queue")
    
    static func stub(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        token: String? = nil
    ) {
        queue.sync {
            let stub = Stub(data: data, response: response, error: error)
            if let token {
                self.tokenizedStubs[token] = stub
            } else {
                self.stub = stub
            }
        }
    }
    
    static func observeRequests(
        token: String? = nil,
        _ observer: @escaping (URLRequest) -> Void
    ) {
        queue.sync {
            if let token {
                self.tokenizedObservers[token] = observer
            } else {
                self.requestObserver = observer
            }
        }
    }
    
    static func removeRequestObserver(token: String? = nil) {
        queue.sync {
            if let token {
                self.tokenizedObservers[token] = nil
            } else {
                self.requestObserver = nil
            }
        }
    }
    
    static func removeStub(token: String) {
        queue.sync {
            self.tokenizedStubs[token] = nil
        }
    }
    
    @discardableResult
    static func tagging(_ request: URLRequest, token: String) -> URLRequest {
        guard
            let mutableCopy = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest
        else {
            preconditionFailure("Failed to create mutable request for token tagging")
        }
        
        URLProtocol.setProperty(token, forKey: tokenKey, in: mutableCopy)
        return mutableCopy as URLRequest
    }
    
    static func removeStub() {
        queue.sync {
            self.stub = nil
            self.tokenizedStubs = [:]
            self.requestObserver = nil
            self.tokenizedObservers = [:]
        }
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override func startLoading() {
        activeToken = URLProtocol.property(forKey: Self.tokenKey, in: request) as? String
        let (stub, observer) = Self.queue.sync { () -> (Stub?, ((URLRequest) -> Void)?) in
            let stub = activeToken.flatMap { Self.tokenizedStubs[$0] } ?? Self.stub
            let observer = activeToken.flatMap { Self.tokenizedObservers[$0] } ?? Self.requestObserver
            return (stub, observer)
        }
        guard let stub else { return }
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
        
        observer?(request)
        cleanupTokenResourcesIfNeeded()
    }
    
    override func stopLoading() {
        cleanupTokenResourcesIfNeeded()
    }
    
    private var activeToken: String?
    
    private func cleanupTokenResourcesIfNeeded() {
        guard let token = activeToken else { return }
        Self.queue.sync {
            Self.tokenizedStubs[token] = nil
            Self.tokenizedObservers[token] = nil
        }
        activeToken = nil
    }
}

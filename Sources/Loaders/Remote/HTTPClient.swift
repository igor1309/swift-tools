//
//  HTTPClient.swift
//  WriterAssistant
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Foundation

public protocol HTTPClient {
    
    func get(with request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

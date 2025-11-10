//
//  HTTPClient.swift
//  WriterAssistant
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Foundation

public typealias HTTPClient = Loading<URLRequest, (Data, HTTPURLResponse)>

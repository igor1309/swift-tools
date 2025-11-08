//
//  anyURL.swift
//  swift-tools
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Foundation

func anyURL() -> URL {
    return URL(string: UUID().uuidString)!
}

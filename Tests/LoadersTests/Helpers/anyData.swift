//
//  anyData.swift
//  swift-tools
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Foundation

func anyData(
    string: String? = nil
) -> Data {
    return .init((string ?? anyMessage()).utf8)
}

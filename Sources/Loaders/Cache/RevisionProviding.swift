//
//  RevisionProviding.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

public protocol RevisionProviding<Revision> {
    associatedtype Revision: Hashable
    var revision: Revision { get }
}

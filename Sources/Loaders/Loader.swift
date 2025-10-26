//
//  Loader.swift
//  swift-tools
//
//  Created by Igor Malyarov on 26.10.2025.
//

/// A generic async throwing closure that loads a `Response` from a `Request`.
public typealias Loader<Request, Response> = (Request) async throws -> Response

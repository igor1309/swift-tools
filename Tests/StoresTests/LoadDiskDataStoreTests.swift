//
//  LoadDiskDataStoreTests.swift
//  swift-tools
//
//  Created by Igor Malyarov on 04.11.2025.
//

import Foundation
import Stores
import Testing

final class LoadDiskDataStoreTests: TestContext {

    // MARK: - load
    
    @Test func test_load_shouldCallKeyMapperWithKey() async throws {
        
        let key = anyMessage()
        let (sut, keyMapper) = try makeSUT(mappedKeys: [key])
        
        _ = try? await sut.load(key: key)
        
        XCTAssertNoDiff(keyMapper.payloads, [key])
    }
    
    @Test func test_load_shouldThrowFetchingError_onMissingEntry() async throws {

        let (sut, _) = try makeSUT()

        await #expect(throws: SUT.RetrievalFailure.self) {
            _ = try await sut.load(key: anyMessage())
        }
    }

    @Test func test_load_shouldReturnData_onSuccessfulRetrieve() async throws {

        let (key, expectedData) = makeKeyWithData()
        let (sut, _) = try makeSUT()

        await insert(expectedData, forKey: key, to: sut)

        let data = try await sut.load(key: key)

        #expect(data == expectedData)
    }
    
    // MARK: - Helpers
    
    private typealias SUT = DiskDataStore
    private typealias KeyMapperSpy = CallSpy<String, String>
    
    private func makeSUT(
        excludeFromBackup: Bool = true,
        mappedKeys: [String]? = nil,
        storeDirectoryURL: URL? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws -> (
        sut: SUT,
        keyMapper: KeyMapperSpy
    ) {
        let keyMapperSpy = KeyMapperSpy(stubs: mappedKeys ?? [])
        let sut = try SUT(
            storeDirectoryURL: storeDirectoryURL ?? testStoreURL(),
            keyMapper: mappedKeys == nil ? { $0 } : keyMapperSpy.call,
            excludeFromBackup: excludeFromBackup
        )

        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        trackForMemoryLeaks(keyMapperSpy, sourceLocation: sourceLocation)

        addTeardownBlock { [weak self] in self?.removeStoreArtifacts() }

        return (sut, keyMapperSpy)
    }
    
    private func makeKeyWithData() -> (String, Data) {

        return (anyMessage(), anyData())
    }

    @discardableResult
    private func insert(
        _ data: Data,
        forKey key: String,
        to sut: SUT
    ) async -> Error? {

        await withCheckedContinuation { continuation in

            sut.insert(data, forKey: key) { error in
                continuation.resume(returning: error)
            }
        }
    }

    // MARK: - FileManager
    
    private let fileManager = FileManager.default
    
    private func testStoreURL() -> URL {
        
        cachesDirectory()
            .appendingPathComponent("\(type(of: self)).store")
    }
    
    private func cachesDirectory() -> URL {
        
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func noDeletePermissionURL() -> URL {

        fileManager.urls(for: .cachesDirectory, in: .systemDomainMask).first!
    }

    private func removeStoreArtifacts() {

        try? fileManager.removeItem(at: testStoreURL())
    }
}

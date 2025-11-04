//
//  DiskDataStoreTests.swift
//  swift-tools
//
//  Created by Igor Malyarov on 04.11.2025.
//

import Stores
import XCTest

final class DiskDataStoreTests: XCTestCase {
    
    override func setUp() {
        
        super.setUp()
        setupEmptyStore()
    }
    
    override func tearDown() {
        
        super.tearDown()
        undoStoreSideEffects()
    }
    
    // MARK: - init
    
    func test_init_shouldThrowOnInvalidURL() throws {
        
        let invalidURL = URL(string: "invalid://store-url")!
        
        try XCTAssertThrowsError(makeSUT(storeDirectoryURL: invalidURL))
    }
    
    func test_init_shouldThrowOnDeletePermissionURL() throws {
        
        let noDeletePermissionURL = noDeletePermissionURL()
        
        try XCTAssertThrowsError(makeSUT(storeDirectoryURL: noDeletePermissionURL))
    }
    
    func test_init_shouldSetDirectory() throws {
        
        let storeDirectoryURL = testStoreURL()
        
        _ = try makeSUT(storeDirectoryURL: storeDirectoryURL)
        
        try XCTAssertTrue(XCTUnwrap(
            storeDirectoryURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory
        ))
    }
    
    func test_init_shouldExcludeFromBackup_onTrue() throws {
        
        let storeDirectoryURL = testStoreURL()
        
        _ = try makeSUT(excludeFromBackup: true, storeDirectoryURL: storeDirectoryURL)
        
        try XCTAssertTrue(XCTUnwrap(
            storeDirectoryURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        ))
    }
    
    func test_init_shouldNotExcludeFromBackup_onFalse() throws {
        
        let storeDirectoryURL = testStoreURL()
        
        _ = try makeSUT(excludeFromBackup: false, storeDirectoryURL: storeDirectoryURL)
        
        try XCTAssertFalse(XCTUnwrap(
            storeDirectoryURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        ))
    }
    
    func test_init_shouldNotCallCollaborators() throws {
        
        let (sut, keyMapper) = try makeSUT()
        
        XCTAssertEqual(keyMapper.callCount, 0)
        XCTAssertNotNil(sut)
    }
    
    // MARK: - insert
    
    func test_insert_shouldCallKeyMapperWithKey() throws {
        
        let (key, data) = makeKeyWithData()
        let (sut, keyMapper) = try makeSUT(mappedKeys: [key])
        
        sut.insert(data, forKey: key) { _ in }
        
        XCTAssertNoDiff(keyMapper.payloads, [key])
    }
    
    func test_insert_shouldOverridePreviouslyInsertedData() throws {
        
        let (key, firstData, secondData) = (anyMessage(), anyData(), anyData())
        let (sut, _) = try makeSUT()
        
        let firstInsertionError = insert(firstData, forKey: key, to: sut)
        
        XCTAssertNil(firstInsertionError, "Expected successful insertion.")
        expect(sut, with: key, toRetrieve: .success(firstData))
        
        let secondInsertionError = insert(secondData, forKey: key, to: sut)
        
        XCTAssertNil(secondInsertionError, "Expected successful cache override.")
        expect(sut, with: key, toRetrieve: .success(secondData))
    }
    
    func test_insert_shouldPersist() throws {
        
        let (key, data) = (anyMessage(), anyData())
        let (sut1, _) = try makeSUT()
        
        XCTAssertNil(insert(data, forKey: key, to: sut1))
        expect(sut1, with: key, toRetrieve: .success(data))
        
        let (sut2, _) = try makeSUT(mappedKeys: [key])
        expect(sut2, with: anyMessage(), toRetrieve: .success(data))
    }
    
    // MARK: - retrieve
    
    func test_retrieve_shouldCallKeyMapperWithKey() throws {
        
        let key = anyMessage()
        let (sut, keyMapper) = try makeSUT(mappedKeys: [key])
        
        sut.retrieve(key: key) { _ in }
        
        XCTAssertNoDiff(keyMapper.payloads, [key])
    }
    
    func test_retrieve_shouldDeliverErrorOnEmptyCache() throws {
        
        let (sut, _) = try makeSUT()
        
        expect(sut, toRetrieve: .failure(SUT.RetrievalFailure()))
    }
    
    func test_retrieve_twice_shouldDeliverErrorOnEmptyCacheTwice() throws {
        
        let (sut, _) = try makeSUT()
        
        expect(sut, toRetrieve: .failure(SUT.RetrievalFailure()))
        expect(sut, toRetrieve: .failure(SUT.RetrievalFailure()))
    }
    
    func test_retrieve_shouldDeliverInsertedValuesAfterInsertingToEmptyCache() throws {
        
        let (key, data) = makeKeyWithData()
        let (sut, _) = try makeSUT()
        
        insert(data, forKey: key, to: sut)
        
        expect(sut, with: key, toRetrieve: .success(data))
    }
    
    func test_retrieve_shouldDeliverFailureAsynchronously_onEmptyCache() throws {
        
        let (sut, _) = try makeSUT()
        let exp = expectation(description: "Wait for async failure")
        var observedResult: Result<Data, Error>?
        var completionInvokedSynchronously = false
        
        sut.retrieve(key: anyMessage()) { result in
            
            observedResult = result
            completionInvokedSynchronously = true
            exp.fulfill()
        }
        
        XCTAssertFalse(completionInvokedSynchronously)
        wait(for: [exp], timeout: 1.0)
        
        switch observedResult {
        case let .failure(error as SUT.RetrievalFailure)?:
            XCTAssertEqual(error, SUT.RetrievalFailure())
        default:
            XCTFail("Expected asynchronous failure, got \(String(describing: observedResult)) instead.")
        }
    }
    
    // MARK: - delete
    
    func test_delete_shouldNotDeliverErrorOnEmptyCacheDeletion() throws {
        
        let (sut, _) = try makeSUT()
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected successful empty cache deletion.")
    }
    
    func test_delete_shouldHaveNoSideEffectsOnEmptyCache() throws {
        
        let (sut, _) = try makeSUT()
        
        expect(sut, toRetrieve: .failure(SUT.RetrievalFailure()))
    }
    
    func test_delete_shouldNotDeliverError_onNonEmptyCacheDeletion() throws {
        
        let (sut, _) = try makeSUT()
        insert(anyData(), forKey: anyMessage(), to: sut)
        
        let deletionError = deleteCache(from: sut)
        
        XCTAssertNil(deletionError, "Expected successful non-empty cache deletion.")
    }
    
    func test_delete_shouldRemovePreviouslyInsertedCache() throws {
        
        let (sut, _) = try makeSUT()
        insert(anyData(), forKey: anyMessage(), to: sut)
        
        deleteCache(from: sut)
        
        expect(sut, toRetrieve: .failure(SUT.RetrievalFailure()))
    }
    
    func test_delete_shouldRespectBackupPolicy_onFalse() throws {
        
        let storeDirectoryURL = testStoreURL()
        let (sut, _) = try makeSUT(excludeFromBackup: false, storeDirectoryURL: storeDirectoryURL)
        
        XCTAssertNil(deleteCache(from: sut))
        
        try XCTAssertFalse(XCTUnwrap(
            storeDirectoryURL.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        ))
    }
    
    // MARK: - other
    
    func test_storeSideEffects_shouldRunSerially() throws {
        
        let (key1, key3) = (anyMessage(), anyMessage())
        let (sut, _) = try makeSUT()
        var operations = [XCTestExpectation]()
        
        let op1 = expectation(description: "Operation 1")
        sut.insert(anyData(), forKey: key1) { _ in
            
            operations.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 2")
        
        sut.deleteCache { _ in
            
            operations.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Operation 3")
        sut.insert(anyData(), forKey: key3) { _ in
            
            operations.append(op3)
            op3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(operations, [op1, op2, op3])
    }
    
    // MARK: - Helpers
    
    private typealias SUT = DiskDataStore
    private typealias KeyMapperSpy = CallSpy<String, String>
    
    private func makeSUT(
        excludeFromBackup: Bool = true,
        mappedKeys: [String]? = nil,
        storeDirectoryURL: URL? = nil,
        file: StaticString = #file,
        line: UInt = #line
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
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(keyMapperSpy, file: file, line: line)
        
        return (sut, keyMapperSpy)
    }
    
    private func makeKeyWithData() -> (String, Data) {
        
        return (anyMessage(), anyData())
    }
    
    @discardableResult
    private func deleteCache(
        from sut: SUT,
        timeout: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        
        let exp = expectation(description: "Wait for cache deletion")
        
        var error: Error?
        sut.deleteCache {
            
            if case let deletionError = $0 {
                
                error = deletionError
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: timeout)
        return error
    }
    
    @discardableResult
    private func insert(
        _ data: Data,
        forKey key: String,
        to sut: SUT,
        timeout: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        
        let exp = expectation(description: "wait for insertion completion")
        var error: Error?
        
        sut.insert(data, forKey: key) {
            
            if case let insertionError = $0 {
                
                error = insertionError
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: timeout)
        
        return error
    }
    
    private func expect(
        _ sut: SUT,
        with key: String = anyMessage(),
        toRetrieve expectedResult: Result<Data, Error>,
        timeout: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for retrieval")
        
        sut.retrieve(key: key) { retrievedResult in
            
            switch (expectedResult, retrievedResult) {
            case let (.success(expected), .success(retrieve)):
                XCTAssertNoDiff(expected, retrieve, "Expected \(expected), got \(retrieve) instead.", file: file, line: line)
                
            case let (.failure(expected as NSError?), .failure(retrieved as NSError?)):
                XCTAssertNoDiff(expected, retrieved, file: file, line: line)
                
            default:
                XCTFail("Expected retrieving \(expectedResult), got \(retrievedResult) instead.", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: timeout)
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
    
    private func setupEmptyStore() {
        
        removeStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        
        removeStoreArtifacts()
    }
    
    private func removeStoreArtifacts() {
        
        try? fileManager.removeItem(at: testStoreURL())
    }
}

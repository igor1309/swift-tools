//
//  AtomicStoreTests.swift
//  swift-tools
//
//  Created by Igor Malyarov on 08.11.2025.
//

import Stores
import Testing

final class AtomicStoreTests: TestContext {
    
    @available(iOS 18.0, macOS 15.0, *)
    @Test func test_init_shouldStoreProvidedValue() async throws {
        
        let initialValue = makeValue("initial")
        let sut = makeSUT(initialValue: initialValue)
        
        #expect(sut.get() == initialValue)
    }
    
    @available(iOS 18.0, macOS 15.0, *)
    @Test func test_set_shouldOverrideValue() async throws {
        
        let sut = makeSUT(initialValue: makeValue("initial"))
        let firstValue = makeValue(anyMessage("first"))
        let latestValue = makeValue(anyMessage("latest"))
        
        sut.set(firstValue)
        sut.set(latestValue)
        
        #expect(sut.get() == latestValue)
    }
    
    @available(iOS 18.0, macOS 15.0, *)
    @Test func test_withValue_shouldReturnClosureResultWithoutMutatingState() async throws {
        
        let initialValue = makeValue("initial")
        let sut = makeSUT(initialValue: initialValue)
        let derivedSuffix = anyMessage("suffix")
        
        let derived = sut.withValue { storedValue in
            storedValue.value + derivedSuffix
        }
        
        #expect(derived == initialValue.value + derivedSuffix)
        #expect(sut.get() == initialValue)
    }
    
    @available(iOS 18.0, macOS 15.0, *)
    @Test func test_mutate_shouldProvideLatestValue() async throws {
        
        let sut = makeSUT(initialValue: makeValue("initial"))
        let firstValue = makeValue(anyMessage("first"))
        let appendedValue = anyMessage("appended")
        
        sut.set(firstValue)
        
        sut.mutate { storedValue in
            
            let base = storedValue.value
            storedValue = .init(value: base + appendedValue)
        }
        
        #expect(sut.get().value == firstValue.value + appendedValue)
    }
    
    @available(iOS 18.0, macOS 15.0, *)
    @Test func test_load_shouldReturnOneOfConcurrentlyStoredValues() async throws {
        
        let sut = makeSUT(initialValue: makeValue("initial"))
        let iterations = 5_000
        let expectedValues = (0..<iterations).map { index in
            makeValue("value-\(index)")
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            
            for candidate in expectedValues {
                group.addTask {
                    sut.set(candidate)
                }
            }
            
            for try await _ in group {
                continue
            }
        }
        
        let loadedValue = sut.get()
        
        #expect(expectedValues.contains { $0 == loadedValue })
    }
    
    // MARK: - Helpers
    
    @available(iOS 18.0, macOS 15.0, *)
    private typealias SUT = AtomicStore<Value>
    
    @available(iOS 18.0, macOS 15.0, *)
    private func makeSUT(
        initialValue: Value,
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> SUT {
        let sut = SUT(initialValue: initialValue)
        
        trackForMemoryLeaks(sut, sourceLocation: sourceLocation)
        
        return sut
    }
    
    private struct Value: Equatable {
        
        let value: String
    }
    
    private func makeValue(
        _ value: String = anyMessage()
    ) -> Value {
        
        return .init(value: value)
    }
}

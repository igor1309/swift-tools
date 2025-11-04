//
//  DiskDataStore.swift
//  swift-tools
//
//  Created by Igor Malyarov on 04.11.2025.
//

import Foundation

/// A disk-based data store that maps string keys to files within a directory.
/// - Manages a root directory for storage, ensuring it exists and is excluded from backups.
/// - Uses a serial `DispatchQueue` to synchronize file operations.
/// - Relies on a `KeyMapper` to convert logical keys into valid file names.
public final class DiskDataStore {
    
    private let storeDirectoryURL: URL
    private let keyMapper: KeyMapper
    private let excludeFromBackup: Bool
    private let queue: DispatchQueue
    
    /// Initializes a `DiskDataStore` with the given directory URL and key-mapping function.
    /// - Parameters:
    ///   - storeDirectoryURL: The file-system directory where cached data will be stored.
    ///   - keyMapper: A function that maps a logical key (`String`) to a file name (`String`).
    /// - Throws: An error if the directory cannot be created or excluded from backups.
    public init(
        storeDirectoryURL: URL,
        keyMapper: @escaping KeyMapper,
        excludeFromBackup: Bool = true
    ) throws {
        
        // Ensure the base directory exists.
        try FileManager.default.createDirectory(
            at: storeDirectoryURL,
            withIntermediateDirectories: true
        )
        // Prevent the directory from being included in backups.
        if excludeFromBackup {
            try storeDirectoryURL.excludeFromBackup()
        }
        
        self.storeDirectoryURL = storeDirectoryURL
        self.keyMapper = keyMapper
        self.excludeFromBackup = excludeFromBackup
        // Create a serial queue labeled with the directory path for thread-safe I/O.
        self.queue = .init(label: "\(DiskDataStore.self)[\(storeDirectoryURL.path)]")
    }
}

private extension URL {
    
    /// Sets the `isExcludedFromBackup` resource value on this URL to `true`.
    /// - Throws: An error if the resource value cannot be set.
    func excludeFromBackup() throws {
        
        var url = self
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }
}

public extension DiskDataStore {
    
    /// A function that transforms a logical key (`String`) into a file-system–safe name (`String`).
    typealias KeyMapper = (String) -> String
    
    /// Deletes all cached files by removing and recreating the storage directory.
    /// - Parameter completion: Called on the calling thread when deletion (and re-creation) completes,
    ///   with an optional `Error` if something went wrong.
    ///
    /// Implementation details:
    /// - Checks if the directory exists; if so, removes it entirely.
    /// - Recreates the directory and re-applies the “exclude from backup” flag when configured.
    /// - All file-system work happens on the internal serial queue.
    func deleteCache(
        completion: @escaping (Error?) -> Void
    ) {
        let storeURL = self.storeDirectoryURL
        let fileManager = FileManager.default
        let excludeFromBackup = self.excludeFromBackup
        
        queue.async {
            
            do {
                if fileManager.fileExists(atPath: storeURL.path) {
                    
                    try fileManager.removeItem(at: storeURL)
                }
                
                try fileManager.createDirectory(at: storeURL, withIntermediateDirectories: true, attributes: nil)
                if excludeFromBackup {
                    try storeURL.excludeFromBackup()
                }
                
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    /// Writes `data` to a file corresponding to `key`.
    /// - Parameters:
    ///   - data: The raw data to store on disk.
    ///   - key: The logical key; used with `keyMapper` to derive a file name.
    ///   - completion: Called on the calling thread when writing completes,
    ///     with an optional `Error` if writing fails.
    ///
    /// Implementation details:
    /// - Computes the target file URL before dispatching to the serial queue.
    /// - Writes data atomically on the internal queue to avoid concurrent writes.
    func insert(
        _ data: Data,
        forKey key: String,
        completion: @escaping (Error?) -> Void
    ) {
        let dataURL = dataURL(forKey: key)
        
        queue.async {
            
            do {
                try data.write(to: dataURL, options: .atomic)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    /// Retrieves data for the given `key` from disk.
    /// - Parameters:
    ///   - key: The logical key; used with `keyMapper` to derive a file name.
    ///   - completion: Called on the calling thread with either the loaded `Data`
    ///     or a `RetrievalFailure` error if the file does not exist or cannot be read.
    ///
    /// Implementation details:
    /// - Checks for file existence and reads contents on the internal queue to provide consistent callback scheduling.
    func retrieve(
        key: String,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let dataURL = dataURL(forKey: key)
        
        queue.async {
            
            guard FileManager.default.fileExists(atPath: dataURL.path)
            else { return completion(.failure(RetrievalFailure())) }
            
            do {
                let data = try Data(contentsOf: dataURL)
                completion(.success(data))
            } catch {
                completion(.failure(RetrievalFailure()))
            }
        }
    }
    
    /// Error type indicating a failure to retrieve data from disk.
    struct RetrievalFailure: Error, Equatable {
        
        public init() {}
    }
}

private extension DiskDataStore {
    
    /// Computes the file URL for a given logical key.
    /// - Parameter key: The logical key to map.
    /// - Returns: A `URL` by appending the mapped file name to `storeDirectoryURL`.
    func dataURL(forKey key: String) -> URL {
        
        storeDirectoryURL.appendingPathComponent(keyMapper(key))
    }
}

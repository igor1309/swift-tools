// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: .packageName,
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .loaders,
        .stores,
    ],
    dependencies: [
        // .combineSchedulers,
        .customDump,
        // .tagged,
    ],
    targets: [
        .loaders,
        .loadersTests,
        .stores,
        .storesTests,
    ]
)

private extension Product {
    
    static let loaders: Product = .library(
        name: .loaders,
        targets: [
            .loaders,
        ]
    )
    
    static let stores: Product = .library(
        name: .stores,
        targets: [
            .stores,
        ]
    )
}

private extension Target {
    
    static let loaders: Target = .target(
        name: .loaders,
        dependencies: [],
        exclude: ["Remote/HTTPResponseDecoder/README.md"]
    )

    static let loadersTests: Target = .testTarget(
        name: .loadersTests,
        dependencies: [
            .customDump,
            .loaders,
        ]
    )
    
    static let stores: Target = .target(
        name: .stores,
        dependencies: []
    )

    static let storesTests: Target = .testTarget(
        name: .storesTests,
        dependencies: [
            .customDump,
            .stores,
        ]
    )
}

private extension Target.Dependency {

    static let loaders: Self = .target(name: .loaders)
    static let stores: Self = .target(name: .stores)
}

private extension String {
    
    static let packageName = "swift-tools"
    
    static let swiftTools = "SwiftTools"
    
    static let loaders = "Loaders"
    static let loadersTests = "LoadersTests"
    
    static let stores = "Stores"
    static let storesTests = "StoresTests"
}

// MARK: - Point-Free

private extension Package.Dependency {
    
    static let casePaths = Package.Dependency.package(
        url: .pointFreeGitHub + .case_paths,
        from: .init(0, 10, 1)
    )
    static let combineSchedulers = Package.Dependency.package(
        url: .pointFreeGitHub + .combine_schedulers,
        from: .init(0, 9, 1)
    )
    static let customDump = Package.Dependency.package(
        url: .pointFreeGitHub + .swift_custom_dump,
        from: .init(0, 10, 2)
    )
    static let identifiedCollections = Package.Dependency.package(
        url: .pointFreeGitHub + .swift_identified_collections,
        from: .init(0, 4, 1)
    )
    static let nonEmpty = Package.Dependency.package(
        url: .pointFreeGitHub + .swift_nonempty,
        from: .init(0, 5, 0)
    )
    static let snapshotTesting = Package.Dependency.package(
        url: .pointFreeGitHub + .swift_snapshot_testing,
        from: .init(1, 10, 0)
    )
    static let swiftUINavigation = Package.Dependency.package(
        url: .pointFreeGitHub + .swiftui_navigation,
        from: .init(0, 4, 5)
    )
    static let tagged = Package.Dependency.package(
        url: .pointFreeGitHub + .swift_tagged,
        from: .init(0, 7, 0)
    )
    static let shimmer = Package.Dependency.package(
        url: .swift_shimmer_path,
        exact: .init(1, 5, 0)
    )
    static let phoneNumberKit = Package.Dependency.package(
        url: .phoneNumberKit_path,
        exact: .init(3, 5, 8)
    )
}

private extension Target.Dependency {
    
    static let casePaths = product(
        name: .casePaths,
        package: .case_paths
    )
    static let combineSchedulers = product(
        name: .combineSchedulers,
        package: .combine_schedulers
    )
    static let customDump = product(
        name: .customDump,
        package: .swift_custom_dump
    )
    static let identifiedCollections = product(
        name: .identifiedCollections,
        package: .swift_identified_collections
    )
    static let nonEmpty = product(
        name: .nonEmpty,
        package: .swift_nonempty
    )
    static let snapshotTesting = product(
        name: .snapshotTesting,
        package: .swift_snapshot_testing
    )
    static let swiftUINavigation = product(
        name: .swiftUINavigation,
        package: .swiftui_navigation
    )
    static let tagged = product(
        name: .tagged,
        package: .swift_tagged
    )
    static let shimmer = product(
        name: .shimmer,
        package: .swift_shimmer
    )
    static let phoneNumberKit = product(
        name: .phoneNumberKit,
        package: .phoneNumberKit
    )
}

private extension String {
    
    static let pointFreeGitHub = "https://github.com/pointfreeco/"
    
    static let casePaths = "CasePaths"
    static let case_paths = "swift-case-paths"
    
    static let combineSchedulers = "CombineSchedulers"
    static let combine_schedulers = "combine-schedulers"
    
    static let customDump = "CustomDump"
    static let swift_custom_dump = "swift-custom-dump"
    
    static let identifiedCollections = "IdentifiedCollections"
    static let swift_identified_collections = "swift-identified-collections"
    
    static let nonEmpty = "NonEmpty"
    static let swift_nonempty = "swift-nonempty"
    
    static let snapshotTesting = "SnapshotTesting"
    static let swift_snapshot_testing = "swift-snapshot-testing"
    
    static let swiftUINavigation = "SwiftUINavigation"
    static let swiftui_navigation = "swiftui-navigation"
    
    static let tagged = "Tagged"
    static let swift_tagged = "swift-tagged"
    
    static let shimmer = "Shimmer"
    static let swift_shimmer = "SwiftUI-Shimmer"
    static let swift_shimmer_path = "https://github.com/markiv/SwiftUI-Shimmer"
    
    static let phoneNumberKit = "PhoneNumberKit"
    static let phoneNumberKit_path = "https://github.com/marmelroy/PhoneNumberKit"
}


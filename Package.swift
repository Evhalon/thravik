// swift-tools-version: 6.0
import PackageDescription

let strict: [SwiftSetting] = [.swiftLanguageMode(.v6)]

let package = Package(
    name: "Redent",
    platforms: [.macOS("26.0")],
    products: [
        .executable(name: "Redent", targets: ["Redent"])
    ],
    targets: [
        .target(name: "RedentKit", swiftSettings: strict),
        .target(name: "RedentCrypto", swiftSettings: strict),
        .target(name: "RedentOTPAuth", dependencies: ["RedentKit", "RedentCrypto"], swiftSettings: strict),
        .target(name: "RedentVault", dependencies: ["RedentKit"], swiftSettings: strict),
        .target(name: "RedentImport", dependencies: ["RedentKit"], swiftSettings: strict),
        .target(name: "RedentEngine", dependencies: ["RedentKit"], resources: [.process("Resources")], swiftSettings: strict),
        .target(name: "RedentDesign", swiftSettings: strict),
        .target(
            name: "RedentUI",
            dependencies: ["RedentKit", "RedentCrypto", "RedentOTPAuth", "RedentDesign"],
            swiftSettings: strict
        ),
        .executableTarget(
            name: "Redent",
            dependencies: ["RedentKit", "RedentUI", "RedentEngine", "RedentVault", "RedentOTPAuth", "RedentDesign", "RedentImport"],
            swiftSettings: strict
        ),
        .testTarget(name: "RedentCryptoTests", dependencies: ["RedentCrypto"], swiftSettings: strict),
        .testTarget(name: "RedentOTPAuthTests", dependencies: ["RedentOTPAuth", "RedentKit"], swiftSettings: strict),
        .testTarget(name: "RedentEngineTests", dependencies: ["RedentEngine", "RedentKit"], swiftSettings: strict),
        .testTarget(name: "RedentKitTests", dependencies: ["RedentKit"], swiftSettings: strict),
        .testTarget(name: "RedentVaultTests", dependencies: ["RedentVault", "RedentKit"], swiftSettings: strict),
        .testTarget(name: "RedentUITests", dependencies: ["RedentUI", "RedentKit"], swiftSettings: strict),
        .testTarget(name: "RedentImportTests", dependencies: ["RedentImport", "RedentKit"], swiftSettings: strict)
    ]
)

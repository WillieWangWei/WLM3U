// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WLM3U",
    platforms: [.iOS(.v10),],
    products: [.library(name: "WLM3U", targets: ["WLM3U"])],
    dependencies: [.package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.1.0"))],
    targets: [.target(name: "WLM3U", path: "Sources")]
)

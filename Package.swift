// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import PackageDescription

let package = Package(
  name: "GTMAppAuth",
  platforms: [
    .macOS(.v12),
    .iOS(.v15),
    .tvOS(.v15),
    .watchOS(.v9)
  ],
  products: [
    .library(
      name: "GTMAppAuth",
      targets: ["GTMAppAuth"]
    ),
    // In-memory fakes for packages that test against GTMAppAuth: KeychainHelperFake and AuthSessionStoreFake.
    .library(
      name: "GTMAppAuthTestHelpers",
      targets: ["GTMAppAuthTestHelpers"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/google/gtm-session-fetcher.git", "3.3.0" ..< "6.0.0"),
    .package(url: "https://github.com/openid/AppAuth-iOS.git", "3.0.0" ..< "4.0.0")
  ],
  targets: [
    .target(
      name: "GTMAppAuth",
      dependencies: [
        .product(name: "GTMSessionFetcherCore", package: "gtm-session-fetcher"),
        .product(name: "AppAuthCore", package: "AppAuth-iOS")
      ],
      path: "GTMAppAuth/Sources",
      resources: [.copy("Resources/PrivacyInfo.xcprivacy")],
      linkerSettings: [
        .linkedFramework("Security"),
      ]
    ),
    .target(
      name: "GTMAppAuthTestHelpers",
      dependencies: [
        "GTMAppAuth"
      ],
      path: "GTMAppAuth/Tests/Helpers/Fakes"
    ),
    // Test factories for AppAuth types and XCTest delegates used only by this package's own tests; not a product, because its @objc extensions would collide with downstream packages' own test categories.
    .target(
      name: "TestHelpers",
      dependencies: [
        .product(name: "AppAuthCore", package: "AppAuth-iOS"),
        "GTMAppAuth"
      ],
      path: "GTMAppAuth/Tests/Helpers",
      exclude: ["Fakes"]
    ),
    .testTarget(
      name: "GTMAppAuthTests",
      dependencies: [
        "GTMAppAuth",
        "TestHelpers",
        "GTMAppAuthTestHelpers"
      ],
      path: "GTMAppAuth/Tests/Unit"
    ),
    .testTarget(
      name: "swift-objc-interop-tests",
      dependencies: [
        .product(name: "AppAuthCore", package: "AppAuth-iOS"),
        "GTMAppAuth",
        "TestHelpers",
        "GTMAppAuthTestHelpers"
      ],
      path: "GTMAppAuth/Tests/ObjCIntegration"
    )
  ]
)

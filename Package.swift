// swift-tools-version:5.5
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
    .macOS(.v10_12),
    .iOS(.v10),
    .tvOS(.v10),
    .watchOS(.v6)
  ],
  products: [
    .library(
      name: "GTMAppAuth",
      targets: ["GTMAppAuth"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/google/gtm-session-fetcher.git", "2.1.0" ..< "4.0.0"),
    .package(url: "https://github.com/openid/AppAuth-iOS.git", "1.6.0" ..< "2.0.0")
  ],
  targets: [
    .target(
      name: "GTMAppAuth",
      dependencies: [
        .product(name: "GTMSessionFetcherCore", package: "gtm-session-fetcher"),
        .product(name: "AppAuthCore", package: "AppAuth-iOS")
      ],
      path: "GTMAppAuth/Sources",
      linkerSettings: [
        .linkedFramework("Security"),
      ]
    ),
    .target(
      name: "TestHelpers",
      dependencies: [
        .product(name: "AppAuthCore", package: "AppAuth-iOS"),
        "GTMAppAuth"
      ],
      path: "GTMAppAuth/Tests/Helpers"
    ),
    .testTarget(
      name: "GTMAppAuthTests",
      dependencies: [
        "GTMAppAuth",
        "TestHelpers"
      ],
      path: "GTMAppAuth/Tests/Unit"
    ),
    .testTarget(
      name: "swift-objc-interop-tests",
      dependencies: [
        .product(name: "AppAuthCore", package: "AppAuth-iOS"),
        "GTMAppAuth",
        "TestHelpers"
      ],
      path: "GTMAppAuth/Tests/ObjCIntegration"
    )
  ]
)

// swift-tools-version:5.1
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
        .iOS(.v9),
        .tvOS(.v9),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "GTMAppAuth",
            targets: ["GTMAppAuth"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/google/gtm-session-fetcher.git", "1.5.0" ..< "2.0.0"),
        .package(url: "https://github.com/openid/AppAuth-iOS.git", "1.4.0" ..< "2.0.0")
    ],
    targets: [
        .target(
            name: "GTMAppAuth",
            dependencies: [
                "GTMSessionFetcherCore",
                "AppAuthCore"
            ],
            path: "GTMAppAuth/Sources",
            sources: [
                ".",
                "iOS",
                "macOS"
            ],
            publicHeadersPath: "Public",
	    cSettings: [
                .headerSearchPath("../../"),
            ],
	    linkerSettings: [
                .linkedFramework("Security"),
	    ]
        ),
        .testTarget(
 	    name: "GTMAppAuth-UnitTests",
	    dependencies: [
	    	"GTMAppAuth",
	    ],
	    path: "GTMAppAuth/UnitTests",
	    linkerSettings: [
                .linkedFramework("Security"),
            ]
        )
    ]
)

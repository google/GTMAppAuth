/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
// Ensure that we import the correct dependency for both SPM and CocoaPods since
// the latter doesn't define separate Clang modules for subspecs
#if SWIFT_PACKAGE
import AppAuthCore
#else
import AppAuth
#endif
import XCTest
@testable import GTMAppAuth

/// A subclass of `AuthState` to use in tests.
@objc(GTMAuthorizationTestingHelper)
public class AuthorizationTestingHelper: AuthState {}

/// The delegate object passed to `AuthorizationTestingHelper`.
@objc(GTMAuthorizationTestDelegate)
public class AuthorizationTestDelegate: NSObject {
  /// The authorization passed back to this delegate.
  @objc public var passedAuthorization: AuthState?
  /// The request passed back to this delegate.
  @objc public var passedRequest: NSMutableURLRequest?
  /// The error passed back to this delegate.
  @objc public var passedError: NSError?
  /// The expectation needing fulfillment when this delegate receives its
  /// callback.
  @objc public let expectation: XCTestExpectation

  /// An initializer creating the delegate.
  ///
  /// - Parameter expectation: The `XCTestExpectation` to be fulfilled.
  @objc public init(expectation: XCTestExpectation) {
    self.expectation = expectation
  }

  /// The function serving as the callback for this delegate.
  ///
  /// - Parameters:
  ///   - authState: The `AuthState` authorizing the request.
  ///   - request: The request to be authorized.
  ///   - error: The `NSError?` should one arise during authorization.
  @objc public func authentication(
    _ authState: AuthState,
    request: NSMutableURLRequest,
    finishedWithError error: NSError?
  ) {
    passedAuthorization = authState
    passedRequest = request
    passedError = error

    expectation.fulfill()
  }
}

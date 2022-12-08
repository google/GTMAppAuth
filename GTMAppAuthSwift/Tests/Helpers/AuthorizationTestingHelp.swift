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
import AppAuthCore
import XCTest
@testable import GTMAppAuthSwift

/// A subclass of `GTMAppAuthFetcherAuthorization` to use in tests.
class AuthorizationTestingHelper: AuthState {}

/// The delegate object passed to `AuthorizationTestingHelper`.
class AuthorizationTestDelegate: NSObject {
  /// The authorization passed back to this delegate.
  var passedAuthorization: AuthState?
  /// The request passed back to this delegate.
  var passedRequest: NSMutableURLRequest?
  /// The error passed back to this delegate.
  var passedError: NSError?
  /// The expectation needing fulfillment when this delegate receives its
  /// callback.
  let expectation: XCTestExpectation

  /// An initializer creating the delegate.
  ///
  /// - Parameter expectation: The `XCTestExpectation` to be fulfilled.
  init(expectation: XCTestExpectation) {
    self.expectation = expectation
  }

  /// The function serving as the callback for this delegate.
  ///
  /// - Parameters:
  ///   - authState: The `AuthState` authorizing the request.
  ///   - request: The request to be authorized.
  ///   - error: The `NSError?` should one arise during authorization.
  @objc func authentication(
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

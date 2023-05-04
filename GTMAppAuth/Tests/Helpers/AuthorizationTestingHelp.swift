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
import GTMAppAuth

/// The delegate object passed to selector-based callback to authorize requests.
@objc(GTMAuthorizationTestDelegate)
public class AuthorizationTestDelegate: NSObject {
  /// The authorization passed back to this delegate.
  @objc public var passedAuthorization: AuthSession?
  /// The request passed back to this delegate.
  @objc public var passedRequest: NSMutableURLRequest?
  /// The error passed back to this delegate.
  @objc public var passedError: NSError?
  /// The expectation needing fulfillment when this delegate receives its callback.
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
  ///   - authSession: The `AuthSession` authorizing the request.
  ///   - request: The request to be authorized.
  ///   - error: The `NSError?` should one arise during authorization.
  @objc public func authentication(
    _ authSession: AuthSession,
    request: NSMutableURLRequest,
    finishedWithError error: NSError?
  ) {
    passedAuthorization = authSession
    passedRequest = request
    passedError = error

    expectation.fulfill()
  }
}

/// A testing helper that does not implement the update error method in `AuthSessionDelegate`.
@objc(GTMAuthSessionDelegateProvideMissingEMMErrorHandling)
public class AuthSessionDelegateProvideMissingEMMErrorHandling: NSObject, AuthSessionDelegate {
  /// The `AuthSession` to which this delegate was given.
  @objc public var originalAuthSession: AuthSession?

  /// Whether or not the delegate callback for additional refresh parameters was called.
  ///
  /// - Note: Defaults to `false`.
  @objc public var additionalRefreshParametersCalled = false

  /// Whether or not the delegate callback for authorization request failure was called.
  ///
  /// - Note: Defaults to `false`.
  @objc public var updatedErrorCalled = false

  /// The expected error from the delegate callback.
  @objc public let expectedError: NSError?

  @objc public init(originalAuthSession: AuthSession, expectedError: NSError? = nil) {
    self.originalAuthSession = originalAuthSession
    self.expectedError = expectedError
  }

  public func additionalTokenRefreshParameters(
    forAuthSession authSession: AuthSession
  ) -> [String : String]? {
    XCTAssertEqual(authSession, originalAuthSession)
    additionalRefreshParametersCalled = true
    return [:]
  }
}

/// A testing helper given to `AuthSession`'s `delegate` to verify delegate callbacks.
@objc(GTMAuthSessionDelegateProvider)
public class AuthSessionDelegateProvider: NSObject, AuthSessionDelegate {
  /// The `AuthSession` to which this delegate was given.
  @objc public var originalAuthSession: AuthSession?

  /// Whether or not the delegate callback for additional refresh parameters was called.
  ///
  /// - Note: Defaults to `false`.
  @objc public var additionalRefreshParametersCalled = false

  /// Whether or not the delegate callback for authorization request failure was called.
  ///
  /// - Note: Defaults to `false`.
  @objc public var updatedErrorCalled = false

  /// The expected error from the delegate callback.
  @objc public let expectedError: NSError?

  @objc public init(originalAuthSession: AuthSession, expectedError: NSError? = nil) {
    self.originalAuthSession = originalAuthSession
    self.expectedError = expectedError
  }

  public func additionalTokenRefreshParameters(
    forAuthSession authSession: AuthSession
  ) -> [String : String]? {
    XCTAssertEqual(authSession, originalAuthSession)
    additionalRefreshParametersCalled = true
    return [:]
  }

  public func updateError(
    forAuthSession authSession: AuthSession,
    originalError: Error,
    completion: @escaping (Error?) -> Void
  ) {
    XCTAssertEqual(authSession, originalAuthSession)
    updatedErrorCalled = true
    completion(expectedError)
  }
}

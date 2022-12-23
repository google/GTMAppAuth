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

import XCTest
// Ensure that we import the correct dependency for both SPM and CocoaPods since
// the latter doesn't define separate Clang modules for subspecs
#if SWIFT_PACKAGE
import AppAuthCore
import TestHelpers
#else
import AppAuth
#endif
@testable import GTMAppAuth

class AuthSessionTests: XCTestCase {
  typealias FetcherAuthError = AuthSession.Error
  private let expectationTimeout: TimeInterval = 5
  private let insecureFakeURL = URL(string: "http://fake.com")!
  private let secureFakeURL = URL(string: "https://fake.com")!
  private let authzEndpoint = URL(
    string: "https://accounts.google.com/o/oauth2/v2/auth"
  )!
  private let tokenEndpoint = URL(string: "https://www.googleapis.com/oauth2/v4/token")!
  private let alternativeTestKeychainItemName = "alternativeItemName"
  private let keychainHelper = KeychainHelperFake(keychainAttributes: [])
  private var keychainStore: KeychainStore {
    KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: keychainHelper
    )
  }
  private var authSession: AuthSession {
    AuthSession(
      authState: OIDAuthState.testInstance(),
      serviceProvider: TestingConstants.testServiceProvider,
      userID: TestingConstants.testUserID,
      userEmail: TestingConstants.testEmail,
      userEmailIsVerified: "y"
    )
  }

  override func tearDown() {
    super.tearDown()
    keychainHelper.passwordStore.removeAll()
    keychainHelper.useDataProtectionKeychain = false
  }

  func testAuthorizeSecureRequestWithCompletion() {
    let authorizeSecureRequestExpectation = expectation(
      description: "Authorize with completion expectation"
    )
    let authSession = AuthSession(
      authState: OIDAuthState.testInstance()
    )
    let request = NSMutableURLRequest(url: secureFakeURL)
    authSession.authorizeRequest(request) { error in
      XCTAssertNil(error)
      authorizeSecureRequestExpectation.fulfill()
    }
    XCTAssertTrue(authSession.isAuthorizingRequest(request as URLRequest))
    waitForExpectations(timeout: expectationTimeout)
    XCTAssertTrue(authSession.isAuthorizedRequest(request as URLRequest))
  }

  func testAuthorizeInsecureRequestWithCompletion() {
    let authorizeInsecureRequestExpectation = expectation(
      description: "Authorize with completion expectation"
    )
    let authSession = AuthSession(authState: OIDAuthState.testInstance())
    let insecureRequest = NSMutableURLRequest(url: insecureFakeURL)
    authSession.authorizeRequest(insecureRequest) { error in
      XCTAssertNotNil(error)
      guard let error = error as? FetcherAuthError else {
        return XCTFail(
          "Unexpected error type: \(String(describing: error.self))"
        )
      }
      XCTAssertEqual(
        error,
        FetcherAuthError.cannotAuthorizeRequest(insecureRequest as URLRequest)
      )
      authorizeInsecureRequestExpectation.fulfill()
    }
    XCTAssertTrue(
      authSession.isAuthorizingRequest(insecureRequest as URLRequest)
    )
    waitForExpectations(timeout: expectationTimeout)
    XCTAssertFalse(
      authSession.isAuthorizedRequest(insecureRequest as URLRequest)
    )
  }

  func testConfigurationForGoogle() {
    let configuration = AuthSession.configurationForGoogle()
    XCTAssertEqual(configuration.authorizationEndpoint, authzEndpoint)
    XCTAssertEqual(configuration.tokenEndpoint, tokenEndpoint)
    // We do not pass the below along to create upon initialization
    XCTAssertNil(configuration.issuer)
    XCTAssertNil(configuration.registrationEndpoint)
    XCTAssertNil(configuration.endSessionEndpoint)
    XCTAssertNil(configuration.discoveryDocument)
  }

  func testAuthorizeSecureRequestWithDelegate() {
    let delegateExpectation = expectation(
      description: "Delegate callback expectation"
    )
    let originalAuthorization = AuthorizationTestingHelper(
      authState: OIDAuthState.testInstance()
    )
    let testingDelegate = AuthorizationTestDelegate(
      expectation: delegateExpectation
    )

    let originalRequest = NSMutableURLRequest(url: self.secureFakeURL)
    originalAuthorization.authorizeRequest(
      originalRequest,
      delegate: testingDelegate,
      didFinish: #selector(
        AuthorizationTestDelegate.authentication(_:request:finishedWithError:)
      )
    )

    waitForExpectations(timeout: expectationTimeout)

    guard let receivedRequest = testingDelegate.passedRequest else {
      return XCTFail("Testing delegate did not receive the request")
    }
    XCTAssertEqual(originalRequest, receivedRequest)

    guard let receivedAuthorization = testingDelegate.passedAuthorization else {
      return XCTFail("Testing delegate did not receive the authorization")
    }
    XCTAssertEqual(originalAuthorization, receivedAuthorization)

    XCTAssertNil(testingDelegate.passedError)
  }

  func testAuthorizeInsecureRequestWithDelegate() {
    let delegateExpectation = expectation(
      description: "Delegate callback expectation"
    )
    let originalAuthorization = AuthorizationTestingHelper(
      authState: OIDAuthState.testInstance()
    )
    let testingDelegate = AuthorizationTestDelegate(
      expectation: delegateExpectation
    )

    let originalRequest = NSMutableURLRequest(url: self.insecureFakeURL)
    originalAuthorization.authorizeRequest(
      originalRequest,
      delegate: testingDelegate,
      didFinish: #selector(
        AuthorizationTestDelegate.authentication(_:request:finishedWithError:)
      )
    )

    waitForExpectations(timeout: expectationTimeout)

    guard let receivedRequest = testingDelegate.passedRequest else {
      return XCTFail("Testing delegate did not receive the request")
    }
    XCTAssertEqual(originalRequest, receivedRequest)

    guard let receivedAuthorization = testingDelegate.passedAuthorization else {
      return XCTFail("Testing delegate did not receive the authorization")
    }
    XCTAssertEqual(originalAuthorization, receivedAuthorization)

    guard let receivedError = testingDelegate
      .passedError as? FetcherAuthError else {
      return XCTFail("Testing delegate did not receive the error")
    }
    let expectedError = FetcherAuthError.cannotAuthorizeRequest(originalRequest as URLRequest)
    XCTAssertEqual(receivedError, expectedError)
  }

  func testStopAuthorization() {
    let authorizeSecureRequestExpectation = expectation(
      description: "Authorize with completion expectation"
    )
    let authSession = AuthSession(authState: OIDAuthState.testInstance())
    let request = NSMutableURLRequest(url: secureFakeURL)
    authSession.authorizeRequest(request) { error in
      XCTAssertNil(error)
      authorizeSecureRequestExpectation.fulfill()
    }
    XCTAssertTrue(authSession.isAuthorizingRequest(request as URLRequest))
    authSession.stopAuthorization()
    XCTAssertFalse(authSession.isAuthorizingRequest(request as URLRequest))
    authorizeSecureRequestExpectation.fulfill()
    waitForExpectations(timeout: expectationTimeout)
  }

  func testStopAuthorizationForRequest() {
    let authorizeSecureRequestExpectation = expectation(
      description: "Authorize with completion expectation"
    )
    let authSession = AuthSession(authState: OIDAuthState.testInstance())
    let request = NSMutableURLRequest(url: secureFakeURL)
    authSession.authorizeRequest(request) { error in
      XCTAssertNil(error)
      authorizeSecureRequestExpectation.fulfill()
    }
    XCTAssertTrue(authSession.isAuthorizingRequest(request as URLRequest))
    authSession.stopAuthorization(for: request as URLRequest)
    XCTAssertFalse(authSession.isAuthorizingRequest(request as URLRequest))
    authorizeSecureRequestExpectation.fulfill()
    waitForExpectations(timeout: expectationTimeout)
  }

  func testCanAuthorize() {
    let authSession = AuthSession(authState: OIDAuthState.testInstance())
    XCTAssertTrue(authSession.canAuthorize)
  }

  func testCannotAuthorize() {
    let testAuthState = OIDAuthState.testInstance(
      authorizationResponse: nil,
      tokenResponse: nil,
      registrationResponse: OIDRegistrationResponse.testInstance()
    )
    let authSession = AuthSession(authState: testAuthState)
    XCTAssertFalse(authSession.canAuthorize)
  }

  func testIsNotPrimeForRefresh() {
    let authSession = AuthSession(authState: OIDAuthState.testInstance())
    XCTAssertFalse(authSession.primeForRefresh())
  }

  func testIsPrimeForRefresh() {
    let testAuthState = OIDAuthState.testInstance(
      authorizationResponse: nil,
      tokenResponse: nil,
      registrationResponse: nil
    )
    let authSession = AuthSession(authState: testAuthState)
    XCTAssertTrue(authSession.primeForRefresh())
  }

  func testAuthorizationNSError() {
    let authorizeInsecureRequestExpectation = expectation(
      description: "Authorize with completion expectation"
    )
    let authSession = AuthSession(authState: OIDAuthState.testInstance())
    let insecureRequest = NSMutableURLRequest(url: insecureFakeURL)
    authSession.authorizeRequest(insecureRequest) { error in
      guard let nsError = error as NSError? else {
        return XCTFail("Could not cast error to `NSError`")
      }
      XCTAssertEqual(
        nsError.domain,
        AuthSession.Error.errorDomain
      )
      guard let errorRequest = nsError.userInfo["request"] as? URLRequest else {
        return XCTFail("No `request` key in `userInfo`")
      }
      XCTAssertEqual(errorRequest, insecureRequest as URLRequest)

      authorizeInsecureRequestExpectation.fulfill()
    }
    waitForExpectations(timeout: expectationTimeout)
  }

  func testUserEmailIsVerified() {
    let tAuthSession = AuthSession(authState: OIDAuthState.testInstance(), userEmailIsVerified: "t")
    let trueAuthSession = AuthSession(
      authState: OIDAuthState.testInstance(),
      userEmailIsVerified: "true"
    )
    let yAuthSession = AuthSession(authState: OIDAuthState.testInstance(), userEmailIsVerified: "y")
    let yesAuthSession = AuthSession(
      authState: OIDAuthState.testInstance(),
      userEmailIsVerified: "yes"
    )
    XCTAssertTrue(tAuthSession.userEmailIsVerified)
    XCTAssertTrue(trueAuthSession.userEmailIsVerified)
    XCTAssertTrue(yAuthSession.userEmailIsVerified)
    XCTAssertTrue(yesAuthSession.userEmailIsVerified)
  }

  // MARK: - Keychain Tests

  func testSaveAuthSession() throws {
    try keychainStore.save(authSession: authSession)
  }

  func testSaveAuthSessionForItemName() throws {
    try keychainStore.save(authSession: authSession, forItemName: alternativeTestKeychainItemName)
  }

  func testSaveAuthSessionThrows() {
    let emptyItemName = ""
    let expectedError = KeychainStore.Error.noService

    XCTAssertThrowsError(try keychainStore.save(
      authSession: authSession,
      forItemName: emptyItemName
    )) { error in
      XCTAssertEqual(error as? KeychainStore.Error, expectedError)
    }
  }

  func testRemoveAuthSession() throws {
    try keychainStore.save(authSession: authSession)
    try keychainStore.removeAuthSession(withItemName: TestingConstants.testKeychainItemName)
  }

  func testRemoveAuthSessionThrows() {
    do {
      try keychainStore.removeAuthSession(withItemName: TestingConstants.testKeychainItemName)
    } catch {
      guard let keychainError = error as? KeychainStore.Error else {
        return XCTFail("`error` should be of type `GTMAppAuthFetcherAuthorization.Error`")
      }
      XCTAssertEqual(
        keychainError,
        KeychainStore.Error.failedToDeletePasswordBecauseItemNotFound(
          itemName: TestingConstants.testKeychainItemName
        )
      )
    }
  }

  func testRetrieveAuthSession() throws {
    try keychainStore.save(authSession: authSession)
    let savedAuthSession = try keychainStore.retrieveAuthSession()
    XCTAssertEqual(savedAuthSession.authState.isAuthorized, authSession.authState.isAuthorized)
    XCTAssertEqual(savedAuthSession.serviceProvider, authSession.serviceProvider)
    XCTAssertEqual(savedAuthSession.userID, authSession.userID)
    XCTAssertEqual(savedAuthSession.userEmail, authSession.userEmail)
    XCTAssertEqual(savedAuthSession.userEmailIsVerified, authSession.userEmailIsVerified)
    XCTAssertFalse(keychainHelper.useDataProtectionKeychain)
  }

  func testRetrieveAuthSessionForItemName() throws {
    try keychainStore.save(authSession: authSession, forItemName: alternativeTestKeychainItemName)
    let retrievedAuthSession = try keychainStore.retrieveAuthSession(
      forItemName: alternativeTestKeychainItemName
    )
    XCTAssertEqual(retrievedAuthSession.authState.isAuthorized, authSession.authState.isAuthorized)
    XCTAssertEqual(retrievedAuthSession.serviceProvider, authSession.serviceProvider)
    XCTAssertEqual(retrievedAuthSession.userID, authSession.userID)
    XCTAssertEqual(retrievedAuthSession.userEmail, authSession.userEmail)
    XCTAssertEqual(retrievedAuthSession.userEmailIsVerified, authSession.userEmailIsVerified)
    XCTAssertFalse(keychainHelper.useDataProtectionKeychain)
  }

  func testRetrieveAuthSessionForMissingNameThrowsError() {
    let missingItemName = "missingItemName"
    do {
      _ = try keychainStore.retrieveAuthSession(forItemName: missingItemName)
    } catch {
      guard case
        .passwordNotFound(forItemName: let itemName) = error as? KeychainStore.Error else {
        return XCTFail(
          "`error` should be `GTMAppAuthFetcherAuthorization.Error.failedToRetrieveAuthorizationFromKeychain"
        )
      }
      XCTAssertEqual(itemName, missingItemName)
    }
  }
}

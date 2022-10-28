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
import AppAuthCore
@testable import GTMAppAuthSwift

class GTMAppAuthFetcherAuthorizationTest: XCTestCase {
  typealias FetcherAuthError = GTMAppAuthFetcherAuthorization.Error
  private let expectationTimeout: TimeInterval = 5
  private let insecureFakeURL = URL(string: "http://fake.com")!
  private let secureFakeURL = URL(string: "https://fake.com")!
  private let authzEndpoint = URL(
    string: "https://accounts.google.com/o/oauth2/v2/auth"
  )!
  private let tokenEndpoint = URL(
    string: "https://www.googleapis.com/oauth2/v4/token"
  )!
  private let testServiceProvider = "fooProvider"
  private let testUserID = "fooUser"
  private let testEmail = "foo@foo.com"
  private let testKeychainItemName = "testName"
  private let keychainHelper = KeychainHelperFake()
  private var keychain: GTMKeychain {
    GTMKeychain(keychainHelper: keychainHelper)
  }
  private var authorization: GTMAppAuthFetcherAuthorization {
    GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance(),
      serviceProvider: testServiceProvider,
      userID: testUserID,
      userEmail: testEmail,
      userEmailIsVerified: "y"
    )
  }

  override func setUp() {
    super.setUp()
    GTMAppAuthFetcherAuthorization.keychain = keychain
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
    let authorization = GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance()
    )
    let request = NSMutableURLRequest(url: secureFakeURL)
    authorization.authorizeRequest(request) { error in
      XCTAssertNil(error)
      authorizeSecureRequestExpectation.fulfill()
    }
    XCTAssertTrue(authorization.isAuthorizingRequest(request as URLRequest))
    waitForExpectations(timeout: expectationTimeout)
    XCTAssertTrue(authorization.isAuthorizedRequest(request as URLRequest))
  }

  func testAuthorizeInsecureRequestWithCompletion() {
    let authorizeInsecureRequestExpectation = expectation(
      description: "Authorize with completion expectation"
    )
    let authorization = GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance()
    )
    let insecureRequest = NSMutableURLRequest(url: insecureFakeURL)
    authorization.authorizeRequest(insecureRequest) { error in
      XCTAssertNotNil(error)
      guard let error = error as? FetcherAuthError else {
        return XCTFail(
          "Unexpected error type: \(String(describing: error.self))"
        )
      }
      XCTAssertEqual(
        error,
        FetcherAuthError.cannotAuthorizeRequest(insecureRequest)
      )
      authorizeInsecureRequestExpectation.fulfill()
    }
    XCTAssertTrue(
      authorization.isAuthorizingRequest(insecureRequest as URLRequest)
    )
    waitForExpectations(timeout: expectationTimeout)
    XCTAssertFalse(
      authorization.isAuthorizedRequest(insecureRequest as URLRequest)
    )
  }

  func testConfigurationForGoogle() {
    let configuration = GTMAppAuthFetcherAuthorization.configurationForGoogle()
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
    let expectedError = FetcherAuthError.cannotAuthorizeRequest(originalRequest)
    XCTAssertEqual(receivedError, expectedError)
  }

  func testStopAuthorization() {
    let authorizeSecureRequestExpectation = expectation(
      description: "Authorize with completion expectation"
    )
    let authorization = GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance()
    )
    let request = NSMutableURLRequest(url: secureFakeURL)
    authorization.authorizeRequest(request) { error in
      XCTAssertNil(error)
      authorizeSecureRequestExpectation.fulfill()
    }
    XCTAssertTrue(authorization.isAuthorizingRequest(request as URLRequest))
    authorization.stopAuthorization()
    XCTAssertFalse(authorization.isAuthorizingRequest(request as URLRequest))
    authorizeSecureRequestExpectation.fulfill()
    waitForExpectations(timeout: expectationTimeout)
  }

  func testStopAuthorizationForRequest() {
    let authorizeSecureRequestExpectation = expectation(
      description: "Authorize with completion expectation"
    )
    let authorization = GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance()
    )
    let request = NSMutableURLRequest(url: secureFakeURL)
    authorization.authorizeRequest(request) { error in
      XCTAssertNil(error)
      authorizeSecureRequestExpectation.fulfill()
    }
    XCTAssertTrue(authorization.isAuthorizingRequest(request as URLRequest))
    authorization.stopAuthorization(for: request as URLRequest)
    XCTAssertFalse(authorization.isAuthorizingRequest(request as URLRequest))
    authorizeSecureRequestExpectation.fulfill()
    waitForExpectations(timeout: expectationTimeout)
  }

  func testCanAuthorize() {
    let authorization = GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance()
    )
    XCTAssertTrue(authorization.canAuthorize)
  }

  func testCannotAuthorize() {
    let testAuthState = OIDAuthState.testInstance(
      authorizationResponse: nil,
      tokenResponse: nil,
      registrationResponse: OIDRegistrationResponse.testInstance()
    )
    let authorization = GTMAppAuthFetcherAuthorization(authState: testAuthState)
    XCTAssertFalse(authorization.canAuthorize)
  }

  func testIsNotPrimeForRefresh() {
    let authorization = GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance()
    )
    XCTAssertFalse(authorization.primeForRefresh())
  }

  func testIsPrimeForRefresh() {
    let testAuthState = OIDAuthState.testInstance(
      authorizationResponse: nil,
      tokenResponse: nil,
      registrationResponse: nil
    )
    let authorization = GTMAppAuthFetcherAuthorization(authState: testAuthState)
    XCTAssertTrue(authorization.primeForRefresh())
  }

  func testAuthorizatioNSError() {
    let authorizeInsecureRequestExpectation = expectation(
      description: "Authorize with completion expectation"
    )
    let authorization = GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance()
    )
    let insecureRequest = NSMutableURLRequest(url: insecureFakeURL)
    authorization.authorizeRequest(insecureRequest) { error in
      guard let nsError = error as? NSError else {
        return XCTFail("Could not cast error to `NSError`")
      }
      XCTAssertEqual(
        nsError.domain,
        GTMAppAuthFetcherAuthorization.Error.errorDomain
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
    let tAuthorization = GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance(),
      userEmailIsVerified: "t"
    )
    let trueAuthorization = GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance(),
      userEmailIsVerified: "true"
    )
    let yAuthorization = GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance(),
      userEmailIsVerified: "y"
    )
    let yesAuthorization = GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance(),
      userEmailIsVerified: "yes"
    )
    XCTAssertTrue(tAuthorization.userEmailIsVerified)
    XCTAssertTrue(trueAuthorization.userEmailIsVerified)
    XCTAssertTrue(yAuthorization.userEmailIsVerified)
    XCTAssertTrue(yesAuthorization.userEmailIsVerified)
  }

  // MARK: - Keychain Tests

  func testSaveAuthorization() throws {
    try GTMAppAuthFetcherAuthorization.save(
      authorization: authorization,
      with: testKeychainItemName
    )
    XCTAssertFalse(keychainHelper.useDataProtectionKeychain)
  }

  func testSaveAuthorizationUsingDataProtectionKeychain() throws {
    try GTMAppAuthFetcherAuthorization.save(
      authorization: authorization,
      with: testKeychainItemName,
      usingDataProtectionKeychain: true
    )
    XCTAssertTrue(keychainHelper.useDataProtectionKeychain)
  }

  func testSaveAuthorizationThrows() {
    let emptyItemName = ""
    let expectedError = GTMKeychainError.noService
    XCTAssertThrowsError(try GTMAppAuthFetcherAuthorization.save(
      authorization: authorization,
      with: emptyItemName
    )) { error in
      XCTAssertEqual(error as? GTMKeychainError, expectedError)
    }
  }

  func testRemoveAuthorization() throws {
    try GTMAppAuthFetcherAuthorization.save(
      authorization: authorization,
      with: testKeychainItemName
    )
    try GTMAppAuthFetcherAuthorization.removeAuthorization(for: testKeychainItemName)
    XCTAssertFalse(keychainHelper.useDataProtectionKeychain)
  }

  func testRemoveAuthorizationUsingDataProtectionKeychain() throws {
    try GTMAppAuthFetcherAuthorization.save(
      authorization: authorization,
      with: testKeychainItemName,
      usingDataProtectionKeychain: true
    )
    try GTMAppAuthFetcherAuthorization.removeAuthorization(
      for: testKeychainItemName,
      usingDataProtectionKeychain: true
    )
    XCTAssertTrue(keychainHelper.useDataProtectionKeychain)
  }

  func testRemoveAuthorizationThrows() {
    do {
      try GTMAppAuthFetcherAuthorization.removeAuthorization(for: testKeychainItemName)
      XCTAssertFalse(keychainHelper.useDataProtectionKeychain)
    } catch {
      guard let keychainError = error as? GTMKeychainError else {
        return XCTFail("`error` should be of type `GTMAppAuthFetcherAuthorization.Error`")
      }
      XCTAssertEqual(
        keychainError,
        GTMKeychainError.failedToDeletePasswordBecauseItemNotFound(
          itemName: Constants.testKeychainItemName
        )
      )
    }
  }

  func testReadAuthorization() throws {
    try GTMAppAuthFetcherAuthorization.save(
      authorization: authorization,
      with: testKeychainItemName
    )
    let savedAuth = try GTMAppAuthFetcherAuthorization.authorization(for: testKeychainItemName)
    XCTAssertEqual(savedAuth.authState.isAuthorized, authorization.authState.isAuthorized)
    XCTAssertEqual(savedAuth.serviceProvider, authorization.serviceProvider)
    XCTAssertEqual(savedAuth.userID, authorization.userID)
    XCTAssertEqual(savedAuth.userEmail, authorization.userEmail)
    XCTAssertEqual(savedAuth.userEmailIsVerified, authorization.userEmailIsVerified)
    XCTAssertFalse(keychainHelper.useDataProtectionKeychain)
  }

  func testReadAuthorizationUsingDataProtectionKeychain() throws {
    try GTMAppAuthFetcherAuthorization.save(
      authorization: authorization,
      with: testKeychainItemName,
      usingDataProtectionKeychain: true
    )
    let savedAuth = try GTMAppAuthFetcherAuthorization.authorization(
      for: testKeychainItemName,
      usingDataProtectionKeychain: true
    )
    XCTAssertEqual(savedAuth.authState.isAuthorized, authorization.authState.isAuthorized)
    XCTAssertEqual(savedAuth.serviceProvider, authorization.serviceProvider)
    XCTAssertEqual(savedAuth.userID, authorization.userID)
    XCTAssertEqual(savedAuth.userEmail, authorization.userEmail)
    XCTAssertEqual(savedAuth.userEmailIsVerified, authorization.userEmailIsVerified)
    XCTAssertTrue(keychainHelper.useDataProtectionKeychain)
  }

  func testReadAuthorizationThrowsError() {
    let missingItemName = "missingItemName"
    do {
      _ = try GTMAppAuthFetcherAuthorization.authorization(for: missingItemName)
    } catch {
      guard case
        .passwordNotFound(forItemName: let itemName) = error as? GTMKeychainError else {
        return XCTFail(
          "`error` should be `GTMAppAuthFetcherAuthorization.Error.failedToRetrieveAuthorizationFromKeychain"
        )
      }
      XCTAssertEqual(itemName, missingItemName)
    }
  }
}

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

class OAuth2AuthStateCompatibilityTests: XCTestCase {
  private let oauth2Compatibility = OAuth2AuthStateCompatibility()
  private lazy var testPersistenceString: String = {
    return "access_token=\(TestingConstants.testAccessToken)&refresh_token=\(TestingConstants.testRefreshToken)&scope=\(TestingConstants.testScope2)&serviceProvider=\(TestingConstants.testServiceProvider)&userEmail=foo%40foo.com&userEmailIsVerified=y&userID=\(TestingConstants.testUserID)"
  }()
  private let keychainHelper = KeychainHelperFake(keychainAttributes: [])
  private lazy var keychainStore: KeychainStore = {
    return KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: keychainHelper
    )
  }()
  private var expectedAuthorization: AuthState {
    AuthState(
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
  }

  func testPersistenceResponseString() {
    let response = OAuth2AuthStateCompatibility.persistenceResponseString(
      forAuthState: expectedAuthorization
    )
    guard let response = response else {
      return XCTFail("Response shouldn't be nil")
    }
    XCTAssertEqual(response, testPersistenceString)
  }

  func testSaveOAuth2Authorization() throws {
    try keychainStore.saveWithGTMOAuth2Format(forAuthorization: expectedAuthorization)
  }

  func testSaveGTMOAuth2AuthorizationThrowsError() {
    let emptyItemName = ""
    keychainStore.itemName = emptyItemName
    XCTAssertThrowsError(
      try keychainStore.saveWithGTMOAuth2Format(forAuthorization: expectedAuthorization)
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        KeychainStore.Error.noService
      )
    }
  }

  func testRemoveOAuth2Authorization() throws {
    try keychainStore.saveWithGTMOAuth2Format(forAuthorization: expectedAuthorization)
    try keychainStore.removeAuthState()
  }

  func testRemoveOAuth2AuthorizationThrowsError() {
    XCTAssertThrowsError(
      try keychainStore.removeAuthState()
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        .failedToDeletePasswordBecauseItemNotFound(itemName: TestingConstants.testKeychainItemName)
      )
    }
  }

  func testAuthorizeFromKeychainForName() throws {
    try keychainStore.saveWithGTMOAuth2Format(forAuthorization: expectedAuthorization)
    let testAuth = try keychainStore.retrieveAuthStateInGTMOAuth2Format(
      tokenURL: TestingConstants.testTokenURL,
      redirectURI: TestingConstants.testRedirectURI,
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientID
    )

    XCTAssertEqual(testAuth.authState.scope, expectedAuthorization.authState.scope)
    XCTAssertEqual(
      testAuth.authState.lastTokenResponse?.accessToken,
      expectedAuthorization.authState.lastTokenResponse?.accessToken
    )
    XCTAssertEqual(testAuth.authState.refreshToken, expectedAuthorization.authState.refreshToken)
    XCTAssertEqual(testAuth.authState.isAuthorized, expectedAuthorization.authState.isAuthorized)
    XCTAssertEqual(testAuth.serviceProvider, expectedAuthorization.serviceProvider)
    XCTAssertEqual(testAuth.userID, expectedAuthorization.userID)
    XCTAssertEqual(testAuth.userEmail, expectedAuthorization.userEmail)
    XCTAssertEqual(testAuth.userEmailIsVerified, expectedAuthorization.userEmailIsVerified)
    XCTAssertEqual(testAuth.canAuthorize, expectedAuthorization.canAuthorize)
  }

  func testAuthorizeFromKeychainForNameThrowsError() throws {
    try keychainStore.saveWithGTMOAuth2Format(forAuthorization: expectedAuthorization)
    let badRedirectURI = ""
    XCTAssertThrowsError(
      _ = try keychainStore.retrieveAuthStateInGTMOAuth2Format(
        tokenURL: TestingConstants.testTokenURL,
        redirectURI: badRedirectURI,
        clientID: TestingConstants.testClientID,
        clientSecret: TestingConstants.testClientSecret
      )
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        .failedToConvertRedirectURItoURL(badRedirectURI)
      )
    }
  }

  func testAuthorizeFromKeychainForPersistenceStringFailedWithBadURI() {
    let badURI = ""
    XCTAssertThrowsError(
      try oauth2Compatibility.authState(
        forPersistenceString: testPersistenceString,
        tokenURL: TestingConstants.testTokenURL,
        redirectURI: badURI,
        clientID: TestingConstants.testClientID,
        clientSecret: TestingConstants.testClientSecret
      )
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        .failedToConvertRedirectURItoURL(badURI)
      )
    }
  }

  func testAuthorizeFromKeychainForPersistenceString() throws {
    let testPersistAuth = try oauth2Compatibility.authState(
      forPersistenceString: testPersistenceString,
      tokenURL: TestingConstants.testTokenURL,
      redirectURI: TestingConstants.testRedirectURI,
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientSecret
    )

    XCTAssertEqual(testPersistAuth.authState.scope, expectedAuthorization.authState.scope)
    XCTAssertEqual(
      testPersistAuth.authState.lastTokenResponse?.accessToken,
      expectedAuthorization.authState.lastTokenResponse?.accessToken
    )
    XCTAssertEqual(testPersistAuth.authState.refreshToken, expectedAuthorization.authState.refreshToken)
    XCTAssertEqual(testPersistAuth.authState.isAuthorized, expectedAuthorization.authState.isAuthorized)
    XCTAssertEqual(testPersistAuth.serviceProvider, expectedAuthorization.serviceProvider)
    XCTAssertEqual(testPersistAuth.userID, expectedAuthorization.userID)
    XCTAssertEqual(testPersistAuth.userEmail, expectedAuthorization.userEmail)
    XCTAssertEqual(testPersistAuth.userEmailIsVerified, expectedAuthorization.userEmailIsVerified)
    XCTAssertEqual(testPersistAuth.canAuthorize, expectedAuthorization.canAuthorize)
  }

  func testAuthorizeFromKeychainMatchesForNameAndPersistenceString() throws {
    let expectedPersistAuth = try oauth2Compatibility.authState(
      forPersistenceString: testPersistenceString,
      tokenURL: TestingConstants.testTokenURL,
      redirectURI: TestingConstants.testRedirectURI,
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientSecret
    )
    try keychainStore.saveWithGTMOAuth2Format(forAuthorization: expectedPersistAuth)

    let testPersistAuth = try keychainStore.retrieveAuthStateInGTMOAuth2Format(
      tokenURL: TestingConstants.testTokenURL,
      redirectURI: TestingConstants.testRedirectURI,
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientSecret
    )

    XCTAssertEqual(testPersistAuth.authState.scope, expectedPersistAuth.authState.scope)
    XCTAssertEqual(
      testPersistAuth.authState.lastTokenResponse?.accessToken,
      expectedPersistAuth.authState.lastTokenResponse?.accessToken
    )
    XCTAssertEqual(testPersistAuth.authState.refreshToken, expectedPersistAuth.authState.refreshToken)
    XCTAssertEqual(testPersistAuth.authState.isAuthorized, expectedPersistAuth.authState.isAuthorized)
    XCTAssertEqual(testPersistAuth.serviceProvider, expectedPersistAuth.serviceProvider)
    XCTAssertEqual(testPersistAuth.userID, expectedPersistAuth.userID)
    XCTAssertEqual(testPersistAuth.userEmail, expectedPersistAuth.userEmail)
    XCTAssertEqual(testPersistAuth.userEmailIsVerified, expectedPersistAuth.userEmailIsVerified)
    XCTAssertEqual(testPersistAuth.canAuthorize, expectedPersistAuth.canAuthorize)
  }

  func testAuthorizeFromKeychainUsingGoogleOAuthProviderInformation() throws {
    let expectedPersistAuth = try oauth2Compatibility.authState(
      forPersistenceString: testPersistenceString,
      tokenURL: TestingConstants.testTokenURL,
      redirectURI: TestingConstants.testRedirectURI,
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientSecret
    )
    try keychainStore.saveWithGTMOAuth2Format(forAuthorization: expectedAuthorization)

    let testAuthorization = try keychainStore.retrieveAuthStateForGoogleInGTMOAuth2Format(
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientSecret
    )

    XCTAssertEqual(testAuthorization.authState.scope, expectedPersistAuth.authState.scope)
    XCTAssertEqual(
      testAuthorization.authState.lastTokenResponse?.accessToken,
      expectedPersistAuth.authState.lastTokenResponse?.accessToken
    )
    XCTAssertEqual(testAuthorization.authState.refreshToken, expectedPersistAuth.authState.refreshToken)
    XCTAssertEqual(testAuthorization.authState.isAuthorized, expectedPersistAuth.authState.isAuthorized)
    XCTAssertEqual(testAuthorization.serviceProvider, expectedPersistAuth.serviceProvider)
    XCTAssertEqual(testAuthorization.userID, expectedPersistAuth.userID)
    XCTAssertEqual(testAuthorization.userEmail, expectedPersistAuth.userEmail)
    XCTAssertEqual(testAuthorization.userEmailIsVerified, expectedPersistAuth.userEmailIsVerified)
    XCTAssertEqual(testAuthorization.canAuthorize, expectedPersistAuth.canAuthorize)
  }
}

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

class GTMOAuth2KeychainCompatibilityTests: XCTestCase {
  private lazy var testPersistenceString: String = {
    return "access_token=\(Constants.testAccessToken)&refresh_token=\(Constants.testRefreshToken)&scope=\(Constants.testScope2)&serviceProvider=\(Constants.testServiceProvider)&userEmail=foo%40foo.com&userEmailIsVerified=y&userID=\(Constants.testUserID)"
  }()
  private let keychainHelper = KeychainHelperFake()
  private lazy var keychain: GTMKeychain = {
    return GTMKeychain(keychainHelper: keychainHelper)
  }()
  private var expectedAuthorization: GTMAppAuthFetcherAuthorization {
    GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance(),
      serviceProvider: Constants.testServiceProvider,
      userID: Constants.testUserID,
      userEmail: Constants.testEmail,
      userEmailIsVerified: "y"
    )
  }

  override func setUp() {
    super.setUp()
    GTMOAuth2KeychainCompatibility.keychain = keychain
  }

  override func tearDown() {
    super.tearDown()
    keychainHelper.passwordStore.removeAll()
    keychainHelper.useDataProtectionKeychain = false
    GTMOAuth2KeychainCompatibility.keychain = nil
  }

  func testPersistenceResponseString() {
    let response = GTMOAuth2KeychainCompatibility.persistenceResponseStringForAuthorization(
      expectedAuthorization
    )
    guard let response = response else {
      return XCTFail("Response shouldn't be nil")
    }
    XCTAssertEqual(response, testPersistenceString)
  }

  func testSaveOAuth2Authorization() throws {
    try GTMOAuth2KeychainCompatibility.save(
      authorization: expectedAuthorization,
      for: Constants.testKeychainItemName
    )
  }

  func testRemoveOAuth2Authorization() throws {
    try GTMOAuth2KeychainCompatibility.save(
      authorization: expectedAuthorization,
      for: Constants.testKeychainItemName
    )
    try GTMOAuth2KeychainCompatibility.removeAuthorizationFromKeychain(for: Constants.testKeychainItemName)
  }

  func testRemoveOAuth2AuthorizationThrowsError() {
    XCTAssertThrowsError(
      try GTMOAuth2KeychainCompatibility.removeAuthorizationFromKeychain(for: "unsavedName")
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainWrapper.Error,
        .failedToDeletePasswordBecauseItemNotFound
      )
    }
  }

  func testAuthorizeFromKeychainForName() throws {
    try GTMOAuth2KeychainCompatibility.save(
      authorization: expectedAuthorization,
      for: Constants.testKeychainItemName
    )
    let testAuth = try GTMOAuth2KeychainCompatibility.authorizeFromKeychain(
      forName: Constants.testKeychainItemName,
      tokenURL: Constants.testTokenURL,
      redirectURI: Constants.testRedirectURI,
      clientID: Constants.testClientID,
      clientSecret: Constants.testClientSecret
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

  func testAuthorizeFromKeychainForPersistenceStringFailedWithBadURI() {
    let badURI = ""

    XCTAssertThrowsError(
      try GTMOAuth2KeychainCompatibility.authorizeFromKeychain(
        forPersistenceString: testPersistenceString,
        tokenURL: Constants.testTokenURL,
        redirectURI: badURI,
        clientID: Constants.testClientID,
        clientSecret: Constants.testClientSecret
      )
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? GTMOAuth2KeychainCompatibility.Error,
        .failedToConvertRedirectURItoURL(badURI)
      )
    }
  }

  func testAuthorizeFromKeychainForPersistenceString() throws {
    try GTMOAuth2KeychainCompatibility.save(
      authorization: expectedAuthorization,
      for: Constants.testKeychainItemName
    )

    let testPersistAuth = try GTMOAuth2KeychainCompatibility.authorizeFromKeychain(
      forPersistenceString: testPersistenceString,
      tokenURL: Constants.testTokenURL,
      redirectURI: Constants.testRedirectURI,
      clientID: Constants.testClientID,
      clientSecret: Constants.testClientSecret
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
    let expectedPersistAuth = try GTMOAuth2KeychainCompatibility.authorizeFromKeychain(
      forPersistenceString: testPersistenceString,
      tokenURL: Constants.testTokenURL,
      redirectURI: Constants.testRedirectURI,
      clientID: Constants.testClientID,
      clientSecret: Constants.testClientSecret
    )
    try GTMOAuth2KeychainCompatibility.save(
      authorization: expectedPersistAuth,
      for: Constants.testKeychainItemName
    )

    let testPersistAuth = try GTMOAuth2KeychainCompatibility.authorizeFromKeychain(
      forName: Constants.testKeychainItemName,
      tokenURL: Constants.testTokenURL,
      redirectURI: Constants.testRedirectURI,
      clientID: Constants.testClientID,
      clientSecret: Constants.testClientSecret
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
    let expectedPersistAuth = try GTMOAuth2KeychainCompatibility.authorizeFromKeychain(
      forPersistenceString: testPersistenceString,
      tokenURL: Constants.testTokenURL,
      redirectURI: Constants.testRedirectURI,
      clientID: Constants.testClientID,
      clientSecret: Constants.testClientSecret
    )
    try GTMOAuth2KeychainCompatibility.save(
      authorization: expectedPersistAuth,
      for: Constants.testKeychainItemName
    )

    let testAuthorization = try GTMOAuth2KeychainCompatibility.authForGoogleFromKeychain(
      for: Constants.testKeychainItemName,
      clientID: Constants.testClientID,
      clientSecret: Constants.testClientSecret
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

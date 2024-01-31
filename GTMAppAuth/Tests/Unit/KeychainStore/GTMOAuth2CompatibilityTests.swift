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

class GTMOAuth2CompatibilityTests: XCTestCase {
  private lazy var testPersistenceString: String = {
    return "access_token=\(TestingConstants.testAccessToken)&refresh_token=\(TestingConstants.testRefreshToken)&scope=\(TestingConstants.testScope2)&serviceProvider=\(TestingConstants.testServiceProvider)&userEmail=foo%40foo.com&userEmailIsVerified=y&userID=\(TestingConstants.testUserID)"
  }()
  private let keychainHelperWithAttributes = KeychainHelperFake(
    keychainAttributes: [.useDataProtectionKeychain,
                         .keychainAccessGroup(name: TestingConstants.testAccessGroup)]
  )
  private lazy var keychainStoreWithAttributes: KeychainStore = {
    return KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: keychainHelperWithAttributes
    )
  }()
  private let keychainHelper = KeychainHelperFake(keychainAttributes: [])
  private lazy var keychainStore: KeychainStore = {
    return KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: keychainHelper
    )
  }()
  private var expectedAuthSession: AuthSession {
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
  }

  func testPersistenceResponseString() {
    let response = GTMOAuth2Compatibility.persistenceResponseString(
      forAuthSession: expectedAuthSession
    )
    guard let response = response else {
      return XCTFail("Response shouldn't be nil")
    }
    XCTAssertEqual(response, testPersistenceString)
  }

  func testSaveOAuth2AuthSession() throws {
    try keychainStore.saveWithGTMOAuth2Format(forAuthSession: expectedAuthSession)
    // Save with keychain attributes to simulate macOS environment with
    // `kSecUseDataProtectionKeychain`
    try keychainStoreWithAttributes.saveWithGTMOAuth2Format(forAuthSession: expectedAuthSession)
  }

  func testSaveGTMOAuth2AuthSessionThrowsError() {
    let emptyItemName = ""
    keychainStore.itemName = emptyItemName
    XCTAssertThrowsError(
      try keychainStore.saveWithGTMOAuth2Format(forAuthSession: expectedAuthSession)
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        KeychainStore.Error.noService
      )
    }
  }

  func testRemoveOAuth2AuthSession() throws {
    try keychainStore.saveWithGTMOAuth2Format(forAuthSession: expectedAuthSession)
    let _ = try keychainStore.retrieveAuthSessionInGTMOAuth2Format(
      tokenURL: TestingConstants.testTokenURL,
      redirectURI: TestingConstants.testRedirectURI,
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientSecret
    )
    try keychainStore.removeAuthSession()
    XCTAssertThrowsError(try keychainStore.retrieveAuthSession()) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        KeychainStore.Error.passwordNotFound(forItemName: TestingConstants.testKeychainItemName)
      )
    }

    try keychainStoreWithAttributes.saveWithGTMOAuth2Format(forAuthSession: expectedAuthSession)
    let _ = try keychainStoreWithAttributes.retrieveAuthSessionInGTMOAuth2Format(
      tokenURL: TestingConstants.testTokenURL,
      redirectURI: TestingConstants.testRedirectURI,
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientSecret
    )
    try keychainStoreWithAttributes.removeAuthSession()
    XCTAssertThrowsError(try keychainStoreWithAttributes.retrieveAuthSession()) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        KeychainStore.Error.passwordNotFound(forItemName: TestingConstants.testKeychainItemName)
      )
    }
  }

  func testRemoveOAuth2AuthSessionhrowsError() {
    XCTAssertThrowsError(
      try keychainStore.removeAuthSession()
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        .failedToDeletePasswordBecauseItemNotFound(itemName: TestingConstants.testKeychainItemName)
      )
    }
  }

  func testAuthSessionFromKeychainForName() throws {
    try keychainStore.saveWithGTMOAuth2Format(forAuthSession: expectedAuthSession)
    let authSession = try keychainStore.retrieveAuthSessionInGTMOAuth2Format(
      tokenURL: TestingConstants.testTokenURL,
      redirectURI: TestingConstants.testRedirectURI,
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientID
    )

    XCTAssertEqual(authSession.authState.scope, expectedAuthSession.authState.scope)
    XCTAssertEqual(
      authSession.authState.lastTokenResponse?.accessToken,
      expectedAuthSession.authState.lastTokenResponse?.accessToken
    )
    XCTAssertEqual(authSession.authState.refreshToken, expectedAuthSession.authState.refreshToken)
    XCTAssertEqual(authSession.authState.isAuthorized, expectedAuthSession.authState.isAuthorized)
    XCTAssertEqual(authSession.serviceProvider, expectedAuthSession.serviceProvider)
    XCTAssertEqual(authSession.userID, expectedAuthSession.userID)
    XCTAssertEqual(authSession.userEmail, expectedAuthSession.userEmail)
    XCTAssertEqual(authSession.userEmailIsVerified, expectedAuthSession.userEmailIsVerified)
    XCTAssertEqual(authSession.canAuthorize, expectedAuthSession.canAuthorize)
  }
  
  func testAuthSessionFromKeychainWithAttributesForName() throws {
    try keychainStoreWithAttributes.saveWithGTMOAuth2Format(forAuthSession: expectedAuthSession)
    let authSession = try keychainStoreWithAttributes.retrieveAuthSessionInGTMOAuth2Format(
      tokenURL: TestingConstants.testTokenURL,
      redirectURI: TestingConstants.testRedirectURI,
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientID
    )

    XCTAssertEqual(authSession.authState.scope, expectedAuthSession.authState.scope)
    XCTAssertEqual(
      authSession.authState.lastTokenResponse?.accessToken,
      expectedAuthSession.authState.lastTokenResponse?.accessToken
    )
    XCTAssertEqual(authSession.authState.refreshToken, expectedAuthSession.authState.refreshToken)
    XCTAssertEqual(authSession.authState.isAuthorized, expectedAuthSession.authState.isAuthorized)
    XCTAssertEqual(authSession.serviceProvider, expectedAuthSession.serviceProvider)
    XCTAssertEqual(authSession.userID, expectedAuthSession.userID)
    XCTAssertEqual(authSession.userEmail, expectedAuthSession.userEmail)
    XCTAssertEqual(authSession.userEmailIsVerified, expectedAuthSession.userEmailIsVerified)
    XCTAssertEqual(authSession.canAuthorize, expectedAuthSession.canAuthorize)
  }

  func testAuthSessionFromKeychainForNameThrowsError() throws {
    try keychainStore.saveWithGTMOAuth2Format(forAuthSession: expectedAuthSession)
    let badRedirectURI = ""
    XCTAssertThrowsError(
      _ = try keychainStore.retrieveAuthSessionInGTMOAuth2Format(
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

  func testAuthSessionFromKeychainForPersistenceStringFailedWithBadURI() {
    let badURI = ""
    XCTAssertThrowsError(
      try GTMOAuth2Compatibility.authSession(
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

  func testAuthSessionFromKeychainForPersistenceString() throws {
    let authSession = try GTMOAuth2Compatibility.authSession(
      forPersistenceString: testPersistenceString,
      tokenURL: TestingConstants.testTokenURL,
      redirectURI: TestingConstants.testRedirectURI,
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientSecret
    )

    XCTAssertEqual(authSession.authState.scope, expectedAuthSession.authState.scope)
    XCTAssertEqual(
      authSession.authState.lastTokenResponse?.accessToken,
      expectedAuthSession.authState.lastTokenResponse?.accessToken
    )
    XCTAssertEqual(authSession.authState.refreshToken, expectedAuthSession.authState.refreshToken)
    XCTAssertEqual(authSession.authState.isAuthorized, expectedAuthSession.authState.isAuthorized)
    XCTAssertEqual(authSession.serviceProvider, expectedAuthSession.serviceProvider)
    XCTAssertEqual(authSession.userID, expectedAuthSession.userID)
    XCTAssertEqual(authSession.userEmail, expectedAuthSession.userEmail)
    XCTAssertEqual(authSession.userEmailIsVerified, expectedAuthSession.userEmailIsVerified)
    XCTAssertEqual(authSession.canAuthorize, expectedAuthSession.canAuthorize)
  }

  func testAuthSessionFromKeychainMatchesForNameAndPersistenceString() throws {
    let expectedPersistAuth = try GTMOAuth2Compatibility.authSession(
      forPersistenceString: testPersistenceString,
      tokenURL: TestingConstants.testTokenURL,
      redirectURI: TestingConstants.testRedirectURI,
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientSecret
    )
    try keychainStore.saveWithGTMOAuth2Format(forAuthSession: expectedPersistAuth)

    let testPersistAuth = try keychainStore.retrieveAuthSessionInGTMOAuth2Format(
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
    XCTAssertEqual(
      testPersistAuth.authState.refreshToken,
      expectedPersistAuth.authState.refreshToken
    )
    XCTAssertEqual(
      testPersistAuth.authState.isAuthorized,
      expectedPersistAuth.authState.isAuthorized
    )
    XCTAssertEqual(testPersistAuth.serviceProvider, expectedPersistAuth.serviceProvider)
    XCTAssertEqual(testPersistAuth.userID, expectedPersistAuth.userID)
    XCTAssertEqual(testPersistAuth.userEmail, expectedPersistAuth.userEmail)
    XCTAssertEqual(testPersistAuth.userEmailIsVerified, expectedPersistAuth.userEmailIsVerified)
    XCTAssertEqual(testPersistAuth.canAuthorize, expectedPersistAuth.canAuthorize)
  }

  func testAuthSessionFromKeychainUsingGoogleOAuthProviderInformation() throws {
    let expectedPersistAuth = try GTMOAuth2Compatibility.authSession(
      forPersistenceString: testPersistenceString,
      tokenURL: TestingConstants.testTokenURL,
      redirectURI: TestingConstants.testRedirectURI,
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientSecret
    )
    try keychainStore.saveWithGTMOAuth2Format(forAuthSession: expectedAuthSession)

    let testAuthSession = try keychainStore.retrieveAuthSessionForGoogleInGTMOAuth2Format(
      clientID: TestingConstants.testClientID,
      clientSecret: TestingConstants.testClientSecret
    )

    XCTAssertEqual(testAuthSession.authState.scope, expectedPersistAuth.authState.scope)
    XCTAssertEqual(
      testAuthSession.authState.lastTokenResponse?.accessToken,
      expectedPersistAuth.authState.lastTokenResponse?.accessToken
    )
    XCTAssertEqual(testAuthSession.authState.refreshToken, expectedPersistAuth.authState.refreshToken)
    XCTAssertEqual(testAuthSession.authState.isAuthorized, expectedPersistAuth.authState.isAuthorized)
    XCTAssertEqual(testAuthSession.serviceProvider, expectedPersistAuth.serviceProvider)
    XCTAssertEqual(testAuthSession.userID, expectedPersistAuth.userID)
    XCTAssertEqual(testAuthSession.userEmail, expectedPersistAuth.userEmail)
    XCTAssertEqual(testAuthSession.userEmailIsVerified, expectedPersistAuth.userEmailIsVerified)
    XCTAssertEqual(testAuthSession.canAuthorize, expectedPersistAuth.canAuthorize)
  }
}

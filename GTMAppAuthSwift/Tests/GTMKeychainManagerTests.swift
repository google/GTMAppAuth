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

class GTMKeychainManagerTests: XCTestCase {
  private let testServiceProvider = "fooProvider"
  private let testUserID = "fooUser"
  private let testEmail = "foo@foo.com"
  private let testKeychainItemName = "testName"
  private let keychainHelper = KeychainHelperFake()
  private var keychainManager: GTMKeychainManager {
    GTMKeychainManager(keychainHelper: keychainHelper)
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

  override func tearDown() {
    super.tearDown()
    keychainHelper.passwordStore.removeAll()
    keychainHelper.useDataProtectionKeychain = false
  }

  func testSaveAuthorization() throws {
    try keychainManager.save(authorization: authorization, with: testKeychainItemName)
    XCTAssertFalse(keychainHelper.useDataProtectionKeychain)
  }

  func testSaveAuthorizationUsingDataProtectionKeychain() throws {
    try keychainManager.save(
      authorization: authorization,
      with: testKeychainItemName,
      usingDataProtectionKeychain: true
    )
    XCTAssertTrue(keychainHelper.useDataProtectionKeychain)
  }

  func testRemoveAuthorization() throws {
    try keychainManager.save(authorization: authorization, with: testKeychainItemName)
    try keychainManager.removeAuthorization(for: testKeychainItemName)
    XCTAssertFalse(keychainHelper.useDataProtectionKeychain)
  }

  func testRemoveAuthorizationUsingDataProtectionKeychain() throws {
    try keychainManager.save(
      authorization: authorization,
      with: testKeychainItemName,
      usingDataProtectionKeychain: true
    )
    try keychainManager.removeAuthorization(
      for: testKeychainItemName,
      usingDataProtectionKeychain: true
    )
    XCTAssertTrue(keychainHelper.useDataProtectionKeychain)
  }

  func testRemoveAuthorizationThrows() {
    do {
      try keychainManager.removeAuthorization(for: testKeychainItemName)
      XCTAssertFalse(keychainHelper.useDataProtectionKeychain)
    } catch {
      guard let keychainError = error as? KeychainWrapper.Error else {
        return XCTFail("`error` should be of type `GTMKeychainManager.Error`")
      }
      XCTAssertEqual(keychainError, KeychainWrapper.Error.failedToDeletePassword)
    }
  }

  func testReadAuthorization() throws {
    try keychainManager.save(authorization: authorization, with: testKeychainItemName)
    let savedAuth = try keychainManager.authorization(for: testKeychainItemName)
    XCTAssertEqual(savedAuth.authState.isAuthorized, authorization.authState.isAuthorized)
    XCTAssertEqual(savedAuth.serviceProvider, authorization.serviceProvider)
    XCTAssertEqual(savedAuth.userID, authorization.userID)
    XCTAssertEqual(savedAuth.userEmail, authorization.userEmail)
    XCTAssertEqual(savedAuth.userEmailIsVerified, authorization.userEmailIsVerified)
    XCTAssertFalse(keychainHelper.useDataProtectionKeychain)
  }

  func testReadAuthorizationUsingDataProtectionKeychain() throws {
    try keychainManager.save(
      authorization: authorization,
      with: testKeychainItemName,
      usingDataProtectionKeychain: true
    )
    let savedAuth = try keychainManager.authorization(
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
    do {
      _ = try keychainManager.authorization(for: "missingItemName")
    } catch {
      guard let keychainError = error as? GTMKeychainManager.Error else {
        return XCTFail("`error` should be of type `GTMKeychainManager.Error")
      }
      XCTAssertEqual(keychainError, GTMKeychainManager.Error.failedToRetrieveAuthorizationFromKeychain)
    }
  }
}

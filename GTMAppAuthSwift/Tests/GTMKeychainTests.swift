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

class GTMKeychainTests: XCTestCase {
  private let keychainHelper = KeychainHelperFake()
  private lazy var keychain: GTMKeychain = {
    return GTMKeychain(
      credentialItemName: Constants.testKeychainItemName,
      keychainHelper: keychainHelper
    )
  }()
  private var authorization: GTMAppAuthFetcherAuthorization {
    GTMAppAuthFetcherAuthorization(
      authState: OIDAuthState.testInstance(),
      serviceProvider: Constants.testServiceProvider,
      userID: Constants.testUserID,
      userEmail: Constants.testEmail,
      userEmailIsVerified: "y"
    )
  }

  override func tearDown() {
    super.tearDown()
    keychainHelper.passwordStore.removeAll()
  }

  func testSaveAndReadAuthorization() throws {
    try keychain.save(authorization: authorization)
    let expectedAuthorization = try keychain.authorization(
      forItemName: Constants.testKeychainItemName
    )
    XCTAssertEqual(
      expectedAuthorization.authState.isAuthorized,
      authorization.authState.isAuthorized
    )
    XCTAssertEqual(expectedAuthorization.serviceProvider, authorization.serviceProvider)
    XCTAssertEqual(expectedAuthorization.userID, authorization.userID)
    XCTAssertEqual(expectedAuthorization.userEmail, authorization.userEmail)
    XCTAssertEqual(expectedAuthorization.userEmailIsVerified, authorization.userEmailIsVerified)
  }

  func testReadAuthorizationWithItemNameGivenToKeychain() throws {
    try keychain.save(authorization: authorization)
    let expectedAuthorization = try keychain.retrieveAuthorization()
    XCTAssertEqual(
      expectedAuthorization.authState.isAuthorized,
      authorization.authState.isAuthorized
    )
    XCTAssertEqual(expectedAuthorization.serviceProvider, authorization.serviceProvider)
    XCTAssertEqual(expectedAuthorization.userID, authorization.userID)
    XCTAssertEqual(expectedAuthorization.userEmail, authorization.userEmail)
    XCTAssertEqual(expectedAuthorization.userEmailIsVerified, authorization.userEmailIsVerified)
  }

  func testReadAuthorizationForItemName() throws {
    let anotherItemName = "anotherItemName"
    try keychain.save(authorization: authorization, forItemName: anotherItemName)
    let expectedAuthorization = try keychain.authorization(forItemName: anotherItemName)

    XCTAssertEqual(
      expectedAuthorization.authState.isAuthorized,
      authorization.authState.isAuthorized
    )
    XCTAssertEqual(expectedAuthorization.serviceProvider, authorization.serviceProvider)
    XCTAssertEqual(expectedAuthorization.userID, authorization.userID)
    XCTAssertEqual(expectedAuthorization.userEmail, authorization.userEmail)
    XCTAssertEqual(expectedAuthorization.userEmailIsVerified, authorization.userEmailIsVerified)
  }

  func testSaveAuthorizationForItemName() throws {
    let anotherItemName = "anotherItemName"
    try keychain.save(authorization: authorization, forItemName: anotherItemName)
    let expectedAuthorization = try keychain.authorization(
      forItemName: anotherItemName
    )
    XCTAssertEqual(
      expectedAuthorization.authState.isAuthorized,
      authorization.authState.isAuthorized
    )
    XCTAssertEqual(expectedAuthorization.serviceProvider, authorization.serviceProvider)
    XCTAssertEqual(expectedAuthorization.userID, authorization.userID)
    XCTAssertEqual(expectedAuthorization.userEmail, authorization.userEmail)
    XCTAssertEqual(expectedAuthorization.userEmailIsVerified, authorization.userEmailIsVerified)
  }

  func testSetPasswordNoService() {
    XCTAssertThrowsError(
      try keychain.save(authorization: authorization, forItemName: "")
    ) { thrownError in
      XCTAssertEqual(thrownError as? GTMKeychainError, .noService)
    }
  }

  func testReadPasswordNoService() throws {
    try keychain.save(authorization: authorization)

    XCTAssertThrowsError(try keychain.authorization(forItemName: "")) { thrownError in
      XCTAssertEqual(thrownError as? GTMKeychainError, .noService)
    }
  }

  func testRemovePasswordNoService() throws {
    try keychain.save(authorization: authorization)

    XCTAssertThrowsError(try keychain.removeAuthorization(withItemName: "")) { thrownError in
      XCTAssertEqual(thrownError as? GTMKeychainError, .noService)
    }
  }

  func testFailedToDeletePasswordError() {
    XCTAssertThrowsError(try keychain.removeAuthorization()) { thrownError in
      XCTAssertEqual(
        thrownError as? GTMKeychainError,
        .failedToDeletePasswordBecauseItemNotFound(itemName: Constants.testKeychainItemName)
      )
    }
  }

  func testPasswordNotFoundError() {
    XCTAssertThrowsError(
      try keychain.authorization(forItemName: Constants.testKeychainItemName)
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? GTMKeychainError,
        .passwordNotFound(forItemName: Constants.testKeychainItemName)
      )
    }
  }
}


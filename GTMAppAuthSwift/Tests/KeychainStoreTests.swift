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

class KeychainStoreTests: XCTestCase {
  private let keychainHelper = KeychainHelperFake()
  private lazy var keychainStore: KeychainStore = {
    return KeychainStore(
      itemName: Constants.testKeychainItemName,
      keychainHelper: keychainHelper
    )
  }()
  private var authState: AuthState {
    AuthState(
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
    try keychainStore.save(authState: authState)
    let expectedAuthorization = try keychainStore.retrieveAuthState(
      forItemName: Constants.testKeychainItemName
    )
    XCTAssertEqual(
      expectedAuthorization.authState.isAuthorized,
      authState.authState.isAuthorized
    )
    XCTAssertEqual(expectedAuthorization.serviceProvider, authState.serviceProvider)
    XCTAssertEqual(expectedAuthorization.userID, authState.userID)
    XCTAssertEqual(expectedAuthorization.userEmail, authState.userEmail)
    XCTAssertEqual(expectedAuthorization.userEmailIsVerified, authState.userEmailIsVerified)
  }

  func testReadAuthorizationWithItemNameGivenToKeychain() throws {
    try keychainStore.save(authState: authState)
    let expectedAuthorization = try keychainStore.retrieveAuthState()
    XCTAssertEqual(
      expectedAuthorization.authState.isAuthorized,
      authState.authState.isAuthorized
    )
    XCTAssertEqual(expectedAuthorization.serviceProvider, authState.serviceProvider)
    XCTAssertEqual(expectedAuthorization.userID, authState.userID)
    XCTAssertEqual(expectedAuthorization.userEmail, authState.userEmail)
    XCTAssertEqual(expectedAuthorization.userEmailIsVerified, authState.userEmailIsVerified)
  }

  func testReadAuthorizationForItemName() throws {
    let anotherItemName = "anotherItemName"
    try keychainStore.save(authState: authState, forItemName: anotherItemName)
    let expectedAuthorization = try keychainStore.retrieveAuthState(forItemName: anotherItemName)

    XCTAssertEqual(
      expectedAuthorization.authState.isAuthorized,
      authState.authState.isAuthorized
    )
    XCTAssertEqual(expectedAuthorization.serviceProvider, authState.serviceProvider)
    XCTAssertEqual(expectedAuthorization.userID, authState.userID)
    XCTAssertEqual(expectedAuthorization.userEmail, authState.userEmail)
    XCTAssertEqual(expectedAuthorization.userEmailIsVerified, authState.userEmailIsVerified)
  }

  func testSaveAuthorizationForItemName() throws {
    let anotherItemName = "anotherItemName"
    try keychainStore.save(authState: authState, forItemName: anotherItemName)
    let expectedAuthorization = try keychainStore.retrieveAuthState(forItemName: anotherItemName)
    XCTAssertEqual(
      expectedAuthorization.authState.isAuthorized,
      authState.authState.isAuthorized
    )
    XCTAssertEqual(expectedAuthorization.serviceProvider, authState.serviceProvider)
    XCTAssertEqual(expectedAuthorization.userID, authState.userID)
    XCTAssertEqual(expectedAuthorization.userEmail, authState.userEmail)
    XCTAssertEqual(expectedAuthorization.userEmailIsVerified, authState.userEmailIsVerified)
  }

  func testSetPasswordNoService() {
    XCTAssertThrowsError(
      try keychainStore.save(authState: authState, forItemName: "")
    ) { thrownError in
      XCTAssertEqual(thrownError as? KeychainStore.Error, .noService)
    }
  }

  func testReadPasswordNoService() throws {
    try keychainStore.save(authState: authState)

    XCTAssertThrowsError(try keychainStore.retrieveAuthState(forItemName: "")) { thrownError in
      XCTAssertEqual(thrownError as? KeychainStore.Error, .noService)
    }
  }

  func testRemovePasswordNoService() throws {
    try keychainStore.save(authState: authState)

    XCTAssertThrowsError(try keychainStore.removeAuthState(withItemName: "")) { thrownError in
      XCTAssertEqual(thrownError as? KeychainStore.Error, .noService)
    }
  }

  func testFailedToDeletePasswordError() {
    XCTAssertThrowsError(try keychainStore.removeAuthState()) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        .failedToDeletePasswordBecauseItemNotFound(itemName: Constants.testKeychainItemName)
      )
    }
  }

  func testPasswordNotFoundError() {
    XCTAssertThrowsError(
      try keychainStore.retrieveAuthState(forItemName: Constants.testKeychainItemName)
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        .passwordNotFound(forItemName: Constants.testKeychainItemName)
      )
    }
  }
}


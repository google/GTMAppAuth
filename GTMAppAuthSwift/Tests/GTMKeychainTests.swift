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
@testable import GTMAppAuthSwift

class GTMKeychainTests: XCTestCase {
  private let keychainHelper = KeychainHelperFake()
  private lazy var keychain: GTMKeychain = {
    return GTMKeychain(keychainHelper: keychainHelper)
  }()

  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
    keychainHelper.passwordStore.removeAll()
  }

  func testStringPassword() throws {
    try keychain.save(password: Constants.testPassword, forItemName: Constants.testKeychainItemName)
    let expectedPassword = try keychain.password(forItemName: Constants.testKeychainItemName)
    XCTAssertEqual(expectedPassword, Constants.testPassword)
    try keychain.removePasswordFromKeychain(withItemName: Constants.testKeychainItemName)
  }

  func testDataPassword() throws {
    guard let passwordData = Constants.testPassword.data(using: .utf8) else {
      return XCTFail("Could not convert `testPassword` into `Data`.")
    }
    try keychain.save(passwordData: passwordData, forItemName: Constants.testKeychainItemName)
    let expectedPasswordData = try keychain.passwordData(forItemName: Constants.testKeychainItemName)
    XCTAssertEqual(expectedPasswordData, Constants.testPassword.data(using: .utf8)!)
    try keychain.removePasswordFromKeychain(withItemName: Constants.testKeychainItemName)
  }

  func testSetPasswordNoService() {
    XCTAssertThrowsError(
      try keychain.save(password: Constants.testPassword, forItemName: "")
    ) { thrownError in
      XCTAssertEqual(thrownError as? GTMKeychainError, .noService)
    }
  }

  func testReadPasswordNoService() throws {
    try keychain.save(password: Constants.testPassword, forItemName: Constants.testKeychainItemName)

    XCTAssertThrowsError(try keychain.password(forItemName: "")) { thrownError in
      XCTAssertEqual(thrownError as? GTMKeychainError, .noService)
    }
  }

  func testRemovePasswordNoService() throws {
    try keychain.save(password: Constants.testPassword, forItemName: Constants.testKeychainItemName)

    XCTAssertThrowsError(try keychain.removePasswordFromKeychain(withItemName: "")) { thrownError in
      XCTAssertEqual(thrownError as? GTMKeychainError, .noService)
    }
  }

  func testFailedToDeletePasswordError() {
    XCTAssertThrowsError(try keychain.removePasswordFromKeychain(
      withItemName: Constants.testKeychainItemName
    )) { thrownError in
      XCTAssertEqual(
        thrownError as? GTMKeychainError,
        .failedToDeletePasswordBecauseItemNotFound(itemName: Constants.testKeychainItemName)
      )
    }
  }

  func testPasswordNotFoundError() {
    XCTAssertThrowsError(
      try keychain.password(forItemName: Constants.testKeychainItemName)
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? GTMKeychainError,
        .passwordNotFound(forItemName: Constants.testKeychainItemName)
      )
    }
  }
}


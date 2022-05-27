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
  private let testPassword = "foo"
  private let testKeychainItemName = "testName"
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
    try keychain.save(password: testPassword, forName: testKeychainItemName)
    let expectedPassword = try keychain.password(forName: testKeychainItemName)
    XCTAssertEqual(expectedPassword, testPassword)
    try keychain.removePasswordFromKeychain(forName: testKeychainItemName)
  }

  func testDataPassword() throws {
    guard let passwordData = testPassword.data(using: .utf8) else {
      return XCTFail("Could not convert `testPassword` into `Data`.")
    }
    try keychain.save(passwordData: passwordData, forName: testKeychainItemName)
    let expectedPasswordData = try keychain.passwordData(forName: testKeychainItemName)
    XCTAssertEqual(expectedPasswordData, testPassword.data(using: .utf8)!)
    try keychain.removePasswordFromKeychain(forName: testKeychainItemName)
  }

  func testSetPasswordNoService() {
    XCTAssertThrowsError(try keychain.save(password: testPassword, forName: "")) { thrownError in
      XCTAssertEqual(thrownError as? KeychainWrapper.Error, .noService)
    }
  }

  func testReadPasswordNoService() throws {
    try keychain.save(password: testPassword, forName: testKeychainItemName)

    XCTAssertThrowsError(try keychain.password(forName: "")) { thrownError in
      XCTAssertEqual(thrownError as? KeychainWrapper.Error, .noService)
    }
  }

  func testRemovePasswordNoService() throws {
    try keychain.save(password: testPassword, forName: testKeychainItemName)

    XCTAssertThrowsError(try keychain.removePasswordFromKeychain(forName: "")) { thrownError in
      XCTAssertEqual(thrownError as? KeychainWrapper.Error, .noService)
    }
  }

  func testFailedToDeletePasswordError() {
    XCTAssertThrowsError(try keychain.removePasswordFromKeychain(
      forName: testKeychainItemName
    )) { thrownError in
      XCTAssertEqual(thrownError as? KeychainWrapper.Error, .failedToDeletePassword)
    }
  }

  func testPasswordNotFoundError() {
    XCTAssertThrowsError(try keychain.password(forName: testKeychainItemName)) { thrownError in
      XCTAssertEqual(thrownError as? KeychainWrapper.Error, .passwordNotFound)
    }
  }
}

fileprivate class KeychainHelperFake: KeychainHelper {
  var useDataProtectionKeychain = false
  var passwordStore = [String: Data]()
  let accountName = "OauthTest"

  func password(service: String) throws -> String {
    guard !service.isEmpty else { throw KeychainWrapper.Error.noService }

    let passwordData = try passwordData(service: service)
    guard let password = String(data: passwordData, encoding: .utf8) else {
      throw KeychainWrapper.Error.passwordNotFound
    }
    return password
  }

  func passwordData(service: String) throws -> Data {
    guard !service.isEmpty else { throw KeychainWrapper.Error.noService }

    guard let passwordData = passwordStore[service + accountName] else {
      throw KeychainWrapper.Error.passwordNotFound
    }
    return passwordData
  }

  func removePassword(service: String) throws {
    guard !service.isEmpty else { throw KeychainWrapper.Error.noService }

    guard let _ = passwordStore.removeValue(forKey: service + accountName) else {
      throw KeychainWrapper.Error.failedToDeletePassword
    }
  }

  func setPassword(
    _ password: String,
    forService service: String,
    accessibility: CFTypeRef
  ) throws {
    guard let passwordData = password.data(using: .utf8) else {
      throw KeychainWrapper.Error.unexpectedPasswordData
    }
    try setPassword(data: passwordData, forService: service, accessibility: nil)
  }

  func setPassword(data: Data, forService service: String, accessibility: CFTypeRef?) throws {
    guard !service.isEmpty else { throw KeychainWrapper.Error.noService }
    passwordStore.updateValue(data, forKey: service + accountName)
  }
}

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
  private let keychainHelper = KeychainHelperFake(keychainConfigurations: [])
  private lazy var keychainStore: KeychainStore = {
    return KeychainStore(
      credentialItemName: Constants.testKeychainItemName,
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
    keychainHelper.generatedKeychainQuery = nil
  }

  func testKeychainQueryHasDataProtectionAttributeOnSave() throws {
    let useDataProtectionAttributeSet: Set<KeychainConfiguration> = [.useDataProtectionKeychain]
    let fakeWithDataProtection = KeychainHelperFake(
      keychainConfigurations: useDataProtectionAttributeSet
    )
    let store = KeychainStore(
      credentialItemName: Constants.testKeychainItemName,
      keychainHelper: fakeWithDataProtection
    )
    try store.save(authState: authState)
    guard let testQuery = fakeWithDataProtection.generatedKeychainQuery as? [String: AnyHashable]
    else {
      XCTFail("`fakeWithDataProtection` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: useDataProtectionAttributeSet,
      accountName: fakeWithDataProtection.accountName,
      service: Constants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)
  }

  func testKeychainQueryHasAccessGroupAttributeOnSave() throws {
    let expectedGroupName = "testGroup"
    let accessGroupAttributeSet: Set<KeychainConfiguration> = [
      .keychainAccessGroup(name: expectedGroupName)
    ]
    let fakeWithAccessGroup = KeychainHelperFake(
      keychainConfigurations: accessGroupAttributeSet
    )
    let store = KeychainStore(
      credentialItemName: Constants.testKeychainItemName,
      keychainHelper: fakeWithAccessGroup
    )
    try store.save(authState: authState)
    guard let testQuery = fakeWithAccessGroup.generatedKeychainQuery as? [String: AnyHashable]
    else {
      XCTFail("`fakeWithAccessGroup` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: accessGroupAttributeSet,
      accountName: fakeWithAccessGroup.accountName,
      service: Constants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)

    guard let testGroupName = testQuery[
      fakeWithAccessGroup.keychainConfigurations.first!.attribute.keyName
    ] else {
      XCTFail("`fakeWithAccessGroup` missing access group keychain attribute")
      return
    }
    XCTAssertEqual(expectedGroupName, testGroupName)
  }

  func testKeychainQueryHasDataProtectionAndAccessGroupAttributesOnSave() throws {
    let expectedGroupName = "testGroup"
    let accessGroupAttributeSet: Set<KeychainConfiguration> = [
      .useDataProtectionKeychain,
      .keychainAccessGroup(name: expectedGroupName)
    ]
    let fakeWithDataProtectionAndAccessGroup = KeychainHelperFake(
      keychainConfigurations: accessGroupAttributeSet
    )
    let store = KeychainStore(
      credentialItemName: Constants.testKeychainItemName,
      keychainHelper: fakeWithDataProtectionAndAccessGroup
    )
    try store.save(authState: authState)
    guard let testQuery = fakeWithDataProtectionAndAccessGroup.generatedKeychainQuery
            as? [String: AnyHashable] else {
      XCTFail("`fakeWithDataProtectionAndAccessGroup` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: accessGroupAttributeSet,
      accountName: fakeWithDataProtectionAndAccessGroup.accountName,
      service: Constants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)

    guard let testUseDataProtectionValue = testQuery[
      KeychainAttribute.dataProtectionKeychain.keyName
    ] as? Bool else {
      XCTFail("`testQuery` did not have a `.useDataProtectionKeychain` attribute")
      return
    }
    XCTAssertTrue(testUseDataProtectionValue)

    guard let testAccessGroupName = testQuery[
      KeychainAttribute.accessGroup(expectedGroupName).keyName
    ] else {
      XCTFail("`testQuery` did not have an `.keychainAccessGroup` attribute")
      return
    }
    XCTAssertEqual(testAccessGroupName, expectedGroupName)
  }

  func testKeychainQueryHasDataProtectionAttributeOnRead() throws {
    let useDataProtectionAttributeSet: Set<KeychainConfiguration> = [.useDataProtectionKeychain]
    let fakeWithDataProtection = KeychainHelperFake(
      keychainConfigurations: useDataProtectionAttributeSet
    )
    let store = KeychainStore(
      credentialItemName: Constants.testKeychainItemName,
      keychainHelper: fakeWithDataProtection
    )
    // Use `try?` to "throw away" the error since we are testing the keychain query and not the call
    _ = try? store.authState(forItemName: Constants.testKeychainItemName)
    guard let testQuery = fakeWithDataProtection.generatedKeychainQuery as? [String: AnyHashable]
    else {
      XCTFail("`fakeWithDataProtection` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: useDataProtectionAttributeSet,
      accountName: fakeWithDataProtection.accountName,
      service: Constants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)
  }

  func testKeychainQueryHasAccessGroupAttributeOnRead() throws {
    let expectedGroupName = "testGroup"
    let accessGroupAttributeSet: Set<KeychainConfiguration> = [
      .keychainAccessGroup(name: expectedGroupName)
    ]
    let fakeWithAccessGroup = KeychainHelperFake(
      keychainConfigurations: accessGroupAttributeSet
    )
    let store = KeychainStore(
      credentialItemName: Constants.testKeychainItemName,
      keychainHelper: fakeWithAccessGroup
    )
    // Use `try?` to "throw away" the error since we are testing the keychain query and not the call
    _ = try? store.authState(forItemName: Constants.testKeychainItemName)
    guard let testQuery = fakeWithAccessGroup.generatedKeychainQuery as? [String: AnyHashable]
    else {
      XCTFail("`fakeWithAccessGroup` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: accessGroupAttributeSet,
      accountName: fakeWithAccessGroup.accountName,
      service: Constants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)

    guard let testGroupName = testQuery[
      fakeWithAccessGroup.keychainConfigurations.first!.attribute.keyName
    ] else {
      XCTFail("`fakeWithAccessGroup` missing access group keychain attribute")
      return
    }
    XCTAssertEqual(expectedGroupName, testGroupName)
  }

  func testKeychainQueryHasDataProtectionAndAccessGroupAttributesOnRead() throws {
    let expectedGroupName = "testGroup"
    let accessGroupAttributeSet: Set<KeychainConfiguration> = [
      .useDataProtectionKeychain,
      .keychainAccessGroup(name: expectedGroupName)
    ]
    let fakeWithDataProtectionAndAccessGroup = KeychainHelperFake(
      keychainConfigurations: accessGroupAttributeSet
    )
    let store = KeychainStore(
      credentialItemName: Constants.testKeychainItemName,
      keychainHelper: fakeWithDataProtectionAndAccessGroup
    )
    // Use `try?` to "throw away" the error since we are testing the keychain query and not the call
    _ = try? store.authState(forItemName: Constants.testKeychainItemName)
    guard let testQuery = fakeWithDataProtectionAndAccessGroup.generatedKeychainQuery
            as? [String: AnyHashable] else {
      XCTFail("`fakeWithDataProtectionAndAccessGroup` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: accessGroupAttributeSet,
      accountName: fakeWithDataProtectionAndAccessGroup.accountName,
      service: Constants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)

    guard let testUseDataProtectionValue = testQuery[
      KeychainAttribute.dataProtectionKeychain.keyName
    ] as? Bool else {
      XCTFail("`testQuery` did not have a `.useDataProtectionKeychain` attribute")
      return
    }
    XCTAssertTrue(testUseDataProtectionValue)

    guard let testAccessGroupName = testQuery[
      KeychainAttribute.accessGroup(expectedGroupName).keyName
    ] else {
      XCTFail("`testQuery` did not have an `.keychainAccessGroup` attribute")
      return
    }
    XCTAssertEqual(testAccessGroupName, expectedGroupName)
  }

  func testKeychainQueryHasDataProtectionAttributeOnRemove() throws {
    let useDataProtectionAttributeSet: Set<KeychainConfiguration> = [.useDataProtectionKeychain]
    let fakeWithDataProtection = KeychainHelperFake(
      keychainConfigurations: useDataProtectionAttributeSet
    )
    let store = KeychainStore(
      credentialItemName: Constants.testKeychainItemName,
      keychainHelper: fakeWithDataProtection
    )
    // Use `try?` to "throw away" the error since we are testing the keychain query and not the call
    _ = try? store.removeAuthState()
    guard let testQuery = fakeWithDataProtection.generatedKeychainQuery as? [String: AnyHashable]
    else {
      XCTFail("`fakeWithDataProtection` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: useDataProtectionAttributeSet,
      accountName: fakeWithDataProtection.accountName,
      service: Constants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)
  }

  func testKeychainQueryHasAccessGroupAttributeOnRemove() throws {
    let expectedGroupName = "testGroup"
    let accessGroupAttributeSet: Set<KeychainConfiguration> = [
      .keychainAccessGroup(name: expectedGroupName)
    ]
    let fakeWithAccessGroup = KeychainHelperFake(
      keychainConfigurations: accessGroupAttributeSet
    )
    let store = KeychainStore(
      credentialItemName: Constants.testKeychainItemName,
      keychainHelper: fakeWithAccessGroup
    )
    // Use `try?` to "throw away" the error since we are testing the keychain query and not the call
    _ = try? store.removeAuthState()
    guard let testQuery = fakeWithAccessGroup.generatedKeychainQuery as? [String: AnyHashable]
    else {
      XCTFail("`fakeWithAccessGroup` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: accessGroupAttributeSet,
      accountName: fakeWithAccessGroup.accountName,
      service: Constants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)

    guard let testGroupName = testQuery[
      fakeWithAccessGroup.keychainConfigurations.first!.attribute.keyName
    ] else {
      XCTFail("`fakeWithAccessGroup` missing access group keychain attribute")
      return
    }
    XCTAssertEqual(expectedGroupName, testGroupName)
  }

  func testKeychainQueryHasDataProtectionAndAccessGroupAttributesOnRemove() throws {
    let expectedGroupName = "testGroup"
    let accessGroupAttributeSet: Set<KeychainConfiguration> = [
      .useDataProtectionKeychain,
      .keychainAccessGroup(name: expectedGroupName)
    ]
    let fakeWithDataProtectionAndAccessGroup = KeychainHelperFake(
      keychainConfigurations: accessGroupAttributeSet
    )
    let store = KeychainStore(
      credentialItemName: Constants.testKeychainItemName,
      keychainHelper: fakeWithDataProtectionAndAccessGroup
    )
    // Use `try?` to "throw away" the error since we are testing the keychain query and not the call
    _ = try? store.removeAuthState()
    guard let testQuery = fakeWithDataProtectionAndAccessGroup.generatedKeychainQuery
            as? [String: AnyHashable] else {
      XCTFail("`fakeWithDataProtectionAndAccessGroup` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: accessGroupAttributeSet,
      accountName: fakeWithDataProtectionAndAccessGroup.accountName,
      service: Constants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)

    guard let testUseDataProtectionValue = testQuery[
      KeychainAttribute.dataProtectionKeychain.keyName
    ] as? Bool else {
      XCTFail("`testQuery` did not have a `.useDataProtectionKeychain` attribute")
      return
    }
    XCTAssertTrue(testUseDataProtectionValue)

    guard let testAccessGroupName = testQuery[
      KeychainAttribute.accessGroup(expectedGroupName).keyName
    ] else {
      XCTFail("`testQuery` did not have an `.keychainAccessGroup` attribute")
      return
    }
    XCTAssertEqual(testAccessGroupName, expectedGroupName)
  }

  func testSaveAndReadAuthorization() throws {
    try keychainStore.save(authState: authState)
    let expectedAuthorization = try keychainStore.authState(
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
    let expectedAuthorization = try keychainStore.authState(forItemName: anotherItemName)

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
    let expectedAuthorization = try keychainStore.authState(forItemName: anotherItemName)
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

    XCTAssertThrowsError(try keychainStore.authState(forItemName: "")) { thrownError in
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
      try keychainStore.authState(forItemName: Constants.testKeychainItemName)
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        .passwordNotFound(forItemName: Constants.testKeychainItemName)
      )
    }
  }
}

extension KeychainStoreTests {
  func comparisonKeychainQuery(
    withAttributes attributes: Set<KeychainConfiguration>,
    accountName: String,
    service: String
  ) -> [String: AnyHashable] {
    var query: [String: AnyHashable] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String : accountName,
      kSecAttrService as String: service,
    ]

    attributes.forEach { configuration in
      switch configuration.attribute {
      case .dataProtectionKeychain:
        query[configuration.attribute.keyName] = kCFBooleanTrue
      case .accessGroup(let name):
        query[configuration.attribute.keyName] = name
      }
    }

    return query
  }
}

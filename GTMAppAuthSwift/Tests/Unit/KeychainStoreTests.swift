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
@testable import TestHelpers
@testable import GTMAppAuthSwift

class KeychainStoreTests: XCTestCase {
  private let keychainHelper = KeychainHelperFake(keychainAttributes: [])
  private lazy var keychainStore: KeychainStore = {
    return KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: keychainHelper
    )
  }()
  private var authState: AuthState {
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
    keychainHelper.generatedKeychainQuery = nil
  }

  func testKeychainQueryHasDataProtectionAttributeOnSave() throws {
    let useDataProtectionAttributeSet: Set<KeychainAttribute> = [.useDataProtectionKeychain]
    let fakeWithDataProtection = KeychainHelperFake(
      keychainAttributes: useDataProtectionAttributeSet
    )
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
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
      service: TestingConstants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)
  }

  func testKeychainQueryHasAccessGroupAttributeOnSave() throws {
    let expectedGroupName = "testGroup"
    let accessGroupAttributeSet: Set<KeychainAttribute> = [
      .keychainAccessGroup(name: expectedGroupName)
    ]
    let fakeWithAccessGroup = KeychainHelperFake(
      keychainAttributes: accessGroupAttributeSet
    )
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
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
      service: TestingConstants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)

    guard let testGroupName = testQuery[
      fakeWithAccessGroup.keychainAttributes.first!.attribute.keyName
    ] else {
      XCTFail("`fakeWithAccessGroup` missing access group keychain attribute")
      return
    }
    XCTAssertEqual(expectedGroupName, testGroupName)
  }

  func testKeychainQueryHasDataProtectionAndAccessGroupAttributesOnSave() throws {
    let expectedGroupName = "testGroup"
    let accessGroupAttributeSet: Set<KeychainAttribute> = [
      .useDataProtectionKeychain,
      .keychainAccessGroup(name: expectedGroupName)
    ]
    let fakeWithDataProtectionAndAccessGroup = KeychainHelperFake(
      keychainAttributes: accessGroupAttributeSet
    )
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
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
      service: TestingConstants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)

    guard let testUseDataProtectionValue = testQuery[
      KeychainAttribute.Attribute.useDataProtectionKeychain.keyName
    ] as? Bool else {
      XCTFail("`testQuery` did not have a `.useDataProtectionKeychain` attribute")
      return
    }
    XCTAssertTrue(testUseDataProtectionValue)

    guard let testAccessGroupName = testQuery[
      KeychainAttribute.Attribute.accessGroup(expectedGroupName).keyName
    ] else {
      XCTFail("`testQuery` did not have an `.keychainAccessGroup` attribute")
      return
    }
    XCTAssertEqual(testAccessGroupName, expectedGroupName)
  }

  func testKeychainQueryHasDataProtectionAttributeOnRead() throws {
    let useDataProtectionAttributeSet: Set<KeychainAttribute> = [.useDataProtectionKeychain]
    let fakeWithDataProtection = KeychainHelperFake(
      keychainAttributes: useDataProtectionAttributeSet
    )
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: fakeWithDataProtection
    )
    // Use `try?` to "throw away" the error since we are testing the keychain query and not the call
    _ = try? store.retrieveAuthState()
    guard let testQuery = fakeWithDataProtection.generatedKeychainQuery as? [String: AnyHashable]
    else {
      XCTFail("`fakeWithDataProtection` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: useDataProtectionAttributeSet,
      accountName: fakeWithDataProtection.accountName,
      service: TestingConstants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)
  }

  func testKeychainQueryHasAccessGroupAttributeOnRead() throws {
    let expectedGroupName = "testGroup"
    let accessGroupAttributeSet: Set<KeychainAttribute> = [
      .keychainAccessGroup(name: expectedGroupName)
    ]
    let fakeWithAccessGroup = KeychainHelperFake(
      keychainAttributes: accessGroupAttributeSet
    )
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: fakeWithAccessGroup
    )
    // Use `try?` to "throw away" the error since we are testing the keychain query and not the call
    _ = try? store.retrieveAuthState()
    guard let testQuery = fakeWithAccessGroup.generatedKeychainQuery as? [String: AnyHashable]
    else {
      XCTFail("`fakeWithAccessGroup` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: accessGroupAttributeSet,
      accountName: fakeWithAccessGroup.accountName,
      service: TestingConstants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)

    guard let testGroupName = testQuery[
      fakeWithAccessGroup.keychainAttributes.first!.attribute.keyName
    ] else {
      XCTFail("`fakeWithAccessGroup` missing access group keychain attribute")
      return
    }
    XCTAssertEqual(expectedGroupName, testGroupName)
  }

  func testKeychainQueryHasDataProtectionAndAccessGroupAttributesOnRead() throws {
    let expectedGroupName = "testGroup"
    let accessGroupAttributeSet: Set<KeychainAttribute> = [
      .useDataProtectionKeychain,
      .keychainAccessGroup(name: expectedGroupName)
    ]
    let fakeWithDataProtectionAndAccessGroup = KeychainHelperFake(
      keychainAttributes: accessGroupAttributeSet
    )
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: fakeWithDataProtectionAndAccessGroup
    )
    // Use `try?` to "throw away" the error since we are testing the keychain query and not the call
    _ = try? store.retrieveAuthState()
    guard let testQuery = fakeWithDataProtectionAndAccessGroup.generatedKeychainQuery
            as? [String: AnyHashable] else {
      XCTFail("`fakeWithDataProtectionAndAccessGroup` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: accessGroupAttributeSet,
      accountName: fakeWithDataProtectionAndAccessGroup.accountName,
      service: TestingConstants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)

    guard let testUseDataProtectionValue = testQuery[
      KeychainAttribute.Attribute.useDataProtectionKeychain.keyName
    ] as? Bool else {
      XCTFail("`testQuery` did not have a `.useDataProtectionKeychain` attribute")
      return
    }
    XCTAssertTrue(testUseDataProtectionValue)

    guard let testAccessGroupName = testQuery[
      KeychainAttribute.Attribute.accessGroup(expectedGroupName).keyName
    ] else {
      XCTFail("`testQuery` did not have an `.keychainAccessGroup` attribute")
      return
    }
    XCTAssertEqual(testAccessGroupName, expectedGroupName)
  }

  func testKeychainQueryHasDataProtectionAttributeOnRemove() throws {
    let useDataProtectionAttributeSet: Set<KeychainAttribute> = [.useDataProtectionKeychain]
    let fakeWithDataProtection = KeychainHelperFake(
      keychainAttributes: useDataProtectionAttributeSet
    )
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
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
      service: TestingConstants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)
  }

  func testKeychainQueryHasAccessGroupAttributeOnRemove() throws {
    let expectedGroupName = "testGroup"
    let accessGroupAttributeSet: Set<KeychainAttribute> = [
      .keychainAccessGroup(name: expectedGroupName)
    ]
    let fakeWithAccessGroup = KeychainHelperFake(
      keychainAttributes: accessGroupAttributeSet
    )
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
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
      service: TestingConstants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)

    guard let testGroupName = testQuery[
      fakeWithAccessGroup.keychainAttributes.first!.attribute.keyName
    ] else {
      XCTFail("`fakeWithAccessGroup` missing access group keychain attribute")
      return
    }
    XCTAssertEqual(expectedGroupName, testGroupName)
  }

  func testKeychainQueryHasDataProtectionAndAccessGroupAttributesOnRemove() throws {
    let expectedGroupName = "testGroup"
    let accessGroupAttributeSet: Set<KeychainAttribute> = [
      .useDataProtectionKeychain,
      .keychainAccessGroup(name: expectedGroupName)
    ]
    let fakeWithDataProtectionAndAccessGroup = KeychainHelperFake(
      keychainAttributes: accessGroupAttributeSet
    )
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
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
      service: TestingConstants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)

    guard let testUseDataProtectionValue = testQuery[
      KeychainAttribute.Attribute.useDataProtectionKeychain.keyName
    ] as? Bool else {
      XCTFail("`testQuery` did not have a `.useDataProtectionKeychain` attribute")
      return
    }
    XCTAssertTrue(testUseDataProtectionValue)

    guard let testAccessGroupName = testQuery[
      KeychainAttribute.Attribute.accessGroup(expectedGroupName).keyName
    ] else {
      XCTFail("`testQuery` did not have an `.keychainAccessGroup` attribute")
      return
    }
    XCTAssertEqual(testAccessGroupName, expectedGroupName)
  }

  func testSaveAndReadAuthorization() throws {
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
        .failedToDeletePasswordBecauseItemNotFound(itemName: TestingConstants.testKeychainItemName)
      )
    }
  }

  func testPasswordNotFoundError() {
    XCTAssertThrowsError(
      try keychainStore.retrieveAuthState(forItemName: TestingConstants.testKeychainItemName)
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        .passwordNotFound(forItemName: TestingConstants.testKeychainItemName)
      )
    }
  }

  // MARK: - NSKeyed(Un)Archiver Class Name Mapping

  func testKeyedArchiverClassNameMapping() throws {
    try keychainStore.save(authState: authState)

    guard let lastUsedArchiver = keychainStore.lastUsedKeyedArchiver else {
      XCTFail("`keychainStore.save(authState:)` should create an `NSKeyedArchiver`")
      return
    }
    guard let mappedClassName = lastUsedArchiver.className(for: AuthState.self) else {
      XCTFail("`lastUsedArchiver` should have a mapped class name for `AuthState.self`")
      return
    }

    XCTAssertEqual(mappedClassName, AuthState.legacyArchiveName)
  }

  func testKeyedUnarchiverClassNameMapping() throws {
    try keychainStore.save(authState: authState)
    _ = try keychainStore.retrieveAuthState() // We don't need to test the retrieved auth here

    guard let lastUsedUnarchiver = keychainStore.lastUsedKeyedUnarchiver else {
      XCTFail("`keychainStore.retrieveAuthState()` should create an `NSKeyedUnarchiver`")
      return
    }
    guard let mappedClass = lastUsedUnarchiver.class(
      forClassName: AuthState.legacyArchiveName
    ) else {
      XCTFail("`lastUsedUnarchiver` should have a class mapping for `AuthState.legacyArchiveName")
      return
    }

    XCTAssertTrue(mappedClass is AuthState.Type)
  }

  func testArchivedDataAsPropertyListClassName() throws {
    try keychainStore.save(authState: authState)
    guard let propertyList = keychainHelper.archiveDataPropertyList as? [String: Any] else {
      XCTFail("`keychainHelper.archiveDataPropertyList` should not be nil")
      return
    }

    guard let objects = propertyList["$objects"] as? [Any] else {
      XCTFail("`propertyList` should have key `\"$objects\"")
      return
    }

    let objectMaps = objects.compactMap { $0 as? [String: String] }
    XCTAssertTrue(objectMaps.count > 0, "`objectMaps` should not be empty")

    guard let classNameMap = objectMaps.first(where: { $0["$classname"] != nil }) else {
      XCTFail("`objectMaps` should contain a dictionary with the key \"$classname\"")
      return
    }

    guard let className = classNameMap["$classname"] else {
      XCTFail("There should be a classname")
      return
    }

    XCTAssertEqual(className, AuthState.legacyArchiveName)
  }

  func testUnarchivedDataAsPropertyListClassName() throws {
    try keychainStore.save(authState: authState)
    _ = try keychainStore.retrieveAuthState() // We don't need to inspect the retrieved auth here

    guard let propertyList = keychainHelper.unarchiveDataPropertyList as? [String: Any] else {
      XCTFail("`keychainHelper.unarchiveDataPropertyList` should not be nil")
      return
    }

    guard let objects = propertyList["$objects"] as? [Any] else {
      XCTFail("`propertyList` should have key `\"$objects\"")
      return
    }

    let objectMaps = objects.compactMap { $0 as? [String: String] }
    XCTAssertTrue(objectMaps.count > 0, "`objectMaps` should have at least one `[String: String]`")

    guard let classNameMap = objectMaps.first(where: { $0["$classname"] != nil }) else {
      XCTFail("`objectMaps` should contain a dictionary with the key \"$classname\"")
      return
    }

    guard let className = classNameMap["$classname"] else {
      XCTFail("There should be a classname")
      return
    }

    XCTAssertEqual(className, AuthState.legacyArchiveName)
  }
}

extension KeychainStoreTests {
  func comparisonKeychainQuery(
    withAttributes attributes: Set<KeychainAttribute>,
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
      case .useDataProtectionKeychain:
        query[configuration.attribute.keyName] = kCFBooleanTrue
      case .accessGroup(let name):
        query[configuration.attribute.keyName] = name
      }
    }

    return query
  }
}

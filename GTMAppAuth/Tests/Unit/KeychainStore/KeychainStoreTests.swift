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
@testable import TestHelpers
#else
import AppAuth
#endif
@testable import GTMAppAuth

class KeychainStoreTests: XCTestCase {
  private let keychainHelper = KeychainHelperFake(keychainAttributes: [])
  private lazy var keychainStore: KeychainStore = {
    return KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: keychainHelper
    )
  }()
  private var authSession: AuthSession {
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
    keychainHelper.generatedKeychainQuery = nil
  }
  
  @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  func testKeychainAttributeKeysHaveCorrectNames() throws {
    let expectedAccessGroup = "unit-test-group"
    let attributes: Set<KeychainAttribute> = [
      KeychainAttribute.keychainAccessGroup(name: expectedAccessGroup)
    ]
    let keychainHelperFake = KeychainHelperFake(keychainAttributes: attributes)
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: keychainHelperFake
    )
    
    try store.save(authSession: authSession)
    guard let testQuery = keychainHelperFake.generatedKeychainQuery as? [String: AnyHashable] else {
      XCTFail("`keychainHelperFake` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: attributes,
      accountName: keychainHelperFake.accountName,
      service: TestingConstants.testKeychainItemName
    )
    XCTAssertEqual(testQuery, comparisonQuery)
    XCTAssertNotNil(testQuery[kSecUseDataProtectionKeychain as String])
    guard let testAccessGroup = testQuery[kSecAttrAccessGroup as String] as? String else {
      XCTFail("`testQuery` should have a keychain access group")
      return
    }
    XCTAssertEqual(testAccessGroup, expectedAccessGroup)
  }

  func testKeychainQueryHasFileBasedKeychainAttributeOnSave() throws {
    let useFileBasedKeychainAttributeSet: Set<KeychainAttribute> = [.useFileBasedKeychain]
    let fakeWithFileBased = KeychainHelperFake(
      keychainAttributes: useFileBasedKeychainAttributeSet
    )
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: fakeWithFileBased
    )
    try store.save(authSession: authSession)
    guard let testQuery = fakeWithFileBased.generatedKeychainQuery as? [String: AnyHashable]
    else {
      XCTFail("`fakeWithFileBased` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: useFileBasedKeychainAttributeSet,
      accountName: fakeWithFileBased.accountName,
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
    try store.save(authSession: authSession)
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

  func testKeychainQueryHasFileBasedKeychainAttributeOnRead() throws {
    let useFileBasedKeychainAttributeSet: Set<KeychainAttribute> = [.useFileBasedKeychain]
    let fakeWithFileBased = KeychainHelperFake(
      keychainAttributes: useFileBasedKeychainAttributeSet
    )
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: fakeWithFileBased
    )
    // Use `try?` to "throw away" the error since we are testing the keychain query and not the call
    _ = try? store.retrieveAuthSession()
    guard let testQuery = fakeWithFileBased.generatedKeychainQuery as? [String: AnyHashable]
    else {
      XCTFail("`fakeWithFileBased` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: useFileBasedKeychainAttributeSet,
      accountName: fakeWithFileBased.accountName,
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
    _ = try? store.retrieveAuthSession()
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

  @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  func testKeychainQueryHasFileBasedKeychainAttributeOnRemove() throws {
    let useFileBasedKeychainAttributeSet: Set<KeychainAttribute> = [.useFileBasedKeychain]
    let fakeWithFileBased = KeychainHelperFake(
      keychainAttributes: useFileBasedKeychainAttributeSet
    )
    let store = KeychainStore(
      itemName: TestingConstants.testKeychainItemName,
      keychainHelper: fakeWithFileBased
    )
    // Use `try?` to "throw away" the error since we are testing the keychain query and not the call
    _ = try? store.removeAuthSession()
    guard let testQuery = fakeWithFileBased.generatedKeychainQuery as? [String: AnyHashable]
    else {
      XCTFail("`fakeWithFileBased` missing keychain query attributes")
      return
    }

    let comparisonQuery = comparisonKeychainQuery(
      withAttributes: useFileBasedKeychainAttributeSet,
      accountName: fakeWithFileBased.accountName,
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
    _ = try? store.removeAuthSession()
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

  func testSaveAndRetrieveAuthSession() throws {
    try keychainStore.save(authSession: authSession)
    let expectedAuthSession = try keychainStore.retrieveAuthSession()
    XCTAssertEqual(
      expectedAuthSession.authState.isAuthorized,
      authSession.authState.isAuthorized
    )
    XCTAssertEqual(expectedAuthSession.serviceProvider, authSession.serviceProvider)
    XCTAssertEqual(expectedAuthSession.userID, authSession.userID)
    XCTAssertEqual(expectedAuthSession.userEmail, authSession.userEmail)
    XCTAssertEqual(expectedAuthSession.userEmailIsVerified, authSession.userEmailIsVerified)
  }

  func testRetrieveAuthSessionWithItemNameGivenToKeychain() throws {
    try keychainStore.save(authSession: authSession)
    let expectedAuthSession = try keychainStore.retrieveAuthSession()
    XCTAssertEqual(
      expectedAuthSession.authState.isAuthorized,
      authSession.authState.isAuthorized
    )
    XCTAssertEqual(expectedAuthSession.serviceProvider, authSession.serviceProvider)
    XCTAssertEqual(expectedAuthSession.userID, authSession.userID)
    XCTAssertEqual(expectedAuthSession.userEmail, authSession.userEmail)
    XCTAssertEqual(expectedAuthSession.userEmailIsVerified, authSession.userEmailIsVerified)
  }

  func testRetrieveAuthSessionForItemName() throws {
    let anotherItemName = "anotherItemName"
    try keychainStore.save(authSession: authSession, withItemName: anotherItemName)
    let expectedAuthSession = try keychainStore.retrieveAuthSession(withItemName: anotherItemName)

    XCTAssertEqual(
      expectedAuthSession.authState.isAuthorized,
      authSession.authState.isAuthorized
    )
    XCTAssertEqual(expectedAuthSession.serviceProvider, authSession.serviceProvider)
    XCTAssertEqual(expectedAuthSession.userID, authSession.userID)
    XCTAssertEqual(expectedAuthSession.userEmail, authSession.userEmail)
    XCTAssertEqual(expectedAuthSession.userEmailIsVerified, authSession.userEmailIsVerified)
  }

  func testRetrievePasswordNoService() throws {
    try keychainStore.save(authSession: authSession)

    XCTAssertThrowsError(try keychainStore.retrieveAuthSession(withItemName: "")) { thrownError in
      XCTAssertEqual(thrownError as? KeychainStore.Error, .noService)
    }
  }

  func testSaveAuthSessionForItemName() throws {
    let anotherItemName = "anotherItemName"
    try keychainStore.save(authSession: authSession, withItemName: anotherItemName)
    let expectedAuthSession = try keychainStore.retrieveAuthSession(withItemName: anotherItemName)
    XCTAssertEqual(
      expectedAuthSession.authState.isAuthorized,
      authSession.authState.isAuthorized
    )
    XCTAssertEqual(expectedAuthSession.serviceProvider, authSession.serviceProvider)
    XCTAssertEqual(expectedAuthSession.userID, authSession.userID)
    XCTAssertEqual(expectedAuthSession.userEmail, authSession.userEmail)
    XCTAssertEqual(expectedAuthSession.userEmailIsVerified, authSession.userEmailIsVerified)
  }

  func testSavePasswordNoService() {
    XCTAssertThrowsError(
      try keychainStore.save(authSession: authSession, withItemName: "")
    ) { thrownError in
      XCTAssertEqual(thrownError as? KeychainStore.Error, .noService)
    }
  }

  func testRemovePasswordNoService() throws {
    try keychainStore.save(authSession: authSession)

    XCTAssertThrowsError(try keychainStore.removeAuthSession(withItemName: "")) { thrownError in
      XCTAssertEqual(thrownError as? KeychainStore.Error, .noService)
    }
  }

  func testFailedToDeletePasswordError() {
    XCTAssertThrowsError(try keychainStore.removeAuthSession()) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        .failedToDeletePasswordBecauseItemNotFound(itemName: TestingConstants.testKeychainItemName)
      )
    }
  }

  func testPasswordNotFoundError() {
    XCTAssertThrowsError(
      try keychainStore.retrieveAuthSession(withItemName: TestingConstants.testKeychainItemName)
    ) { thrownError in
      XCTAssertEqual(
        thrownError as? KeychainStore.Error,
        .passwordNotFound(forItemName: TestingConstants.testKeychainItemName)
      )
    }
  }

  // MARK: - NSKeyed(Un)Archiver Class Name Mapping

  func testKeyedArchiverClassNameMapping() throws {
    try keychainStore.save(authSession: authSession)

    guard let lastUsedArchiver = keychainStore.lastUsedKeyedArchiver else {
      XCTFail("`keychainStore.save(authSession:)` should create an `NSKeyedArchiver`")
      return
    }
    guard let mappedClassName = lastUsedArchiver.className(for: AuthSession.self) else {
      XCTFail("`lastUsedArchiver` should have a mapped class name for `AuthSession.self`")
      return
    }

    XCTAssertEqual(mappedClassName, AuthSession.legacyArchiveName)
  }

  func testKeyedUnarchiverClassNameMapping() throws {
    try keychainStore.save(authSession: authSession)
    _ = try keychainStore.retrieveAuthSession() // We don't need to test the retrieved auth here

    guard let lastUsedUnarchiver = keychainStore.lastUsedKeyedUnarchiver else {
      XCTFail("`keychainStore.retrieveAuthSession()` should create an `NSKeyedUnarchiver`")
      return
    }
    guard let mappedClass = lastUsedUnarchiver.class(
      forClassName: AuthSession.legacyArchiveName
    ) else {
      XCTFail("`lastUsedUnarchiver` should have a class mapping for `AuthSession.legacyArchiveName")
      return
    }

    XCTAssertTrue(mappedClass is AuthSession.Type)
  }

  func testArchivedDataAsPropertyListClassName() throws {
    try keychainStore.save(authSession: authSession)
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

    XCTAssertEqual(className, AuthSession.legacyArchiveName)
  }

  func testUnarchivedDataAsPropertyListClassName() throws {
    try keychainStore.save(authSession: authSession)
    _ = try keychainStore.retrieveAuthSession() // We don't need to inspect the retrieved auth here

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

    XCTAssertEqual(className, AuthSession.legacyArchiveName)
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

    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
      query[kSecUseDataProtectionKeychain] = kCFBooleanTrue
    }

    attributes.forEach { configuration in
      switch configuration.attribute {
      case .useFileBasedKeychain:
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
          query[configuration.attribute.keyName] = kCFBooleanFalse
        }
      case .accessGroup(let name):
        query[configuration.attribute.keyName] = name
      }
    }

    return query
  }
}

/*
 * Copyright 2026 Google LLC
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
import GTMAppAuthTestHelpers
#else
import AppAuth
#endif
@testable import GTMAppAuth

class AuthSessionStoreFakeTests: XCTestCase {
  func testRetrieveWithoutSaveThrows() {
    let store = AuthSessionStoreFake()
    XCTAssertThrowsError(try store.retrieveAuthSession()) { error in
      XCTAssertEqual(error as? AuthSessionStoreFake.Error, .noSavedAuthSession)
    }
  }

  func testSaveThenRetrieveReturnsSameSession() throws {
    let store = AuthSessionStoreFake()
    let session = AuthSession(authState: OIDAuthState.testInstance())
    try store.save(authSession: session)
    let retrieved = try store.retrieveAuthSession()
    XCTAssertIdentical(retrieved, session)
    XCTAssertIdentical(store.savedAuthSession, session)
  }

  func testRemoveClearsSavedSession() throws {
    let store = AuthSessionStoreFake()
    let session = AuthSession(authState: OIDAuthState.testInstance())
    try store.save(authSession: session)
    try store.removeAuthSession()
    XCTAssertNil(store.savedAuthSession)
    XCTAssertThrowsError(try store.retrieveAuthSession()) { error in
      XCTAssertEqual(error as? AuthSessionStoreFake.Error, .noSavedAuthSession)
    }
  }

  func testRemoveOnEmptyStoreDoesNotThrow() {
    let store = AuthSessionStoreFake()
    XCTAssertNoThrow(try store.removeAuthSession())
  }

  func testSaveErrorIsThrownAndNothingIsStored() {
    let store = AuthSessionStoreFake()
    store.saveError = NSError(domain: "test", code: 1)
    let session = AuthSession(authState: OIDAuthState.testInstance())
    XCTAssertThrowsError(try store.save(authSession: session)) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.domain, "test")
      XCTAssertEqual(nsError.code, 1)
    }
    XCTAssertNil(store.savedAuthSession)
  }

  func testRetrieveErrorIsThrown() throws {
    let store = AuthSessionStoreFake()
    let session = AuthSession(authState: OIDAuthState.testInstance())
    try store.save(authSession: session)
    store.retrieveError = NSError(domain: "test", code: 1)
    XCTAssertThrowsError(try store.retrieveAuthSession()) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.domain, "test")
      XCTAssertEqual(nsError.code, 1)
    }
  }

  func testRemoveErrorIsThrownAndSessionIsKept() throws {
    let store = AuthSessionStoreFake()
    let session = AuthSession(authState: OIDAuthState.testInstance())
    try store.save(authSession: session)
    store.removeError = NSError(domain: "test", code: 1)
    XCTAssertThrowsError(try store.removeAuthSession()) { error in
      let nsError = error as NSError
      XCTAssertEqual(nsError.domain, "test")
      XCTAssertEqual(nsError.code, 1)
    }
    XCTAssertIdentical(store.savedAuthSession, session)
  }
}

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

import Foundation
import GTMAppAuth

/// An in-memory `AuthSessionStore` for tests.
///
/// Holds at most one `AuthSession`. Set `saveError`, `retrieveError` or `removeError` to make the
/// corresponding operation throw instead.
@objc(GTMAuthSessionStoreFake)
public final class AuthSessionStoreFake: NSObject, AuthSessionStore {
  /// Errors thrown by the fake itself.
  public enum Error: Swift.Error, Equatable {
    /// `retrieveAuthSession()` was called while nothing was stored.
    case noSavedAuthSession
  }

  /// The session most recently saved and not since removed.
  @objc public var savedAuthSession: AuthSession?
  /// When set, `save(authSession:)` throws this instead of storing the session.
  @objc public var saveError: Swift.Error?
  /// When set, `retrieveAuthSession()` throws this.
  @objc public var retrieveError: Swift.Error?
  /// When set, `removeAuthSession()` throws this instead of clearing the stored session.
  @objc public var removeError: Swift.Error?

  @objc public override init() { super.init() }

  @objc(saveAuthSession:error:)
  public func save(authSession: AuthSession) throws {
    if let saveError = saveError {
      throw saveError
    }
    savedAuthSession = authSession
  }

  @objc(removeAuthSessionWithError:)
  public func removeAuthSession() throws {
    if let removeError = removeError {
      throw removeError
    }
    savedAuthSession = nil
  }

  @objc(retrieveAuthSessionWithError:)
  public func retrieveAuthSession() throws -> AuthSession {
    if let retrieveError = retrieveError {
      throw retrieveError
    }
    guard let savedAuthSession = savedAuthSession else {
      throw Error.noSavedAuthSession
    }
    return savedAuthSession
  }
}

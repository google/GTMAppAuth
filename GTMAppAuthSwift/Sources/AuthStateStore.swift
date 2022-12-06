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

import Foundation

/// Represents the operations needed to provide `AuthState` storage.
@objc(GTMAuthStateStore)
public protocol AuthStateStore {
  /// Saves the provided `AuthState`.
  ///
  /// - Parameter authState: An instance of `AuthState` to save.
  /// - Throws: Any error that may arise during the save.
  /// - Note: This save operation will use the `itemName` provided during initialization.
  @objc func save(authState: AuthState) throws

  /// Removes the stored `AuthState`.
  ///
  /// - Throws: Any error that may arise during the removal.
  /// - Note: This removal will use the `itemName` provided during initialization.
  @objc func removeAuthState() throws

  /// Retrieves the stored `AuthState`.
  ///
  /// - Throws: Any error that may arise during the retrieval.
  /// - Note: This retrieval will use the `itemName` provided during initialization.
  @objc func retrieveAuthState() throws -> AuthState
}

/// Represents the operations needed to convert OAuth2 authorizations to `AuthState` instances along
/// with credential storage.
@objc public protocol GTMOAuth2AuthStateStore {
  /// Attempts to create an `AuthState` from stored data in GTMOAuth2 format.
  ///
  /// - Parameters:
  ///   - tokenURL: The OAuth token endpoint URL.
  ///   - redirectURI: The OAuth redirect URI used when obtaining the original authorization.
  ///   - clientID: The OAuth client ID.
  ///   - clientSecret: The OAuth client secret.
  /// - Returns: An `AuthState` object.
  /// - Throws: Any error arising from the `AuthState` creation.
  @objc func retrieveAuthStateInGTMOAuth2Format(
    tokenURL: URL,
    redirectURI: String,
    clientID: String,
    clientSecret: String?
  ) throws -> AuthState

  /// Saves the authorization state in a GTMOAuth2 compatible manner.
  ///
  /// - Parameters:
  ///   - authorization: The `AuthState` to save.
  /// - Throws: Any error that may arise during the retrieval.
  @available(*, deprecated, message: "Use AuthStateStore.save(authState:)")
  @objc func saveWithGTMOAuth2Format(
    forAuthorization authorization: AuthState
  ) throws

  /// Removes stored tokens, such as when the user signs out.
  ///
  /// - Throws: Any error that may arise during the removal.
  @objc func removeGTMOAuth2AuthState() throws
}

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

/// Represents the operations needed to provide credential storage.
@objc public protocol CredentialStore {
  /// The `String` name for the stored credential.
  var credentialItemName: String { get }

  /// Creates an instance of the `CredentialStore` conforming instance.
  ///
  /// - Parameter credentialItemName: The `String` name for the credential.
  init(credentialItemName: String)

  /// Saves the provided authorization.
  ///
  /// - Parameter authorization: An instance of `GTMAppAuthFetcherAuthorization` to save.
  /// - Throws: Any error that may arise during the save.
  /// - Note: This save operation will use the `credentialItemName` provided during initialization.
  func save(authorization: GTMAppAuthFetcherAuthorization) throws

  /// Saves the provided authorization with the given `itemName`.
  ///
  /// - Parameter authorization: An instance of `GTMAppAuthFetcherAuthorization` to save.
  /// - Throws: Any error that may arise during the save.
  /// - Note: This save operation will _not_ use the `credentialItemName` provided during
  ///     initialization.
  func save(authorization: GTMAppAuthFetcherAuthorization, forItemName itemName: String) throws

  /// Removes the authorization matching the provided `itemName`.
  ///
  /// - Parameter itemName: The `String` name to use while finding the authorization to remove.
  /// - Throws: Any error that may arise during the removal.
  /// - Note: This removal will _not_ use the `credentialItemName` provided during initialization.
  func remove(authorizationWithItemName itemName: String) throws

  /// Removes the authorization matching the provided `itemName`.
  ///
  /// - Throws: Any error that may arise during the removal.
  /// - Note: This removal will use the `credentialItemName` provided during initialization.
  func removeAuthorization() throws

  /// Retrieves the authorization matching the provided item name.
  ///
  /// - Parameter itemName: The `String` name for the authorization to retrieve from the store.
  /// - Throws: Any error that may arise during the retrieval.
  /// - Note: This retrieval will _not_ use the `credentialItemName` provided during initialization.
  func authorization(forItemName itemName: String) throws -> GTMAppAuthFetcherAuthorization

  /// Retrieves the authorization.
  ///
  /// - Throws: Any error that may arise during the retrieval.
  /// - Note: This retrieval will use the `credentialItemName` provided during initialization.
  func retrieveAuthorization() throws -> GTMAppAuthFetcherAuthorization
}

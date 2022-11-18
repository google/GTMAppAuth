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
  @objc var credentialItemName: String { get }

  /// Creates an instance of the `CredentialStore` conforming instance.
  ///
  /// - Parameter credentialItemName: The `String` name for the credential.
  @objc init(credentialItemName: String)

  /// Saves the provided authorization.
  ///
  /// - Parameter authorization: An instance of `GTMAppAuthFetcherAuthorization` to save.
  /// - Throws: Any error that may arise during the save.
  /// - Note: This save operation will use the `credentialItemName` provided during initialization.
  @objc func save(authorization: GTMAppAuthFetcherAuthorization) throws

  /// Saves the provided authorization with the given `itemName`.
  ///
  /// - Parameter authorization: An instance of `GTMAppAuthFetcherAuthorization` to save.
  /// - Throws: Any error that may arise during the save.
  /// - Note: This save operation will _not_ use the `credentialItemName` provided during
  ///     initialization.
  @objc func save(authorization: GTMAppAuthFetcherAuthorization, forItemName itemName: String) throws

  /// Removes the authorization matching the provided `itemName`.
  ///
  /// - Parameter itemName: The `String` name to use while finding the authorization to remove.
  /// - Throws: Any error that may arise during the removal.
  /// - Note: This removal will _not_ use the `credentialItemName` provided during initialization.
  @objc func removeAuthorization(withItemName itemName: String) throws

  /// Removes the authorization matching the provided `itemName`.
  ///
  /// - Throws: Any error that may arise during the removal.
  /// - Note: This removal will use the `credentialItemName` provided during initialization.
  @objc func removeAuthorization() throws

  /// Retrieves the authorization matching the provided item name.
  ///
  /// - Parameter itemName: The `String` name for the authorization to retrieve from the store.
  /// - Throws: Any error that may arise during the retrieval.
  /// - Note: This retrieval will _not_ use the `credentialItemName` provided during initialization.
  @objc func authorization(forItemName itemName: String) throws -> GTMAppAuthFetcherAuthorization

  /// Retrieves the authorization.
  ///
  /// - Throws: Any error that may arise during the retrieval.
  /// - Note: This retrieval will use the `credentialItemName` provided during initialization.
  @objc func retrieveAuthorization() throws -> GTMAppAuthFetcherAuthorization
}

@objc public protocol OAuth2CompatibilityCredentialStore {
  /// Attempts to create a `GTMAppAuthFetcherAuthorization` from stored data in GTMOAuth2 format,
  /// at the supplied identifier.
  ///
  /// - Parameters:
  ///   - itemName: The name for the item to find.
  ///   - tokenURL: The OAuth token endpoint URL.
  ///   - redirectURI: The OAuth redirect URI used when obtaining the original authorization.
  ///   - clientID: The OAuth client ID.
  ///   - clientSecret: The OAuth client secret.
  /// - Returns: A `GTMAppAuthFetcherAuthorization` object.
  /// - Throws: An instance of `GTMOAuth2KeychainCompatibility.Error` arising from the retrieval.
  @objc func authorization(
    forItemName itemName: String,
    tokenURL: URL,
    redirectURI: String,
    clientID: String,
    clientSecret: String?
  ) throws -> GTMAppAuthFetcherAuthorization

  /// Attempts to create a `GTMAppAuthFetcherAuthorization` from a `String` representation of the
  /// GTMOAuth2 keychain data.
  ///
  /// - Parameters:
  ///   - persistenceString: `String` representation of the GTMOAuth2 data.
  ///   - tokenURL: The OAuth token endpoint URL.
  ///   - redirectURI: The OAuth redirect URI used when obtaining the original authorization.
  ///   - clientID: The OAuth client ID.
  ///   - clientSecret: The OAuth client secret.
  /// - Returns: A `GTMAppAuthFetcherAuthorization` object, or nil.
  /// - Throws: An instance of `GTMOAuth2KeychainCompatibility.Error` arising from the retrieval.
  @objc func authorization(
    forPersistenceString persistenceString: String,
    tokenURL: URL,
    redirectURI: String,
    clientID: String,
    clientSecret: String?
  ) throws -> GTMAppAuthFetcherAuthorization

  /// Attempts to create a `GTMAppAuthFetcherAuthorization` from data stored in a GTMOAuth2 format
  /// at the supplied identifier.
  ///
  /// Uses Google OAuth provider information.
  ///
  /// - Parameters:
  ///   - itemName: The keychain name.
  ///   - clientID: The OAuth client id.
  ///   - clientSecret: The OAuth client secret.
  /// - Returns: A `GTMAppAuthFetcherAuthorization` object, or nil.
  /// - Throws: An instance of `GTMOAuth2KeychainCompatibility.Error` arising from the retrieval.
  @objc(authForGoogleForItemName:clientID:clientSecret:error:)
  func authForGoogle(
    forItemName itemName: String,
    clientID: String,
    clientSecret: String
  ) throws -> GTMAppAuthFetcherAuthorization

  /// Saves the authorization state in a GTMOAuth2 compatible manner.
  ///
  /// - Parameters:
  ///   - authorization: The `GTMAppAuthFetcherAuthorization` to save.
  ///   - itemName: The name of the item to save.
  /// - Throws: An instance of `GTMOAuth2KeychainCompatibility.Error` arising from the save.
  @available(*, deprecated, message: "Use GTMAppAuthFetcherAuthorization.save(authorization:with:)")
  @objc func saveWithOAuth2Format(
    forAuthorization authorization: GTMAppAuthFetcherAuthorization,
    withItemName itemName: String
  ) throws

  /// Removes stored tokens, such as when the user signs out.
  ///
  /// - Parameters:
  ///   - itemName: The keychain name.
  /// - Throws: An instance of `GTMOAuth2KeychainCompatibility.Error` arising from the removal.
  @objc func removeOAuth2Authorization(withItemName itemName: String) throws
}

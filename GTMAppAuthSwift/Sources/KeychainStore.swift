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
import Security
// Ensure that we import the correct dependency for both SPM and CocoaPods since
// the latter doesn't define separate Clang modules for subspecs
#if SWIFT_PACKAGE
import AppAuthCore
import GTMSessionFetcherCore
#else
import AppAuth
import GTMSessionFetcher
#endif

/// A helper providing a concrete implementation for saving and loading auth data to the keychain.
@objc(GTMKeychainStore)
public final class KeychainStore: NSObject {
  private var keychainHelper: KeychainHelper
  @objc public var itemName: String
  /// Attributes that configure the behavior of the keychain.
  @objc public let keychainAttributes: Set<KeychainAttribute>

  /// An initializer for testing to create an instance of this keychain wrapper with a given helper.
  ///
  /// - Parameters:
  ///   - itemName: The `String` name for the credential to store in the keychain.
  ///   - keychainAttributes: A `Set` of `KeychainAttribute` to use with the keychain.
  @objc public convenience init(
    itemName: String,
    keychainAttributes: Set<KeychainAttribute>
  ) {
    let keychain = KeychainWrapper(keychainAttributes: keychainAttributes)
    self.init(
      itemName: itemName,
      keychainAttributes: keychainAttributes,
      keychainHelper: keychain
    )
  }

  /// An initializer for testing to create an instance of this keychain wrapper with a given helper.
  ///
  /// - Parameters:
  ///   - itemName: The `String` name for the credential to store in the keychain.
  ///   - keychainHelper: An instance conforming to `KeychainHelper`.
  convenience init(itemName: String, keychainHelper: KeychainHelper) {
    self.init(
      itemName: itemName,
      keychainAttributes: [],
      keychainHelper: keychainHelper
    )
  }

  /// An initializer for testing to create an instance of this keychain wrapper with a given helper.
  ///
  /// - Parameters:
  ///   - itemName: The `String` name for the credential to store in the keychain.
  ///   - keychainAttributes: A `Set` of `KeychainAttribute` to use with the keychain.
  ///   - keychainHelper: An instance conforming to `KeychainHelper`.
  init(
    itemName: String,
    keychainAttributes: Set<KeychainAttribute>,
    keychainHelper: KeychainHelper
  ) {
    self.itemName = itemName
    self.keychainAttributes = keychainAttributes
    self.keychainHelper = keychainHelper
    super.init()
  }

  @available(macOS 10.13, iOS 11, tvOS 11, watchOS 4, *)
  private func modernUnarchiveAuthorization(
    withPasswordData passwordData: Data,
    itemName: String
  ) throws -> AuthState {
    guard let authorization = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: AuthState.self,
            from: passwordData
          ) else {
      throw AuthState
        .Error
        .failedToConvertKeychainDataToAuthorization(forItemName: itemName)
    }
    return authorization
  }
}

// MARK: - AuthStateStore Conformance

extension KeychainStore: AuthStateStore {
  /// An initializer for to create an instance of this keychain wrapper.
  ///
  /// - Parameters:
  ///   - itemName: The `String` name for the credential to store in the keychain.
  @objc public convenience init(itemName: String) {
    self.init(itemName: itemName, keychainHelper: KeychainWrapper())
  }

  @objc public func save(authState: AuthState) throws {
    let authorizationData: Data = try authorizationData(fromAuthorization: authState)
    try keychainHelper.setPassword(
      data: authorizationData,
      forService: itemName,
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )
  }

  @objc public func save(authState: AuthState, forItemName itemName: String) throws {
    let authorizationData = try authorizationData(fromAuthorization: authState)
    try keychainHelper.setPassword(
      data: authorizationData,
      forService: itemName,
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )
  }

  private func authorizationData(
    fromAuthorization authState: AuthState
  ) throws -> Data {
    let authorizationData: Data
    if #available(macOS 10.13, iOS 11, tvOS 11, watchOS 4, *) {
      do {
        authorizationData = try NSKeyedArchiver.archivedData(
          withRootObject: authState,
          requiringSecureCoding: true
        )
      } catch {
        throw KeychainStore.Error.failedToConvertAuthorizationToData
      }
    } else {
      authorizationData = NSKeyedArchiver.archivedData(withRootObject: authState)
    }
    return authorizationData
  }

  @objc public func removeAuthState(withItemName itemName: String) throws {
    try keychainHelper.removePassword(forService: itemName)
  }

  @objc public func removeAuthState() throws {
    try keychainHelper.removePassword(forService: itemName)
  }

  @objc public func retrieveAuthState(forItemName itemName: String) throws -> AuthState {
    let passwordData = try keychainHelper.passwordData(forService: itemName)

    if #available(macOS 10.13, iOS 11, tvOS 11, watchOS 4, *) {
      return try modernUnarchiveAuthorization(withPasswordData: passwordData, itemName: itemName)
    } else {
      guard let auth = NSKeyedUnarchiver.unarchiveObject(with: passwordData) as? AuthState else {
        throw AuthState
          .Error
          .failedToConvertKeychainDataToAuthorization(forItemName: itemName)
      }
      return auth
    }
  }

  @objc public func retrieveAuthState() throws -> AuthState {
    let passwordData = try keychainHelper.passwordData(forService: itemName)

    if #available(macOS 10.13, iOS 11, tvOS 11, watchOS 4, *) {
      return try modernUnarchiveAuthorization(
        withPasswordData: passwordData,
        itemName: itemName
      )
    } else {
      guard let auth = NSKeyedUnarchiver.unarchiveObject(with: passwordData) as? AuthState else {
        throw AuthState
          .Error
          .failedToConvertKeychainDataToAuthorization(forItemName: itemName)
      }
      return auth
    }
  }

  /// Attempts to create an `AuthState` from stored data in GTMOAuth2 format.
  ///
  /// - Parameters:
  ///   - tokenURL: The OAuth token endpoint URL.
  ///   - redirectURI: The OAuth redirect URI used when obtaining the original authorization.
  ///   - clientID: The OAuth client ID.
  ///   - clientSecret: The OAuth client secret.
  /// - Returns: An `AuthState` object.
  /// - Throws: Any error arising from the `AuthState` creation.
  @objc public func retrieveAuthStateInGTMOAuth2Format(
    tokenURL: URL,
    redirectURI: String,
    clientID: String,
    clientSecret: String?
  ) throws -> AuthState {
    let password = try keychainHelper.password(forService: itemName)
    let oauth2Compatibility = OAuth2AuthStateCompatibility()
    let authorization = try oauth2Compatibility.authState(
      forPersistenceString: password,
      tokenURL: tokenURL,
      redirectURI: redirectURI,
      clientID: clientID,
      clientSecret: clientSecret
    )
    return authorization
  }

  /// Attempts to create a `AuthState` from data stored in a GTMOAuth2 format.
  ///
  /// Uses Google OAuth provider information.
  ///
  /// - Parameters:
  ///   - clientID: The OAuth client id.
  ///   - clientSecret: The OAuth client secret.
  /// - Returns: An `AuthState` object, or nil.
  /// - Throws: Any error arising from the `AuthState` creation.
  @objc public func retrieveAuthStateForGoogleInGTMOAuth2Format(
    clientID: String,
    clientSecret: String
  ) throws -> AuthState {
    return try retrieveAuthStateInGTMOAuth2Format(
      tokenURL: OAuth2AuthStateCompatibility.googleTokenURL,
      redirectURI: OAuth2AuthStateCompatibility.nativeClientRedirectURI,
      clientID: clientID,
      clientSecret: clientSecret
    )
  }

  /// Saves the authorization state in a GTMOAuth2 compatible manner.
  ///
  /// - Parameters:
  ///   - authorization: The `AuthState` to save.
  /// - Throws: Any error that may arise during the retrieval.
  @objc public func saveWithGTMOAuth2Format(
    forAuthorization authorization: AuthState
  ) throws {
    guard let persistence = OAuth2AuthStateCompatibility
      .persistenceResponseString(forAuthState: authorization) else {
      throw KeychainStore.Error.failedToCreateResponseStringFromAuthorization(authorization)
    }
    try keychainHelper.setPassword(
      persistence,
      forService: itemName,
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
  }
}

// MARK: - Keychain Errors

public extension KeychainStore {
  /// Errors that may arise while saving, reading, and removing passwords from the Keychain.
  enum Error: Swift.Error, Equatable, CustomNSError {
    case unhandled(status: OSStatus)
    case passwordNotFound(forItemName: String)
    /// Error thrown when there is no name for the item in the keychain.
    case noService
    case unexpectedPasswordData(forItemName: String)
    case failedToCreateResponseStringFromAuthorization(AuthState)
    case failedToConvertRedirectURItoURL(String)
    case failedToConvertAuthorizationToData
    case failedToDeletePassword(forItemName: String)
    case failedToDeletePasswordBecauseItemNotFound(itemName: String)
    case failedToSetPassword(forItemName: String)

    public static var errorDomain: String {
      "GTMAppAuthKeychainErrorDomain"
    }

    public var errorUserInfo: [String : Any] {
      switch self {
      case .unhandled(status: let status):
        return ["status": status]
      case .passwordNotFound(let itemName):
        return ["itemName": itemName]
      case .noService:
        return [:]
      case .unexpectedPasswordData(let itemName):
        return ["itemName": itemName]
      case .failedToCreateResponseStringFromAuthorization(let authorization):
        return ["authorization": authorization]
      case .failedToConvertRedirectURItoURL(let redirectURI):
        return ["redirectURI": redirectURI]
      case .failedToConvertAuthorizationToData:
        return [:]
      case .failedToDeletePassword(let itemName):
        return ["itemName": itemName]
      case .failedToDeletePasswordBecauseItemNotFound(itemName: let itemName):
        return ["itemName": itemName]
      case .failedToSetPassword(forItemName: let itemName):
        return ["itemName": itemName]
      }
    }
  }
}

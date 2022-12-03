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
  // Needed for `AuthStateStore` and listed here because extensions cannot add stored properties
  @objc public var itemName: String

  /// An initializer for testing to create an instance of this keychain wrapper with a given helper.
  ///
  /// - Parameters:
  ///   - itemName: The `String` name for the credential to store in the keychain.
  ///   - keychainHelper: An instance conforming to `KeychainHelper`.
  init(itemName: String, keychainHelper: KeychainHelper) {
    self.itemName = itemName
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
}

// MARK: - OAuth2CompatibilityCredentialStore Conformance

extension KeychainStore: GTMOAuth2AuthStateStore {
  @objc public func retrieveAuthStateInGTMOAuth2Format(
    forItemName itemName: String,
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

  @objc public func retrieveAuthStateForGoogleInGTMOAuth2Format(
    forItemName itemName: String,
    clientID: String,
    clientSecret: String
  ) throws -> AuthState {
    return try retrieveAuthStateInGTMOAuth2Format(
      forItemName: itemName,
      tokenURL: OAuth2AuthStateCompatibility.googleTokenURL,
      redirectURI: OAuth2AuthStateCompatibility.nativeClientRedirectURI,
      clientID: clientID,
      clientSecret: clientSecret
    )
  }

  @objc public func saveWithGTMOAuth2Format(
    forAuthorization authorization: AuthState,
    withItemName itemName: String
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

  @objc public func removeOAuth2AuthState(withItemName itemName: String) throws {
    try keychainHelper.removePassword(forService: itemName)
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

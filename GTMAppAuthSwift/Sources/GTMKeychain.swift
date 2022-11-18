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

/// An utility for providing a concrete implementation for saving and loading data to the keychain.
@objc public final class GTMKeychain: NSObject {
  private var keychainHelper: KeychainHelper
  // Needed for `CredentialStore` and listed here because extensions cannot add stored properties
  @objc public var credentialItemName: String

  /// An initializer for testing to create an instance of this keychain wrapper with a given helper.
  ///
  /// - Parameters:
  ///   - credentialItemName: The `String` name for the credential to store in the keychain.
  ///   - keychainHelper: An instance conforming to `KeychainHelper`.
  init(credentialItemName: String, keychainHelper: KeychainHelper) {
    self.credentialItemName = credentialItemName
    self.keychainHelper = keychainHelper
    super.init()
  }

  @available(macOS 10.13, iOS 11, tvOS 11, watchOS 4, *)
  private func modernUnarchiveAuthorization(
    withPasswordData passwordData: Data,
    itemName: String
  ) throws -> GTMAppAuthFetcherAuthorization {
    guard let authorization = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: GTMAppAuthFetcherAuthorization.self,
            from: passwordData
          ) else {
      throw GTMAppAuthFetcherAuthorization
        .Error
        .failedToConvertKeychainDataToAuthorization(forItemName: itemName)
    }
    return authorization
  }
}

// MARK: - CredentialStore Conformance

extension GTMKeychain: CredentialStore {
  /// An initializer for to create an instance of this keychain wrapper.
  ///
  /// - Parameters:
  ///   - credentialItemName: The `String` name for the credential to store in the keychain.
  @objc public convenience init(credentialItemName: String) {
    self.init(credentialItemName: credentialItemName, keychainHelper: KeychainWrapper())
  }

  @objc public func save(authorization: GTMAppAuthFetcherAuthorization) throws {
    let authorizationData: Data = try authorizationData(fromAuthorization: authorization)
    try keychainHelper.setPassword(
      data: authorizationData,
      forService: credentialItemName,
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )
  }

  @objc public func save(
    authorization: GTMAppAuthFetcherAuthorization,
    forItemName itemName: String
  ) throws {
    let authorizationData = try authorizationData(fromAuthorization: authorization)
    try keychainHelper.setPassword(
      data: authorizationData,
      forService: itemName,
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )
  }

  private func authorizationData(
    fromAuthorization authorization: GTMAppAuthFetcherAuthorization
  ) throws -> Data {
    let authorizationData: Data
    if #available(macOS 10.13, iOS 11, tvOS 11, watchOS 4, *) {
      do {
        authorizationData = try NSKeyedArchiver.archivedData(
          withRootObject: authorization,
          requiringSecureCoding: true
        )
      } catch {
        throw GTMKeychainError.failedToConvertAuthorizationToData
      }
    } else {
      authorizationData = NSKeyedArchiver.archivedData(withRootObject: authorization)
    }
    return authorizationData
  }

  @objc public func removeAuthorization(withItemName itemName: String) throws {
    try keychainHelper.removePassword(forService: itemName)
  }

  @objc public func removeAuthorization() throws {
    try keychainHelper.removePassword(forService: credentialItemName)
  }

  @objc public func authorization(
    forItemName itemName: String
  ) throws -> GTMAppAuthFetcherAuthorization {
    let passwordData = try keychainHelper.passwordData(forService: itemName)

    if #available(macOS 10.13, iOS 11, tvOS 11, watchOS 4, *) {
      return try modernUnarchiveAuthorization(withPasswordData: passwordData, itemName: itemName)
    } else {
      guard let auth = NSKeyedUnarchiver.unarchiveObject(with: passwordData)
              as? GTMAppAuthFetcherAuthorization else {
        throw GTMAppAuthFetcherAuthorization
          .Error
          .failedToConvertKeychainDataToAuthorization(forItemName: itemName)
      }
      return auth
    }
  }

  @objc public func retrieveAuthorization() throws -> GTMAppAuthFetcherAuthorization {
    let passwordData = try keychainHelper.passwordData(forService: credentialItemName)

    if #available(macOS 10.13, iOS 11, tvOS 11, watchOS 4, *) {
      return try modernUnarchiveAuthorization(
        withPasswordData: passwordData,
        itemName: credentialItemName
      )
    } else {
      guard let auth = NSKeyedUnarchiver.unarchiveObject(with: passwordData)
              as? GTMAppAuthFetcherAuthorization else {
        throw GTMAppAuthFetcherAuthorization
          .Error
          .failedToConvertKeychainDataToAuthorization(forItemName: credentialItemName)
      }
      return auth
    }
  }
}

// MARK: - OAuth2CompatibilityCredentialStore Conformance

extension GTMKeychain: OAuth2CompatibilityCredentialStore {
  @objc public func authorization(
    forItemName itemName: String,
    tokenURL: URL,
    redirectURI: String,
    clientID: String,
    clientSecret: String?
  ) throws -> GTMAppAuthFetcherAuthorization {
    let password = try keychainHelper.password(forService: itemName)
    let authorization = try authorization(
      forPersistenceString: password,
      tokenURL: tokenURL,
      redirectURI: redirectURI,
      clientID: clientID,
      clientSecret: clientSecret
    )
    return authorization
  }

  @objc public func authorization(
    forPersistenceString persistenceString: String,
    tokenURL: URL,
    redirectURI: String,
    clientID: String,
    clientSecret: String?
  ) throws -> GTMAppAuthFetcherAuthorization {
    let persistenceDictionary = GTMOAuth2KeychainCompatibility.dictionary(
      fromKeychainPassword: persistenceString
    )
    guard let redirectURL = URL(string: redirectURI) else {
      throw GTMKeychainError.failedToConvertRedirectURItoURL(redirectURI)
    }

    let authConfig = OIDServiceConfiguration(
      authorizationEndpoint: tokenURL,
      tokenEndpoint: tokenURL
    )

    let authRequest = OIDAuthorizationRequest(
      configuration: authConfig,
      clientId: clientID,
      clientSecret: clientSecret,
      scope: persistenceDictionary[oauth2ScopeKey],
      redirectURL: redirectURL,
      responseType: OIDResponseTypeCode,
      state: nil,
      nonce: nil,
      codeVerifier: nil,
      codeChallenge: nil,
      codeChallengeMethod: nil,
      additionalParameters: nil
    )

    let authResponse = OIDAuthorizationResponse(
      request: authRequest,
      parameters: persistenceDictionary as [String: NSString]
    )
    var additionalParameters = persistenceDictionary
    additionalParameters.removeValue(forKey: oauth2ScopeKey)
    additionalParameters.removeValue(forKey: oauth2RefreshTokenKey)

    let tokenRequest = OIDTokenRequest(
      configuration: authConfig,
      grantType: "token",
      authorizationCode: nil,
      redirectURL: redirectURL,
      clientID: clientID,
      clientSecret: clientSecret,
      scope: persistenceDictionary[oauth2ScopeKey],
      refreshToken: persistenceDictionary[oauth2RefreshTokenKey],
      codeVerifier: nil,
      additionalParameters: additionalParameters
    )
    let tokenResponse = OIDTokenResponse(
      request: tokenRequest,
      parameters: persistenceDictionary as [String: NSString]
    )

    let authState = OIDAuthState(authorizationResponse: authResponse, tokenResponse: tokenResponse)
    // We're not serializing the token expiry date, so the first refresh needs to be forced.
    authState.setNeedsTokenRefresh()

    let authorization = GTMAppAuthFetcherAuthorization(
      authState: authState,
      serviceProvider: persistenceDictionary[GTMAppAuthFetcherAuthorization.serviceProviderKey],
      userID: persistenceDictionary[GTMAppAuthFetcherAuthorization.userIDKey],
      userEmail: persistenceDictionary[GTMAppAuthFetcherAuthorization.userEmailKey],
      userEmailIsVerified: persistenceDictionary[GTMAppAuthFetcherAuthorization.userEmailIsVerifiedKey]
    )
    return authorization
  }

  @objc public func authForGoogle(
    forItemName itemName: String,
    clientID: String,
    clientSecret: String
  ) throws -> GTMAppAuthFetcherAuthorization {
    return try authorization(
      forItemName: itemName,
      tokenURL: GTMOAuth2KeychainCompatibility.googleTokenURL,
      redirectURI: GTMOAuth2KeychainCompatibility.nativeClientRedirectURI,
      clientID: clientID,
      clientSecret: clientSecret
    )
  }

  @objc public func saveWithOAuth2Format(
    forAuthorization authorization: GTMAppAuthFetcherAuthorization,
    withItemName itemName: String
  ) throws {
    guard let persistence = GTMOAuth2KeychainCompatibility
      .persistenceResponseStringForAuthorization(authorization) else {
      throw GTMKeychainError.failedToCreateResponseStringFromAuthorization(authorization)
    }
    try keychainHelper.setPassword(
      persistence,
      forService: itemName,
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)
  }

  @objc public func removeOAuth2Authorization(withItemName itemName: String) throws {
    try keychainHelper.removePassword(forService: itemName)
  }
}

// MARK: - Keychain Errors

/// Errors that may arise while saving, reading, and removing passwords from the Keychain.
public enum GTMKeychainError: Error, Equatable, CustomNSError {
  case unhandled(status: OSStatus)
  case passwordNotFound(forItemName: String)
  /// Error thrown when there is no name for the item in the keychain.
  case noService
  case unexpectedPasswordData(forItemName: String)
  case failedToCreateResponseStringFromAuthorization(GTMAppAuthFetcherAuthorization)
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

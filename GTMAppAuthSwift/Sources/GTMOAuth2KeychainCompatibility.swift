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
import AppAuthCore
import GTMSessionFetcherCore

// Standard OAuth keys
let oauth2AccessTokenKey = "access_token"
let oauth2RefreshTokenKey = "refresh_token"
let oauth2ScopeKey = "scope"
let oauth2ErrorKey = "error"
let oauth2TokenTypeKey = "token_type"
let oauth2ExpiresInKey = "expires_in"
let oauth2CodeKey = "code"
let oauth2AssertionKey = "assertion"
let oauth2RefreshScopeKey = "refreshScope"

// URI indicating an installed app is signing in. This is described at
//
// https://developers.google.com/identity/protocols/OAuth2InstalledApp#formingtheurl
//
let oobString = "urn:ietf:wg:oauth:2.0:oob"

/// Class to support serialization and deserialization of @c GTMAppAuthFetcherAuthorization
/// in the format used by GTMOAuth2.
///
/// The methods of this class are capable of serializing and deserializing auth objects in a way
/// compatible with the serialization in @c GTMOAuth2ViewControllerTouch and
/// `GTMOAuth2WindowController` in GTMOAuth2.
@objc public final class GTMOAuth2KeychainCompatibility: NSObject {
  static var keychain: GTMKeychain?

/// Encodes the given @c GTMAppAuthFetcherAuthorization in a GTMOAuth2 compatible persistence
/// string using URL param key/value encoding.
///
/// - Parameters:
///   - authorization: The `GTMAppAuthFetcherAuthorization` to serialize in GTMOAuth2 format.
/// - Returns: An `String?` representing the GTMOAuth2 persistence representation of the
/// authorization object.
  @objc public static func persistenceResponseStringForAuthorization(
    _ authorization: GTMAppAuthFetcherAuthorization
  ) -> String? {
    let refreshToken = authorization.authState.refreshToken
    let accessToken = authorization.authState.lastTokenResponse?.accessToken

    let dict = [
      oauth2RefreshTokenKey: refreshToken,
      oauth2AccessTokenKey: accessToken,
      serviceProviderKey: authorization.serviceProvider,
      userIDKey: authorization.userID,
      userEmailKey: authorization.userEmail,
      userEmailIsVerifiedKey: authorization._userEmailIsVerified,
      oauth2ScopeKey: authorization.authState.scope
    ]

    var result = ""
    var joiner = ""
    dict
      .sorted { $0.key < $1.key }
      .compactMap { key, value in
        if let val = dict[key] as? String {
          return (key, val)
        } else {
          return nil
        }
      }
      .forEach { (keyValue: (key: String, value: String)) in
        if let encodedKey = encodedOAuthValue(originalString: keyValue.key),
           let encodedValue = encodedOAuthValue(originalString: keyValue.value) {
          result = result.appendingFormat("%@%@=%@", joiner, encodedKey, encodedValue)
        }
        joiner = "&"
      }

    return !result.isEmpty ? result : nil
  }

  // MARK: - Encoded OAuth Value

  private static func encodedOAuthValue(originalString: String) -> String? {
    // For parameters, we'll explicitly leave spaces unescaped now, and replace them with +'s
    let forceEscape = "!*'();:@&=+$,/?%#[]"
    let escapeCharacters = CharacterSet(charactersIn: forceEscape)
    let urlQueryCharacters = CharacterSet.urlQueryAllowed.symmetricDifference(escapeCharacters)
    return originalString.addingPercentEncoding(withAllowedCharacters: urlQueryCharacters)
  }

  // MARK: - OAuth2

/// Attempts to create a `GTMAppAuthFetcherAuthorization` from data stored in the keychain in
/// GTMOAuth2 format, at the supplied keychain identifier.
///
/// - Parameters:
///   - name: The keychain name.
///   - tokenURL: The OAuth token endpoint URL.
///   - redirectURI: The OAuth redirect URI used when obtaining the original authorization.
///   - clientID: The OAuth client id.
///   - clientSecret: The OAuth client secret.
/// - Returns: A `GTMAppAuthFetcherAuthorization` object, or nil.
/// - Throws: An Instance of `GTMOAuth2KeychainCompatibility.Error` arising from the retrieval.
  @objc public static func authorizeFromKeychain(
    forName name: String,
    tokenURL: URL,
    redirectURI: String,
    clientID: String,
    clientSecret: String?
  ) throws -> GTMAppAuthFetcherAuthorization {
    let keychain = keychain ?? GTMKeychain()

    let password = try keychain.password(forName: name)
    let authorization = try authorizeFromKeychain(
      forPersistenceString: password,
      tokenURL: tokenURL,
      redirectURI: redirectURI,
      clientID: clientID,
      clientSecret: clientSecret
    )
    return authorization
  }

/// Attempts to create a `GTMAppAuthFetcherAuthorization` from a `String` representation of the
/// GTMOAuth2 keychain data.
///
/// - Parameters:
///   - persistenceString: `String` representation of the GTMOAuth2 keychain data.
///   - tokenURL: The OAuth token endpoint URL.
///   - redirectURI: The OAuth redirect URI used when obtaining the original authorization.
///   - clientID: The OAuth client id.
///   - clientSecret: The OAuth client secret.
/// - Returns: A `GTMAppAuthFetcherAuthorization` object, or nil.
/// - Throws: An Instance of `GTMOAuth2KeychainCompatibility.Error` arising from the retrieval.
  @objc public static func authorizeFromKeychain(
    forPersistenceString persistenceString: String,
    tokenURL: URL,
    redirectURI: String,
    clientID: String,
    clientSecret: String?
  ) throws -> GTMAppAuthFetcherAuthorization {
    let persistenceDictionary = dictionary(from: persistenceString)
    guard let redirectURL = URL(string: redirectURI) else {
      throw Error.failedToConvertRedirectURItoURL(redirectURI)
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
      serviceProvider: persistenceDictionary[serviceProviderKey],
      userID: persistenceDictionary[userIDKey],
      userEmail: persistenceDictionary[userEmailKey],
      userEmailIsVerified: persistenceDictionary[userEmailIsVerifiedKey]
    )
    return authorization
  }


/// Attempts to create a @c GTMAppAuthFetcherAuthorization from data stored in the keychain in
/// GTMOAuth2 format, at the supplied keychain identifier. Uses Google OAuth provider information.
///
/// - Parameters:
///   - name: The keychain name.
///   - clientID: The OAuth client id.
///   - clientSecret: The OAuth client secret.
/// - Returns: A `GTMAppAuthFetcherAuthorization` object, or nil.
/// - Throws: An Instance of `GTMOAuth2KeychainCompatibility.Error` arising from the retrieval.
  @objc public static func authForGoogleFromKeychain(
    for name: String,
    clientID: String,
    clientSecret: String
  ) throws -> GTMAppAuthFetcherAuthorization {
    return try authorizeFromKeychain(
      forName: name,
      tokenURL: googleTokenURL,
      redirectURI: nativeClientRedirectURI,
      clientID: clientID,
      clientSecret: clientSecret
    )
  }

/// Saves the authorization state to the keychain, in a GTMOAuth2 compatible manner.
///
/// - Parameters:
///   - authorization: The `GTMAppAuthFetcherAuthorization` to save to the keychain.
///   - name: The keychain name.
/// - Throws: An Instance of `GTMOAuth2KeychainCompatibility.Error` arising from the save.
  @available(*, deprecated, message: "Use GTMAppAuthFetcherAuthorization.save(authorization:with:)")
  @objc public static func save(
    authorization: GTMAppAuthFetcherAuthorization,
    for name: String
  ) throws {
    guard let password = persistenceResponseStringForAuthorization(authorization) else {
      throw Error.failedToCreateResponseStringFromAuthorization(authorization)
    }

    let keychain = keychain ?? GTMKeychain()
    try keychain.save(password: password, forName: name)
  }

/// Removes stored tokens, such as when the user signs out.
///
/// - Parameters:
///   - name: The keychain name.
/// - Throws: An Instance of `GTMOAuth2KeychainCompatibility.Error` arising from the removal.
  @objc public static func removeAuthorizationFromKeychain(for name: String) throws {
    let keychain = keychain ?? GTMKeychain()

    try keychain.removePasswordFromKeychain(forName: name)
  }

  // MARK: - OAuth2 Utilities

  private static var googleAuthorizationURL: URL {
    return URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
  }

  private static var googleTokenURL: URL {
    return URL(string: "https://www.googleapis.com/oauth2/v4/token")!
  }

  private static var googleRevocationURL: URL {
    return URL(string: "https://accounts.google.com/o/oauth2/revoke")!
  }

  private static var googleUserInfoURL: URL {
    return URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!
  }

  private static var nativeClientRedirectURI: String {
    return oobString
  }

  private static func dictionary(from keychainPassword: String) -> [String: String] {
    let keyValueTuples: [(String, String)] = keychainPassword
      .components(separatedBy: "&")
      .compactMap {
        let equalComps = $0.components(separatedBy: "=")
        guard let key = equalComps.first,
              let percentsRemovedKey = key.removingPercentEncoding,
              let value = equalComps.last,
              let percentsRemovedValue = value.removingPercentEncoding else {
          return nil
        }
        return (percentsRemovedKey, percentsRemovedValue)
      }
    let passwordDictionary = Dictionary(uniqueKeysWithValues: keyValueTuples)
    return passwordDictionary
  }
}

public extension GTMOAuth2KeychainCompatibility {
  /// Errors arising when saving, reading, or removing OAuth2 authorizations from the Keychain.
  enum Error: Swift.Error, CustomNSError, Equatable {
    case failedToConvertRedirectURItoURL(String)
    case failedToCreateResponseStringFromAuthorization(GTMAppAuthFetcherAuthorization)

    public static var errorDomain: String {
      "GTMOauth2KeychainCompatibilityErrorDomain"
    }
  }
}

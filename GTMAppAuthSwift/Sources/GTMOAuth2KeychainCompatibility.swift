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
// Ensure that we import the correct dependency for both SPM and CocoaPods since
// the latter doesn't define separate Clang modules for subspecs
#if SWIFT_PACKAGE
import AppAuthCore
import GTMSessionFetcherCore
#else
import AppAuth
import GTMSessionFetcher
#endif

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

/// Class to support serialization and deserialization of `GTMAppAuthFetcherAuthorization` in the
/// format used by GTMOAuth2.
///
/// The methods of this class are capable of serializing and deserializing auth objects in a way
/// compatible with the serialization in `GTMOAuth2ViewControllerTouch` and
/// `GTMOAuth2WindowController` in GTMOAuth2.
@objc public final class GTMOAuth2KeychainCompatibility: NSObject {
  static var keychain: GTMKeychain?

  /// Encodes the given `GTMAppAuthFetcherAuthorization` in a GTMOAuth2 compatible persistence
  /// string using URL param key/value encoding.
  ///
  /// - Parameters:
  ///   - authorization: The `GTMAppAuthFetcherAuthorization` to serialize in GTMOAuth2 format.
  /// - Returns: A `String?` representing the GTMOAuth2 persistence representation of the
  ///   authorization object.
  @objc public static func persistenceResponseStringForAuthorization(
    _ authorization: GTMAppAuthFetcherAuthorization
  ) -> String? {
    // TODO: (mdmathias) Write a test for this method that ensures nil is returned.
    let refreshToken = authorization.authState.refreshToken
    let accessToken = authorization.authState.lastTokenResponse?.accessToken

    let dict = [
      oauth2RefreshTokenKey: refreshToken,
      oauth2AccessTokenKey: accessToken,
      GTMAppAuthFetcherAuthorization.serviceProviderKey: authorization.serviceProvider,
      GTMAppAuthFetcherAuthorization.userIDKey: authorization.userID,
      GTMAppAuthFetcherAuthorization.userEmailKey: authorization.userEmail,
      GTMAppAuthFetcherAuthorization.userEmailIsVerifiedKey: authorization._userEmailIsVerified,
      oauth2ScopeKey: authorization.authState.scope
    ]

    let responseString = dict
      .sorted { $0.key < $1.key }
      .compactMap { (key, _) -> String? in
        guard let val = dict[key] as? String,
              let encodedKey = encodedOAuthValue(forOriginalString: key),
              let encodedValue = encodedOAuthValue(forOriginalString: val) else {
          return nil
        }
        return String(format: "%@=%@", arguments: [encodedKey, encodedValue])
      }
      .joined(separator: "&")

    return responseString.isEmpty ? nil : responseString
  }

  // MARK: - Encoded OAuth Value

  private static func encodedOAuthValue(
    forOriginalString originalString: String
  ) -> String? {
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
  ///   - itemName: The keychain name.
  ///   - tokenURL: The OAuth token endpoint URL.
  ///   - redirectURI: The OAuth redirect URI used when obtaining the original authorization.
  ///   - clientID: The OAuth client ID.
  ///   - clientSecret: The OAuth client secret.
  /// - Returns: A `GTMAppAuthFetcherAuthorization` object, or nil.
  /// - Throws: An instance of `GTMOAuth2KeychainCompatibility.Error` arising from the retrieval.
  @objc public static func authorizeFromKeychain(
    forItemName itemName: String,
    tokenURL: URL,
    redirectURI: String,
    clientID: String,
    clientSecret: String?
  ) throws -> GTMAppAuthFetcherAuthorization {
    let keychain = keychain ?? GTMKeychain()

    let password = try keychain.password(forItemName: itemName)
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
  ///   - clientID: The OAuth client ID.
  ///   - clientSecret: The OAuth client secret.
  /// - Returns: A `GTMAppAuthFetcherAuthorization` object, or nil.
  /// - Throws: An instance of `GTMOAuth2KeychainCompatibility.Error` arising from the retrieval.
  @objc public static func authorizeFromKeychain(
    forPersistenceString persistenceString: String,
    tokenURL: URL,
    redirectURI: String,
    clientID: String,
    clientSecret: String?
  ) throws -> GTMAppAuthFetcherAuthorization {
    let persistenceDictionary = dictionary(fromKeychainPassword: persistenceString)
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
      serviceProvider: persistenceDictionary[GTMAppAuthFetcherAuthorization.serviceProviderKey],
      userID: persistenceDictionary[GTMAppAuthFetcherAuthorization.userIDKey],
      userEmail: persistenceDictionary[GTMAppAuthFetcherAuthorization.userEmailKey],
      userEmailIsVerified: persistenceDictionary[GTMAppAuthFetcherAuthorization.userEmailIsVerifiedKey]
    )
    return authorization
  }

  /// Attempts to create a `GTMAppAuthFetcherAuthorization` from data stored in the keychain in
  /// GTMOAuth2 format, at the supplied keychain identifier.
  ///
  /// Uses Google OAuth provider information.
  ///
  /// - Parameters:
  ///   - itemName: The keychain name.
  ///   - clientID: The OAuth client id.
  ///   - clientSecret: The OAuth client secret.
  /// - Returns: A `GTMAppAuthFetcherAuthorization` object, or nil.
  /// - Throws: An instance of `GTMOAuth2KeychainCompatibility.Error` arising from the retrieval.
  @objc(authForGoogleFromKeychainForName:clientID:clientSecret:error:)
  public static func authForGoogleFromKeychain(
    forKeychainItemName itemName: String,
    clientID: String,
    clientSecret: String
  ) throws -> GTMAppAuthFetcherAuthorization {
    return try authorizeFromKeychain(
      forItemName: itemName,
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
  ///   - itemName: The keychain name.
  /// - Throws: An instance of `GTMOAuth2KeychainCompatibility.Error` arising from the save.
  @available(*, deprecated, message: "Use GTMAppAuthFetcherAuthorization.save(authorization:with:)")
  @objc(saveAuthorization:forName:error:)
  public static func save(
    authorization: GTMAppAuthFetcherAuthorization,
    forKeychainItemName itemName: String
  ) throws {
    // TODO: (mdmathias) Write a test ensuring this error is thrown.
    guard let password = persistenceResponseStringForAuthorization(authorization) else {
      throw Error.failedToCreateResponseStringFromAuthorization(authorization)
    }

    let keychain = keychain ?? GTMKeychain()
    try keychain.save(password: password, forItemName: itemName)
  }

  /// Removes stored tokens, such as when the user signs out.
  ///
  /// - Parameters:
  ///   - itemName: The keychain name.
  /// - Throws: An instance of `GTMOAuth2KeychainCompatibility.Error` arising from the removal.
  @objc(removeAuthorizationFromKeychainForName:error:)
  public static func removeAuthorizationFromKeychain(forItemName itemName: String) throws {
    let keychain = keychain ?? GTMKeychain()
    try keychain.removePasswordFromKeychain(withItemName: itemName)
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

  private static func dictionary(
    fromKeychainPassword keychainPassword: String
  ) -> [String: String] {
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

    public var errorUserInfo: [String : Any] {
      switch self {
      case .failedToConvertRedirectURItoURL(let uri):
        return ["uri": uri]
      case .failedToCreateResponseStringFromAuthorization(let authorization):
        return ["authorization": authorization]
      }
    }
  }
}

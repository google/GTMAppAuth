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

/// An implementation of the @c GTMFetcherAuthorizationProtocol protocol for the AppAuth library.
///
/// Enables you to use AppAuth with the GTM Session Fetcher library.
@objc open class GTMAppAuthFetcherAuthorization: NSObject,
                                                 GTMFetcherAuthorizationProtocol,
                                                 NSSecureCoding {
  // MARK: - Retrieving Authorizations

  /// Internally scoped helper for used for setting the keychain to a fake in tests.
  static var keychain: GTMKeychain?

  /// Retrieves the saved authorization for the supplied name.
  ///
  /// - Parameter itemName: The `String` name for the save authorization.
  /// - Throws: An instance of `GTMKeychainManager.Error` if retrieving the authorization failed.
  @objc public final class func authorization(
    for itemName: String
  ) throws -> GTMAppAuthFetcherAuthorization {
    let keychain = keychain ?? GTMKeychain()
    let passwordData = try? keychain.passwordData(forName: itemName)

    if #available(macOS 10.13, iOS 11, tvOS 11, *) {
      return try modernUnarchiveAuthorization(with: passwordData, itemName: itemName)
    }

    guard let passwordData = passwordData,
          let auth = NSKeyedUnarchiver.unarchiveObject(with: passwordData)
            as? GTMAppAuthFetcherAuthorization else {
      throw GTMAppAuthFetcherAuthorization
        .Error
        .failedToRetrieveAuthorizationFromKeychain(forItemName: itemName)
    }
    return auth
  }

  /// Retrieves the saved authorization for the supplied name.
  ///
  /// - Parameters:
  ///   - itemName: The `String` name for the save authorization.
  ///   - usingDataProtectionKeychain: A `Bool` detailing whether or not to use the data protection
  ///     keychain.
  /// - Throws: An instance of `KeychainWrapper.Error` if retrieving the authorization failed.
  @available(macOS 10.15, *)
  @objc public final class func authorization(
    for itemName: String,
    usingDataProtectionKeychain: Bool
  ) throws -> GTMAppAuthFetcherAuthorization {
    let keychain = keychain ?? GTMKeychain()
    let passwordData = try? keychain.passwordData(
      forName: itemName,
      usingDataProtectionKeychain: usingDataProtectionKeychain
    )
    guard let passwordData = passwordData,
          let authorization = NSKeyedUnarchiver.unarchiveObject(with: passwordData)
            as? GTMAppAuthFetcherAuthorization  else {
      throw GTMAppAuthFetcherAuthorization
        .Error
        .failedToRetrieveAuthorizationFromKeychain(forItemName: itemName)
    }
    return authorization
  }

  @available(macOS 10.13, iOS 11, tvOS 11, *)
  private final class func modernUnarchiveAuthorization(
    with passwordData: Data?,
    itemName: String
  ) throws -> GTMAppAuthFetcherAuthorization {
    guard let passwordData = passwordData,
          let authorization = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: GTMAppAuthFetcherAuthorization.self,
            from: passwordData
          ) else {
      throw GTMAppAuthFetcherAuthorization
        .Error
        .failedToRetrieveAuthorizationFromKeychain(forItemName: itemName)
    }
    return authorization
  }

  // MARK: - Removing Authorizations

  /// Removes the saved authorization for the supplied name.
  ///
  /// - Parameter itemName: The `String` name for the authorization saved in the keychain.
  /// - Throws: Any error that may arise during removal, including `KeychainWrapper.Error`.
  @objc public final class func removeAuthorization(for itemName: String) throws {
    let keychain = keychain ?? GTMKeychain()
    try keychain.removePasswordFromKeychain(forName: itemName)
  }

  /// Removes the saved authorization for the supplied name.
  ///
  /// - Parameters:
  ///   - itemName: The `String` name for the authorization saved in the keychain.
  ///   - usingDataProtectionKeychain: A `Bool` detailing whether or not to use the data protection
  ///     keychain.
  /// - Throws: Any error that may arise during removal, including `KeychainWrapper.Error`.
  @available(macOS 10.15, *)
  @objc public final class func removeAuthorization(
    for itemName: String,
    usingDataProtectionKeychain: Bool
  ) throws {
    let keychain = keychain ?? GTMKeychain()
    try keychain.removePasswordFromKeychain(
      forName: itemName,
      usingDataProtectionKeychain: usingDataProtectionKeychain
    )
  }

  // MARK: - Saving Authorizations

  /// Saves the passed authorization with the provided name.
  ///
  /// - Parameters:
  ///   - authorization: An instance of `GMTAppAuthFetcherAuthorization`.
  ///   - itemName: The `String` name for the authorization to save in the Keychain.
  /// - Throws: Any error that may arise during removal, including `KeychainWrapper.Error`.
  @objc public final class func save(
    authorization: GTMAppAuthFetcherAuthorization,
    with itemName: String
  ) throws {
    let keychain = keychain ?? GTMKeychain()
    if #available(macOS 10.13, iOS 11, tvOS 11, *) {
      let authorizationData = try NSKeyedArchiver.archivedData(
        withRootObject: authorization,
        requiringSecureCoding: true
      )
      try keychain.save(passwordData: authorizationData,forName: itemName)
    } else {
      let authorizationData = NSKeyedArchiver.archivedData(withRootObject: authorization)
      try keychain.save(passwordData: authorizationData, forName: itemName)
    }
  }

  /// Saves the passed authorization with the provided name.
  ///
  /// - Parameters:
  ///   - authorization: An instance of `GMTAppAuthFetcherAuthorization`.
  ///   - itemName: The `String` name for the authorization to save in the Keychain.
  ///   - usingDataProtectionKeychain: A `Bool` detailing whether or not to use the data protection
  ///     keychain.
  /// - Throws: Any error that may arise during removal, including `KeychainWrapper.Error`.
  @available(macOS 10.15, *)
  @objc public final class func save(
    authorization: GTMAppAuthFetcherAuthorization,
    with itemName: String,
    usingDataProtectionKeychain: Bool
  ) throws {
    let keychain = keychain ?? GTMKeychain()
    let authorizationData = NSKeyedArchiver.archivedData(withRootObject: authorization)
    try keychain.save(
      passwordData: authorizationData,
      forName: itemName,
      usingDataProtectionKeychain: usingDataProtectionKeychain
    )
  }

  /// The AppAuth authentication state.
  @objc public let authState: OIDAuthState

  /// Service identifier, for example "Google"; not used for authentication.
  ///
  /// The provider name is just for allowing stored authorization to be associated with the
  /// authorizing service.
  @objc public let serviceProvider: String?

  /// User ID from the ID Token.
  ///
  /// Never send this value to your backend as an authentication token, rather send an ID Token and
  /// validate it.
  @objc public let userID: String?

  /// The user email.
  @objc public let userEmail: String?

  /// The verified string.
  ///
  /// If the result is false, then the email address is listed with the account on the server, but
  /// the address has not been confirmed as belonging to the owner of the account.
  private let _userEmailIsVerified: String?

  /// Email verified status; not used for authentication.
  @objc public var userEmailIsVerified: Bool {
    guard let verification = _userEmailIsVerified else {
      return false
    }
    return (verification as NSString).boolValue
  }

  /// For development only, allow authorization of non-SSL requests, allowing transmission of the
  /// bearer token unencrypted.
  @objc public var shouldAuthorizeAllRequests = false

  /// Delegate of the `GTMAppAuthFetcherAuthorization` used to supply additional parameters on token
  /// refresh.
  @objc public weak var tokenRefreshDelegate: GTMAppAuthFetcherAuthorizationTokenRefreshDelegate?

  /// The fetcher service.
  @objc public var fetcherService: GTMSessionFetcherServiceProtocol? = nil

  private let serialAuthArgsQueue = DispatchQueue(label: "com.google.gtmappauth")
  private var authorizationArgs = [AuthorizationArguments]()

  // MARK: - Keys

  private let authStateKey = "authState"
  private let serviceProviderKey = "serviceProvider"
  private let userIDKey = "userID"
  private let userEmailKey = "userEmail"
  private let userEmailIsVerifiedKey = "userEmailIsVerified"

  /// Creates a new `GTMAppAuthFetcherAuthorization` using the given `OIDAuthState` from AppAuth.
  ///
  /// - Parameters:
  ///   - authState: The authorization state.
  ///   - serviceProvider: An optional string to describe the service.
  ///   - userID: An optional string of the user ID.
  ///   - userEmail: An optional string of the user's email address.
  ///   - userEmailIsVerified: An optional string representation of a boolean to indicate
  ///     that the email address has been verified. Pass "true" or "false".
  @objc public init(
    authState: OIDAuthState,
    serviceProvider: String? = nil,
    userID: String? = nil,
    userEmail: String? = nil,
    userEmailIsVerified: String? = nil
  ) {
    self.authState = authState
    self.serviceProvider = serviceProvider

    if let idToken = authState.lastTokenResponse?.idToken ??
        authState.lastAuthorizationResponse.idToken,
       let claims = OIDIDToken(
        idTokenString: idToken
       )?.claims as? [String: String] {
      self.userID = claims["sub"]
      self.userEmail = claims["email"]
      self._userEmailIsVerified = claims["email_verified"]
    } else {
      self.userID = userID
      self.userEmail = userEmail
      self._userEmailIsVerified = userEmailIsVerified
    }
    super.init()
  }

  // MARK: - Secure Coding

  @objc public static let supportsSecureCoding = true

  @objc public func encode(with coder: NSCoder) {
    coder.encode(authState, forKey: authStateKey)
    coder.encode(serviceProvider, forKey: serviceProviderKey)
    coder.encode(userID, forKey: userIDKey)
    coder.encode(userEmail, forKey: userEmailKey)
    coder.encode(_userEmailIsVerified, forKey: userEmailIsVerifiedKey)
  }

  @objc public required init?(coder: NSCoder) {
    guard let authState = coder.decodeObject(of: OIDAuthState.self, forKey: authStateKey),
          let serviceProvider = coder
      .decodeObject(of: NSString.self, forKey: serviceProviderKey) as? String,
          let userID = coder
      .decodeObject(of: NSString.self, forKey: userIDKey) as? String,
          let userEmail = coder
      .decodeObject(of: NSString.self, forKey: userEmailKey) as? String,
          let userEmailIsVerified = coder
      .decodeObject(of: NSString.self, forKey: userEmailIsVerifiedKey) as? String
    else {
      return nil
    }
    self.authState = authState
    self.serviceProvider = serviceProvider
    self.userID = userID
    self.userEmail = userEmail
    self._userEmailIsVerified = userEmailIsVerified
  }

  // MARK: - Authorizing Requests (GTMFetcherAuthorizationProtocol)

  /// Adds an authorization header to the given request, using the authorization state. Refreshes
  /// the access token if needed.
  ///
  /// - Parameters:
  ///   - request: The request to authorize.
  ///   - handler: The block that is called after authorizing the request is attempted. If `error`
  ///     is non-nil, the authorization failed. Errors in the domain `OIDOAuthTokenErrorDomain`
  ///     indicate that the authorization itself is invalid, and will need to be re-obtained from
  ///     the user. `GTMAppAuthFetcherAuthorization.Error` indicate another unrecoverable error.
  ///     Errors in other domains may indicate a transitive error condition such as a network error,
  ///     and typically you do not need to reauthenticate the user on such errors.
  ///
  /// The completion handler is scheduled on the main thread, unless the `callbackQueue` property is
  /// set on the `fetcherService` in which case the handler is scheduled on that queue.
  @objc public func authorizeRequest(
    _ request: NSMutableURLRequest?,
    completionHandler handler: @escaping (Swift.Error?) -> Void
  ) {
    guard let request = request else { return }
    let arguments = AuthorizationArguments(
      request: request,
      callbackStyle: .completion(handler)
    )
    authorizeRequest(withArguments: arguments)
  }

  /// Adds an authorization header to the given request, using the authorization state. Refreshes
  /// the access token if needed.
  ///
  /// - Parameters:
  ///   - request: The request to authorize.
  ///   - delegate: The delegate to receive the callback.
  ///   - sel: The `Selector` to call upon the provided `delegate`.
  @objc public func authorizeRequest(
    _ request: NSMutableURLRequest?,
    delegate: Any,
    didFinish sel: Selector
  ) {
    guard let request = request else { return }
    let arguments = AuthorizationArguments(
      request: request,
      callbackStyle: .delegate(delegate, sel)
    )
    authorizeRequest(withArguments: arguments)
  }

  private func authorizeRequest(withArguments args: AuthorizationArguments) {
    serialAuthArgsQueue.sync {
      authorizationArgs.append(args)
    }
    let additionalRefreshParameters = tokenRefreshDelegate?
      .additionalRefreshParameters(authorization: self)

    let authStateAction = {
      (accessToken: String?, idToken: String?, error: Swift.Error?) in
      self.serialAuthArgsQueue.sync { [weak self] in
        guard let self = self else { return }
        for queuedArgs in self.authorizationArgs {
          self.authorizeRequestImmediately(
            args: queuedArgs,
            accessToken: accessToken
          )
        }
        self.authorizationArgs.removeAll()
      }
    }
    authState.performAction(
      freshTokens: authStateAction,
      additionalRefreshParameters: additionalRefreshParameters
    )
  }

  private func authorizeRequestImmediately(
    args: AuthorizationArguments,
    accessToken: String?
  ) {
    var args = args
    let request = args.request
    let requestURL = request.url
    let scheme = requestURL?.scheme
    let isAuthorizableRequest = requestURL == nil
      || scheme?.caseInsensitiveCompare("https") == .orderedSame
      || requestURL?.isFileURL ?? false
      || shouldAuthorizeAllRequests

    if !isAuthorizableRequest {
      //
      #if DEBUG
      print(
"""
Request (\(request)) is not https, a local file, or nil. It may be insecure.
"""
      )
      #endif
    }

    if isAuthorizableRequest,
        let accessToken = accessToken,
        !accessToken.isEmpty {
      request.setValue(
        "Bearer \(accessToken)",
        forHTTPHeaderField: "Authorization"
      )
      // `request` is authorized even if previous refreshes produced an error
      args.error = nil
    } else if accessToken?.isEmpty ?? true {
      args.error = Error.accessTokenEmptyForRequest(request)
    } else {
      args.error = Error.cannotAuthorizeRequest(request)
    }

    let callbackQueue = fetcherService?.callbackQueue ?? DispatchQueue.main
    callbackQueue.async { [weak self] in
      guard let self = self else { return }
      switch args.callbackStyle {
      case .completion(let callback):
        self.invokeCompletionCallback(with: callback, error: args.error)
      case .delegate(let delegate, let selector):
        self.invokeDelegateCallback(
          delegate: delegate,
          selector: selector,
          request: request,
          error: args.error
        )
      }
    }
  }

  private func invokeDelegateCallback(
    delegate: Any,
    selector: Selector,
    request: NSMutableURLRequest,
    error: Swift.Error?
  ) {
    guard let delegate = delegate as? NSObject,
          delegate.responds(to: selector) else {
      return
    }
    let authorization = self
    let methodImpl = delegate.method(for: selector)
    typealias DelegateCallback = @convention(c) (
      NSObject,
      Selector,
      GTMAppAuthFetcherAuthorization,
      NSMutableURLRequest,
      NSError?
    ) -> Void
    let authorizeRequest: DelegateCallback = unsafeBitCast(
      methodImpl,
      to: DelegateCallback.self
    )
    authorizeRequest(
      delegate,
      selector,
      authorization,
      request,
      error as? NSError
    )
  }

  private func invokeCompletionCallback(
    with handler: (Swift.Error?) -> Void,
    error: Swift.Error?
  ) {
    handler(error)
  }

  // MARK: - Stopping Authorization

  /// Stops authorization for all pending requests.
  @objc public func stopAuthorization() {
    serialAuthArgsQueue.sync {
      authorizationArgs.removeAll()
    }
  }

  /// Stops authorization for the provided `URLRequest` if it is queued for authorization.
  @objc public func stopAuthorization(for request: URLRequest) {
    serialAuthArgsQueue.sync {
      guard let index = authorizationArgs.firstIndex(where: {
        $0.request as URLRequest == request
      }) else {
        return
      }
      authorizationArgs.remove(at: index)
    }
  }

  /// Returns `true` if the provided `URLRequest` is currently in the process of, or is in the queue
  /// for, authorization.
  @objc public func isAuthorizingRequest(_ request: URLRequest) -> Bool {
    var argsWithMatchingRequest: AuthorizationArguments?
    serialAuthArgsQueue.sync {
      argsWithMatchingRequest = authorizationArgs.first { args in
        args.request as URLRequest == request
      }
    }
    return argsWithMatchingRequest != nil
  }

  /// Returns `true` if the provided `URLRequest` has the "Authorization" header field.
  @objc public func isAuthorizedRequest(_ request: URLRequest) -> Bool {
    guard let authField = request.value(
      forHTTPHeaderField: "Authorization"
    ) else {
      return false
    }
    return !authField.isEmpty
  }

  /// Returns `true` if the authorization state is currently valid.
  ///
  /// This doesn't guarantee that a request will get a valid authorization, as the authorization
  /// state could become invalid on the next token refresh.
  @objc public var canAuthorize: Bool {
    return authState.isAuthorized
  }

  /// Whether or not this authorization is prime for refresh.
  ///
  /// - Returns: `false` if the `OIDAuthState`'s `refreshToken` is nil. `true` otherwise.
  ///
  /// If `true`, calling this method will `setNeedsTokenRefresh()` on the `OIDAuthState` instance
  /// property.
  @objc public func primeForRefresh() -> Bool {
    guard authState.refreshToken == nil else {
      return false
    }
    authState.setNeedsTokenRefresh()
    return true
  }

  /// Convenience method to return an @c OIDServiceConfiguration for Google.
  ///
  /// - Returns: An `OIDServiceConfiguration` object setup with Google OAuth endpoints.
  @objc public static func configurationForGoogle() -> OIDServiceConfiguration {
    let authzEndpoint = URL(
      string: "https://accounts.google.com/o/oauth2/v2/auth"
    )!
    let tokenEndpoint = URL(
      string: "https://www.googleapis.com/oauth2/v4/token"
    )!
    let configuration = OIDServiceConfiguration(
      authorizationEndpoint: authzEndpoint,
      tokenEndpoint: tokenEndpoint
    )
    return configuration
  }
}

private struct AuthorizationArguments {
  let request: NSMutableURLRequest
  let callbackStyle: CallbackStyle
  var error: Swift.Error?
}

extension AuthorizationArguments {
  enum CallbackStyle {
    case completion((Swift.Error?) -> Void)
    case delegate(Any, Selector)
  }
}

/// Delegate of the GTMAppAuthFetcherAuthorization used to supply additional parameters on token
/// refresh.
@objc public protocol GTMAppAuthFetcherAuthorizationTokenRefreshDelegate: NSObjectProtocol {
  func additionalRefreshParameters(
    authorization: GTMAppAuthFetcherAuthorization
  ) -> [String: String]?
}

public extension GTMAppAuthFetcherAuthorization {
  // MARK: - Errors

  /// Errors that may arise while authorizing a request or saving a request to the keychain.
  enum Error: Swift.Error, Equatable, CustomNSError {
    case cannotAuthorizeRequest(NSURLRequest)
    case accessTokenEmptyForRequest(NSURLRequest)
    case failedToRetrieveAuthorizationFromKeychain(forItemName: String)

    public static var errorDomain: String {
      "GTMAppAuthFetcherAuthorizationErrorDomain"
    }

    public var errorUserInfo: [String : Any] {
      switch self {
      case .cannotAuthorizeRequest(let request):
        return ["request": request]
      case .accessTokenEmptyForRequest(let request):
        return ["request": request]
      case .failedToRetrieveAuthorizationFromKeychain(forItemName: let name):
        return ["itemName": name]
      }
    }
  }
}

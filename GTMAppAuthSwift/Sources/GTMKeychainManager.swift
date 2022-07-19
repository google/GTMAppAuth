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

/// A class managing the reading and saving of `GTMAppAuthFetcherAuthorization` to the Keychain.
@objc public final class GTMKeychainManager: NSObject {
  private let keychainHelper: KeychainHelper
  private lazy var keychain: GTMKeychain = {
    GTMKeychain(keychainHelper: keychainHelper)
  }()

  init(keychainHelper: KeychainHelper) {
    self.keychainHelper = keychainHelper
  }

  @objc override public init() {
    self.keychainHelper = KeychainWrapper()
    super.init()
  }

  // MARK: - Retrieving Authorizations

  /// Retrieves the saved authorization for the supplied name.
  ///
  /// - Parameter itemName: The `String` name for the save authorization.
  /// - Throws: An instance of `GTMKeychainManager.Error` if retrieving the authorization failed.
  @objc public func authorization(for itemName: String) throws -> GTMAppAuthFetcherAuthorization {
    let passwordData = try? keychain.passwordData(forName: itemName)

    if #available(macOS 10.13, iOS 11, tvOS 11, *) {
      return try modernUnarchiveAuthorization(with: passwordData)
    }

    guard let passwordData = passwordData,
          let auth = NSKeyedUnarchiver.unarchiveObject(with: passwordData)
            as? GTMAppAuthFetcherAuthorization else {
      throw Error.failedToRetrieveAuthorizationFromKeychain
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
  @objc public func authorization(
    for itemName: String,
    usingDataProtectionKeychain: Bool
  ) throws -> GTMAppAuthFetcherAuthorization {
    let passwordData = try? keychain.passwordData(
      forName: itemName,
      usingDataProtectionKeychain: usingDataProtectionKeychain
    )

    // Don't need to check macOS here because method is only available for 10.15 and higher.
    if #available(iOS 11, tvOS 11, *) {
      return try modernUnarchiveAuthorization(with: passwordData)
    }

    guard let passwordData = passwordData,
          let authorization = NSKeyedUnarchiver.unarchiveObject(with: passwordData)
            as? GTMAppAuthFetcherAuthorization  else {
      throw Error.failedToRetrieveAuthorizationFromKeychain
    }
    return authorization
  }

  @available(macOS 10.13, iOS 11, tvOS 11, *)
  private func modernUnarchiveAuthorization(
    with passwordData: Data?
  ) throws -> GTMAppAuthFetcherAuthorization {
    guard let passwordData = passwordData,
          let authorization = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: GTMAppAuthFetcherAuthorization.self,
            from: passwordData
          ) else {
      throw Error.failedToRetrieveAuthorizationFromKeychain
    }
    return authorization
  }

  // MARK: - Removing Authorizations

  /// Removes the saved authorization for the supplied name.
  ///
  /// - Parameter itemName: The `String` name for the authorization saved in the keychain.
  /// - Throws: Any error that may arise during removal, including `KeychainWrapper.Error`.
  @objc public func removeAuthorization(for itemName: String) throws {
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
  @objc public func removeAuthorization(
    for itemName: String,
    usingDataProtectionKeychain: Bool
  ) throws {
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
  @objc public func save(
    authorization: GTMAppAuthFetcherAuthorization,
    with itemName: String
  ) throws {
    if #available(macOS 10.13, iOS 11, tvOS 11, *) {
      try modernArchive(authorization: authorization, itemName: itemName)
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
  @objc public func save(
    authorization: GTMAppAuthFetcherAuthorization,
    with itemName: String,
    usingDataProtectionKeychain: Bool
  ) throws {
    // Don't need to check macOS here because method is only available for 10.15 and higher.
    if #available(iOS 11, tvOS 11, *) {
      try modernArchive(
        authorization: authorization,
        itemName: itemName,
        usingDataProtectionKeychain: usingDataProtectionKeychain
      )
    } else {
      let authorizationData = NSKeyedArchiver.archivedData(withRootObject: authorization)
      try keychain.save(
        passwordData: authorizationData,
        forName: itemName,
        usingDataProtectionKeychain: usingDataProtectionKeychain
      )
    }
  }

  @available(macOS 10.13, iOS 11, tvOS 11, *)
  private func modernArchive(
    authorization: GTMAppAuthFetcherAuthorization,
    itemName: String,
    usingDataProtectionKeychain: Bool = false
  ) throws {
    let authorizationData = try NSKeyedArchiver.archivedData(
      withRootObject: authorization,
      requiringSecureCoding: true
    )
    if #available(macOS 10.15, *), usingDataProtectionKeychain {
      try keychain.save(
        passwordData: authorizationData,
        forName: itemName,
        usingDataProtectionKeychain: usingDataProtectionKeychain
      )
    } else {
      try keychain.save(passwordData: authorizationData,forName: itemName)
    }
  }
}

public extension GTMKeychainManager {
  /// Errors that may arise when saving, reading, or removing authorizations from the Keychain.
  enum Error: Swift.Error, CustomNSError, Equatable {
    case failedToRetrieveAuthorizationFromKeychain

    public static var errorDomain: String {
      "GTMKeychainManagerErrorDomain"
    }
  }
}

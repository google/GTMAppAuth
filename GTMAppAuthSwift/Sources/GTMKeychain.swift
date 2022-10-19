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

/// An internal utility for saving and loading data to the keychain.
final class GTMKeychain {
  private var keychainHelper: KeychainHelper

  /// An initializer for testing to create an instance of this keychain wrapper with a given helper.
  ///
  /// - Parameter keychainHelper: An instance conforming to `KeychainHelper`.
  init(keychainHelper: KeychainHelper? = nil) {
    if let helper = keychainHelper {
      self.keychainHelper = helper
    } else {
      self.keychainHelper = KeychainWrapper()
    }
  }

  /// Saves the password `String` to the keychain with the given identifier.
  ///
  /// - Parameters:
  ///   - password: The `String` password.
  ///   - name: The name for the Keychain item.
  /// - Throws: An instance of `KeychainWrapper.Error`.
  func save(password: String, forName name: String) throws {
    try savePasswordToKeychain(password: password, name: name)
  }

  /// Saves the password `String` to the keychain with the given identifier.
  ///
  /// - Parameters:
  ///   - password: The `String` password.
  ///   - name: The name for the Keychain item.
  ///   - usingDataProtectionKeychain: A `Bool` indicating whether to use the data
  ///     protection keychain on macOS 10.15.
  /// - Throws: An instance of `KeychainWrapper.Error`.
  @available(macOS 10.15, *)
  func save(password: String, forName name: String, usingDataProtectionKeychain: Bool) throws {
    try savePasswordToKeychain(
      password: password,
      name: name,
      usingDataProtectionKeychain: usingDataProtectionKeychain
    )
  }

  private func savePasswordToKeychain(
    password: String,
    name: String,
    usingDataProtectionKeychain: Bool = false
  ) throws {
    keychainHelper.useDataProtectionKeychain = usingDataProtectionKeychain
    try keychainHelper.setPassword(
      password,
      forService: name,
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )
  }

  /// Retrieves the `String` password for the given `String` identifier.
  ///
  /// - Parameter name: A `String` identifier for the Keychain item.
  /// - Returns: A `String` password if found.
  /// - Throws: An instance of `KeychainWrapper.Error`.
  func password(forName name: String) throws -> String {
    try passwordFromKeychain(keychainItemName: name)
  }

  /// Retrieves the `String` password for the given `String` identifier.
  ///
  /// - Parameters:
  ///   - name: A `String` identifier for the Keychain item.
  ///   - usingDataProtectionKeychain: A `Bool` indicating whether to use the data protection
  ///     keychain on macOS 10.15.
  /// - Returns: A `String` password if found.
  /// - Throws: An instance of `KeychainWrapper.Error`.
  @available(macOS 10.15, *)
  func password(forName name: String, usingDataProtectionKeychain: Bool) throws -> String {
    try passwordFromKeychain(
      keychainItemName: name,
      usingDataProtectionKeychain: usingDataProtectionKeychain
    )
  }

  private func passwordFromKeychain(
    keychainItemName: String,
    usingDataProtectionKeychain: Bool = false
  ) throws -> String {
    keychainHelper.useDataProtectionKeychain = usingDataProtectionKeychain
    return try keychainHelper.password(service: keychainItemName)
  }

  /// Saves the password `Data` to the keychain with the given identifier.
  ///
  /// - Parameters:
  ///   - passwordData: The password `Data`.
  ///   - name: The name for the Keychain item.
  /// - Throws: An instance of `KeychainWrapper.Error`.
  func save(passwordData: Data, forName name: String) throws {
    try savePasswordDataToKeychain(passwordData: passwordData, name: name)
  }

  /// Saves the password `Data` to the keychain with the given identifier.
  ///
  /// - Parameters:
  ///   - password: The password `Data`.
  ///   - name: The name for the Keychain item.
  ///   - usingDataProtectionKeychain: A `Bool` indicating whether to use the data protection
  ///     keychain on macOS 10.15.
  /// - Throws: An instance of `KeychainWrapper.Error`.
  @available(macOS 10.15, *)
  func save(passwordData: Data, forName name: String, usingDataProtectionKeychain: Bool) throws {
    try savePasswordDataToKeychain(
      passwordData: passwordData,
      name: name,
      usingDataProtectionKeychain: usingDataProtectionKeychain
    )
  }

  private func savePasswordDataToKeychain(
    passwordData: Data,
    name: String,
    usingDataProtectionKeychain: Bool = false
  ) throws {
    keychainHelper.useDataProtectionKeychain = usingDataProtectionKeychain
    try keychainHelper.setPassword(
      data: passwordData,
      forService: name,
      accessibility: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    )
  }

  /// Retrieves the password `Data` for the given `String` identifier.
  ///
  /// - Parameter name: A `String` identifier for the Keychain item.
  /// - Returns: The password `Data` if found.
  /// - Throws: An instance of `KeychainWrapper.Error`.
  func passwordData(forName name: String) throws -> Data {
    try passwordDataFromKeychain(keychainItemName: name)
  }

  /// Retrieves the password `Data` for the given `String` identifier.
  ///
  /// - Parameters:
  ///   - name: A `String` identifier for the Keychain item.
  ///   - usingDataProtectionKeychain: A `Bool` indicating whether to use the data protection
  ///     keychain on macOS 10.15.
  /// - Returns: The password `Data` if found.
  /// - Throws: An instance of `KeychainWrapper.Error`.
  @available(macOS 10.15, *)
  func passwordData(forName name: String, usingDataProtectionKeychain: Bool) throws -> Data {
    try passwordDataFromKeychain(
      keychainItemName: name,
      usingDataProtectionKeychain: usingDataProtectionKeychain
    )
  }

  private func passwordDataFromKeychain(
    keychainItemName: String,
    usingDataProtectionKeychain: Bool = false
  ) throws -> Data {
    keychainHelper.useDataProtectionKeychain = usingDataProtectionKeychain
    return try keychainHelper.passwordData(service: keychainItemName)
  }

  /// Removes stored password string, such as when the user signs out.
  ///
  /// - Parameter name: The Keychain name for the item.
  /// - Throws: An instance of `KeychainWrapper.Error`.
  func removePasswordFromKeychain(forName name: String) throws {
    try removePasswordFromKeychain(keychainItemName: name)
  }

  /// Removes stored password string, such as when the user signs out. Note that if you choose to
  /// start using the data protection keychain on macOS, any items previously created will not be
  /// accessible without migration.
  ///
  /// - Parameters:
  ///   - name: The Keychain name for the item.
  ///   - usingDataProtectionKeychain: A Boolean value that indicates whether to use the data
  ///     protection keychain on macOS 10.15+.
  /// - Throws: An instance of `KeychainWrapper.Error`.
  @available(macOS 10.15, *)
  func removePasswordFromKeychain(forName name: String, usingDataProtectionKeychain: Bool) throws {
    try removePasswordFromKeychain(
      keychainItemName: name,
      usingDataProtectionKeychain: usingDataProtectionKeychain
    )
  }

  private func removePasswordFromKeychain(
    keychainItemName: String,
    usingDataProtectionKeychain: Bool = false
  ) throws {
    keychainHelper.useDataProtectionKeychain = usingDataProtectionKeychain
    try keychainHelper.removePassword(service: keychainItemName)
  }
}

// MARK: - Keychain helper

/// A protocol defining the helper API for interacting with the Keychain.
protocol KeychainHelper {
  var accountName: String { get }
  var useDataProtectionKeychain: Bool { get set }
  func password(service: String) throws -> String
  func passwordData(service: String) throws -> Data
  func removePassword(service: String) throws
  func setPassword(_ password: String, forService service: String, accessibility: CFTypeRef) throws
  func setPassword(data: Data, forService service: String, accessibility: CFTypeRef?) throws
}

/// An internally scoped keychain helper.
struct KeychainWrapper: KeychainHelper {
  let accountName = "OAuth"
  var useDataProtectionKeychain = false
  @available(macOS 10.15, *)
  private var isMaxMacOSVersionGreaterThanTenOneFive: Bool {
    let tenOneFive = OperatingSystemVersion(majorVersion: 10, minorVersion: 15, patchVersion: 0)
    return ProcessInfo().isOperatingSystemAtLeast(tenOneFive)
  }

  func keychainQuery(service: String) -> [String: Any] {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String : accountName,
      kSecAttrService as String: service,
    ]

    #if os(macOS) && isMaxMacOSVersionGreaterThanTenOneFive
    if #available(macOS 10.15, *), useDataProtectionKeychain {
      query[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
    }
    #endif

    return query
  }

  func password(service: String) throws -> String {
    let passwordData = try passwordData(service: service)
    guard let result = String(data: passwordData, encoding: .utf8) else {
      throw GTMKeychainError.unexpectedPasswordData(forItemName: service)
    }
    return result
  }

  func passwordData(service: String) throws -> Data {
    guard !service.isEmpty else { throw GTMKeychainError.noService }

    var passwordItem: AnyObject?
    var keychainQuery = keychainQuery(service: service)
    keychainQuery[kSecReturnData as String] = true
    keychainQuery[kSecMatchLimit as String] = kSecMatchLimitOne
    let status = SecItemCopyMatching(keychainQuery as CFDictionary, &passwordItem)

    guard status != errSecItemNotFound else {
      throw GTMKeychainError.passwordNotFound(forItemName: service)
    }

    guard status == errSecSuccess else { throw GTMKeychainError.unhandled(status: status) }

    guard let result = passwordItem as? Data else {
      throw GTMKeychainError.unexpectedPasswordData(forItemName: service)
    }

    return result
  }

  func removePassword(service: String) throws {
    guard !service.isEmpty else { throw GTMKeychainError.noService }
    let keychainQuery = keychainQuery(service: service)
    let status = SecItemDelete(keychainQuery as CFDictionary)

    guard status != errSecItemNotFound else {
      throw GTMKeychainError.failedToDeletePasswordBecauseItemNotFound(itemName: service)
    }
    guard status == noErr else { throw GTMKeychainError.failedToDeletePassword(forItemName: service) }
  }

  func setPassword(
    _ password: String,
    forService service: String,
    accessibility: CFTypeRef
  ) throws {
    let passwordData = Data(password.utf8)
    try setPassword(data: passwordData, forService: service, accessibility: accessibility)
  }

  func setPassword(data: Data, forService service: String, accessibility: CFTypeRef?) throws {
    guard !service.isEmpty else { throw GTMKeychainError.noService }
    do {
      try removePassword(service: service)
    } catch GTMKeychainError.failedToDeletePasswordBecauseItemNotFound {
      // Don't throw; password doesn't exist since the password is being saved for the first time
    } catch {
      // throw here since this is some other error
      throw error
    }
    guard !data.isEmpty else { return }
    var keychainQuery = keychainQuery(service: service)
    keychainQuery[kSecValueData as String] = data

    if let accessibility = accessibility {
      keychainQuery[kSecAttrAccessible as String] = accessibility
    }

    let status = SecItemAdd(keychainQuery as CFDictionary, nil)
    guard status == noErr else { throw GTMKeychainError.failedToSetPassword(forItemName: service) }
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
    case .failedToDeletePassword(let itemName):
      return ["itemName": itemName]
    case .failedToDeletePasswordBecauseItemNotFound(itemName: let itemName):
      return ["itemName": itemName]
    case .failedToSetPassword(forItemName: let itemName):
      return ["itemName": itemName]
    }
  }
}

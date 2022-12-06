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
@testable import GTMAppAuthSwift

class KeychainHelperFake: KeychainHelper {
  var useDataProtectionKeychain = false
  var passwordStore = [String: Data]()
  let accountName = "OauthTest"
  let keychainConfigurations: Set<KeychainConfiguration>
  var generatedKeychainQuery: [String: Any]?

  required init(keychainConfigurations: Set<KeychainConfiguration>) {
    self.keychainConfigurations = keychainConfigurations
  }

  func keychainQuery(forService service: String) -> [String : Any] {
    var query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String : accountName,
      kSecAttrService as String: service,
    ]

    keychainConfigurations.forEach { configuration in
      switch configuration.attribute {
      case .useDataProtectionKeychain:
        query[configuration.attribute.keyName] = kCFBooleanTrue
      case .accessGroup(let name):
        query[configuration.attribute.keyName] = name
      }
    }

    return query
  }

  func password(forService service: String) throws -> String {
    guard !service.isEmpty else { throw KeychainStore.Error.noService }

    let passwordData = try passwordData(forService: service)
    guard let password = String(data: passwordData, encoding: .utf8) else {
      throw KeychainStore.Error.passwordNotFound(forItemName: service)
    }
    return password
  }

  func passwordData(forService service: String) throws -> Data {
    guard !service.isEmpty else { throw KeychainStore.Error.noService }

    generatedKeychainQuery = keychainQuery(forService: service)
    guard let passwordData = passwordStore[service + accountName] else {
      throw KeychainStore.Error.passwordNotFound(forItemName: service)
    }
    return passwordData
  }

  func removePassword(forService service: String) throws {
    guard !service.isEmpty else { throw KeychainStore.Error.noService }

    generatedKeychainQuery = keychainQuery(forService: service)
    guard let _ = passwordStore.removeValue(forKey: service + accountName) else {
      throw KeychainStore.Error.failedToDeletePasswordBecauseItemNotFound(itemName: service)
    }
  }

  func setPassword(
    _ password: String,
    forService service: String,
    accessibility: CFTypeRef
  ) throws {
    do {
      try removePassword(forService: service)
    } catch KeychainStore.Error.failedToDeletePasswordBecauseItemNotFound {
      // No need to throw this error since we are setting a new password
    } catch {
      throw error
    }

    guard let passwordData = password.data(using: .utf8) else {
      throw KeychainStore.Error.unexpectedPasswordData(forItemName: service)
    }
    try setPassword(data: passwordData, forService: service, accessibility: nil)
  }

  func setPassword(data: Data, forService service: String, accessibility: CFTypeRef?) throws {
    guard !service.isEmpty else { throw KeychainStore.Error.noService }
    generatedKeychainQuery = keychainQuery(forService: service)
    passwordStore.updateValue(data, forKey: service + accountName)
  }
}

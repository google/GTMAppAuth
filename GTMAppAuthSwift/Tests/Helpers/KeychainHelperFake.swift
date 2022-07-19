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

  func password(service: String) throws -> String {
    guard !service.isEmpty else { throw KeychainWrapper.Error.noService }

    let passwordData = try passwordData(service: service)
    guard let password = String(data: passwordData, encoding: .utf8) else {
      throw KeychainWrapper.Error.passwordNotFound
    }
    return password
  }

  func passwordData(service: String) throws -> Data {
    guard !service.isEmpty else { throw KeychainWrapper.Error.noService }

    guard let passwordData = passwordStore[service + accountName] else {
      throw KeychainWrapper.Error.passwordNotFound
    }
    return passwordData
  }

  func removePassword(service: String) throws {
    guard !service.isEmpty else { throw KeychainWrapper.Error.noService }

    guard let _ = passwordStore.removeValue(forKey: service + accountName) else {
      throw KeychainWrapper.Error.failedToDeletePasswordBecauseItemNotFound
    }
  }

  func setPassword(
    _ password: String,
    forService service: String,
    accessibility: CFTypeRef
  ) throws {
    do {
      try removePassword(service: service)
    } catch KeychainWrapper.Error.failedToDeletePasswordBecauseItemNotFound {
      // No need to throw this error since we are setting a new password
    } catch {
      throw error
    }

    guard let passwordData = password.data(using: .utf8) else {
      throw KeychainWrapper.Error.unexpectedPasswordData
    }
    try setPassword(data: passwordData, forService: service, accessibility: nil)
  }

  func setPassword(data: Data, forService service: String, accessibility: CFTypeRef?) throws {
    guard !service.isEmpty else { throw KeychainWrapper.Error.noService }
    passwordStore.updateValue(data, forKey: service + accountName)
  }
}

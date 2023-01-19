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

/// A `Swift.Error` type used to convert a passed `NSError`.
///
/// Internally, this error is used when the delegate of `AuthSession` passes in a custom `NSError`
/// into the `completion` of
/// `AuthSessionDelegate.authorizeRequestDidFail(forAuthSession:error:completion:)`.
@objc public final class GTMAppAuthExternalError: NSObject, Swift.Error, CustomNSError {
  @objc public let errorCode: Int
  @objc public let errorUserInfo: [String : Any]
  @objc public static let errorDomain: String = "GTMAppAuthExternalErrorDomain"
  /// The key to use in the passed error's `userInfo` dictionary to specify the caller's error
  /// domain.
  @objc public static let customErrorDomainKey = "customErrorDomainKey"

  init(externalError: NSError) {
    self.errorCode = externalError.code
    let info: [String: Any] = [GTMAppAuthExternalError.customErrorDomainKey: externalError.domain]
    let userInfo = info.merging(externalError.userInfo) { _, new in new }
    self.errorUserInfo = userInfo
  }
}

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

/// Methods defining the `AuthSession`'s delegate.
@objc(GTMAuthSessionDelegate)
public protocol AuthSessionDelegate {
  /// Used to supply additional parameters on token refresh.
  /// - Parameters:
  ///   - authSession: The `AuthSession` needing additional token refresh parameters.
  /// - Returns: An optional `[String: String]` supplying the additional token refresh parameters.
  @objc optional func additionalRefreshParameters(
    forAuthSession authSession: AuthSession
  ) -> [String: String]?

  /// A callback letting the delegate know that the authorization request failed.
  /// - Parameters:
  ///   - authSession: The `AuthSession` whose authorization request failed.
  ///   - error: The `Error` associated with the failure.
  @objc optional func authorizeRequestDidFail(
    forAuthSession authSession: AuthSession,
    error: Swift.Error
  )
}

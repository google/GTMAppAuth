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

import AppAuthCore

/// Protocol for creating a test instance of `OIDRegistrationResponse` with a request and
/// parameters.
@objc public protocol RegistrationResponseTesting: Testing {
  static func testInstance(
    request: OIDRegistrationRequest,
    parameters: [String: String]
  ) -> Self
}

@objc extension OIDRegistrationResponse: RegistrationResponseTesting {
  public static func testInstance() -> Self {
    return testInstance(
      request: OIDRegistrationRequest.testInstance(),
      parameters: [:]
    )
  }

  public static func testInstance(
    request: OIDRegistrationRequest,
    parameters: [String: String]
  ) -> Self {
    return OIDRegistrationResponse(
      request: request,
      parameters: parameters as [String: NSCopying & NSObjectProtocol]
    ) as! Self
  }
}

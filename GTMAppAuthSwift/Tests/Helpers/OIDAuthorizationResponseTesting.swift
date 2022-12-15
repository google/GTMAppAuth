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

/// Create a testing instance of `OIDAuthorizationResponse` taking arguments for additional
/// parameters and an error description.
@objc public protocol AuthorizationResponseTesting: Testing {
  static func testInstance(
    additionalParameters: [String: String]?,
    errorDescription: String?
  ) -> Self
}

@objc extension OIDAuthorizationResponse: AuthorizationResponseTesting {
  @objc public static func testInstance() -> Self {
    return testInstance(
      additionalParameters: nil,
      errorDescription: nil
    )
  }

  @objc public static func testInstance(
    additionalParameters: [String : String]?,
    errorDescription: String?
  ) -> Self {
    var parameters = [String: String]()
    if let errorString = errorDescription {
      parameters["error"] = errorString
    } else {
      parameters["code"] = "authorization_code"
      parameters["state"] = "state"
      parameters["token_type"] = OIDGrantTypeAuthorizationCode
      if let additionalParameters = additionalParameters {
        parameters.merge(additionalParameters) { _, new in new }
      }
    }
    return OIDAuthorizationResponse(
      request: OIDAuthorizationRequest.testInstance(),
      parameters: parameters as [String: NSCopying & NSObjectProtocol]
    ) as! Self
  }
}

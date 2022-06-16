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

/// A protocol to help create test instances of `OIDAuthState` with various
/// arguments.
protocol AuthStateTesting: Testing {
  static func testInstance(idToken: String) -> Self
  static func testInstance(tokenResponse: OIDTokenResponse) -> Self
  static func testInstance(
    authorizationResponse: OIDAuthorizationResponse?,
    tokenResponse: OIDTokenResponse?,
    registrationResponse: OIDRegistrationResponse?
  ) -> Self
}

extension OIDAuthState: AuthStateTesting {
  static func testInstance() -> Self {
    return OIDAuthState(
      authorizationResponse: OIDAuthorizationResponse.testInstance(),
      tokenResponse: OIDTokenResponse.testInstance()
    ) as! Self
  }

  static func testInstance(idToken: String) -> Self {
    return testInstance(
      tokenResponse: OIDTokenResponse.testInstance(idToken: idToken)
    )
  }

  static func testInstance(tokenResponse: OIDTokenResponse) -> Self {
    return testInstance(
      authorizationResponse: OIDAuthorizationResponse.testInstance(),
      tokenResponse: tokenResponse,
      registrationResponse: nil
    )
  }

  static func testInstance(
    authorizationResponse: OIDAuthorizationResponse?,
    tokenResponse: OIDTokenResponse?,
    registrationResponse: OIDRegistrationResponse?
  ) -> Self {
    return OIDAuthState(
      authorizationResponse: authorizationResponse,
      tokenResponse: tokenResponse,
      registrationResponse: registrationResponse
    ) as! Self
  }
}

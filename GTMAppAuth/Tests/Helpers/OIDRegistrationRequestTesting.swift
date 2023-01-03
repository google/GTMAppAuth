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

// Ensure that we import the correct dependency for both SPM and CocoaPods since
// the latter doesn't define separate Clang modules for subspecs
#if SWIFT_PACKAGE
import AppAuthCore
#else
import AppAuth
#endif

/// Protocol for creating a test instance of `OIDRegistrationRequest` with a configuration.
@objc public protocol RegistrationRequestTesting: Testing {
  static func testInstance(configuration: OIDServiceConfiguration) -> Self
}

@objc extension OIDRegistrationRequest: RegistrationRequestTesting {
  public static func testInstance() -> Self {
    testInstance(configuration: OIDServiceConfiguration.testInstance())
  }

  public static func testInstance(configuration: OIDServiceConfiguration) -> Self {
    return OIDRegistrationRequest(
      configuration: configuration,
      redirectURIs: [],
      responseTypes: nil,
      grantTypes: nil,
      subjectType: nil,
      tokenEndpointAuthMethod: nil,
      additionalParameters: nil
    ) as! Self
  }
}

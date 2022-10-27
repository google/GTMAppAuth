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

/// Extension for creating a test instance of `OIDServiceConfiguration`.
extension OIDServiceConfiguration: Testing {
  static func testInstance() -> Self {
    return OIDServiceConfiguration(
      authorizationEndpoint: URL(string: "https://test.com/auth")!,
      tokenEndpoint: URL(string: "https://test.com/token")!
    ) as! Self
  }
}

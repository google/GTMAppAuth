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

/// A protocol for creating a test instance of `Self`.
protocol Testing {
  static func testInstance() -> Self
}

// MARK: - Constants

struct Constants {
  static let testAccessToken = "access_token"
  static let accessTokenExpiresIn = 3600
  static let testRefreshToken = "refresh_token"
  static let serverAuthCode = "server_auth_code"

  static let alg = "RS256"
  static let kid = "alkjdfas"
  static let typ = "JWT"
  static let userID = "123456789"
  static let hostedDomain = "fakehosteddomain.com"
  static let issuer = "https://test.com"
  static let audience = "audience"
  static let IDTokenExpires = 1000
  static let issuedAt = 0

  static let fatNameKey = "name";
  static let fatGivenNameKey = "given_name"
  static let fatFamilyNameKey = "family_name"
  static let fatPictureURLKey = "picture"

  static let fatName = "fake username"
  static let fatGivenName = "fake"
  static let fatFamilyName = "username"
  static let fatPictureURL = "fake_user_picture_url"

  static let testClientID = "87654321.googleusercontent.com"
  static let testScope1 = "email"
  static let testScope2 = "profile"
  static let testCodeVerifier = "codeVerifier"
  static let testPassword = "foo"
  static let testKeychainItemName = "testName"
  static let testServiceProvider = "fooProvider"
  static let testUserID = "123456789"
  static let testEmail = "foo@foo.com"
  static let testClientSecret = "fooSecret"
  static let testTokenURL: URL = URL(string: "https://testTokenURL.com")!
  static let testRedirectURI = "https://testRedirectURI.com"
}

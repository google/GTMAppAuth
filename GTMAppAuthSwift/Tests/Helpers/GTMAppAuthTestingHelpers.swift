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

let testAccessToken = "access_token"
let accessTokenExpiresIn = 3600
let testRefreshToken = "refresh_token"
let serverAuthCode = "server_auth_code"

// MARK: - ID token constants
let alg = "RS256"
let kid = "alkjdfas"
let typ = "JWT"
let userID = "12345679"
let hostedDomain = "fakehosteddomain.com"
let issuer = "https://test.com"
let audience = "audience"
let IDTokenExpires = 1000
let issuedAt = 0

let fatNameKey = "name";
let fatGivenNameKey = "given_name"
let fatFamilyNameKey = "family_name"
let fatPictureURLKey = "picture"

let fatName = "fake username"
let fatGivenName = "fake"
let fatFamilyName = "username"
let fatPictureURL = "fake_user_picture_url"

// MARK: - Test Values

let testClientID = "87654321.googleusercontent.com"
let testScope1 = "email"
let testScope2 = "profile"
let testCodeVerifier = "codeVerifier"
let testPassword = "foo"
let testKeychainItemName = "testName"
let testServiceProvider = "fooProvider"
let testUserID = "fooUser"
let testEmail = "foo@foo.com"
let testClientSecret = "fooSecret"
let testTokenURL: URL = URL(string: "https://testTokenURL.com")!
let testRedirectURI = "https://testRedirectURI.com"

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
@objc(GTMTesting)
public protocol Testing {
  static func testInstance() -> Self
}

// MARK: - Constants

@objc(GTMTestingConstants)
public class TestingConstants: NSObject {
  @objc public static let testAccessGroup = "testAccessGroup"
  @objc public static let testAccessToken = "access_token"
  @objc public static let accessTokenExpiresIn = 3600
  @objc public static let testRefreshToken = "refresh_token"
  @objc public static let serverAuthCode = "server_auth_code"

  @objc public static let alg = "RS256"
  @objc public static let kid = "alkjdfas"
  @objc public static let typ = "JWT"
  @objc public static let userID = "123456789"
  @objc public static let hostedDomain = "fakehosteddomain.com"
  @objc public static let issuer = "https://test.com"
  @objc public static let audience = "audience"
  @objc public static let IDTokenExpires = 1000
  @objc public static let issuedAt = 0

  @objc public static let fatNameKey = "name";
  @objc public static let fatGivenNameKey = "given_name"
  @objc public static let fatFamilyNameKey = "family_name"
  @objc public static let fatPictureURLKey = "picture"

  @objc public static let fatName = "fake username"
  @objc public static let fatGivenName = "fake"
  @objc public static let fatFamilyName = "username"
  @objc public static let fatPictureURL = "fake_user_picture_url"
  
  @objc public static let testClientID = "87654321.googleusercontent.com"
  @objc public static let testScope1 = "email"
  @objc public static let testScope2 = "profile"
  @objc public static let testCodeVerifier = "codeVerifier"
  @objc public static let testPassword = "foo"
  @objc public static let testKeychainItemName = "testName"
  @objc public static let testServiceProvider = "fooProvider"
  @objc public static let testUserID = "123456789"
  @objc public static let testEmail = "foo@foo.com"
  @objc public static let testClientSecret = "fooSecret"
  @objc public static let testTokenURL: URL = URL(string: "https://testTokenURL.com")!
  @objc public static let testRedirectURI = "https://testRedirectURI.com"
}

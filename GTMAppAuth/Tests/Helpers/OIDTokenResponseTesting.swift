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

/// Protocol for creating a test instance of `OIDTokenResponse`.
@objc public protocol TokenResponseTesting: Testing {
  static func testInstance(idToken: String) -> Self
  static func testInstance(
    idToken: String,
    accessToken: String?,
    expires: NSNumber?,
    tokenRequest: OIDTokenRequest?
  ) -> Self
}

@objc extension OIDTokenResponse: TokenResponseTesting {
  public static func testInstance() -> Self {
    return testInstance(idToken: idToken)
  }

  public static func testInstance(idToken: String) -> Self {
    return OIDTokenResponse.testInstance(
      idToken: idToken,
      accessToken: nil,
      expires: nil,
      tokenRequest: nil
    ) as! Self
  }

  public static func testInstanceWithoutAccessToken(
    idToken: String,
    expires: NSNumber?,
    tokenRequest: OIDTokenRequest?
  ) -> Self {
    let parameters: [String: NSObject & NSCopying] = [
      "expires_in": (expires ?? NSNumber(value: TestingConstants.accessTokenExpiresIn)),
      "token_type": "example_token_type" as NSString,
      "refresh_token": TestingConstants.testRefreshToken as NSString,
      "scope": OIDScopeUtilities.scopes(with: [TestingConstants.testScope2]) as NSString,
      "server_code": TestingConstants.serverAuthCode as NSString,
      "id_token": idToken as NSString
    ]

    return OIDTokenResponse(
      request: tokenRequest ?? OIDTokenRequest.testInstance(),
      parameters: parameters
    ) as! Self
  }

  public static func testInstanceWithEmptyAccessToken(
    idToken: String,
    expires: NSNumber?,
    tokenRequest: OIDTokenRequest?
  ) -> Self {
    let parameters: [String: NSObject & NSCopying] = [
      "access_token": "" as NSString,
      "expires_in": (expires ?? NSNumber(value: TestingConstants.accessTokenExpiresIn)),
      "token_type": "example_token_type" as NSString,
      "refresh_token": TestingConstants.testRefreshToken as NSString,
      "scope": OIDScopeUtilities.scopes(with: [TestingConstants.testScope2]) as NSString,
      "server_code": TestingConstants.serverAuthCode as NSString,
      "id_token": idToken as NSString
    ]

    return OIDTokenResponse(
      request: tokenRequest ?? OIDTokenRequest.testInstance(),
      parameters: parameters
    ) as! Self
  }

  public static func testInstance(
    idToken: String,
    accessToken: String?,
    expires: NSNumber?,
    tokenRequest: OIDTokenRequest?
  ) -> Self {
    let parameters: [String: NSObject & NSCopying] = [
      "access_token": (accessToken ?? TestingConstants.testAccessToken) as NSString,
      "expires_in": (expires ?? NSNumber(value: TestingConstants.accessTokenExpiresIn)),
      "token_type": "example_token_type" as NSString,
      "refresh_token": TestingConstants.testRefreshToken as NSString,
      "scope": OIDScopeUtilities.scopes(with: [TestingConstants.testScope2]) as NSString,
      "server_code": TestingConstants.serverAuthCode as NSString,
      "id_token": idToken as NSString
    ]

    return OIDTokenResponse(
      request: tokenRequest ?? OIDTokenRequest.testInstance(),
      parameters: parameters
    ) as! Self
  }

  static var idToken: String {
    return idToken(sub: TestingConstants.userID, exp: TestingConstants.IDTokenExpires, fat: false)
  }

  static func idToken(sub: String, exp: Int, fat: Bool) -> String {
    let headerContents = [
      "alg": TestingConstants.alg,
      "kid": TestingConstants.kid,
      "typ": TestingConstants.typ,
    ]

    // `try!` is fine here since failing is okay in the test
    let headerJson = try! JSONSerialization.data(
      withJSONObject: headerContents,
      options: .prettyPrinted
    )

    var payloadContents = [
      "sub": sub,
      "hd": TestingConstants.hostedDomain,
      "iss": TestingConstants.issuer,
      "aud": TestingConstants.audience,
      "exp": exp,
      "iat": TestingConstants.issuedAt
    ] as [String : Any]

    if fat {
      payloadContents[TestingConstants.fatNameKey] = TestingConstants.fatName
      payloadContents[TestingConstants.fatGivenNameKey] = TestingConstants.fatGivenName
      payloadContents[TestingConstants.fatFamilyNameKey] = TestingConstants.fatFamilyName
      payloadContents[TestingConstants.fatPictureURLKey] = TestingConstants.fatPictureURL
    }

    let payloadData = try! JSONSerialization.data(
      withJSONObject: payloadContents,
      options: .prettyPrinted
    )

    return "\(headerJson.base64EncodedString()).\(payloadData.base64EncodedString()).FakeSignature"
  }
}

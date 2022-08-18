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

/// Protocol for creating a test instance of `OIDTokenResponse`.
protocol TokenResponseTesting: Testing {
  static func testInstance(idToken: String) -> Self
  static func testInstance(
    idToken: String,
    accessToken: String?,
    expires: NSNumber?,
    tokenRequest: OIDTokenRequest?
  ) -> Self
}

extension OIDTokenResponse: TokenResponseTesting {
  static func testInstance() -> Self {
    return testInstance(idToken: idToken)
  }

  static func testInstance(idToken: String) -> Self {
    return OIDTokenResponse.testInstance(
      idToken: idToken,
      accessToken: nil,
      expires: nil,
      tokenRequest: nil
    ) as! Self
  }

  static func testInstance(
    idToken: String,
    accessToken: String?,
    expires: NSNumber?,
    tokenRequest: OIDTokenRequest?
  ) -> Self {
    let parameters = [
      "access_token": accessToken ?? Constants.testAccessToken,
      "expires_in": expires ?? Constants.accessTokenExpiresIn as NSNumber,
      "token_type": "example_token_type",
      "refresh_token": Constants.testRefreshToken,
      "scope": OIDScopeUtilities.scopes(with: [Constants.testScope2]),
      "server_code": Constants.serverAuthCode,
      "id_token": idToken
    ] as! [String : NSCopying & NSObjectProtocol]

    return OIDTokenResponse(
      request: tokenRequest ?? OIDTokenRequest.testInstance(),
      parameters: parameters
    ) as! Self
  }

  static var idToken: String {
    return idToken(sub: Constants.userID, exp: Constants.IDTokenExpires, fat: false)
  }

  static func idToken(sub: String, exp: Int, fat: Bool) -> String {
    let headerContents = [
      "alg": Constants.alg,
      "kid": Constants.kid,
      "typ": Constants.typ,
    ]

    // `try!` is fine here since failing is okay in the test
    let headerJson = try! JSONSerialization.data(
      withJSONObject: headerContents,
      options: .prettyPrinted
    )

    var payloadContents = [
      "sub": sub,
      "hd": Constants.hostedDomain,
      "iss": Constants.issuer,
      "aud": Constants.audience,
      "exp": exp,
      "iat": Constants.issuedAt
    ] as [String : Any]

    if fat {
      payloadContents[Constants.fatNameKey] = Constants.fatName
      payloadContents[Constants.fatGivenNameKey] = Constants.fatGivenName
      payloadContents[Constants.fatFamilyNameKey] = Constants.fatFamilyName
      payloadContents[Constants.fatPictureURLKey] = Constants.fatPictureURL
    }

    let payloadData = try! JSONSerialization.data(
      withJSONObject: payloadContents,
      options: .prettyPrinted
    )

    return "\(headerJson.base64EncodedString()).\(payloadData.base64EncodedString()).FakeSignature"
  }
}

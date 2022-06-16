//
//  File.swift
//  
//
//  Created by Matt Mathias on 6/22/22.
//

import AppAuthCore

/// Protocol for creating a test instance of `OIDRegistrationResponse` with a
/// request and parameters.
protocol RegistrationResponseTesting: Testing {
  static func testInstance(
    request: OIDRegistrationRequest,
    parameters: [String: String]
  ) -> Self
}

extension OIDRegistrationResponse: RegistrationResponseTesting {
  static func testInstance() -> Self {
    return testInstance(
      request: OIDRegistrationRequest.testInstance(),
      parameters: [:]
    )
  }

  static func testInstance(
    request: OIDRegistrationRequest,
    parameters: [String: String]
  ) -> Self {
    return OIDRegistrationResponse(
      request: request,
      parameters: parameters as [String: NSCopying & NSObjectProtocol]
    ) as! Self
  }
}

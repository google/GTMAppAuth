//
//  File.swift
//  
//
//  Created by Matt Mathias on 6/22/22.
//

import AppAuthCore

/// Protocol for creating a test instance of `OIDRegistrationRequest` with a configuration.
protocol RegistrationRequestTesting: Testing {
  static func testInstance(configuration: OIDServiceConfiguration) -> Self
}

extension OIDRegistrationRequest: RegistrationRequestTesting {
  static func testInstance() -> Self {
    testInstance(configuration: OIDServiceConfiguration.testInstance())
  }

  static func testInstance(configuration: OIDServiceConfiguration) -> Self {
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

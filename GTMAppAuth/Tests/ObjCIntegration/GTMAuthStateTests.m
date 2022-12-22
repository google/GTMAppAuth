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

#import <XCTest/XCTest.h>

#if SWIFT_PACKAGE
@import AppAuthCore;
@import TestHelpers;
#else
@import AppAuth;
#import <GTMAppAuth/TestHelpers-Swift.h>
#endif
@import GTMAppAuth;

@interface GTMAuthStateTests : XCTestCase

@property (nonatomic) NSURL *googleAuthzEndpoint;
@property (nonatomic) NSURL *tokenEndpoint;
@property (nonatomic) NSURL *secureURL;
@property (nonatomic) NSTimeInterval expectationTimeout;

@end

@implementation GTMAuthStateTests

- (void)setUp {
  self.secureURL = [NSURL URLWithString:@"https://fake.com"];
  self.googleAuthzEndpoint = [NSURL URLWithString:@"https://accounts.google.com/o/oauth2/v2/auth"];
  self.tokenEndpoint = [NSURL URLWithString:@"https://www.googleapis.com/oauth2/v4/token"];
  self.expectationTimeout = 5;
  [super setUp];
}

- (void)testInitWithOIDAuthState {
  GTMAuthState *authorization =
  [[GTMAuthState alloc] initWithAuthState:[OIDAuthState testInstance]];
  XCTAssertNotNil(authorization);
}

- (void)testDesignatedInitializer {
  GTMAuthState *authorization =
  [[GTMAuthState alloc] initWithAuthState:OIDAuthState.testInstance
                                            serviceProvider:GTMTestingConstants.testServiceProvider
                                                     userID:GTMTestingConstants.testUserID
                                                  userEmail:GTMTestingConstants.testEmail
                                        userEmailIsVerified:@"y"];
  XCTAssertNotNil(authorization);
  XCTAssertTrue(authorization.authState.isAuthorized);
  XCTAssertEqualObjects(authorization.serviceProvider, [GTMTestingConstants testServiceProvider]);
  XCTAssertEqualObjects(authorization.userID, [GTMTestingConstants testUserID]);
  XCTAssertEqualObjects(authorization.userEmail, [GTMTestingConstants testEmail]);
  XCTAssertTrue(authorization.userEmailIsVerified);
}

- (void)testAuthorizeSecureRequestWithCompletion {
  XCTestExpectation *authRequestExpectation =
      [[XCTestExpectation alloc] initWithDescription:@"Authorize with completion"];

  GTMAuthState *authorization =
      [[GTMAuthState alloc] initWithAuthState:OIDAuthState.testInstance];
  NSMutableURLRequest *secureRequest = [NSMutableURLRequest requestWithURL:self.secureURL];

  [authorization authorizeRequest:secureRequest completionHandler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
    [authRequestExpectation fulfill];
  }];

  XCTAssertTrue([authorization isAuthorizingRequest:secureRequest]);
  [self waitForExpectations:@[authRequestExpectation] timeout:self.expectationTimeout];
  XCTAssertTrue([authorization isAuthorizedRequest:secureRequest]);
}

- (void)testAuthorizeSecureRequestWithDelegate {
  XCTestExpectation *delegateExpectation =
      [[XCTestExpectation alloc] initWithDescription:@"Authorize with delegate"];

  GTMAuthState *authorization =
      [[GTMAuthState alloc] initWithAuthState:OIDAuthState.testInstance];
  NSMutableURLRequest *secureRequest = [NSMutableURLRequest requestWithURL:self.secureURL];

  OIDAuthState *authState = OIDAuthState.testInstance;
  GTMAuthorizationTestingHelper *originalAuthorization =
      [[GTMAuthorizationTestingHelper alloc] initWithAuthState:authState];
  GTMAuthorizationTestDelegate *testingDelegate =
      [[GTMAuthorizationTestDelegate alloc] initWithExpectation:delegateExpectation];

  NSMutableURLRequest *originalRequest = [[NSMutableURLRequest alloc] initWithURL:self.secureURL];
  [originalAuthorization authorizeRequest:originalRequest
                                 delegate:testingDelegate
                        didFinishSelector:@selector(authentication:request:finishedWithError:)];

  [self waitForExpectations:@[delegateExpectation] timeout:self.expectationTimeout];

  XCTAssertNotNil(testingDelegate.passedRequest);
  XCTAssertEqual(originalRequest, testingDelegate.passedRequest);
  XCTAssertNotNil(testingDelegate.passedAuthorization);
  XCTAssertEqual(originalAuthorization, testingDelegate.passedAuthorization);
  XCTAssertNil(testingDelegate.passedError);
}

- (void)testStopAuthorization {
  XCTestExpectation *authorizeSecureRequestExpectation =
      [self expectationWithDescription:@"Authorize with completion expectation"];

  GTMAuthState *authorization =
      [[GTMAuthState alloc] initWithAuthState:OIDAuthState.testInstance];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.secureURL];

  [authorization authorizeRequest:request completionHandler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
    [authorizeSecureRequestExpectation fulfill];
  }];

  XCTAssertTrue([authorization isAuthorizingRequest:request]);
  [authorization stopAuthorization];
  XCTAssertFalse([authorization isAuthorizingRequest:request]);
  [authorizeSecureRequestExpectation fulfill];
  [self waitForExpectations:@[authorizeSecureRequestExpectation] timeout:self.expectationTimeout];
}

- (void)testStopAuthorizationForRequest {
  XCTestExpectation *authorizeSecureRequestExpectation =
  [self expectationWithDescription:@"Authorize with completion expectation"];

  GTMAuthState *authorization =
      [[GTMAuthState alloc] initWithAuthState:OIDAuthState.testInstance];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.secureURL];

  [authorization authorizeRequest:request completionHandler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
    [authorizeSecureRequestExpectation fulfill];
  }];

  XCTAssertTrue([authorization isAuthorizingRequest:request]);
  [authorization stopAuthorizationForRequest:request];
  XCTAssertFalse([authorization isAuthorizingRequest:request]);
  [authorizeSecureRequestExpectation fulfill];
  [self waitForExpectations:@[authorizeSecureRequestExpectation] timeout:self.expectationTimeout];
}

- (void)testIsAuthorizedRequest {
  GTMAuthState *authorization =
      [[GTMAuthState alloc] initWithAuthState:OIDAuthState.testInstance];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.secureURL];
  XCTAssertFalse([authorization isAuthorizedRequest:request]);
}

- (void)testCanAuthorizeRequest {
  GTMAuthState *authorization =
      [[GTMAuthState alloc] initWithAuthState:OIDAuthState.testInstance];
  XCTAssertTrue([authorization canAuthorize]);
}

- (void)testCannotAuthorizeRequest {
  OIDAuthState *testAuthState =
      [OIDAuthState testInstanceWithAuthorizationResponse:nil
                                            tokenResponse:nil
                                     registrationResponse:OIDRegistrationResponse.testInstance];
  GTMAuthState *authorization =
      [[GTMAuthState alloc] initWithAuthState:testAuthState];
  XCTAssertFalse([authorization canAuthorize]);
}

- (void)testIsNotPrimeForRefresh {
  GTMAuthState *authorization =
      [[GTMAuthState alloc] initWithAuthState:OIDAuthState.testInstance];
  XCTAssertFalse([authorization primeForRefresh]);
}

- (void)testIsPrimeForRefresh {
  OIDAuthState *testAuthState =
      [OIDAuthState testInstanceWithAuthorizationResponse:nil
                                            tokenResponse:nil
                                     registrationResponse:OIDRegistrationResponse.testInstance];
  GTMAuthState *authorization =
      [[GTMAuthState alloc] initWithAuthState:testAuthState];
  XCTAssertTrue([authorization primeForRefresh]);
}

- (void)testConfigurationForGoogle {
  OIDServiceConfiguration *configuration = [GTMAuthState configurationForGoogle];
  XCTAssertNotNil(configuration);
  XCTAssertEqualObjects(configuration.authorizationEndpoint, self.googleAuthzEndpoint);
  XCTAssertEqualObjects(configuration.tokenEndpoint, self.tokenEndpoint);
}

@end

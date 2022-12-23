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
#import "GTMAppAuth_Unit_objc_api_integration-Swift.h"
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
  GTMAuthSession *authSession =
      [[GTMAuthSession alloc] initWithAuthState:[OIDAuthState testInstance]];
  XCTAssertNotNil(authSession);
}

- (void)testDesignatedInitializer {
  GTMAuthSession *authSession =
      [[GTMAuthSession alloc] initWithAuthState:OIDAuthState.testInstance
                                serviceProvider:GTMTestingConstants.testServiceProvider
                                         userID:GTMTestingConstants.testUserID
                                      userEmail:GTMTestingConstants.testEmail
                            userEmailIsVerified:@"y"];
  XCTAssertNotNil(authSession);
  XCTAssertTrue(authSession.authState.isAuthorized);
  XCTAssertEqualObjects(authSession.serviceProvider, [GTMTestingConstants testServiceProvider]);
  XCTAssertEqualObjects(authSession.userID, [GTMTestingConstants testUserID]);
  XCTAssertEqualObjects(authSession.userEmail, [GTMTestingConstants testEmail]);
  XCTAssertTrue(authSession.userEmailIsVerified);
}

- (void)testAuthorizeSecureRequestWithCompletion {
  XCTestExpectation *authRequestExpectation =
      [[XCTestExpectation alloc] initWithDescription:@"Authorize with completion"];

  GTMAuthSession *authSession =
      [[GTMAuthSession alloc] initWithAuthState:OIDAuthState.testInstance];
  NSMutableURLRequest *secureRequest = [NSMutableURLRequest requestWithURL:self.secureURL];

  [authSession authorizeRequest:secureRequest completionHandler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
    [authRequestExpectation fulfill];
  }];

  XCTAssertTrue([authSession isAuthorizingRequest:secureRequest]);
  [self waitForExpectations:@[authRequestExpectation] timeout:self.expectationTimeout];
  XCTAssertTrue([authSession isAuthorizedRequest:secureRequest]);
}

- (void)testAuthorizeSecureRequestWithDelegate {
  XCTestExpectation *delegateExpectation =
      [[XCTestExpectation alloc] initWithDescription:@"Authorize with delegate"];

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

  GTMAuthSession *authSession =
      [[GTMAuthSession alloc] initWithAuthState:OIDAuthState.testInstance];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.secureURL];

  [authSession authorizeRequest:request completionHandler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
    [authorizeSecureRequestExpectation fulfill];
  }];

  XCTAssertTrue([authSession isAuthorizingRequest:request]);
  [authSession stopAuthorization];
  XCTAssertFalse([authSession isAuthorizingRequest:request]);
  [authorizeSecureRequestExpectation fulfill];
  [self waitForExpectations:@[authorizeSecureRequestExpectation] timeout:self.expectationTimeout];
}

- (void)testStopAuthorizationForRequest {
  XCTestExpectation *authorizeSecureRequestExpectation =
  [self expectationWithDescription:@"Authorize with completion expectation"];

  GTMAuthSession *authSession =
      [[GTMAuthSession alloc] initWithAuthState:OIDAuthState.testInstance];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.secureURL];

  [authSession authorizeRequest:request completionHandler:^(NSError * _Nullable error) {
    XCTAssertNil(error);
    [authorizeSecureRequestExpectation fulfill];
  }];

  XCTAssertTrue([authSession isAuthorizingRequest:request]);
  [authSession stopAuthorizationForRequest:request];
  XCTAssertFalse([authSession isAuthorizingRequest:request]);
  [authorizeSecureRequestExpectation fulfill];
  [self waitForExpectations:@[authorizeSecureRequestExpectation] timeout:self.expectationTimeout];
}

- (void)testIsAuthorizedRequest {
  GTMAuthSession *authSession =
      [[GTMAuthSession alloc] initWithAuthState:OIDAuthState.testInstance];
  NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.secureURL];
  XCTAssertFalse([authSession isAuthorizedRequest:request]);
}

- (void)testCanAuthorizeRequest {
  GTMAuthSession *authSession =
      [[GTMAuthSession alloc] initWithAuthState:OIDAuthState.testInstance];
  XCTAssertTrue([authSession canAuthorize]);
}

- (void)testCannotAuthorizeRequest {
  OIDAuthState *testAuthState =
      [OIDAuthState testInstanceWithAuthorizationResponse:nil
                                            tokenResponse:nil
                                     registrationResponse:OIDRegistrationResponse.testInstance];
  GTMAuthSession *authSession = [[GTMAuthSession alloc] initWithAuthState:testAuthState];
  XCTAssertFalse([authSession canAuthorize]);
}

- (void)testIsNotPrimeForRefresh {
  GTMAuthSession *authSession =
      [[GTMAuthSession alloc] initWithAuthState:OIDAuthState.testInstance];
  XCTAssertFalse([authSession primeForRefresh]);
}

- (void)testIsPrimeForRefresh {
  OIDAuthState *testAuthState =
      [OIDAuthState testInstanceWithAuthorizationResponse:nil
                                            tokenResponse:nil
                                     registrationResponse:OIDRegistrationResponse.testInstance];
  GTMAuthSession *authSession = [[GTMAuthSession alloc] initWithAuthState:testAuthState];
  XCTAssertTrue([authSession primeForRefresh]);
}

- (void)testConfigurationForGoogle {
  OIDServiceConfiguration *configuration = [GTMAuthSession configurationForGoogle];
  XCTAssertNotNil(configuration);
  XCTAssertEqualObjects(configuration.authorizationEndpoint, self.googleAuthzEndpoint);
  XCTAssertEqualObjects(configuration.tokenEndpoint, self.tokenEndpoint);
}

@end

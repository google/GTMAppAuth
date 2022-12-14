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

@import GTMAppAuthSwift;
@import TestHelpers;

@interface GTMAuthStateTests : XCTestCase
@end

@implementation GTMAuthStateTests

- (void)testInitWithOIDAuthState {
  GTMAppAuthFetcherAuthorization *authorization =
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:[OIDAuthState testInstance]];
  XCTAssertNotNil(authorization);
}

- (void)testDesignatedInitializer {
  GTMAppAuthFetcherAuthorization *authorization =
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:[OIDAuthState testInstance]
                                                serviceProvider:[GTMTestingConstants testServiceProvider]
                                                         userID:[GTMTestingConstants testUserID]
                                                      userEmail:[GTMTestingConstants testEmail]
                                            userEmailIsVerified:@"y"];
  XCTAssertNotNil(authorization);
  XCTAssertTrue(authorization.authState.isAuthorized);
  XCTAssertEqualObjects(authorization.serviceProvider, [GTMTestingConstants testServiceProvider]);
  XCTAssertEqualObjects(authorization.userID, [GTMTestingConstants testUserID]);
  XCTAssertEqualObjects(authorization.userEmail, [GTMTestingConstants testEmail]);
  XCTAssertTrue(authorization.userEmailIsVerified);
}

@end

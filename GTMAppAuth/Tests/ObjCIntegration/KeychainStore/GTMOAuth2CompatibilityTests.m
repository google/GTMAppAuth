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

@interface GTMOAuth2CompatibilityTests : XCTestCase

@property (nonatomic) GTMAuthSession *expectedAuthSession;

@end

@implementation GTMOAuth2CompatibilityTests

- (void)setUp {
  self.expectedAuthSession =
      [[GTMAuthSession alloc] initWithAuthState:OIDAuthState.testInstance
                                serviceProvider:GTMTestingConstants.testServiceProvider
                                         userID:GTMTestingConstants.userID
                                      userEmail:GTMTestingConstants.testEmail
                            userEmailIsVerified:@"y"];
  [super setUp];
}

- (NSString *)expectedPersistenceResponseString {
  return [NSString stringWithFormat:@"access_token=%@&refresh_token=%@&scope=%@&serviceProvider=%@&userEmail=foo%%40foo.com&userEmailIsVerified=y&userID=%@", GTMTestingConstants.testAccessToken, GTMTestingConstants.testRefreshToken, GTMTestingConstants.testScope2, GTMTestingConstants.testServiceProvider, GTMTestingConstants.testUserID];
}

- (void)testPersistenceResponseString {
  NSString *testPersistenceResponseString =
      [GTMOAuth2Compatibility persistenceResponseStringForAuthSession:self.expectedAuthSession];
  XCTAssertNotNil(testPersistenceResponseString);
  XCTAssertEqualObjects([self expectedPersistenceResponseString], testPersistenceResponseString);
}

- (void)testAuthStateForPersistenceString {
  NSError *error;
  GTMOAuth2Compatibility *gtmOAuth2Compat = [[GTMOAuth2Compatibility alloc] init];
  GTMAuthSession *testPersistAuthSession =
      [gtmOAuth2Compat authSessionForPersistenceString:[self expectedPersistenceResponseString]
                                              tokenURL:GTMTestingConstants.testTokenURL
                                           redirectURI:GTMTestingConstants.testRedirectURI
                                              clientID:GTMTestingConstants.testClientID
                                          clientSecret:GTMTestingConstants.testClientSecret
                                                 error:&error];
  XCTAssertNil(error);
  XCTAssertEqual(testPersistAuthSession.authState.scope, self.expectedAuthSession.authState.scope);
  XCTAssertEqualObjects(testPersistAuthSession.authState.lastTokenResponse.accessToken,
                        self.expectedAuthSession.authState.lastTokenResponse.accessToken);
  XCTAssertEqualObjects(testPersistAuthSession.authState.refreshToken,
                        self.expectedAuthSession.authState.refreshToken);
  XCTAssertEqual(testPersistAuthSession.authState.isAuthorized,
                 self.expectedAuthSession.authState.isAuthorized);
  XCTAssertEqualObjects(testPersistAuthSession.serviceProvider,
                        self.expectedAuthSession.serviceProvider);
  XCTAssertEqualObjects(testPersistAuthSession.userID, self.expectedAuthSession.userID);
  XCTAssertEqualObjects(testPersistAuthSession.userEmail, self.expectedAuthSession.userEmail);
  XCTAssertEqual(testPersistAuthSession.userEmailIsVerified,
                 self.expectedAuthSession.userEmailIsVerified);
  XCTAssertEqual(testPersistAuthSession.canAuthorize, self.expectedAuthSession.canAuthorize);
}

- (void)testAuthSessionForPersistenceStringThrows {
  NSError *error;
  GTMOAuth2Compatibility *gtmOAuth2Compat = [[GTMOAuth2Compatibility alloc] init];

  GTMAuthSession *testPersistAuthSession __unused =
      [gtmOAuth2Compat authSessionForPersistenceString:[self expectedPersistenceResponseString]
                                              tokenURL:GTMTestingConstants.testTokenURL
                                           redirectURI:@""
                                              clientID:GTMTestingConstants.testClientID
                                          clientSecret:GTMTestingConstants.testClientSecret
                                                 error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, GTMKeychainStoreErrorCodeFailedToConvertRedirectURItoURL);
}

@end

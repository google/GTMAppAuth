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

@import AppAuthCore;
@import GTMAppAuthSwift;
@import TestHelpers;

@interface GTMOAuth2KeychainCompatibilityTests : XCTestCase

@property (nonatomic) GTMAppAuthFetcherAuthorization *expectedAuthorization;

@end

@implementation GTMOAuth2KeychainCompatibilityTests

- (void)setUp {
  self.expectedAuthorization =
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:OIDAuthState.testInstance
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
      [GTMOAuth2KeychainCompatibility persistenceResponseStringForAuthState:self.expectedAuthorization];
  XCTAssertNotNil(testPersistenceResponseString);
  XCTAssertEqualObjects([self expectedPersistenceResponseString], testPersistenceResponseString);
}

- (void)testAuthStateForPersistenceString {
  NSError *error;
  GTMOAuth2KeychainCompatibility *oauth2Compat = [[GTMOAuth2KeychainCompatibility alloc] init];
  GTMAppAuthFetcherAuthorization *testPersistAuth =
      [oauth2Compat authStateForPersistenceString:[self expectedPersistenceResponseString]
                                         tokenURL:GTMTestingConstants.testTokenURL
                                      redirectURI:GTMTestingConstants.testRedirectURI
                                         clientID:GTMTestingConstants.testClientID
                                     clientSecret:GTMTestingConstants.testClientSecret
                                            error:&error];
  XCTAssertNil(error);
  XCTAssertEqual(testPersistAuth.authState.scope, self.expectedAuthorization.authState.scope);
  XCTAssertEqualObjects(testPersistAuth.authState.lastTokenResponse.accessToken,
                        self.expectedAuthorization.authState.lastTokenResponse.accessToken);
  XCTAssertEqualObjects(testPersistAuth.authState.refreshToken,
                        self.expectedAuthorization.authState.refreshToken);
  XCTAssertEqual(testPersistAuth.authState.isAuthorized,
                 self.expectedAuthorization.authState.isAuthorized);
  XCTAssertEqualObjects(testPersistAuth.serviceProvider,
                        self.expectedAuthorization.serviceProvider);
  XCTAssertEqualObjects(testPersistAuth.userID, self.expectedAuthorization.userID);
  XCTAssertEqualObjects(testPersistAuth.userEmail, self.expectedAuthorization.userEmail);
  XCTAssertEqual(testPersistAuth.userEmailIsVerified,
                 self.expectedAuthorization.userEmailIsVerified);
  XCTAssertEqual(testPersistAuth.canAuthorize, self.expectedAuthorization.canAuthorize);
}

- (void)testAuthStateForPersistenceStringThrows {
  NSError *error;
  GTMOAuth2KeychainCompatibility *oauth2Compat = [[GTMOAuth2KeychainCompatibility alloc] init];
  GTMAppAuthFetcherAuthorization *testPersistAuth =
      [oauth2Compat authStateForPersistenceString:[self expectedPersistenceResponseString]
                                         tokenURL:GTMTestingConstants.testTokenURL
                                      redirectURI:@""
                                         clientID:GTMTestingConstants.testClientID
                                     clientSecret:GTMTestingConstants.testClientSecret
                                            error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, GTMKeychainStoreErrorCodeFailedToConvertRedirectURItoURL);
}

@end

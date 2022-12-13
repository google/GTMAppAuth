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

@interface GTMKeychainStoreTests : XCTestCase

@property (nonatomic) GTMAppAuthFetcherAuthorization *authorization;
@property (nonatomic) GTMKeychainStore *keychainStore;

@end

@implementation GTMKeychainStoreTests

- (void)setUp {
  self.authorization =
      [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:[OIDAuthState testInstance]];

  NSSet *emptyKeychainAttributes = [NSSet setWithArray:@[]];
  GTMKeychainHelperFake *fakeKeychain =
      [[GTMKeychainHelperFake alloc] initWithKeychainAttributes:emptyKeychainAttributes];
  self.keychainStore =
      [[GTMKeychainStore alloc] initWithItemName:[GTMTestingConstants testKeychainItemName]
                              keychainAttributes:emptyKeychainAttributes
                                  keychainHelper:fakeKeychain];
}

- (void)testSaveAuthorization {
  NSError *error;
  [self.keychainStore saveWithAuthState:self.authorization error:&error];
  XCTAssertNil(error);
}

- (void)testSaveAuthorizationErrorNoServiceName {
  NSError *error;
  [self.keychainStore saveWithAuthState:self.authorization
                            forItemName:@""
                                  error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, @"GTMAppAuthKeychainErrorDomain");
  XCTAssertEqual(error.code, GTMKeychainStoreErrorCodeNoService);
}

- (void)testReadAuthorization {
  NSError *error;
  [self.keychainStore saveWithAuthState:self.authorization error:&error];
  XCTAssertNil(error);

  GTMAppAuthFetcherAuthorization *testAuthorization =
      [self.keychainStore retrieveAuthStateAndReturnError:&error];
  XCTAssertNil(error);

  XCTAssertNotNil(testAuthorization);
  XCTAssertEqual(testAuthorization.authState.isAuthorized,
                 self.authorization.authState.isAuthorized);
  XCTAssertEqualObjects(testAuthorization.serviceProvider, self.authorization.serviceProvider);
  XCTAssertEqualObjects(testAuthorization.userID, self.authorization.userID);
  XCTAssertEqualObjects(testAuthorization.userEmail, self.authorization.userEmail);
  XCTAssertEqual(testAuthorization.userEmailIsVerified, self.authorization.userEmailIsVerified);
}

- (void)testRemoveAuthorization {
  NSError *error;
  [self.keychainStore saveWithAuthState:self.authorization error:&error];
  XCTAssertNil(error);

  [self.keychainStore removeAuthStateAndReturnError:&error];
  XCTAssertNil(error);
}

@end

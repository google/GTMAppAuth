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

@interface GTMKeychainStoreTests : XCTestCase

@property (nonatomic) GTMAuthState *authorization;
@property (nonatomic) GTMKeychainStore *keychainStore;

@end

@implementation GTMKeychainStoreTests

- (void)setUp {
  self.authorization =
      [[GTMAuthState alloc] initWithAuthState:[OIDAuthState testInstance]];

  NSSet *emptyKeychainAttributes = [NSSet set];
  GTMKeychainHelperFake *fakeKeychain =
      [[GTMKeychainHelperFake alloc] initWithKeychainAttributes:emptyKeychainAttributes];
  self.keychainStore =
      [[GTMKeychainStore alloc] initWithItemName:[GTMTestingConstants testKeychainItemName]
                              keychainAttributes:emptyKeychainAttributes
                                  keychainHelper:fakeKeychain];
  [super setUp];
}

- (void)testInitWithItemName {
  GTMKeychainStore *keychainStore =
      [[GTMKeychainStore alloc] initWithItemName:[GTMTestingConstants testKeychainItemName]];
  XCTAssertNotNil(keychainStore);
}

- (void)testInitWithItemNameKeychainAttributes {
  GTMKeychainStore *keychainStore =
      [[GTMKeychainStore alloc] initWithItemName:[GTMTestingConstants testKeychainItemName]
                              keychainAttributes:[NSSet set]];
  XCTAssertNotNil(keychainStore);
}

- (void)testInitWithItemNameKeychainHelper {
  GTMKeychainHelperFake *fakeKeychain =
      [[GTMKeychainHelperFake alloc] initWithKeychainAttributes:[NSSet set]];
  GTMKeychainStore *keychainStore =
      [[GTMKeychainStore alloc] initWithItemName:[GTMTestingConstants testKeychainItemName]
                              keychainHelper:fakeKeychain];
  XCTAssertNotNil(keychainStore);
}

- (void)testInitWithItemNameKeychainAttributesKeychainHelper {
  GTMKeychainHelperFake *fakeKeychain =
      [[GTMKeychainHelperFake alloc] initWithKeychainAttributes:[NSSet set]];
  GTMKeychainStore *keychainStore =
      [[GTMKeychainStore alloc] initWithItemName:[GTMTestingConstants testKeychainItemName]
                              keychainAttributes:[NSSet set]
                                  keychainHelper:fakeKeychain];
  XCTAssertNotNil(keychainStore);
}

- (void)testSaveAuthorization {
  NSError *error;
  [self.keychainStore saveAuthState:self.authorization error:&error];
  XCTAssertNil(error);
}

- (void)testSavingWithNewItemName {
  NSString *newItemName = @"newItemName";
  self.keychainStore.itemName = newItemName;

  NSError *error;
  [self.keychainStore saveAuthState:self.authorization
                        forItemName:newItemName
                              error:&error];
  XCTAssertNil(error);

  XCTAssertEqualObjects(newItemName, self.keychainStore.itemName);
  GTMAuthState *retrievedAuth =
      [self.keychainStore retrieveAuthStateForItemName:self.keychainStore.itemName error:&error];
  XCTAssertNotNil(retrievedAuth);

  XCTAssertEqual(retrievedAuth.authState.isAuthorized,
                 self.authorization.authState.isAuthorized);
  XCTAssertEqualObjects(retrievedAuth.serviceProvider, self.authorization.serviceProvider);
  XCTAssertEqualObjects(retrievedAuth.userID, self.authorization.userID);
  XCTAssertEqualObjects(retrievedAuth.userEmail, self.authorization.userEmail);
  XCTAssertEqual(retrievedAuth.userEmailIsVerified, self.authorization.userEmailIsVerified);
}

- (void)testSavingWithCustomItemName {
  NSString *customItemName = @"customItemName";
  NSError *error;

  [self.keychainStore saveAuthState:self.authorization
                        forItemName:customItemName
                              error:&error];
  XCTAssertNil(error);

  GTMAuthState *retrievedAuth =
  [self.keychainStore retrieveAuthStateForItemName:customItemName error:&error];
  XCTAssertNotNil(retrievedAuth);
  XCTAssertNil(error);

  XCTAssertNotNil(retrievedAuth);

  XCTAssertEqual(retrievedAuth.authState.isAuthorized,
                 self.authorization.authState.isAuthorized);
  XCTAssertEqualObjects(retrievedAuth.serviceProvider, self.authorization.serviceProvider);
  XCTAssertEqualObjects(retrievedAuth.userID, self.authorization.userID);
  XCTAssertEqualObjects(retrievedAuth.userEmail, self.authorization.userEmail);
  XCTAssertEqual(retrievedAuth.userEmailIsVerified, self.authorization.userEmailIsVerified);
}

- (void)testSaveAuthorizationErrorNoServiceName {
  NSError *error;
  [self.keychainStore saveAuthState:self.authorization
                        forItemName:@""
                              error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, @"GTMAppAuthKeychainErrorDomain");
  XCTAssertEqual(error.code, GTMKeychainStoreErrorCodeNoService);
}

- (void)testRetrieveAuthorization {
  NSError *error;
  [self.keychainStore saveAuthState:self.authorization error:&error];
  XCTAssertNil(error);

  GTMAuthState *testAuthorization =
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

- (void)testRetrieveAuthorizationForMissingItemName {
  NSError *error;
  NSString *missingItemName = @"missingItemName";
  GTMAuthState *missingAuth =
      [self.keychainStore retrieveAuthStateForItemName:missingItemName error:&error];

  XCTAssertNil(missingAuth);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, GTMKeychainStoreErrorCodePasswordNotFound);
}

- (void)testRetrieveAuthorizationForCustomItemName {
  NSError *error;
  NSString *customItemName = @"customItemName";
  self.keychainStore.itemName = customItemName;
  [self.keychainStore saveAuthState:self.authorization forItemName:customItemName error:&error];
  XCTAssertNil(error);

  GTMAuthState *retrievedAuth =
      [self.keychainStore retrieveAuthStateAndReturnError:&error];
  XCTAssertNotNil(retrievedAuth);
  XCTAssertNotNil(retrievedAuth);
  XCTAssertEqual(retrievedAuth.authState.isAuthorized,
                 self.authorization.authState.isAuthorized);
  XCTAssertEqualObjects(retrievedAuth.serviceProvider, self.authorization.serviceProvider);
  XCTAssertEqualObjects(retrievedAuth.userID, self.authorization.userID);
  XCTAssertEqualObjects(retrievedAuth.userEmail, self.authorization.userEmail);
  XCTAssertEqual(retrievedAuth.userEmailIsVerified, self.authorization.userEmailIsVerified);
}

- (void)testRemoveAuthorization {
  NSError *error;
  [self.keychainStore saveAuthState:self.authorization error:&error];
  XCTAssertNil(error);

  [self.keychainStore removeAuthStateAndReturnError:&error];
  XCTAssertNil(error);
}

- (void)testRemoveAuthorizationForMissingItemNameThrowsError {
  NSError *error;
  NSString *missingItemName = @"missingItemName";
  [self.keychainStore saveAuthState:self.authorization error:&error];
  XCTAssertNil(error);

  [self.keychainStore removeAuthStateWithItemName:missingItemName error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, GTMKeychainStoreErrorCodeFailedToDeletePasswordBecauseItemNotFound);
}

- (void)testKeychainStoreAttributes {
  NSString *testAccessGroupName = @"testKeychainAccessGroup";
  GTMKeychainAttribute *useDataProtection = [GTMKeychainAttribute useDataProtectionKeychain];
  GTMKeychainAttribute *keychainAccessGroup =
      [GTMKeychainAttribute keychainAccessGroupWithName:testAccessGroupName];
  NSSet<GTMKeychainAttribute *> *attributes =
      [NSSet setWithArray:@[
        useDataProtection, keychainAccessGroup
      ]];

  GTMKeychainStore *keychainStore =
      [[GTMKeychainStore alloc] initWithItemName:[GTMTestingConstants testKeychainItemName]
                              keychainAttributes:attributes];
  XCTAssertTrue(keychainStore.keychainAttributes.count > 0);
  XCTAssertTrue([keychainStore.keychainAttributes containsObject:useDataProtection]);
  XCTAssertTrue([keychainStore.keychainAttributes containsObject:keychainAccessGroup]);
}

- (void)testSaveAuthStateInGTMOAuth2Format {
  NSError *error;
  [self.keychainStore saveWithGTMOAuth2FormatForAuthorization:self.authorization
                                                        error:&error];
  XCTAssertNil(error);
}

- (void)testRetrieveAuthStateInGTMOAuth2Format {
  NSError *error;
  GTMAuthState *expectedAuthorization =
      [[GTMAuthState alloc] initWithAuthState:[OIDAuthState testInstance]
                                                serviceProvider:[GTMTestingConstants testServiceProvider]
                                                         userID:[GTMTestingConstants testUserID]
                                                      userEmail:[GTMTestingConstants testEmail]
                                            userEmailIsVerified:@"y"];
  [self.keychainStore saveWithGTMOAuth2FormatForAuthorization:expectedAuthorization
                                                        error:&error];
  XCTAssertNil(error);

  GTMAuthState *testAuth =
      [self.keychainStore retrieveAuthStateInGTMOAuth2FormatWithTokenURL:[GTMTestingConstants testTokenURL]
                                                             redirectURI:[GTMTestingConstants testRedirectURI]
                                                                clientID:[GTMTestingConstants testClientID]
                                                            clientSecret:[GTMTestingConstants testClientSecret]
                                                                   error:&error];

  XCTAssertNil(error);
  XCTAssertEqualObjects(testAuth.authState.scope, expectedAuthorization.authState.scope);
  XCTAssertEqualObjects(testAuth.authState.lastTokenResponse.accessToken,
                        expectedAuthorization.authState.lastTokenResponse.accessToken);
  XCTAssertEqualObjects(testAuth.authState.refreshToken,
                        expectedAuthorization.authState.refreshToken);
  XCTAssertEqual(testAuth.authState.isAuthorized, expectedAuthorization.authState.isAuthorized);
  XCTAssertEqualObjects(testAuth.serviceProvider, expectedAuthorization.serviceProvider);
  XCTAssertEqualObjects(testAuth.userID, expectedAuthorization.userID);
  XCTAssertEqualObjects(testAuth.userEmail, expectedAuthorization.userEmail);
  XCTAssertEqual(testAuth.userEmailIsVerified, expectedAuthorization.userEmailIsVerified);
  XCTAssertEqual(testAuth.canAuthorize, expectedAuthorization.canAuthorize);
}

- (void)testRemoveAuthStateInGTMOAuth2Format {
  NSError *error;
  [self.keychainStore saveWithGTMOAuth2FormatForAuthorization:self.authorization
                                                        error:&error];
  XCTAssertNil(error);

  [self.keychainStore removeAuthStateAndReturnError:&error];
  XCTAssertNil(error);
}

@end

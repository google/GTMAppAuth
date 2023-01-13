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

@property (nonatomic) GTMAuthSession *authSession;
@property (nonatomic) GTMKeychainStore *keychainStore;

@end

@implementation GTMKeychainStoreTests

- (void)setUp {
  self.authSession = [[GTMAuthSession alloc] initWithAuthState:[OIDAuthState testInstance]];

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
  [self.keychainStore saveAuthSession:self.authSession error:&error];
  XCTAssertNil(error);
}

- (void)testSavingWithNewItemName {
  NSString *newItemName = @"newItemName";
  self.keychainStore.itemName = newItemName;

  NSError *error;
  [self.keychainStore saveAuthSession:self.authSession
                          forItemName:newItemName
                                error:&error];
  XCTAssertNil(error);

  XCTAssertEqualObjects(newItemName, self.keychainStore.itemName);
  GTMAuthSession *authSession =
      [self.keychainStore retrieveAuthSessionWithItemName:self.keychainStore.itemName error:&error];
  XCTAssertNotNil(authSession);

  XCTAssertEqual(authSession.authState.isAuthorized, self.authSession.authState.isAuthorized);
  XCTAssertEqualObjects(authSession.serviceProvider, self.authSession.serviceProvider);
  XCTAssertEqualObjects(authSession.userID, self.authSession.userID);
  XCTAssertEqualObjects(authSession.userEmail, self.authSession.userEmail);
  XCTAssertEqual(authSession.userEmailIsVerified, self.authSession.userEmailIsVerified);
}

- (void)testSavingWithCustomItemName {
  NSString *customItemName = @"customItemName";
  NSError *error;

  [self.keychainStore saveAuthSession:self.authSession
                          forItemName:customItemName
                                error:&error];
  XCTAssertNil(error);

  GTMAuthSession *retrievedAuth =
  [self.keychainStore retrieveAuthSessionWithItemName:customItemName error:&error];
  XCTAssertNotNil(retrievedAuth);
  XCTAssertNil(error);

  XCTAssertNotNil(retrievedAuth);

  XCTAssertEqual(retrievedAuth.authState.isAuthorized,
                 self.authSession.authState.isAuthorized);
  XCTAssertEqualObjects(retrievedAuth.serviceProvider, self.authSession.serviceProvider);
  XCTAssertEqualObjects(retrievedAuth.userID, self.authSession.userID);
  XCTAssertEqualObjects(retrievedAuth.userEmail, self.authSession.userEmail);
  XCTAssertEqual(retrievedAuth.userEmailIsVerified, self.authSession.userEmailIsVerified);
}

- (void)testSaveAuthSessionErrorNoServiceName {
  NSError *error;
  [self.keychainStore saveAuthSession:self.authSession
                          forItemName:@""
                                error:&error];
  XCTAssertNotNil(error);
  XCTAssertEqualObjects(error.domain, @"GTMAppAuthKeychainErrorDomain");
  XCTAssertEqual(error.code, GTMKeychainStoreErrorCodeNoService);
}

- (void)testRetrieveAuthSession {
  NSError *error;
  [self.keychainStore saveAuthSession:self.authSession error:&error];
  XCTAssertNil(error);

  GTMAuthSession *authSession = [self.keychainStore retrieveAuthSessionWithError:&error];
  XCTAssertNil(error);

  XCTAssertNotNil(authSession);
  XCTAssertEqual(authSession.authState.isAuthorized, self.authSession.authState.isAuthorized);
  XCTAssertEqualObjects(authSession.serviceProvider, self.authSession.serviceProvider);
  XCTAssertEqualObjects(authSession.userID, self.authSession.userID);
  XCTAssertEqualObjects(authSession.userEmail, self.authSession.userEmail);
  XCTAssertEqual(authSession.userEmailIsVerified, self.authSession.userEmailIsVerified);
}

- (void)testRetrieveAuthSessionForMissingItemName {
  NSError *error;
  NSString *missingItemName = @"missingItemName";
  GTMAuthSession *missingAuthSession =
      [self.keychainStore retrieveAuthSessionWithItemName:missingItemName error:&error];

  XCTAssertNil(missingAuthSession);
  XCTAssertNotNil(error);
  XCTAssertEqual(error.code, GTMKeychainStoreErrorCodePasswordNotFound);
}

- (void)testRetrieveAuthSessionForCustomItemName {
  NSError *error;
  NSString *customItemName = @"customItemName";
  self.keychainStore.itemName = customItemName;
  [self.keychainStore saveAuthSession:self.authSession forItemName:customItemName error:&error];
  XCTAssertNil(error);

  GTMAuthSession *retrievedAuthSession =
      [self.keychainStore retrieveAuthSessionWithError:&error];
  XCTAssertNotNil(retrievedAuthSession);
  XCTAssertNotNil(retrievedAuthSession);
  XCTAssertEqual(retrievedAuthSession.authState.isAuthorized,
                 self.authSession.authState.isAuthorized);
  XCTAssertEqualObjects(retrievedAuthSession.serviceProvider, self.authSession.serviceProvider);
  XCTAssertEqualObjects(retrievedAuthSession.userID, self.authSession.userID);
  XCTAssertEqualObjects(retrievedAuthSession.userEmail, self.authSession.userEmail);
  XCTAssertEqual(retrievedAuthSession.userEmailIsVerified, self.authSession.userEmailIsVerified);
}

- (void)testRemoveAuthSession {
  NSError *error;
  [self.keychainStore saveAuthSession:self.authSession error:&error];
  XCTAssertNil(error);

  [self.keychainStore removeAuthSessionWithError:&error];
  XCTAssertNil(error);
}

- (void)testRemoveAuthSessionForMissingItemNameThrowsError {
  NSError *error;
  NSString *missingItemName = @"missingItemName";
  [self.keychainStore saveAuthSession:self.authSession error:&error];
  XCTAssertNil(error);

  [self.keychainStore removeAuthSessionWithItemName:missingItemName error:&error];
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

- (void)testSaveAuthSessionInGTMOAuth2Format {
  NSError *error;
  [self.keychainStore saveWithGTMOAuth2FormatForAuthSession:self.authSession error:&error];
  XCTAssertNil(error);
}

- (void)testRetrieveAuthSessionInGTMOAuth2Format {
  NSError *error;
  GTMAuthSession *expectedAuthSession =
      [[GTMAuthSession alloc] initWithAuthState:[OIDAuthState testInstance]
                                serviceProvider:[GTMTestingConstants testServiceProvider]
                                         userID:[GTMTestingConstants testUserID]
                                      userEmail:[GTMTestingConstants testEmail]
                            userEmailIsVerified:@"y"];
  [self.keychainStore saveWithGTMOAuth2FormatForAuthSession:expectedAuthSession error:&error];
  XCTAssertNil(error);

  GTMAuthSession *testAuth =
      [self.keychainStore
          retrieveAuthSessionInGTMOAuth2FormatWithTokenURL:[GTMTestingConstants testTokenURL]
                                               redirectURI:[GTMTestingConstants testRedirectURI]
                                                  clientID:[GTMTestingConstants testClientID]
                                              clientSecret:[GTMTestingConstants testClientSecret]
                                                     error:&error];

  XCTAssertNil(error);
  XCTAssertEqualObjects(testAuth.authState.scope, expectedAuthSession.authState.scope);
  XCTAssertEqualObjects(testAuth.authState.lastTokenResponse.accessToken,
                        expectedAuthSession.authState.lastTokenResponse.accessToken);
  XCTAssertEqualObjects(testAuth.authState.refreshToken,
                        expectedAuthSession.authState.refreshToken);
  XCTAssertEqual(testAuth.authState.isAuthorized, expectedAuthSession.authState.isAuthorized);
  XCTAssertEqualObjects(testAuth.serviceProvider, expectedAuthSession.serviceProvider);
  XCTAssertEqualObjects(testAuth.userID, expectedAuthSession.userID);
  XCTAssertEqualObjects(testAuth.userEmail, expectedAuthSession.userEmail);
  XCTAssertEqual(testAuth.userEmailIsVerified, expectedAuthSession.userEmailIsVerified);
  XCTAssertEqual(testAuth.canAuthorize, expectedAuthSession.canAuthorize);
}

- (void)testRemoveAuthSessionInGTMOAuth2Format {
  NSError *error;
  [self.keychainStore saveWithGTMOAuth2FormatForAuthSession:self.authSession error:&error];
  XCTAssertNil(error);

  [self.keychainStore removeAuthSessionWithError:&error];
  XCTAssertNil(error);
}

@end

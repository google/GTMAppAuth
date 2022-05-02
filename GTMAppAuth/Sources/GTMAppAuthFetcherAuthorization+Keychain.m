/*! @file GTMAppAuthFetcherAuthorization+Keychain.m
    @brief GTMAppAuth SDK
    @copyright
        Copyright 2016 Google Inc.
    @copydetails
        Licensed under the Apache License, Version 2.0 (the "License");
        you may not use this file except in compliance with the License.
        You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

        Unless required by applicable law or agreed to in writing, software
        distributed under the License is distributed on an "AS IS" BASIS,
        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
        See the License for the specific language governing permissions and
        limitations under the License.
 */

#import "GTMAppAuth/Sources/Public/GTMAppAuth/GTMAppAuthFetcherAuthorization+Keychain.h"

#import "GTMAppAuth/Sources/Public/GTMAppAuth/GTMKeychain.h"

@implementation GTMAppAuthFetcherAuthorization (Keychain)

+ (GTMAppAuthFetcherAuthorization *)authorizationFromKeychainForName:(NSString *)keychainItemName {
  return [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:keychainItemName
                                               withDataProtectionKeychain:NO];
}

+ (GTMAppAuthFetcherAuthorization *)authorizationFromKeychainForName:(NSString *)keychainItemName
                                          withDataProtectionKeychain:(BOOL)dataProtectionKeychain {
  NSData *passwordData = [GTMKeychain passwordDataFromKeychainForName:keychainItemName
                                           withDataProtectionKeychain:dataProtectionKeychain];
  if (!passwordData) {
    return nil;
  }
  GTMAppAuthFetcherAuthorization *authorization = (GTMAppAuthFetcherAuthorization *)
      [NSKeyedUnarchiver unarchiveObjectWithData:passwordData];
  return authorization;
}

+ (BOOL)removeAuthorizationFromKeychainForName:(NSString *)keychainItemName {
  return [GTMAppAuthFetcherAuthorization removeAuthorizationFromKeychainForName:keychainItemName
                                                     withDataProtectionKeychain:NO];
}

+ (BOOL)removeAuthorizationFromKeychainForName:(NSString *)keychainItemName
                    withDataProtectionKeychain:(BOOL)dataProtectionKeychain {
  return [GTMKeychain removePasswordFromKeychainForName:keychainItemName
                             withDataProtectionKeychain:dataProtectionKeychain];
}

+ (BOOL)saveAuthorization:(GTMAppAuthFetcherAuthorization *)auth
        toKeychainForName:(NSString *)keychainItemName {
  return [GTMAppAuthFetcherAuthorization saveAuthorization:auth
                                         toKeychainForName:keychainItemName
                                withDataProtectionKeychain:NO];
}

+ (BOOL)saveAuthorization:(GTMAppAuthFetcherAuthorization *)auth
             toKeychainForName:(NSString *)keychainItemName
    withDataProtectionKeychain:(BOOL)dataProtectionKeychain {
  NSData *authorizationData = [NSKeyedArchiver archivedDataWithRootObject:auth];
  return [GTMKeychain savePasswordDataToKeychainForName:keychainItemName
                                           passwordData:authorizationData
                             withDataProtectionKeychain:dataProtectionKeychain];
}

@end

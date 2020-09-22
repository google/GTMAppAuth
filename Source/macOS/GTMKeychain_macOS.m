/*! @file GTMKeychain_macOS.m
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

#import <TargetConditionals.h>

#if TARGET_OS_OSX

#if SWIFT_PACKAGE
#import "../GTMKeychain.h"
#else
#import "GTMKeychain.h"
#endif

#import <Security/Security.h>
#import <Foundation/Foundation.h>

static const char *kKeychainAccountName = "OAuth";

@implementation GTMKeychain

+ (NSString *)prefsKeyForName:(NSString *)keychainItemName {
  NSString *result = [@"OAuth2: " stringByAppendingString:keychainItemName];
  return result;
}

+ (NSString *)passwordFromKeychainForName:(NSString *)keychainItemName {
  // before accessing the keychain, check preferences to verify that we've
  // previously saved a token to the keychain (so we don't needlessly raise
  // a keychain access permission dialog)
  NSString *prefKey = [self prefsKeyForName:keychainItemName];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  BOOL flag = [defaults boolForKey:prefKey];
  if (!flag) {
    return nil;
  }

  SecKeychainRef defaultKeychain = NULL;
  const char *utf8ServiceName = keychainItemName.UTF8String;
  SecKeychainItemRef *dontWantItemRef = NULL;

  void *passwordBuff = NULL;
  UInt32 passwordBuffLength = 0;

  OSStatus err = SecKeychainFindGenericPassword(defaultKeychain,
                                  (UInt32) strlen(utf8ServiceName), utf8ServiceName,
                                  (UInt32) strlen(kKeychainAccountName), kKeychainAccountName,
                                  &passwordBuffLength, &passwordBuff,
                                  dontWantItemRef);
  if (err == noErr && passwordBuff != NULL) {
    NSString *password = [[NSString alloc] initWithBytes:passwordBuff
                                                  length:passwordBuffLength
                                                encoding:NSUTF8StringEncoding];

    // free the password buffer that was allocated above
    SecKeychainItemFreeContent(NULL, passwordBuff);

    if (password != nil) {
      return password;
    }
  }
  return nil;
}

+ (NSData *)passwordDataFromKeychainForName:(NSString *)keychainItemName {
  // before accessing the keychain, check preferences to verify that we've
  // previously saved a token to the keychain (so we don't needlessly raise
  // a keychain access permission dialog)
  NSString *prefKey = [self prefsKeyForName:keychainItemName];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  BOOL flag = [defaults boolForKey:prefKey];
  if (!flag) {
    return nil;
  }

  SecKeychainRef defaultKeychain = NULL;
  const char *utf8ServiceName = [keychainItemName UTF8String];
  SecKeychainItemRef *dontWantItemRef = NULL;

  void *passwordBuff = NULL;
  UInt32 passwordBuffLength = 0;

  OSStatus err = SecKeychainFindGenericPassword(defaultKeychain,
                                  (UInt32) strlen(utf8ServiceName), utf8ServiceName,
                                  (UInt32) strlen(kKeychainAccountName), kKeychainAccountName,
                                  &passwordBuffLength, &passwordBuff,
                                  dontWantItemRef);
  if (err == noErr && passwordBuff != NULL) {

    NSData *passwordData = [[NSData alloc] initWithBytes:passwordBuff length:passwordBuffLength];

    // free the password buffer that was allocated above
    SecKeychainItemFreeContent(NULL, passwordBuff);

    return passwordData;
  }
  return nil;
}

+ (BOOL)removePasswordFromKeychainForName:(NSString *)keychainItemName {
  SecKeychainRef defaultKeychain = NULL;
  SecKeychainItemRef itemRef = NULL;
  const char *utf8ServiceName = [keychainItemName UTF8String];

  // we don't really care about the password here, we just want to
  // get the SecKeychainItemRef so we can delete it.
  OSStatus err = SecKeychainFindGenericPassword (defaultKeychain,
                                   (UInt32) strlen(utf8ServiceName), utf8ServiceName,
                                   (UInt32) strlen(kKeychainAccountName), kKeychainAccountName,
                                   0, NULL, // ignore password
                                   &itemRef);
  if (err != noErr) {
    // failure to find is success
    return YES;
  } else {
    // found something, so delete it
    err = SecKeychainItemDelete(itemRef);
    CFRelease(itemRef);

    // remove our preference key
    NSString *prefKey = [self prefsKeyForName:keychainItemName];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:prefKey];

    return (err == noErr);
  }
}

+ (BOOL)savePasswordToKeychainForName:(NSString *)keychainItemName password:(NSString *)password {
  SecKeychainRef defaultKeychain = NULL;
  SecKeychainItemRef *dontWantItemRef= NULL;
  const char *utf8ServiceName = [keychainItemName UTF8String];
  const char *utf8Password = [password UTF8String];

  OSStatus err = SecKeychainAddGenericPassword(defaultKeychain,
                             (UInt32) strlen(utf8ServiceName), utf8ServiceName,
                             (UInt32) strlen(kKeychainAccountName), kKeychainAccountName,
                             (UInt32) strlen(utf8Password), utf8Password,
                             dontWantItemRef);
  BOOL didSucceed = (err == noErr);
  if (didSucceed) {
    // write to preferences that we have a keychain item (so we know later
    // that we can read from the keychain without raising a permissions dialog)
    NSString *prefKey = [self prefsKeyForName:keychainItemName];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:prefKey];
  }

  return didSucceed;
}

+ (BOOL)savePasswordDataToKeychainForName:(NSString *)keychainItemName
                             passwordData:(NSData *)passwordData {
  SecKeychainRef defaultKeychain = NULL;
  SecKeychainItemRef *dontWantItemRef= NULL;
  const char *utf8ServiceName = [keychainItemName UTF8String];
  const void *passwordBytes = [passwordData bytes];
  UInt32 passwordBytesLength = (UInt32) [passwordData length];

  OSStatus err = SecKeychainAddGenericPassword(defaultKeychain,
                             (UInt32) strlen(utf8ServiceName), utf8ServiceName,
                             (UInt32) strlen(kKeychainAccountName), kKeychainAccountName,
                             passwordBytesLength, passwordBytes,
                             dontWantItemRef);
  BOOL didSucceed = (err == noErr);
  if (didSucceed) {
    // write to preferences that we have a keychain item (so we know later
    // that we can read from the keychain without raising a permissions dialog)
    NSString *prefKey = [self prefsKeyForName:keychainItemName];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:prefKey];
  }

  return didSucceed;
}

@end

#endif // TARGET_OS_OSX

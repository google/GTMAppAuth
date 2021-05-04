/*! @file GTMAppAuth.h
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

#import "GTMAppAuthFetcherAuthorization.h"
#import "GTMAppAuthFetcherAuthorization+Keychain.h"

#if TARGET_OS_TV
#elif TARGET_OS_WATCH
#elif TARGET_OS_IOS || TARGET_OS_MAC
#import "GTMKeychain.h"
#import "GTMOAuth2KeychainCompatibility.h"
#else
#warn "Platform Undefined"
#endif

/*! @file OIDAuthState+Mac.h
    @brief AppAuth iOS SDK
    @copyright
        Copyright 2016 Google Inc. All Rights Reserved.
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

#import "OIDAuthState.h"

NS_ASSUME_NONNULL_BEGIN

/*! @brief macOS specific convenience methods for @c OIDAuthState.
 */
@interface OIDAuthState (Mac)

/*! @brief Convenience method to create a @c OIDAuthState by presenting an authorization request
        and performing the authorization code exchange in the case of code flow requests.
    @param authorizationRequest The authorization request to present.
    @param callback The method called when the request has completed or failed.
    @return A @c OIDAuthorizationFlowSession instance which will terminate when it
        receives a @c OIDAuthorizationFlowSession.cancel message, or after processing a
        @c OIDAuthorizationFlowSession.resumeAuthorizationFlowWithURL: message.
 */
+ (id<OIDAuthorizationFlowSession>)
    authStateByPresentingAuthorizationRequest:(OIDAuthorizationRequest *)authorizationRequest
                                     callback:(OIDAuthStateAuthorizationCallback)callback;
@end

NS_ASSUME_NONNULL_END

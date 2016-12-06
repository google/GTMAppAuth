/*! @file GTMTVAuthorizationRequest.h
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

#import <Foundation/Foundation.h>

#import "OIDAuthorizationRequest.h"

@class GTMTVServiceConfiguration;

NS_ASSUME_NONNULL_BEGIN

/*! @brief Represents a TV and limited input device authorization request.
    @see https://developers.google.com/identity/protocols/OAuth2ForDevices
 */
@interface GTMTVAuthorizationRequest : OIDAuthorizationRequest

/*! @brief Designated initializer.
    @param configuration The service's configuration.
    @param clientID The client identifier.
    @param clientSecret The client secret.
    @param scope A scope string per the OAuth2 spec (a space-delimited set of scopes).
    @param redirectURL The client's redirect URI.
    @param responseType The expected response type.
    @param state An opaque value used by the client to maintain state between the request and
        callback.
    @param codeVerifier The PKCE code verifier. See @c OIDAuthorizationRequest.generateCodeVerifier.
    @param codeChallenge The PKCE code challenge, calculated from the code verifier such as with
        @c OIDAuthorizationRequest.codeChallengeS256ForVerifier:.
    @param codeChallengeMethod The PKCE code challenge method.
        ::OIDOAuthorizationRequestCodeChallengeMethodS256 when
        @c OIDAuthorizationRequest.codeChallengeS256ForVerifier: is used to create the code
        challenge.
    @param additionalParameters The client's additional authorization parameters.
 */
- (instancetype)
    initWithConfiguration:(GTMTVServiceConfiguration *)configuration
                 clientId:(NSString *)clientID
             clientSecret:(nullable NSString *)clientSecret
                    scope:(nullable NSString *)scope
              redirectURL:(NSURL *)redirectURL
             responseType:(NSString *)responseType
                    state:(nullable NSString *)state
             codeVerifier:(nullable NSString *)codeVerifier
            codeChallenge:(nullable NSString *)codeChallenge
      codeChallengeMethod:(nullable NSString *)codeChallengeMethod
     additionalParameters:(nullable NSDictionary<NSString *, NSString *> *)additionalParameters
    NS_DESIGNATED_INITIALIZER;

/*! @brief Creates a TV authorization request with opinionated defaults
    @param configuration The service's configuration.
    @param clientID The client identifier.
    @param clientSecret The client secret.
    @param scopes An array of scopes to combine into a single scope string per the OAuth2 spec.
    @param TVAuthorizationURL The TV & limited input device authorization endpoint URL.
    @param additionalParameters The client's additional authorization parameters.
 */
- (instancetype)
    initWithConfiguration:(GTMTVServiceConfiguration *)configuration
                 clientId:(NSString *)clientID
             clientSecret:(NSString *)clientSecret
                   scopes:(nullable NSArray<NSString *> *)scopes
     additionalParameters:(nullable NSDictionary<NSString *, NSString *> *)additionalParameters;

/*! @brief Constructs an @c NSURLRequest representing the TV authorization request.
    @return An @c NSURLRequest representing the TV authorization request.
 */
- (NSURLRequest *)URLRequest;

@end

NS_ASSUME_NONNULL_END

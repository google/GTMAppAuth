/*! @file OIDAuthorizationService.h
    @brief AppAuth iOS SDK
    @copyright
        Copyright 2015 Google Inc. All Rights Reserved.
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

@class OIDAuthorization;
@class OIDAuthorizationRequest;
@class OIDAuthorizationResponse;
@class OIDRegistrationRequest;
@class OIDRegistrationResponse;
@class OIDServiceConfiguration;
@class OIDTokenRequest;
@class OIDTokenResponse;
@protocol OIDAuthorizationFlowSession;
@protocol OIDAuthorizationUICoordinator;

NS_ASSUME_NONNULL_BEGIN

/*! @brief Represents the type of block used as a callback for creating a service configuration from
        a remote OpenID Connect Discovery document.
    @param configuration The service configuration, if available.
    @param error The error if an error occurred.
 */
typedef void (^OIDDiscoveryCallback)(OIDServiceConfiguration *_Nullable configuration,
                                     NSError *_Nullable error);

/*! @brief Represents the type of block used as a callback for various methods of
        @c OIDAuthorizationService.
    @param authorizationResponse The authorization response, if available.
    @param error The error if an error occurred.
 */
typedef void (^OIDAuthorizationCallback)(OIDAuthorizationResponse *_Nullable authorizationResponse,
                                         NSError *_Nullable error);

/*! @brief Represents the type of block used as a callback for various methods of
        @c OIDAuthorizationService.
    @param tokenResponse The token response, if available.
    @param error The error if an error occurred.
 */
typedef void (^OIDTokenCallback)(OIDTokenResponse *_Nullable tokenResponse,
                                 NSError *_Nullable error);

/*! @brief Represents the type of dictionary used to specify additional querystring parameters
        when making authorization or token endpoint requests.
 */
typedef NSDictionary<NSString *, NSString *> *_Nullable OIDTokenEndpointParameters;

/*! @brief Represents the type of block used as a callback for various methods of
        @c OIDAuthorizationService.
    @param registrationResponse The registration response, if available.
    @param error The error if an error occurred.
*/
typedef void (^OIDRegistrationCompletion)(OIDRegistrationResponse *_Nullable registrationResponse,
                                          NSError *_Nullable error);

/*! @brief Performs various OAuth and OpenID Connect related calls via the user agent or
        \NSURLSession.
 */
@interface OIDAuthorizationService : NSObject {
  // property variables
  OIDServiceConfiguration *_configuration;
}

/*! @brief The service's configuration.
    @remarks Each authorization service is initialized with a configuration. This configuration
        specifies how to connect to a particular OAuth provider. Clients should use separate
        authorization service instances for each provider they wish to integrate with.
        Configurations may be created manually, or via an OpenID Connect Discovery Document.
 */
@property(nonatomic, readonly) OIDServiceConfiguration *configuration;

/*! @internal
    @brief Unavailable. This class should not be initialized.
 */
- (instancetype)init NS_UNAVAILABLE;

/*! @brief Convenience method for creating an authorization service configuration from an OpenID
        Connect compliant issuer URL.
    @param issuerURL The service provider's OpenID Connect issuer.
    @param completion A block which will be invoked when the authorization service configuration has
        been created, or when an error has occurred.
    @see https://openid.net/specs/openid-connect-discovery-1_0.html
 */
+ (void)discoverServiceConfigurationForIssuer:(NSURL *)issuerURL
                                   completion:(OIDDiscoveryCallback)completion;


/*! @brief Convenience method for creating an authorization service configuration from an OpenID
        Connect compliant identity provider's discovery document.
    @param discoveryURL The URL of the service provider's OpenID Connect discovery document.
    @param completion A block which will be invoked when the authorization service configuration has
        been created, or when an error has occurred.
    @see https://openid.net/specs/openid-connect-discovery-1_0.html
 */
+ (void)discoverServiceConfigurationForDiscoveryURL:(NSURL *)discoveryURL
                                         completion:(OIDDiscoveryCallback)completion;

/*! @brief Perform an authorization flow using a generic flow shim.
    @param request The authorization request.
    @param UICoordinator Generic authorization UI coordinator that can present an authorization
        request.
    @param callback The method called when the request has completed or failed.
    @return A @c OIDAuthorizationFlowSession instance which will terminate when it
        receives a @c OIDAuthorizationFlowSession.cancel message, or after processing a
        @c OIDAuthorizationFlowSession.resumeAuthorizationFlowWithURL: message.
 */
+ (id<OIDAuthorizationFlowSession>)
    presentAuthorizationRequest:(OIDAuthorizationRequest *)request
                  UICoordinator:(id<OIDAuthorizationUICoordinator>)UICoordinator
                       callback:(OIDAuthorizationCallback)callback;

/*! @brief Performs a token request.
    @param request The token request.
    @param callback The method called when the request has completed or failed.
 */
+ (void)performTokenRequest:(OIDTokenRequest *)request callback:(OIDTokenCallback)callback;

/*! @brief Performs a registration request.
    @param request The registration request.
    @param completion The method called when the request has completed or failed.
 */
+ (void)performRegistrationRequest:(OIDRegistrationRequest *)request
                        completion:(OIDRegistrationCompletion)completion;

@end

/*! @brief Represents an in-flight authorization flow session.
 */
@protocol OIDAuthorizationFlowSession <NSObject>

/*! @brief Cancels the code flow session, invoking the request's callback with a cancelled error.
    @remarks Has no effect if called more than once, or after a
        @c OIDAuthorizationFlowSession.resumeAuthorizationFlowWithURL: message was received. Will
        cause an error with code: @c ::OIDErrorCodeProgramCanceledAuthorizationFlow to be passed to
        the @c callback block passed to
        @c OIDAuthorizationService.presentAuthorizationRequest:presentingViewController:callback:
 */
- (void)cancel;

/*! @brief Clients should call this method with the result of the authorization code flow if it
        becomes available.
    @param URL The redirect URL invoked by the authorization server.
    @discussion When the URL represented a valid authorization response, implementations
        should clean up any left-over UI state from the authorization, for example by
        closing the \SFSafariViewController or looback HTTP listener if those were used.
        The completion block of the pending authorization request should then be invoked.
    @remarks Has no effect if called more than once, or after a @c cancel message was received.
    @return YES if the passed URL matches the expected redirect URL and was consumed, NO otherwise.
 */
- (BOOL)resumeAuthorizationFlowWithURL:(NSURL *)URL;

/*! @brief @c OIDAuthorizationUICoordinator or clients should call this method when the
         authorization flow failed with a non-OAuth error.
    @param error The error that is the reason for the failure of this authorization flow.
    @remarks Has no effect if called more than once, or after a @c cancel message was received.
 */
- (void)failAuthorizationFlowWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END

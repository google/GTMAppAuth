/*! @file AppAuthExampleViewController.m
    @brief GTMAppAuth macOS SDK Example
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

#import "GTMAppAuthExampleViewController.h"

#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"
#import "GTMSessionFetcher.h"
#import "GTMSessionFetcherService.h"

/*! @brief The OIDC issuer from which the configuration will be discovered.
 */
static NSString *const kIssuer = @"https://accounts.google.com";

/*! @brief The OAuth client ID.
    @discussion For Google, register your client at
        https://console.developers.google.com/apis/credentials?project=_
 */
static NSString *const kClientID = @"YOUR_CLIENT.apps.googleusercontent.com";

/*! @brief The OAuth client secret.
    @discussion For Google, register your client at
        https://console.developers.google.com/apis/credentials?project=_
 */
static NSString *const kClientSecret = @"YOUR_CLIENT_SECRET";

/*! @brief The OAuth redirect URI for the client @c kClientID.
    @discussion With Google, the scheme of the redirect URI is the reverse DNS notation of the
        client ID. This scheme must be registered as a scheme in the project's Info
        property list ("CFBundleURLTypes" plist key). Any path component will work, we use
        'oauthredirect' here to help disambiguate from any other use of this scheme.
 */
static NSString *const kRedirectURI =
    @"com.googleusercontent.apps.YOUR_CLIENT:/oauthredirect";

/*! @brief NSCoding key for the authorization property.
 */
static NSString *const kExampleAuthorizerKey = @"authorization";

@interface GTMAppAuthExampleViewController () <OIDAuthStateChangeDelegate,
                                               OIDAuthStateErrorDelegate>
@end

@implementation GTMAppAuthExampleViewController

- (void)viewDidLoad {
  [super viewDidLoad];

#if !defined(NS_BLOCK_ASSERTIONS)

  // NOTE:
  //
  // To run this sample, you need to register your own Google API client at
  // https://console.developers.google.com/apis/credentials?project=_ and update three configuration
  // points in the sample: kClientID and kRedirectURI constants in AppAuthExampleViewController.m
  // and the URI scheme in Info.plist (URL Types -> Item 0 -> URL Schemes -> Item 0).
  // Full instructions: https://github.com/openid/AppAuth-iOS/blob/master/Example-Mac/README.md

  NSAssert(![kClientID isEqualToString:@"YOUR_CLIENT.apps.googleusercontent.com"],
           @"Update kClientID with your own client ID. "
            "Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Example-Mac/README.md");

  NSAssert(![kRedirectURI isEqualToString:@"com.googleusercontent.apps.YOUR_CLIENT:/oauthredirect"],
           @"Update kRedirectURI with your own redirect URI. "
            "Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Example-Mac/README.md");

  // verifies that the custom URI scheme has been updated in the Info.plist
  NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
  NSAssert(urlTypes.count > 0, @"No custom URI scheme has been configured for the project.");
  NSArray *urlSchemes = ((NSDictionary *)urlTypes.firstObject)[@"CFBundleURLSchemes"];
  NSAssert(urlSchemes.count > 0, @"No custom URI scheme has been configured for the project.");
  NSString *urlScheme = urlSchemes.firstObject;

  NSAssert(![urlScheme isEqualToString:@"com.googleusercontent.apps.YOUR_CLIENT"],
           @"Configure the URI scheme in Info.plist (URL Types -> Item 0 -> URL Schemes -> Item 0) "
            "with the scheme of your redirect URI. Full instructions: "
            "https://github.com/openid/AppAuth-iOS/blob/master/Example-Mac/README.md");

#endif // !defined(NS_BLOCK_ASSERTIONS)

  _logTextView.layer.borderColor = [NSColor colorWithWhite:0.8 alpha:1.0].CGColor;
  _logTextView.layer.borderWidth = 1.0f;
  _logTextView.textContainer.lineBreakMode = NSLineBreakByCharWrapping;

  [self loadState];
  [self updateUI];
}

/*! @brief Saves the @c GTMAppAuthFetcherAuthorization to @c NSUSerDefaults.
 */
- (void)saveState {
  if (_authorization.canAuthorize) {
    [GTMAppAuthFetcherAuthorization saveAuthorization:_authorization
                                    toKeychainForName:kExampleAuthorizerKey];
  } else {
    [GTMAppAuthFetcherAuthorization removeAuthorizationFromKeychainForName:kExampleAuthorizerKey];
  }
}

/*! @brief Loads the @c GTMAppAuthFetcherAuthorization from @c NSUSerDefaults.
 */
- (void)loadState {
  GTMAppAuthFetcherAuthorization* authorization =
      [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:kExampleAuthorizerKey];
  [self setAuthorization:authorization];
}

/*! @brief Refreshes UI, typically called after the auth state changed.
 */
- (void)updateUI {
  _userinfoButton.enabled = [_authorization canAuthorize];
  _forceRefreshButton.enabled = [_authorization canAuthorize];
  _clearAuthStateButton.enabled = _authorization != nil;
  // dynamically changes authorize button text depending on authorized state
  if (!_authorization) {
    _authAutoButton.title = @"Authorize";
  } else {
    _authAutoButton.title = @"Re-authorize";
  }
}

/*! @brief Forces a token refresh.
    @param sender IBAction sender.
 */
- (IBAction)forceRefresh:(nullable id)sender {
  [_authorization.authState setNeedsTokenRefresh];
}

- (void)stateChanged {
  [self saveState];
  [self updateUI];
}

- (void)didChangeState:(OIDAuthState *)state {
  // TODO(wdenniss): update for GTMAppAuth
  [self stateChanged];
}

- (void)setAuthorization:(GTMAppAuthFetcherAuthorization*)authorization {
  _authorization = authorization;
 [self saveState];
 [self updateUI];
}


- (void)authState:(OIDAuthState *)state didEncounterAuthorizationError:(nonnull NSError *)error {
  [self logMessage:@"Received authorization error: %@", error];
}

- (IBAction)authWithAutoCodeExchange:(nullable id)sender {
  NSURL *issuer = [NSURL URLWithString:kIssuer];
  NSURL *redirectURI = [NSURL URLWithString:kRedirectURI];

  [self logMessage:@"Fetching configuration for issuer: %@", issuer];

  // discovers endpoints
  [OIDAuthorizationService discoverServiceConfigurationForIssuer:issuer
      completion:^(OIDServiceConfiguration *_Nullable configuration, NSError *_Nullable error) {

    if (!configuration) {
      [self logMessage:@"Error retrieving discovery document: %@", [error localizedDescription]];
      [self setAuthorization:nil];
      return;
    }

    [self logMessage:@"Got configuration: %@", configuration];

    // builds authentication request
    OIDAuthorizationRequest *request =
        [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                      clientId:kClientID
                                                  clientSecret:kClientSecret
                                                        scopes:@[OIDScopeOpenID, OIDScopeProfile]
                                                   redirectURL:redirectURI
                                                  responseType:OIDResponseTypeCode
                                          additionalParameters:nil];
    // performs authentication request
    self.appDelegate.currentAuthorizationFlow =
        [OIDAuthState authStateByPresentingAuthorizationRequest:request
                            callback:^(OIDAuthState *_Nullable authState,
                                       NSError *_Nullable error) {
      if (authState) {
        GTMAppAuthFetcherAuthorization *authorization =
            [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];
        [self setAuthorization:authorization];
        [self logMessage:@"Got authorization tokens. Access token: %@",
                         authState.lastTokenResponse.accessToken];
      } else {
        [self setAuthorization:nil];
        [self logMessage:@"Authorization error: %@", [error localizedDescription]];
      }
    }];
  }];
}

- (IBAction)clearAuthState:(nullable id)sender {
  [self setAuthorization:nil];
}

- (IBAction)clearLog:(nullable id)sender {
  [_logTextView.textStorage setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
}

- (IBAction)userinfo:(nullable id)sender {
  [self logMessage:@"Performing userinfo request"];

  // Creates a GTMSessionFetcherService with the authorization.
  // Normally you would save this service object and re-use it for all REST API calls.
  GTMSessionFetcherService *fetcherService = [[GTMSessionFetcherService alloc] init];
  fetcherService.authorizer = self.authorization;

  // Creates a fetcher for the API call.
  NSURL *userinfoEndpoint = [NSURL URLWithString:@"https://www.googleapis.com/oauth2/v3/userinfo"];
  GTMSessionFetcher *fetcher = [fetcherService fetcherWithURL:userinfoEndpoint];
  [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {

    // Checks for an error.
    if (error) {
      // OIDOAuthTokenErrorDomain indicates an issue with the authorization.
      if ([error.domain isEqual:OIDOAuthTokenErrorDomain]) {
        [self setAuthorization:nil];
        [self logMessage:@"Authorization error during token refresh, clearing state. %@", error];
      // Other errors are assumed transient.
      } else {
        [self logMessage:@"Transient error during token refresh. %@", error];
      }
      return;
    }

    // Parses the JSON response.
    NSError *jsonError = nil;
    id jsonDictionaryOrArray =
        [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];

    // JSON error.
    if (jsonError) {
      [self logMessage:@"JSON decoding error %@", jsonError];
      return;
    }

    // Success response!
    [self logMessage:@"Success: %@", jsonDictionaryOrArray];
  }];
}

/*! @brief Logs a message to stdout and the textfield.
    @param format The format string and arguments.
 */
- (void)logMessage:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2) {
  // gets message as string
  va_list argp;
  va_start(argp, format);
  NSString *log = [[NSString alloc] initWithFormat:format arguments:argp];
  va_end(argp);

  // outputs to stdout
  NSLog(@"%@", log);

  // appends to output log
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"hh:mm:ss";
  NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
  NSString *logLine = [NSString stringWithFormat:@"\n%@: %@", dateString, log];
  NSAttributedString* logLineAttr = [[NSAttributedString alloc] initWithString:logLine];
  [[_logTextView textStorage] appendAttributedString:logLineAttr];
}

@end

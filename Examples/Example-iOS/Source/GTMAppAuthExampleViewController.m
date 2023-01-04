/*! @file AppAuthExampleViewController.m
    @brief GTMAppAuth SDK iOS Example
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

#import <QuartzCore/QuartzCore.h>

@import AppAuth;
@import GTMAppAuth;
#ifdef COCOAPODS
@import GTMSessionFetcher;
#else // SPM
@import GTMSessionFetcherCore;
#endif

#import "AppDelegate.h"

/*! @brief The OIDC issuer from which the configuration will be discovered.
 */
static NSString *const kIssuer = @"https://accounts.google.com";

/*! @brief The OAuth client ID.
    @discussion For Google, register your client at
        https://console.developers.google.com/apis/credentials?project=_
        The client should be registered with the "iOS" type.
 */
static NSString *const kClientID = @"YOUR_CLIENT.apps.googleusercontent.com";

/*! @brief The OAuth redirect URI for the client @c kClientID.
    @discussion With Google, the scheme of the redirect URI is the reverse DNS notation of the
        client ID. This scheme must be registered as a scheme in the project's Info
        property list ("CFBundleURLTypes" plist key). Any path component will work, we use
        'oauthredirect' here to help disambiguate from any other use of this scheme.
 */
static NSString *const kRedirectURI =
    @"com.googleusercontent.apps.YOUR_CLIENT:/oauthredirect";

/*! @brief The key used to store our `GTMAuthSession` in the keychain.
 */
static NSString *const kKeychainStoreItemName = @"authorization";

@interface GTMAppAuthExampleViewController () <OIDAuthStateChangeDelegate,
                                               OIDAuthStateErrorDelegate>

@property (nonatomic, strong) GTMKeychainStore *keychainStore;

@end

@implementation GTMAppAuthExampleViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.keychainStore = [[GTMKeychainStore alloc] initWithItemName:kKeychainStoreItemName];
#if !defined(NS_BLOCK_ASSERTIONS)
  // NOTE:
  //
  // To run this sample, you need to register your own iOS client at
  // https://console.developers.google.com/apis/credentials?project=_ and update three configuration
  // points in the sample: kClientID and kRedirectURI constants in AppAuthExampleViewController.m
  // and the URI scheme in Info.plist (URL Types -> Item 0 -> URL Schemes -> Item 0).
  // Full instructions: https://github.com/openid/AppAuth-iOS/blob/master/Example/README.md

  NSAssert(![kClientID isEqualToString:@"YOUR_CLIENT.apps.googleusercontent.com"],
           @"Update kClientID with your own client ID. "
            "Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Example/README.md");

  NSAssert(![kRedirectURI isEqualToString:@"com.googleusercontent.apps.YOUR_CLIENT:/oauthredirect"],
           @"Update kRedirectURI with your own redirect URI. "
            "Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Example/README.md");

  // verifies that the custom URI scheme has been updated in the Info.plist
  NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
  NSAssert(urlTypes.count > 0, @"No custom URI scheme has been configured for the project.");
  NSArray *urlSchemes = ((NSDictionary *)urlTypes.firstObject)[@"CFBundleURLSchemes"];
  NSAssert(urlSchemes.count > 0, @"No custom URI scheme has been configured for the project.");
  NSString *urlScheme = urlSchemes.firstObject;

  NSAssert(![urlScheme isEqualToString:@"com.googleusercontent.apps.YOUR_CLIENT"],
           @"Configure the URI scheme in Info.plist (URL Types -> Item 0 -> URL Schemes -> Item 0) "
            "with the scheme of your redirect URI. Full instructions: "
            "https://github.com/openid/AppAuth-iOS/blob/master/Example/README.md");

#endif // !defined(NS_BLOCK_ASSERTIONS)

  _logTextView.layer.borderColor = [UIColor colorWithWhite:0.8 alpha:1.0].CGColor;
  _logTextView.layer.borderWidth = 1.0f;
  _logTextView.alwaysBounceVertical = YES;
  _logTextView.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
  _logTextView.text = @"";

  [self loadState];
  [self updateUI];
}

/*! @brief Saves the @c GTMAuthSession to the keychain.
 */
- (void)saveState {
  NSError *error;
  if (_authSession.canAuthorize) {
    [self.keychainStore saveAuthSession:_authSession error:&error];
  } else {
    [self.keychainStore removeAuthSessionAndReturnError:&error];
  }
  if (error) {
    NSLog(@"Error saving state: %@ error", error);
  }
}

/*! @brief Loads the @c GTMAuthSession from the keychain.
 */
- (void)loadState {
  NSError *error;
  GTMAuthSession *authSession =
      [self.keychainStore retrieveAuthSessionAndReturnError:&error];
  if (error) {
    NSLog(@"Error loading state: %@", error);
  }
  [self setAuthSession:authSession];
}

- (void)setAuthSession:(GTMAuthSession *)authSession {
  if ([_authSession isEqual:authSession]) {
    return;
  }
  _authSession = authSession;
  [self stateChanged];
}

/*! @brief Refreshes UI, typically called after the auth state changed.
 */
- (void)updateUI {
  _userinfoButton.enabled = _authSession.canAuthorize;
  _clearAuthStateButton.enabled = _authSession.canAuthorize;
  // dynamically changes authorize button text depending on authorized state
  if (!_authSession.canAuthorize) {
    [_authAutoButton setTitle:@"Authorize" forState:UIControlStateNormal];
    [_authAutoButton setTitle:@"Authorize" forState:UIControlStateHighlighted];
  } else {
    [_authAutoButton setTitle:@"Re-authorize" forState:UIControlStateNormal];
    [_authAutoButton setTitle:@"Re-authorize" forState:UIControlStateHighlighted];
  }
}

- (void)stateChanged {
  [self saveState];
  [self updateUI];
}

- (void)didChangeState:(OIDAuthState *)state {
  [self stateChanged];
}

- (void)authState:(OIDAuthState *)state didEncounterAuthorizationError:(NSError *)error {
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
      [self setAuthSession:nil];
      return;
    }

    [self logMessage:@"Got configuration: %@", configuration];

    // builds authentication request
    OIDAuthorizationRequest *request =
        [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                      clientId:kClientID
                                                        scopes:@[OIDScopeOpenID, OIDScopeProfile]
                                                   redirectURL:redirectURI
                                                  responseType:OIDResponseTypeCode
                                          additionalParameters:nil];
    // performs authentication request
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [self logMessage:@"Initiating authorization request with scope: %@", request.scope];

    appDelegate.currentAuthorizationFlow =
        [OIDAuthState authStateByPresentingAuthorizationRequest:request
            presentingViewController:self
                            callback:^(OIDAuthState *_Nullable authState,
                                       NSError *_Nullable error) {
      if (authState) {
        GTMAuthSession *authSession = [[GTMAuthSession alloc] initWithAuthState:authState];

        [self setAuthSession:authSession];
        [self logMessage:@"Got authorization tokens. Access token: %@",
                         authState.lastTokenResponse.accessToken];
      } else {
        [self setAuthSession:nil];
        [self logMessage:@"Authorization error: %@", [error localizedDescription]];
      }
    }];
  }];
}

- (IBAction)clearAuthState:(nullable id)sender {
  [self setAuthSession:nil];
}

- (IBAction)clearLog:(nullable id)sender {
  _logTextView.text = @"";
}

- (IBAction)userinfo:(nullable id)sender {
  [self logMessage:@"Performing userinfo request"];

  // Creates a GTMSessionFetcherService with the authorization.
  // Normally you would save this service object and re-use it for all REST API calls.
  GTMSessionFetcherService *fetcherService = [[GTMSessionFetcherService alloc] init];
  fetcherService.authorizer = self.authSession;

  // Creates a fetcher for the API call.
  NSURL *userinfoEndpoint = [NSURL URLWithString:@"https://www.googleapis.com/oauth2/v3/userinfo"];
  GTMSessionFetcher *fetcher = [fetcherService fetcherWithURL:userinfoEndpoint];
  [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
    // Checks for an error.
    if (error) {
      // OIDOAuthTokenErrorDomain indicates an issue with the authorization.
      if ([error.domain isEqual:OIDOAuthTokenErrorDomain]) {
        [self setAuthSession:nil];
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
  _logTextView.text = [NSString stringWithFormat:@"%@%@%@: %@",
                                                 _logTextView.text,
                                                 ([_logTextView.text length] > 0) ? @"\n" : @"",
                                                 dateString,
                                                 log];
}

@end

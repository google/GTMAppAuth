/*! @file GTMAppAuthTVExampleViewController.m
    @brief GTMAppAuth tvOS SDK Example
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

#import "GTMAppAuthTVExampleViewController.h"

#import <AppAuth/AppAuth.h>
#import <GTMAppAuth/GTMAppAuth.h>

#import "GTMSessionFetcher.h"
#import "GTMSessionFetcherService.h"

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

/*! @brief NSCoding key for the authorization property.
 */
static NSString *const kExampleAuthorizerKey = @"authorization";

@interface GTMAppAuthTVExampleViewController ()

@end

@implementation GTMAppAuthTVExampleViewController {
  GTMTVAuthorizationCancelBlock _cancelBlock;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.

#if !defined(NS_BLOCK_ASSERTIONS)
  // NOTE:
  //
  // To run this sample, you need to register your own Google API client at
  // https://console.developers.google.com/apis/credentials?project=_ using the type "Other"
  // and update two configuration points in the sample: the kClientID and kRedirectURI constants
  // this file.
  NSAssert(![kClientID isEqualToString:@"YOUR_CLIENT.apps.googleusercontent.com"],
           @"Update kClientID with your own client ID. ");
  NSAssert(![kClientSecret isEqualToString:@"YOUR_CLIENT_SECRET"],
           @"Update kClientSecret with your own client secret. ");
#endif // !defined(NS_BLOCK_ASSERTIONS)

  logTextView.text = @"";
  signInView.hidden = YES;
  cancelSignInButton.hidden = YES;
  logTextView.selectable = YES;
  logTextView.panGestureRecognizer.allowedTouchTypes = @[ @(UITouchTypeIndirect) ];

  [self loadState];
  [self updateUI];
}

- (IBAction)signin:(id)sender {
  if (_cancelBlock) {
    [self cancelSignIn:nil];
  }

  // builds authentication request
  GTMTVServiceConfiguration *configuration = [GTMTVAuthorizationService TVConfigurationForGoogle];
  GTMTVAuthorizationRequest *request =
      [[GTMTVAuthorizationRequest alloc] initWithConfiguration:configuration
                                                      clientId:kClientID
                                                  clientSecret:kClientSecret
                                                        scopes:@[ OIDScopeOpenID, OIDScopeProfile ]
                                          additionalParameters:nil];

  _cancelBlock = [GTMTVAuthorizationService authorizeTVRequest:request
      initializaiton:^(GTMTVAuthorizationResponse *_Nullable response,
                       NSError *_Nullable error) {
    if (response) {
      [self logMessage:@"Authorization response: %@", response];
      signInView.hidden = NO;
      cancelSignInButton.hidden = NO;
      verificationURLLabel.text = response.verificationURL;
      userCodeLabel.text = response.userCode;
    } else {
      [self logMessage:@"Initialization error %@", error];
    }
  } completion:^(GTMAppAuthFetcherAuthorization *_Nullable authorization,
                 NSError *_Nullable error) {
    signInView.hidden = YES;
    if (authorization) {
      [self setAuthorization:authorization];
      [self logMessage:@"Token response: %@", authorization.authState.lastTokenResponse];
    } else {
      [self setAuthorization:nil];
      [self logMessage:@"Error: %@", error];
    }
  }];
}

- (IBAction)cancelSignIn:(nullable id)sender {
  if (_cancelBlock) {
    _cancelBlock();
    _cancelBlock = nil;
  }
  signInView.hidden = YES;
  cancelSignInButton.hidden = YES;
}

- (void)setAuthorization:(GTMAppAuthFetcherAuthorization*)authorization {
  _authorization = authorization;
  [self saveState];
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
  if (authorization) {
    [self logMessage:@"Authorization restored: %@", authorization];
  }
}

/*! @brief Refreshes UI, typically called after the auth state changed.
 */
- (void)updateUI {
  signInButtons.hidden = [_authorization canAuthorize];
  signedInButtons.hidden = !signInButtons.hidden;
}

- (IBAction)clearAuthState:(nullable id)sender {
  [self setAuthorization:nil];
  [self logMessage:@"Authorization state cleared."];
}

- (IBAction)clearLog:(nullable id)sender {
  [logTextView.textStorage setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
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
  UIFont *systemFont = [UIFont systemFontOfSize:36.0f];
  NSDictionary * fontAttributes =
      [[NSDictionary alloc] initWithObjectsAndKeys:systemFont, NSFontAttributeName, nil];
  NSMutableAttributedString* logLineAttr =
      [[NSMutableAttributedString alloc] initWithString:logLine attributes:fontAttributes];
  [[logTextView textStorage] appendAttributedString:logLineAttr];

  // Scroll to bottom
  if(logTextView.text.length > 0 ) {
    NSRange bottom = NSMakeRange(logTextView.text.length - 1, 1);
    [logTextView scrollRangeToVisible:bottom];
  }
}

@end

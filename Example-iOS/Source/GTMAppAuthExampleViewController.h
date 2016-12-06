/*! @file AppAuthExampleViewController.h
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
#import <UIKit/UIKit.h>

@class OIDAuthState;
@class GTMAppAuthFetcherAuthorization;
@class OIDServiceConfiguration;

NS_ASSUME_NONNULL_BEGIN

/*! @brief The example application's view controller.
 */
@interface GTMAppAuthExampleViewController : UIViewController

@property(nullable) IBOutlet UIButton *authAutoButton;
@property(nullable) IBOutlet UIButton *userinfoButton;
@property(nullable) IBOutlet UIButton *clearAuthStateButton;
@property(nullable) IBOutlet UITextView *logTextView;

/*! @brief The authorization state.
 */
@property(nonatomic, nullable) GTMAppAuthFetcherAuthorization *authorization;

/*! @brief Authorization code flow using @c OIDAuthState automatic code exchanges.
    @param sender IBAction sender.
 */
- (IBAction)authWithAutoCodeExchange:(nullable id)sender;

/*! @brief Performs a Userinfo API call using @c GTMAppAuthFetcherAuthorization.
    @param sender IBAction sender.
 */
- (IBAction)userinfo:(nullable id)sender;

/*! @brief Nils the @c OIDAuthState object.
    @param sender IBAction sender.
 */
- (IBAction)clearAuthState:(nullable id)sender;

/*! @brief Clears the UI log.
    @param sender IBAction sender.
 */
- (IBAction)clearLog:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END

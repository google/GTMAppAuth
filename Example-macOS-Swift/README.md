# Example Project

## CocoaPods Dependencies

1. In the current folder, run the following command to install the required
library pods.

```
$ pod install
```

2. Open the workspace:

```
$ open GTMAppAuth-Swift.xcworkspace
```

### Creating a Google OAuth Client

To configure the sample with a Google OAuth client, visit
https://console.developers.google.com/apis/credentials?project=_ and create a
new project. Then tap "Create credentials" and select "OAuth client ID".
Follow the instructions to configure the consent screen (just the Product Name
is needed).

Then, complete the OAuth client creation by selecting "Other" as the Application
type.

Copy the client ID to the clipboard.

### Configure the Example

The example doesn't work out of the box, you need to configure your settings. We have marked out in GTMAppAuthViewController where you need to update the settings in the project to work.  For Clarity, we have also included the details in here:
1. Obtain your Client Id and URL scheme details from here: https://console.developers.google.com. Note you don't need the Client Secret to access the API in IOS / MacOS. 
Update the variables `kClientID` with your client ID from above. Update the  `kRedirectURI` with the *reverse DNS notation* form
of the client ID. For example, if the client ID is
`YOUR_CLIENT.apps.googleusercontent.com`, the reverse DNS notation would be
`com.googleusercontent.apps.YOUR_CLIENT`. A path component is added resulting in
`com.googleusercontent.apps.YOUR_CLIENT:/oauthredirect`.
2. Make sure you have enabled Sandbox Entitlements and have allowed Outgoing connection otherwise this will not work.(Under Project-> Capabilities. This has been done in this project)
3. Finally, open `Info.plist` and fully expand "URL types" (a.k.a.
"CFBundleURLTypes") and replace `com.googleusercontent.apps.YOUR_CLIENT` with
the reverse DNS notation form of your client ID (not including the
`:/oauthredirect` path component).
4. If you want to access a specific service then update the scopes listed in the `scopesToAccess` variable. We have added in Scope to get ID and Profile data for the purpose of this demo. For additional Google scopes, you can get these from the Google scopes URL: https://developers.google.com/identity/protocols/googlescopes
5. As a temporary work around you may need to update your Pods Project Deployment target to 10.11 as some of the methods used are not supported by older MacOS versions. 


Once you have made those three changes, the sample should be ready to try with your new OAuth client.

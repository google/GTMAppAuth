# iOS Example

## Getting Started

Choose which package manager you'd like to use. Note that Cocoapods is in maintenance mode, and the sample project will be removed soon. Use of SPM is strongly suggested.

### Swift Package Manager

In the Example-iOS folder, run the following command to open the Swift Pacakage Manager
project:

```
open Example-iOS.xcodeproj
```

### CocoaPods

1. In the Example-iOS folder, run the following command to install the required
library pods:

```
$ pod install
```

2. Open the generated workspace for the CocoaPods project:

```
$ open Example-iOSForPod.xcworkspace
```

## Configuration

The example doesn't work out of the box, you need to configure it with your own
client ID.

### Creating a Google OAuth Client

To configure the sample with a Google OAuth client, visit
https://console.developers.google.com/apis/credentials?project=_ and create a
new project. Then tap "Create credentials" and select "OAuth client ID".
Follow the instructions to configure the consent screen (just the Product Name
is needed).

Then, complete the OAuth client creation by selecting "iOS" as the Application
type.  Enter the Bundle ID of the project (`com.example.GTMAppAuth.Example-iOS`
by default, but you may want to change this — via `PRODUCT_BUNDLE_IDENTIFIER`
in `Config/Example.local.xcconfig` for the Swift Package Manager project, or in
the target's build settings for the CocoaPods project — and use your own
Bundle ID).

Copy the client ID to the clipboard.

### Configure the Example

The OAuth client configuration is injected at build time via the `OIDC_*`
build settings, which flow into `Info.plist` and are read by
`GTMAppAuthExampleViewController.m` at runtime.

The values you'll set are:

- `OIDC_CLIENT_ID` — your client ID, e.g. `YOUR_CLIENT.apps.googleusercontent.com`.
- `OIDC_REDIRECT_URI` — the *reverse DNS notation* form of the client ID with a
  path component appended. For example, if the client ID is
  `YOUR_CLIENT.apps.googleusercontent.com`, the reverse DNS notation would be
  `com.googleusercontent.apps.YOUR_CLIENT`, resulting in
  `com.googleusercontent.apps.YOUR_CLIENT:/oauthredirect`.
- `OIDC_REDIRECT_URI_SCHEME` — the scheme of the redirect URI (the reverse DNS
  notation form of your client ID, without the `:/oauthredirect` path
  component). This is registered as the app's custom URL scheme
  ("CFBundleURLTypes") automatically.

#### Swift Package Manager project

Create the gitignored file `Config/Example.local.xcconfig` next to the tracked
`Config/Example.xcconfig`, overriding the placeholder defaults:

```
OIDC_CLIENT_ID = YOUR_CLIENT.apps.googleusercontent.com
OIDC_REDIRECT_URI = com.googleusercontent.apps.YOUR_CLIENT:/oauthredirect
OIDC_REDIRECT_URI_SCHEME = com.googleusercontent.apps.YOUR_CLIENT
```

You can also set code-signing overrides there (`CODE_SIGN_STYLE`,
`DEVELOPMENT_TEAM`, `PROVISIONING_PROFILE_SPECIFIER`,
`PRODUCT_BUNDLE_IDENTIFIER`) to build for a physical device — see the comments
in `Config/Example.xcconfig`.

#### CocoaPods project

The `Example-iOSForPod` project's base configuration is owned by CocoaPods, so
it does not use `Config/Example.xcconfig`. Instead, edit the `OIDC_*`
User-Defined build settings directly on the `Example-iOSForPod` target
(Build Settings → User-Defined), replacing the `YOUR_CLIENT` placeholder
values.

Once configured, the sample should be ready to try with your new OAuth client.

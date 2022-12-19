# 3.0.0

- GTMAppAuth has been translated to Swift. ([#190](https://github.com/google/GTMAppAuth/pull/190))
- Improved API surface. ([#203](https://github.com/google/GTMAppAuth/pull/203))
  - `GTMAppAuthFetcherAuthorization` renamed `GTMAuthState`.
  - `GTMAuthStateStore` protocol introduced.
  - `GTMKeychainStore` class conforming to `GTMAuthStateStore` provides keychain storage of `GTMAuthState` objects as well as GTMOAuth2 compatibility.
    - Added the ability to specify a keychain access group.
  - Error handling.
- Unit tests added. ([#190](https://github.com/google/GTMAppAuth/pull/190), [#202](https://github.com/google/GTMAppAuth/pull/202))

# 2.0.0

* Updated the GTMSessionFetcher dependency to allow 3.x versions. ([#192](https://github.com/google/GTMAppAuth/pull/192))
* Minimum deployment versions for iOS and tvOS increased to 10. ([#188](https://github.com/google/GTMAppAuth/pull/188), [#191](https://github.com/google/GTMAppAuth/pull/191))

# 1.3.1

* Updated the GTMSessionFetcher dependency to allow 2.x versions. ([#155](https://github.com/google/GTMAppAuth/pull/155), [#175](https://github.com/google/GTMAppAuth/pull/175))
* Use secure coding with `NSKeyedArchiver` when available. ([#145](https://github.com/google/GTMAppAuth/pull/145))

# 1.3.0

* Added the option to use the data protection keychain on macOS. ([#151](https://github.com/google/GTMAppAuth/pull/151))
* Unified the keychain access layer, moving macOS to the modern SecItem API. ([#150](https://github.com/google/GTMAppAuth/pull/150))
* Added Swift Package Manager projects for the example apps. ([#153](https://github.com/google/GTMAppAuth/pull/153))

# 1.2.3

* Fixed Keychain duplicate entry error on macOS. ([#138](https://github.com/google/GTMAppAuth/pull/138))
* Match GTMSessionFetcher's min macOS version to avoid warnings. ([#142](https://github.com/google/GTMAppAuth/pull/142))

# 1.2.2

* Fixed Swift Package Manager issue with Xcode 12.5.

# 1.2.1

* Address CocoaPod packaging issue in the 1.2.0 release.

# 1.2.0

* Addressed several Swift Package Manager issues.
* Restructured the project for cleaner Swift Package Manager support.

# 1.1.0

* Added Swift Package Manager support.
* Added watchOS support.

# 1.0.0

* Moved tvOS authorization support out to a branch.

# 0.8.0

* Added `tokenRefreshDelegate` to `GTMAppAuthFetcherAuthorization`.
* Updated to depend on AppAuth/Core 1.0.
* Added CHANGELOG.md.

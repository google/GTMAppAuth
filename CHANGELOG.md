# GTMAppAuth Changelog

## 1.3.0 (2022-05-05)

* Added the option to use the data protection keychain on macOS. ([#151](https://github.com/google/GTMAppAuth/pull/151))
* Unified the keychain access layer, moving macOS to the modern SecItem API. ([#150](https://github.com/google/GTMAppAuth/pull/150))

## 1.2.3 (2022-03-22)

* Fixed Keychain duplicate entry error on macOS. ([#138](https://github.com/google/GTMAppAuth/pull/138))
* Match GTMSessionFetcher's min macOS version to avoid warnings. ([#142](https://github.com/google/GTMAppAuth/pull/142))

## 1.2.2 (2021-05-04)

* Fixed Swift Package Manager issue with Xcode 12.5.

## 1.2.1 (2021-04-02)

* Address CocoaPod packaging issue in the 1.2.0 release.

## 1.2.0 (2021-03-31)

* Addressed several Swift Package Manager issues.
* Restructured the project for cleaner Swift Package Manager support.

## 1.1.0 (2020-09-29)

* Added Swift Package Manager support.
* Added watchOS support.

## 1.0.0 (2019-08-13)

* Moved tvOS authorization support out to a branch.

## 0.8.0 (2019-08-01)

* Added `tokenRefreshDelegate` to `GTMAppAuthFetcherAuthorization`.
* Updated to depend on AppAuth/Core 1.0.
* Added CHANGELOG.md.

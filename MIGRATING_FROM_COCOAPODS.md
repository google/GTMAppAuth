# Migrating from CocoaPods to Swift Package Manager

CocoaPods trunk becomes read-only on December 2, 2026. GTMAppAuth 6.0.0 is the
last version published to CocoaPods. Existing pod versions remain installable,
but future GTMAppAuth releases are distributed via Swift Package Manager only.

## Steps

1. In the project directory, remove the `pod 'GTMAppAuth'` line from the
   `Podfile`. If it was the only pod, run `pod deintegrate`, delete the
   `Podfile`, `Podfile.lock`, and the generated `.xcworkspace`, and open the
   `.xcodeproj` from then on.
2. In Xcode: **File > Add Package Dependencies…**, enter
   `https://github.com/google/GTMAppAuth`, and choose "Up to Next Major Version"
   from 6.0.0.
3. Add the `GTMAppAuth` product to each target that used the pod.
4. `import GTMAppAuth` does not change. Update any direct imports of its
   dependencies (next section), then clean the build folder and build.

## Imports of AppAuth and GTMSessionFetcher

Under Swift Package Manager, GTMAppAuth depends on the `AppAuthCore` and
`GTMSessionFetcherCore` products, which are separate modules. Under CocoaPods
they were the `AppAuth` and `GTMSessionFetcher` modules.

If your code imports them directly, change `import AppAuth` to
`import AppAuthCore` when you only use core types, and
`import GTMSessionFetcher` to `import GTMSessionFetcherCore`. If you use
AppAuth's external user agent (for example presenting an authorization request
in a browser), add the AppAuth-iOS package
(`https://github.com/openid/AppAuth-iOS`) and its `AppAuth` product to your
target as well; see [AppAuth-iOS](https://github.com/openid/AppAuth-iOS) for its
own migration notes.

## Don't mix package managers

GTMAppAuth depends on AppAuth and GTMSessionFetcher, and GoogleSignIn depends on
GTMAppAuth. If any of GoogleSignIn, GTMAppAuth, AppAuth, or GTMSessionFetcher
(or Firebase, or another pod that shares them) is in your `Podfile`, migrate
them to Swift Package Manager together. Mixing CocoaPods and Swift Package
Manager copies of the same library in one target leads to duplicate symbols,
dependency cycles, and build errors.

## If you can't migrate yet

You can stay on GTMAppAuth 6.0.0 via CocoaPods.

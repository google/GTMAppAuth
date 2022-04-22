Pod::Spec.new do |s|

  s.name         = "GTMAppAuth"
  s.version      = "1.2.3"
  s.summary      = "Authorize GTM Session Fetcher requests with AppAuth via GTMAppAuth"

  s.description  = <<-DESC

GTMAppAuth enables you to use AppAuth with the Google Toolbox for Mac - Session
Fetcher and Google APIs Client Library for Objective-C For REST libraries by
providing an implementation of GTMFetcherAuthorizationProtocol for authorizing
requests with AppAuth.

                   DESC

  s.homepage     = "https://github.com/google/GTMAppAuth"
  s.license      = { :type => 'Apache', :file => 'LICENSE' }
  s.author       = "Google LLC"

  s.source       = { :git => "https://github.com/google/GTMAppAuth.git", :tag => s.version }
  ios_deployment_target = '9.0'
  osx_deployment_target = '10.12'
  tvos_deployment_target = '9.0'
  watchos_deployment_target = '6.0'
  s.prefix_header_file = false
  s.source_files = "GTMAppAuth/Sources/*.{h,m}",
                   "GTMAppAuth/Sources/Public/GTMAppAuth/*.h"
  s.public_header_files = "GTMAppAuth/Sources/Public/GTMAppAuth/*.h"
  s.requires_arc = true

  s.ios.source_files = "GTMAppAuth/Sources/GTMOAuth2KeychainCompatibility/*.{h,m}",
                       "GTMAppAuth/Sources/iOS/GTMKeychain_iOS.m"
  s.ios.deployment_target = ios_deployment_target

  s.osx.source_files = "GTMAppAuth/Sources/GTMOAuth2KeychainCompatibility/*.{h,m}",
                       "GTMAppAuth/Sources/macOS/GTMKeychain_macOS.m"
  s.osx.deployment_target = osx_deployment_target

  s.tvos.source_files = "GTMAppAuth/Sources/iOS/GTMKeychain_iOS.m"
  s.tvos.deployment_target = tvos_deployment_target

  s.watchos.source_files = "GTMAppAuth/Sources/iOS/GTMKeychain_iOS.m"
  s.watchos.deployment_target = watchos_deployment_target

  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}"',
    'SWIFT_OBJC_BRIDGING_HEADER' => '${SRCROOT}/GTMAppAuth/GTMAppAuth/UnitTests/GTMAppAuthTests-Bridging-Header.h'
  }

  s.framework = 'Security'
  s.dependency 'GTMSessionFetcher/Core', '~> 1.5'
  s.dependency 'AppAuth/Core', '~> 1.4'
  
  s.test_spec 'Tests' do |test_spec|
    test_spec.platforms = {
      :ios => ios_deployment_target,
      :osx => osx_deployment_target
    }
    test_spec.source_files = "GTMAppAuth/UnitTests/*"
  end
end

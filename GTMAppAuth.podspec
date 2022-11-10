Pod::Spec.new do |s|

  s.name         = "GTMAppAuth"
  s.version      = "1.3.1"
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
  s.prefix_header_file = false
  s.source_files = "GTMAppAuth/Sources/**/*.{h,m}",
  s.public_header_files = "GTMAppAuth/Sources/Public/GTMAppAuth/*.h"
  s.requires_arc = true

  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = '10.12'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '6.0'

  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}"'
  }

  s.framework = 'Security'
  s.dependency 'GTMSessionFetcher/Core', '>= 1.5', '< 3.0'
  s.dependency 'AppAuth/Core', '~> 1.6'
end

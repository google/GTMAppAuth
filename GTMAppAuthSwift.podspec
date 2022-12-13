Pod::Spec.new do |s|

  s.name          = "GTMAppAuthSwift"
  s.version       = "1.3.0"
  s.swift_version = "4.0"
  s.summary       = "Authorize GTM Session Fetcher requests with AppAuth via GTMAppAuth"

  s.description   = <<-DESC

GTMAppAuth enables you to use AppAuth with the Google Toolbox for Mac - Session
Fetcher and Google APIs Client Library for Objective-C For REST libraries by
providing an implementation of GTMFetcherAuthorizationProtocol for authorizing
requests with AppAuth.

                    DESC

  s.homepage      = "https://github.com/google/GTMAppAuth"
  s.license       = { :type => "Apache", :file => "LICENSE" }
  s.author        = "Google LLC"

  s.source        = { :git => "https://github.com/google/GTMAppAuth.git", :tag => s.version }
  s.prefix_header_file = false
  s.source_files = "GTMAppAuthSwift/Sources/*.swift"

  ios_deployment_target = "10.0"
  osx_deployment_target = "10.12"
  s.ios.deployment_target = ios_deployment_target
  s.osx.deployment_target = osx_deployment_target
  s.tvos.deployment_target = "10.0"
  s.watchos.deployment_target = "6.0"

  s.framework = "Security"
  s.dependency 'GTMSessionFetcher/Core', '>= 1.5', '< 4.0'
  s.dependency "AppAuth/Core", "~> 1.6"

  s.test_spec 'unit' do |unit_tests|
    unit_tests.platform = {
      :ios => ios_deployment_target,
      :macos => osx_deployment_target,
    }
    unit_tests.source_files = [
      "GTMAppAuthSwift/Tests/*.swift",
      "SwiftToObjCAPITests/*.[mh]",
    ]
    unit_tests.requires_app_host = false
  end
end


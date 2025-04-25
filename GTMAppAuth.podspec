Pod::Spec.new do |s|

  s.name          = 'GTMAppAuth'
  s.version       = '4.1.1'
  s.swift_version = '4.0'
  s.summary       = 'Authorize GTM Session Fetcher requests with AppAuth via GTMAppAuth'

  s.description   = <<-DESC

GTMAppAuth enables you to use AppAuth with the Google Toolbox for Mac - Session
Fetcher and Google APIs Client Library for Objective-C For REST libraries by
providing an implementation of GTMFetcherAuthorizationProtocol for authorizing
requests with AppAuth.

                    DESC

  s.homepage      = 'https://github.com/google/GTMAppAuth'
  s.license       = { :type => 'Apache', :file => 'LICENSE' }
  s.author        = 'Google LLC'

  s.source        = { :git => 'https://github.com/google/GTMAppAuth.git', :tag => s.version }
  s.prefix_header_file = false
  s.source_files = 'GTMAppAuth/Sources/**/*.swift'
  s.resource_bundles = {
    "GTMAppAuth_Privacy" => "GTMAppAuth/Sources/Resources/PrivacyInfo.xcprivacy"
  }

  ios_deployment_target = '12.0'
  osx_deployment_target = '10.12'
  tvos_deployment_target = '10.0'
  watchos_deployment_target = '6.0'
  s.ios.deployment_target = ios_deployment_target
  s.osx.deployment_target = osx_deployment_target
  s.tvos.deployment_target = tvos_deployment_target
  s.watchos.deployment_target = watchos_deployment_target

  s.framework = 'Security'
  s.dependency 'GTMSessionFetcher/Core', '>= 3.3', '< 4.0'
  s.dependency 'AppAuth/Core', '~> 2.0'

  s.test_spec 'unit' do |unit_tests|
    unit_tests.platforms = {
      :ios => ios_deployment_target,
      :osx => osx_deployment_target,
      :tvos => tvos_deployment_target,
    }
    unit_tests.source_files = [
      'GTMAppAuth/Tests/Unit/**/*.swift',
      'GTMAppAuth/Tests/Helpers/**/*.swift',
    ]
    unit_tests.dependency 'AppAuth/Core'
    unit_tests.requires_app_host = true
  end

  s.test_spec 'objc-api-integration' do |api_tests|
    api_tests.platforms = {
      :ios => ios_deployment_target,
      :osx => osx_deployment_target,
      :tvos => tvos_deployment_target,
    }
    api_tests.source_files = [
      'GTMAppAuth/Tests/ObjCIntegration/**/*.m',
      'GTMAppAuth/Tests/Helpers/**/*.swift',
    ]
    api_tests.dependency 'AppAuth/Core'
    api_tests.requires_app_host = true
  end

end

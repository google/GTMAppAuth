Pod::Spec.new do |s|

  s.name         = "GTMAppAuth"
  s.version      = "0.1.0"
  s.summary      = "Authorize GTM Session Fetcher requests with AppAuth via GTMAppAuth"

  s.description  = <<-DESC

GTMAppAuth enables you to use AppAuth with the Google Toolbox for Mac - Session
Fetcher and Google APIs Client Library for Objective-C For REST libraries by
providing an implementation of GTMFetcherAuthorizationProtocol for authorizing
requests with AppAuth.

                   DESC

  s.homepage     = "https://github.com/google/GTMAppAuth"
  s.license      = "Apache License, Version 2.0"
  s.authors      = { "William Denniss" => "wdenniss@google.com",
                   }

  s.source       = { :git => "https://github.com/google/GTMAppAuth.git", :tag => s.version }

  s.source_files = "Source/*.{h,m}"
  s.requires_arc = true

  s.ios.source_files = "Source/GTMOAuth2KeychainCompatibility/*.{h,m}",
                       "Source/iOS/**/*.{h,m}"
  s.ios.deployment_target = "7.0"
  s.ios.framework    = "SafariServices"

  s.osx.source_files = "Source/GTMOAuth2KeychainCompatibility/*.{h,m}",
                       "Source/macOS/**/*.{h,m}"
  s.osx.deployment_target = '10.8'

  s.frameworks = 'Security', 'SystemConfiguration'
  s.dependency 'GTMSessionFetcher', '~> 1.1'
  s.dependency 'AppAuth', '~> 0.7.0'
end


Pod::Spec.new do |s|

  s.name         = "WWZSocket"
  s.version      = "0.0.1"
  s.summary      = "A short description of WWZSocket."

  # s.description  = <<-DESC
  #                  DESC

  s.homepage     = "http://github.com/ccwuzhou/WWZSocket"

  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  s.author             = { "wwz" => "wwz@zgkjd.com" }

  s.platform     = :ios

  s.ios.deployment_target = "8.0"

  s.source       = { :git => "http://github.com/ccwuzhou/WWZSocket.git", :tag => "#{s.version}" }

  s.source_files  = "WWZSocket/*.{h,m}"

  s.public_header_files = "WWZSocket/WWZSocket.h"

  s.requires_arc = true

  s.dependency "CocoaAsyncSocket"
  s.framework  = "Foundation"
  # s.frameworks = "SomeFramework", "AnotherFramework"

end


Pod::Spec.new do |s|

  s.name         = "WWZSocket"
  s.version      = "1.1.0"
  s.summary      = "A short description of WWZSocket."

  # s.description  = <<-DESC
  #                  DESC

  s.homepage     = "https://github.com/ccwuzhou/WWZSocket"

  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }

  s.author             = { "wwz" => "wwz@zgkjd.com" }

  s.platform     = :ios

  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/ccwuzhou/WWZSocket.git", :tag => "#{s.version}" }

  s.source_files  = "WWZSocket/WWZSocket/*.{h,m}"

  # s.public_header_files = "WWZSocket/WWZSocket.h"

  s.requires_arc = true

  s.framework  = "Foundation"

  s.dependency "CocoaAsyncSocket"
  
  # s.frameworks = "SomeFramework", "AnotherFramework"

end

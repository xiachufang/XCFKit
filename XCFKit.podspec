Pod::Spec.new do |s|
  s.name         = "XCFKit"
  s.version      = "1.0.0"
  s.summary      = "Standard toolset classes & categories used by xiachufang iOS Projects"
  s.homepage     = "https://github.com/xiachufang/XCFKit"
  s.author       = { "yiplee" => "guoyinl@gmail.com" }
  s.requires_arc = true
  s.license      = "MIT"

  s.source       = { :git => "https://github.com/xiachufang/XCFKit.git", :tag => s.version.to_s }
  s.platform     = :ios, "8.0"

  s.source_files = 'XCFKit/**/*.{h,m,mm}'
  s.frameworks       = [ 'Foundation', 'UIKit' ]

end

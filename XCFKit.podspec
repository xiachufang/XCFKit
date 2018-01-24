Pod::Spec.new do |s|
  s.name         = "XCFKit"
  s.version      = "1.0.0"
  s.summary      = "Standard toolset classes & categories used by xiachufang iOS Projects"
  s.homepage     = "https://github.com/xiachufang/XCFKit"
  s.author       = { "yiplee" => "guoyinl@gmail.com" }
  s.requires_arc = true
  s.license      = "MIT"

  s.source       = { :git => "git@github.com:xiachufang/XCFKit.git", :tag => s.version.to_s }
  s.platform     = :ios, "8.0"
  s.frameworks       = [ 'Foundation', 'UIKit' ]
  
  s.source_files = "XCFKit" , "XCFKit/UI"
end

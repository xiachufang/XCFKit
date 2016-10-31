Pod::Spec.new do |s|
  s.name         = "XCFKit"
  s.version      = "0.1.0-beta"

  s.summary      = "A iOS framework for XIACHUFANG iOS Project ."
  s.homepage     = "https://github.com/xiachufang/XCFKit"
  s.description  = 'XCFKit 包含下厨房 iOS 项目所需要的自定义的 UI 组件， \
                    网络和数据模型等等'

  s.requires_arc = true

  s.license      = "MIT"
  s.author       = { "yiplee" => "guoyinl@gmail.com" }

  s.platform     = :ios, "8.0"

  s.source       = { :git => "git@github.com:xiachufang/XCFKit.git", :tag => "#{s.version}" }

  s.source_files = "XCFKit" , "XCFKit/UI"
  s.resource_bundle = { 'buttonBackgroundImages' => 'XCFKit/**/*.xcassets' }

  s.frameworks       = [ 'Foundation', 'UIKit' ]

end

Pod::Spec.new do |s|
    s.name         = "XCFKit"
    s.version      = "1.1.1"
    s.summary      = "Standard toolset classes & categories used by xiachufang iOS Projects"
    s.homepage     = "https://github.com/xiachufang/XCFKit"
    s.author       = { "yiplee" => "guoyinl@gmail.com" }
    s.requires_arc = true
    s.license      = "MIT"

    s.source       = { :git => "https://github.com/xiachufang/XCFKit.git", :tag => s.version.to_s }
    s.platform     = :ios, "8.0"

    s.source_files = 'XCFKit/XCFKit.h', 'XCFKit/XCFKitCompat.{h,m}'
    s.library      = 'c++'
    s.framework    = 'UIKit'
    s.resource_bundles = {"Video" => 'XCFKit/Resource/*.png'}

    s.subspec 'Foundation' do |f|
        f.ios.deployment_target = '7.0'
        f.source_files = 'XCFKit/Foudation/*.{h,m,mm}'
        f.framework = 'Foundation'
    end

    s.subspec 'UIKit' do |u|
        u.ios.deployment_target = '8.0'
        u.source_files = 'XCFKit/UIKit/*.{h,m}'
        u.framework = 'UIKit'
    end

    s.subspec 'VideoPlayer' do |v|
        v.ios.deployment_target = '8.0'
        v.source_files = 'XCFKit/VideoPlayer/*.{h,m}'
        v.frameworks = ['UIKit', 'AVFoundation']
        v.dependency 'XCFKit/UIKit'
    end

end

#
# Be sure to run `pod lib lint rmpaint.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "rmpaint"
  s.version          = "0.9.3"
  s.summary          = "Painting for iOS"
  s.description      = <<-DESC
Painting for iOS based on the GLPaint example by Apple.
                       DESC
  s.homepage         = "https://github.com/robotmedia/rmpaint-ios"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'Apache 2.0'
  s.author           = { "RobotMedia" => "hello@robotmedia.net" }
  s.source           = { :git => "https://github.com/kompozer/rmpaint-ios.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'RMPaint/RMPaint/**/*.{h,m}'
  s.resource_bundles = {
    'rmpaint' => ['Pod/Assets/*.png']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end

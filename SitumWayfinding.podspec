#
# Be sure to run `pod lib lint SitumWayfinding.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SitumWayfinding'
  s.version          = '0.1.19'
  s.summary          = 'Indoor Location for iOS.'
  s.static_framework = true

  s.description      = <<-DESC
    With Situm IPS platform you can develop your wayfinding solution from zero, and with the module Situm WYF you can easily integrate guiding functionality in an existing APP to improve your visitors experience, whether in hospitals, malls, airports, corporate headquarters or convention centers.
                       DESC

  s.homepage         = 'http://developers.situm.es/pages/mobile/ios/'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Name' => 'support@situm.es' }
  s.source           = { :git => 'https://github.com/situmtech/ios-swift-library-wayfinding.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.platform = :ios, '10.0'
  s.swift_version = '5.0'

  s.source_files = 'SitumWayfinding/Classes/**/*'
  s.resources = ['SitumWayfinding/Assets/*.storyboard', 'SitumWayfinding/Assets/Images/**/*.png']
  s.dependency 'GoogleMaps', '~> 4.2.0'
  s.dependency 'SitumSDK', '~> 2.51.5'

end

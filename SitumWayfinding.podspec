#
# Be sure to run `pod lib lint SitumWayfinding.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SitumWayfinding'
  s.version          = '0.19.10'
  s.summary          = 'Indoor Location for iOS.'
  s.static_framework = true

  # arm64 is exclude in Google-Maps-iOS-Utils
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  s.description      = <<-DESC
    With Situm IPS platform you can develop your wayfinding solution from zero, and with the module Situm WYF you can easily integrate guiding functionality in an existing APP to improve your visitors experience, whether in hospitals, malls, airports, corporate headquarters or convention centers.
                       DESC

  s.homepage         = 'http://developers.situm.es/pages/mobile/ios/'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Name' => 'support@situm.es' }
  s.source           = { :git => 'https://github.com/situmtech/ios-swift-library-wayfinding.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.platform = :ios, '12.0'
  s.swift_version = '5.0'

  s.source_files = 'SitumWayfinding/Classes/**/*'
  s.resources = [
    'SitumWayfinding/Assets/*.storyboard',
    'SitumWayfinding/Assets/Images/**/*.png',
    'SitumWayfinding/Assets/Fonts/**/*.ttf',
  ]
  s.resource_bundles = {
    'SitumWayfinding' => [
        'SitumWayfinding/Localizations/**/*',
        'SitumWayfinding/Classes/situm_google_maps_style.json',
        'SitumWayfinding/Classes/situm_google_maps_style_dark.json',
        'SitumWayfinding/Assets/Images/**/*.xcassets',
        'SitumWayfinding/Assets/Fonts/**/*.ttf',
    ]
  }
  
  s.dependency 'GoogleMaps', '~> 4.2.0'
  s.dependency 'SitumSDK', '~> 3.5.0'
  s.dependency 'Google-Maps-iOS-Utils', '~> 4.1.0'

end

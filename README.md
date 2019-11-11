# SitumWayfinding

[![CI Status](https://img.shields.io/travis/fsvilas/SitumWayfinding.svg?style=flat)](https://travis-ci.org/fsvilas/SitumWayfinding)
[![Version](https://img.shields.io/cocoapods/v/SitumWayfinding.svg?style=flat)](https://cocoapods.org/pods/SitumWayfinding)
[![License](https://img.shields.io/cocoapods/l/SitumWayfinding.svg?style=flat)](https://cocoapods.org/pods/SitumWayfinding)
[![Platform](https://img.shields.io/cocoapods/p/SitumWayfinding.svg?style=flat)](https://cocoapods.org/pods/SitumWayfinding)

## Description

Situm Wayfinding Module has been designed to create indoor location applications in the simplest way. It has been built in the top of the Situm SDK and its functionalities has been widely tested. If you are interested in building applications using the Situm SDK, please refer to [Situm iOS SDK Sample app](https://github.com/situmtech/situm-ios-swift-getting-started).

## Disclaimer

This code is in alpha release. Modifying SitumWayfinding code is not recommended at this stage. To work with SitumWayfinding use the offered public methods 

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Afterwards you would need to provide yours apikeys. You can do that from WayfindingController, replace the indicative texts with your Situm Dashboard, Google Maps Credentials and a proper Building ID.


## Installation

SitumWayfinding is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SitumWayfinding'
```

To provide user location SitumWayfinding needs some system permissions. 

Go to the Info tab of the Settings of your app. We need to add descriptors for the system permissions, accompanied with a label of your liking. The description value of these keys can be anything you want, for example just type “Location and bluetooth is required to find out where you are”. The required keys to use our SDK are the following:

* __NSLocationAlwaysUsageDescription__ (in XCode, “Privacy - Location Always Usage Description”).
* __NSLocationWhenInUseUsageDescription__ (in XCode, “Privacy - Location When In Use Usage Description”).
* __NSBluetoothPeripheralUsageDescription__ (in XCode, “Privacy - Bluetooth Peripheral Usage Description”).
* Only if you are targeting iOS13.0 or superior: __NSBluetoothAlwaysUsageDescription__ (in XCode, “Privacy - Bluetooth Always Usage Description”)

## License

SitumWayfinding is available under the MIT license. See the LICENSE file for more info.

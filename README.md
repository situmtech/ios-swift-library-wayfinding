# SitumWayfinding

[![CI Status](https://img.shields.io/travis/fsvilas/SitumWayfinding.svg?style=flat)](https://travis-ci.org/fsvilas/SitumWayfinding)
[![Version](https://img.shields.io/cocoapods/v/SitumWayfinding.svg?style=flat)](https://cocoapods.org/pods/SitumWayfinding)
[![License](https://img.shields.io/cocoapods/l/SitumWayfinding.svg?style=flat)](https://cocoapods.org/pods/SitumWayfinding)
[![Platform](https://img.shields.io/cocoapods/p/SitumWayfinding.svg?style=flat)](https://cocoapods.org/pods/SitumWayfinding)

> [!IMPORTANT]  
> This guide refers to the old version of the Wayfinding module, which is **no longer maintained**. We strongly recommend adopting [MapView](https://github.com/situmtech/situm-ios-swift-getting-started), the new visual component available for iOS.
To stay up to date, checkout the [Situm iOS SDK changelog](https://situm.com/docs/ios-sdk-changelog/).

## Description

Situm Wayfinding Module written in Swift for iOS devices has been designed to create indoor location applications in the simplest way. It has been built in the top of the Situm SDK and allows users to position in a building, see its floors, see the building POIs (Point Of Interest), create routes to any point of the building, receive instructions to reach a place and more. If you are interested in building applications using the Situm SDK, please refer to [Situm iOS SDK Sample app](https://github.com/situmtech/situm-ios-swift-getting-started).

## Submitting Contributions

You will need to sign a Contributor License Agreement (CLA) before making a submission. 
[Learn more here.](https://situm.com/contributions/)

## Disclaimer

This code is in alpha release. Modifying SitumWayfinding code is not recommended at this stage. To work with SitumWayfinding use the offered public methods.

## Requirements

1. MacOS.
2. Xcode. More about this IDE [here] (https://developer.apple.com/xcode/).
3. Cocoapods. Information about the installation process [here] (https://guides.cocoapods.org/using/getting-started.html). 

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

## Authenticate and load the wayfinding module

In order to use both SitumSDK and GoogleMaps capabilities you need to authenticate yourself.
This can be done by storing the credentials in a `Credentials` object that will later be forwarded to the `SitumMapsLibrary` initializer.
You should also provide the `SitumMapsLibrary` with the UIView, the UIViewController that are gonna contain the wayfinding UI and some settings to adjust the behaviour of the module.
Finally, you just need to call the load() method. The following example illustrates this process:

```
let credentials = Credentials(user: "YOUR SITUM USER", password:  "YOUR SITUM PASSWORD", googleMapsApiKey: "YOUR GOOGLE MAPS API KEY")
let buildingId = "YOUR_BUILDING_ID"
let settings = LibrarySettings.Builder()
    .setCredentials(credentials: credentials)
    .setBuildingId(buildingId: buildingId)
    .build()

let library = SitumMapsLibrary(containedBy: containerView, controlledBy: containerViewController, withSettings: settings)
do{
    try library.load()
}catch{
    // PROPERLY MANAGE ERROR
}
```

## License

SitumWayfinding is available under the MIT license. See the LICENSE file for more info.

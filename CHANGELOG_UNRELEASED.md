### Changed
- Added support to customize minZoom and maxZoom on the map. With this feature as a developer you can provide values that configure the minimum and maximum value of zoom the map will allow the user to set. Since the base map depends on GoogleMaps, you can see more information regarding the zoom parameter on https://developers.google.com/maps/documentation/android-sdk/views#zoom for Android and https://developers.google.com/maps/documentation/ios-sdk/views#zoom for iOS.
- Added support to configure the look and feel of the UI based on the dashboard theme. Change base colors and logos with the variable useDashboardTheme. Default to true.
-  Updated Situm SDK dependency to 2.56.0
- UI improvements : Improvements in the UI of the bottom information view
- UI improvements: Improvements in the floor selector appeareance
- UI improvements: Now if you use the dashboard theme the primary color is applied to most of the coloured items of the UI
- Improved texts of several languages

### Added
- Added hebrew and portuguese languages
- Use the new SDK api to handle reception of location events (with 
[addDelegate](https://developers.situm.com/sdk_documentation/ios/documentation/classes/sitlocationmanager#/c:objc(cs)SITLocationManager(im)addDelegate:) 
and [removeDelegate](https://developers.situm.com/sdk_documentation/ios/documentation/classes/sitlocationmanager#/c:objc(cs)SITLocationManager(im)removeDelegate:))
- Added dark mode support

## Deprecated
- When the back button is enabled in Wayfinding library, if the user taps in it the library no longer stops positioning
automatically. To stop the positioning you should use [SITLocationManager.sharedInstance().removeUpdates()](https://developers.situm.com/sdk_documentation/ios/documentation/protocols/sitlocationinterface#/c:objc(pl)SITLocationInterface(im)removeUpdates)

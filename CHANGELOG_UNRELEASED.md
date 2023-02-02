### Added
- Added hebrew and portuguese languages
- Use the new SDK api to handle reception of location events (with 
[addDelegate](https://developers.situm.com/sdk_documentation/ios/documentation/classes/sitlocationmanager#/c:objc(cs)SITLocationManager(im)addDelegate:) 
and [removeDelegate](https://developers.situm.com/sdk_documentation/ios/documentation/classes/sitlocationmanager#/c:objc(cs)SITLocationManager(im)removeDelegate:))
- Added dark mode support

## Changed
- UI improvements : Improvements in the UI of the bottom information view
- UI improvements: Improvements in the floor selector appeareance
- UI improvements: Now if you use the dashboard theme the primary color is applied to most of the coloured items of the UI
- Improved texts of several languages

## Deprecated
- When the back button is enabled in Wayfinding library, if the user taps in it the library no longer stops positioning
automatically. To stop the positioning you should use [SITLocationManager.sharedInstance().removeUpdates()](https://developers.situm.com/sdk_documentation/ios/documentation/protocols/sitlocationinterface#/c:objc(pl)SITLocationInterface(im)removeUpdates)
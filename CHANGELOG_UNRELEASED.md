### Changed
- Use the new SDK api to handle reception of location events (with addDelegate and removeDelegate)
- Added dark mode support
- UI improvements : Improvements in the UI of the bottom information view
- UI improvements: Improvements in the floor selector appeareance
- UI improvements: Now if you use the dashboard theme the primary color is applied to most of the coloured items of the UI

## Deprecated
- When the back button is enabled in Wayfinding library, if the user taps in it the library no longer stops positioning 
automatically. To stop the positioning you should use [SITLocationManager.sharedInstance().removeUpdates()](https://developers.situm.com/sdk_documentation/ios/documentation/protocols/sitlocationinterface#/c:objc(pl)SITLocationInterface(im)removeUpdates)
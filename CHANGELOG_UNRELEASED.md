### Changed
- Use the new SDK api to handle reception of location events (with addDelegate and removeDelegate)

## Deprecated
- When the back button is enabled in Wayfinding library, when user taps in it the library no longer stops positioning 
automatically. To stop the positioning you should use [SITLocationManager.sharedInstance().removeUpdates()](https://developers.situm.com/sdk_documentation/ios/documentation/protocols/sitlocationinterface#/c:objc(pl)SITLocationInterface(im)removeUpdates)
# Changelog
All notable changes to this project will be documented in this file. For previous versions see CHANGES file

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

All non released changes should be in CHANGELOG_UNRELEASED.md file

---------
## [0.19.7] - 2023-08-11
### Changed
- Update iOS SDK to version 3.0.2

## [0.19.6] - 2023-08-11
### Changed
- Update iOS SDK to version 2.62.0

## [0.19.5] - 2023-06-26
### Changed
- Update iOS SDK to version 2.61.0

## [0.19.4] - 2023-06-01
### Changed
- Update iOS SDK to version 2.60.2

## [0.19.3] - 2023-05-15
## Fixed
- Fixed bug that generated errors getting directions in certain cases (the user went out of route and the system tried to automaticallly recomputed).
- Fixed bug that showed incorrect information when the user centered the camera while getting position updates.

# Changed
- Updated Situm SDK dependency to 2.60.1.
- Updated Hebrew translations.

## [0.19.2] - 2023-03-20
### Fixed
* Fixed a crash when trying to unload a wyf module that has not yet been presented into screen

## [0.19.1] - 2023-03-15
### Changed
- Enabled remote configuration by default.
- Enabled clustering option by default.
- Enabled showPoiNames option by default.
- Enabled useDashboardTheme option by default.
- Update iOS SDK to version 2.59.0


## [0.19.0] - 2023-03-09
### Added
- Added new method to unload the Wayfinding module, this method should be used if the wyf module is not needed or before calling the load method again. If the unload method is not called, Wayfinding will consume unnecesary resources and can be left in an inequrate state.
- Added new functionality to place a custom POI on the map, as well as public methods to obtain, select and delete said custom POI.

### Fixed
- Fixed bug that does not clean the previous user position in some cases when reloading Wayfinding.
- Fixed a bug when the user was on navigation if the Wayfinding view is removed from screen and presented again afterwards.
- Fixed a bug that causes the duplication of some pois if the user has been on a route and the positioning is stopped.

# Changed
- Updated Situm SDK dependency to 2.58.0

## [0.18.2] - 2023-02-23
# Changed
- Updated Situm SDK dependency to 2.57.1

## [0.18.1] - 2023-02-16
### Changed
-  Updated Situm SDK dependency to 2.57.0

## [0.18.0] - 2023-02-02
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


## [0.17.1] - 2022-12-22
### Changed
- Added Turkish translations
- When the floor name is available show it instead of the ground level. The floor name will be shown in the search bar and in the bottom bar when a POI is selected

## [0.17.0] - 2022-12-21
### Added:
- Added floor change icons in the route path to indicate when a change of floor has to be made
- Added support to show tiles downloaded offline. To manage these tiles you should check the documentation on SitumSDK
- Updated Situm SDK dependency to 2.55.0

## [0.16.1] - 2022-11-07
### Changed:
- Improvements in the calculation of time to goal and arrival expected time whe the user request a route to a point.

## [0.16.0] - 2022-11-03
### Added:
- Added onNavigationStarted method to OnNavigationListener to notify when all route calculation are finished and the navigation starts.

## [0.15.0] - 2022-10-31
### Added:
- Add new method startPositioning to SitumMapsLibrary that allow to start positioning the user in the map
### Changed
-  Updated Situm SDK dependency to 2.54.2
### Fixed
- Fixed bug when poi names are shown and poi name is too long. Previously the name was cut

## [0.14.0] - 2022-10-27
### Added:
- Add new method setFloorsListVisible(floorsListVisible: Bool) in LibrarySettings to show or hide the floors list
- Add new method setPositioningFabVisible(positioningFabVisible: Bool) in LibrarySettings to show or hide the positioning button
### Changed:
- UI Improvements: Change the size, rounding and font of the center button
- UI Improvements: Increase size of cluster icons and make them look like android
- UI Improvements: Improvemnts in user feedback. Now an alert is shown when the user tries to start positioning if they previously rejected one of the system permissions Wayfinding needs to provide locations.

### Fixed:
- improved some translations text

## [0.13.0] - 2022-10-24
### Added:
- Added support for Top level POIs. These POIs will never be clustered, so they will be visible all the time no matter
  the level of zoom. To set top level pois create for that POI a custom field in dashboard with a property "top_level" and value "true"
### Changed
- UI Improvements: Decrease the size of POI icons.
- UI Improvements: Update size, font and stroke of POI labels. The new font used is Roboto
### Fixed:
- Fixed a bug that shows an invisible nav bar if search bar is set to be hidden SITLibrarySettings and you stop positioning.

## [0.12.0] - 2022-10-20
### Added:
- Added new method presentInNewView(_ view: UIView, controlledBy viewController: UIViewController) in SitumMapsLibrary that allow to present the WYF module in a different container view without the need of reset WYF module.
- Add new method filterPois(by categoryIds: [String]) to filter POIs by given category Ids. This will hide the icon of 
  every POI in the map that not matches these categories

### Changed
- Break clusters of POIs when zoom is very close to building

## [0.11.1] - 2022-10-10
### Fixed:
- Fixed a bug that do not load floor plan image on first load

### Changed:
- Updated Situm SDK dependency to 2.54.1

## [0.11.0] - 2022-10-05
### Added:
- Add new method setShowNavigationIndications(showNavigationIndications: Bool) in LibrarySettings to show navigation indications
- Added Arabic translations

### Changed:
- Updated Situm SDK dependency to 2.54.0

## [0.10.0] - 2022-09-29
### Added:
- Added support for using tiles in google maps

### Fixed
- Fixed a bug in setUseDashboardTheme from the LibrarySettings Builder. Now the dashboard theme works again.

## [0.9.0] - 2022-09-06
### Added:
- Added Japanese and French translations

### Changed
-  Updated Situm SDK dependency to 2.53.0

### Fixed
- Fixed a bug that caused the application to crash when exiting a route
- Fixed a bug that causes buildings with only one floor not showing its floorplan on the map.
- Fixed a error that caused release branches in pipelines to generate artifacts in debug mode

## [0.8.1] - 2022-08-12
### Changed
-  Updated Situm SDK dependency to 2.52.4

### Fixed
- Fixed an error that caused release branches in pipelines to generate artifacts in debug mode
- Fixed a bug that makes the user orientation not being updated when the screen is not centered in the user position.

## [0.8.0] - 2022-07-04
### Changed:
* Corrected methods lockCameraToBuilding(buildingId: String) and lockCameraToBuilding(building: SITBuilding) in SitumMapsLibrary to limit the minimun zoom to fit on the building bounds

## [0.7.0] - 2022-06-20

### Added:
* Add new method setEnablePoiClustering(enablePoisClustering: Bool) in LibrarySettings to activate or deactivate marker clustering of pois displayed in the map


## [0.6.0] - 2022-06-16

### Added:
* Add new method enableOneBuildingMode(buildingId: String) in SitumMapsLibrary to limit zoom and pan to a single building
* Add new method enableOneBuildingMode(building: SITBuilding) in SitumMapsLibrary to limit zoom and pan to a single building
* Behavior change when selecting a POI. If it is selected, the icon is shown in blue, while if it is not selected, it is black. If the parameter to show the name of the POI is active, it will be shown whether it is selected or not.
* Now the route is recalculated when the user goes outside the route (but still in building). The new route is 
recalculated from the actual user location

## [0.5.0] - 2022-04-12

### Changed:
* Adjusted navigation parameters to improve navigatin experience
* Added method setShowSearchBar to LibrarySettings Builder. This method allows to hide or show the POI search bar
* Added method setShowBackButton to LibrarySettings Builder. This method allows to hide or show the navigation back button

## [0.4.0] - 2022-03-31

### Changed:
* Navigation UI has been redesigned with aesthetic improvements and better and more clear information about the route
* Changes in GoogleMaps styles to adjust the colors and lightness of some cartographic elements.
* Changes in GoogleMaps styles to hide GoogleMaps POI names.
* Changed the behaviour of the module when setShowTextPois is not set. Now the default value is false so only the POI icons whithout its name will appear on the map.
* Updated situm sdk dependency to 2.52.1
* Changed the behaviour of long presses over the map. Now a marker is shown only if the long press is performed inside the bounds of the building.

### Fixed:
* Fixed a bug detected in naviagation mode when the user goes outside the route. In previous versions while the user 
was outside the route the user location was not updated.

## [0.3.0] - 2022-03-14

### Added:
* The setShowTextPois method has been added in SitumMapsLibrary. This method allows that the name of each POIs is shown on the map above the POI icon. If it is set to true, the POI name is seen above the POI icon, if it is set to false, only the POI icon appears.
* Added localization for spanish language in Wayfinding

## [0.2.0] - 2022-02-21
### Added
* Added protocol OnNavigationListener and a method setOnNavigationListener on SitumMapsLibrary. As a developer you can 
set a listener and implement the protocol methods to get notified of events during navigation (onNavigationRequested, 
onNavigationError and onNavigationFinished). Each of the protocol methods will receive an object that complies to 
protocol Navigation.
* Added protocol Navigation that holds information about the current status of the navigation and the navigation 
destination.

## [0.1.22] - 2022-02-21
# Added
* Added method navigateToLocation(floor, lat, lng) on SitumMapLibrary to navigate to a location in the current building.
The location is specified by a floor, a latitude and a longitude

* Added the method setUseRemoteConfig(Bool) to LibrarySettings to start positioning using the Remote Configuration. The default value is false. When this parameter is set to true the local settings will be overwritten.

## [0.1.21] - 2022-02-07

### Addded
* Added method navigateToPoi(poi,completion) on SitumMapLibrary to navigate towards a POI on the map. A callback could 
be passed as a parameter to know when the navigation was started (since the action is asynchronous)

## [0.1.20] - 2022-01-28

### Addded
* Added protocol OnMapReadyListener that notifies when it is safe to perform operations over the map. A class that
implement this protocol could be set on SitumMapsLibrary to react to this notification
* Added method on SitumMapLibrary to select a POI on the map. A callback could be passed as a parameter to know when the 
POI was selected (since the action is asynchronous)

## [0.1.19] - 2022-01-14

### Added
 * Added protocol OnPoiSelectionListener and method setOnPoiSelectionListener on SitumMap protocol. As a developer you can set a listener and implement the protocol methods to get notified of selection/deselection of Pois
 * Added protocol OnFloorChangeListener and method setOnFloorChangeListener on SitumMap protocol. As a developer you can set a listener and implement the protocol method to get notified of changes in the selected floor

 ### Changed
 * Now changes on the selected floor doesn't causes the deselection of the selected Poi

## [0.1.18] - 2021-12-23

### Added
* Finished the implementation of the search bar. This search bar presents the building POIs ordered alphabetically and provides basic filtering capbilities. A selection of a POI implies that:
 1) If there was a selected POI it is deselected.
 2) The active floor plan is changed to the selected POI floor if neccesary. 
 3) The footer bar is uptated to show the POI info.
 4) The navigation button to request a route to that POI is displayed.
* Added a public method setSearchViewPlaceholder in LibrarySettings class.

### Changed
* Updated situm sdk dependency to 2.51.5

## [0.1.17] - 2021-12-14

### Added
* First version of the search bar. In this version the selection of a result is not yet implemented.

## [0.1.16] - 2021-11-30

### Fixed
* Previously when a building was first shown in the app, the default floor that appeared in the screen was the highest floor. Now this was changed to be the lowest floor

### Added
* Added methods in LibrarySettings and SitumMapView to set the user marker from a local asset.
* Now the user position error range circle gets its color from the dashboard when the option useDashboardTheme is set to true. The same applies to the navigation path color.

## [0.1.15] - 2021-11-11

### Fixed
* Change in the design of the route marking line

### Changed
* Updated situm sdk dependency to 2.51.4

## [0.1.14] - 2020-07-27

### Fixed
* Fixed issue when automatically changing floors on new locations

### Changed
* Update levels to order them from lower (bottom) to upper levels (top)
* Updated situm sdk dependency to 2.51.1

## [0.1.13] - 2020-05-26

### Fixed
* User position accuracy. Position accuracy previously had a fixed radio, now the radio is properly updated taking into account the actual accuracy.

### Changed
* Minimun iOS Target supporte changed from ios 9 to ios 10
* Updated situm sdk dependency to 2.50.9
* Updated Google Maps dependency to 4.2.0

## [0.1.12] - 2020-02-16

### Added
* Customize logo and primary color based on profile
* Updated situm sdk dependency to 2.50.5

## [0.1.11] - 2020-10-03

#### Fixed
* Fixed crash when requesting navigation from outdoor position.

#### Changed
* Improved experience when user goes outdoor during navigation. Now navigation is stopped if user leaves the current building

## [0.1.10] - 2020-10-28

#### Fixed
* Replace deprecated UIAlertView for UIAlertController

## [0.1.9] - 2019-12-26

#### Changed
* Change positioning view so it also prints outdoor positions

#### Fixed
* Fix a bug that kept the user's marker on screen after selecting a different floor


## [0.1.8] - 2019-11-12

### Added
* New methods to stop nagivation and positioning


## [0.1.7] - 2019-11-11
### Added
* New load method that allows injecting GoogleMaps map

### Changed
* Make pod public
* Make public methods accesible from Objective-C
* Correct bug causing multiple presentations of several Error Alerts

## [0.1.6] - 2019-11-04

#### Changed
* Add level name when it exists to floor selector
* Correct relogin error
* Remove unnecessary methods from class `UserDefaultsWrapper`
* Correct target merbership of classes `UserDefaultsWrapper` and `Logger`


## [0.1.5] - 2019-06-27

# Added
* Add new class `SitumView`
* Add option to load Wayfinding module as a view (only programmaticaly before)
* Add new custom error `UnsuportedConfigurationError`

#### Changed
* Credentials are now set through a separate method `setCredentials()`
* Not providing credentials before loading the module now throws an exception


## [0.1.4] - 2019-06-19

### Added
* Add `SitumMap` protocol
* Add function `getGoogleMap()` to `SitumMapsLibrary` class
* Add interceptors functionality for location, directions and navigation requests

### Changed
* Rename `Facade`to `SitumMapsLibrary`
* `onBackPressedCallback` is now passed to `SitumMapsLibrary` through a separate method
* Apply all new changes to SMT


## [0.1.3] - 2019-06-11

### Added
* Add onBackCallback to Facade's load method
* Add new class Credentials

### Changed
* CI now fails if the podspec can´t be pushed in master-release
* Refactor Facade Methods

### Deleted
* Deleted KeysStore class


## [0.1.2] - 2019-05-29

### Added
* Add jazzy to generate appledoc during Jenkins compilation
* Add podspec

### Changed
* Comment all public classes and methods in SitumWayfinding
* Modify Jenkinsfile so it cleans "build/" and "docs/" after compilation



## [0.1.1] - 2019-05-24

### Added
* Add login and building selection screen from SMT
* Add new target to compile SMT and Wayfinding in the same project

### Changed
* Positioning view now always matches its superview size


## [0.1.0] - 2019-05-23

### Added
* Initial implementation of the wayfinding module.

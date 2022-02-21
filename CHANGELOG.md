# Changelog
All notable changes to this project will be documented in this file. For previous versions see CHANGES file

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

All non released changes should be in CHANGELOG_UNRELEASED.md file

---------
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

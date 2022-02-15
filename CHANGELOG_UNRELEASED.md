## [0.2.0] - 2022-02-15

### Added
* Added method navigateToLocation(floor, lat, lng) on SitumMapLibrary to navigate to a location in the current building.
The location is specified by a floor, a latitude and a longitude
* Add OnNavigationListener protocol to listen for events related to navigation and the ability to hook up with custom
callbacks. This will give information about navigation either made by user or by developer. This will include an object
Navigation which holds information about the current status and the destination.
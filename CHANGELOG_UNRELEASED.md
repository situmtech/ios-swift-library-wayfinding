## [0.2.0] - 2022-02-15

### Added
* Added method navigateToLocation(floor, lat, lng) on SitumMapLibrary to navigate to a location in the current building.
The location is specified by a floor, a latitude and a longitude
* Added protocol OnNavigationListener and a method setOnNavigationListener on SitumMapsLibrary. As a developer you can 
set a listener and implement the protocol methods to get notified of events during navigation (onNavigationRequested, 
onNavigationError and onNavigationFinished). Each of the protocol methods will receive an object that complies to 
protocol Navigation.
* Added protocol Navigation that holds information about the current status of the navigation and the navigation 
destination.
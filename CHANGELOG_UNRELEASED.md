### Added:
* Add new method enableOneBuildingMode(buildingId: String) in SitumMapsLibrary to limit zoom and pan to a single building
* Add new method enableOneBuildingMode(building: SITBuilding) in SitumMapsLibrary to limit zoom and pan to a single building
* Behavior change when selecting a POI. If it is selected, the icon is shown in blue, while if it is not selected, it is black. If the parameter to show the name of the POI is active, it will be shown whether it is selected or not.
* Now the route is recalculated when the user goes outside the route (but still in building). The new route is 
recalculated from the actual user location
* Add new method setEnablePoiClustering(enablePoisClustering: Bool) in LibrarySettings to activate or deactivate marker clustering of pois displayed in the map
### Added:
-  Added floor change icons in the route path to indicate when a change of floor has to be made
- Added support to fetch offline tiles on demand from dashboard. There are a couple of new methods to handle this in
  SitumMapsLibrary:
  - fetchTilesOffline will download all available tiles for a building to the storage of the phone 
    (making them available offline)
  - clearTiles will wipe out all data of all downloaded tiles for every building
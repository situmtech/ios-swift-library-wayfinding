### Added
- Added new method to unload the Wayfinding module, this method should be used if the wyf module is not needed or before calling the load method again. If the unload method is not called, Wayfinding will consume unnecesary resources and can be left in an inequrate state.

### Fixed
- Fixed bug that does not clean the previous user position in some cases when reloading Wayfinding.
- Fixed a bug when the user was on navigation if the Wayfinding view is removed from screen and presented again afterwards.
- Fixed a bug that causes the duplication of some pois if the user has been on a route and the positioning is stopped.

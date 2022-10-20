## [0.12.0] - 2022-10-05
### Added:
- Added new method presentInNewView(_ view: UIView, controlledBy viewController: UIViewController) in SitumMapsLibrary that allow to present the WYF module in a different container view without the need of reset WYF module.
- Add new method filterPois(by categoryIds: [String]) to filter POIs by given category Ids. This will hide the icon of 
  every POI in the map that not matches these categories

### Changed
- Break clusters of POIs when zoom is very close to building
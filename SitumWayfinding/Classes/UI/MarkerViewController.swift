import SitumSDK
import GoogleMaps

extension PositioningViewController {
    //MARK: POI Selection
    //Programatic POI selection, a POI can also be selected by the user tapping on it in the  phone screen
    func select(poi: SITPOI) throws {
        try select(poi: poi, success: {})
    }
    
    func select(poi: SITPOI, success: @escaping () -> Void) throws {
        if let indexpath = getIndexPath(floorId: poi.position().floorIdentifier) {
            select(floor: indexpath)
        }
        if let markerPoi = poiMarkers.first(where: { ($0.userData as! SITPOI).id == poi.id }) {
            select(marker: SitumMarker(from: markerPoi), success: success)
        } else {
            throw WayfindingError.invalidPOI
        }
    }
    
    func select(marker: SitumMarker) {
        select(marker: marker, success: {})
    }
    
    //Imitates actions done by google maps when a user select a marker
    func select(marker: SitumMarker, success: @escaping () -> Void) {
        //TODO Extender para que sexa valido tamen para os custom markers
        if marker != lastSelectedMarker {
            deselect(marker: lastSelectedMarker)
        }
        
        loadIcon(selected: true, poi: marker.poi!, map: false, marker: marker.gmsMarker)
        
        CATransaction.begin()
        CATransaction.setValue(0.5, forKey: kCATransactionAnimationDuration)
        CATransaction.setCompletionBlock({
            // self.mapView.selectedMarker = marker.gmsMarker // tooltip sobre POI
            if marker.isPoiMarker() {
                self.poiMarkerWasSelected(poiMarker: marker)
            }
            self.lastSelectedMarker = marker
            success()
        })
        self.mapView.animate(toLocation: marker.gmsMarker.position)
        CATransaction.commit()
    }
    
    func deselect(marker: SitumMarker?) {
        mapView.selectedMarker = nil
        self.removeLastCustomMarkerIfOutsideRoute()
        self.changeNavigationButtonVisibility(isVisible: false)
        self.updateInfoBarLabelsIfNotInsideRoute(mainLabel: self.buildingName)
        self.lastSelectedMarker = nil
        if let umarker = marker, umarker.isPoiMarker() {
            poiMarkerWasDeselected(poiMarker: umarker)
            loadIcon(selected: false, poi: umarker.poi!, map: false, marker: umarker.gmsMarker)
        }
    }
    
    func poiMarkerWasSelected(poiMarker: SitumMarker) {
        if (!self.isUserNavigating()) {
            self.changeNavigationButtonVisibility(isVisible: true)
        }
        self.updateInfoBarLabelsIfNotInsideRoute(
            mainLabel: poiMarker.poi?.name ?? DEFAULT_POI_NAME,
            secondaryLabel: self.buildingName
        )
        if (self.positioningButton.isSelected) {
            showCenterButton()
        }
        isCameraCentered = false
        //Call only if this marker wasnt already the selected one
        if poiMarker != lastSelectedMarker, let uPoi = poiMarker.poi, let uBuildingInfo = buildingInfo {
            poiWasSelected(poi: uPoi, buildingInfo: uBuildingInfo)
        }
    }
    
    func poiMarkerWasDeselected(poiMarker: SitumMarker) {
        if let uPoi = poiMarker.poi, let uBuildingInfo = buildingInfo {
            poiWasDeselected(poi: uPoi, buildingInfo: uBuildingInfo)
        }
    }
    
    func poiWasSelected(poi: SITPOI, buildingInfo: SITBuildingInfo) {
        delegateNotifier?.notifyOnPOISelected(poi: poi, buildingInfo: buildingInfo)
    }
    
    func poiWasDeselected(poi: SITPOI, buildingInfo: SITBuildingInfo) {
        delegateNotifier?.notifyOnPOIDeselected(poi: poi, buildingInfo: buildingInfo)
    }
    
    func cleanPois() {
        for poiMarker in poiMarkers {
            poiMarker.map = nil
        }
        poiMarkers.removeAll()
    }
    
    func displayDestinationMarker(floor: String?) {
        let floorIdentifier: String = self.getFloorIdFromMarker(marker: self.destinationMarker!)
        let mapView = (floor == floorIdentifier) ? self.mapView : nil
        self.destinationMarker?.setMapView(mapView: mapView)
    }
    
    func displayPois(onFloor floorIdentifier: String?) {
        self.cleanPois()
        var poisInSelectedFloor: Array<SITPOI> = Array()
        for poi in buildingInfo!.indoorPois {
            if poi.position().floorIdentifier == floorIdentifier {
                poisInSelectedFloor.append(poi)
            }
        }
        
        for poi in poisInSelectedFloor {
            if let marker = self.createMarker(withPOI: poi) {
                self.poiMarkers.append(marker)
                if poi == lastSelectedMarker?.poi && self.mapView.selectedMarker == nil {
                    self.mapView.selectedMarker = marker
                }
            }
        }
        poisInSelectedFloor.removeAll()
    }
    
    func updateUserMarker(with location: SITLocation) {
        let selectedLevel: SITFloor? = orderedFloors(buildingInfo: buildingInfo)![selectedLevelIndex]
        if isCameraCentered || location.position.isOutdoor() || selectedLevel?.identifier == location.position
            .floorIdentifier {
            let userMarkerImage = getMarkerImage(for: location)
            let color = UIColor(
                red: 0x00 / 255.0,
                green: 0x75 / 255.0,
                blue: 0xc9 / 255.0,
                alpha: 1
            )
            positionDrawer?.updateUserLocation(
                with: location,
                with: userMarkerImage,
                with: primaryColor(defaultColor: color).withAlphaComponent(0.4)
            )
            self.makeUserMarkerVisible(visible: true)
        } else {
            makeUserMarkerVisible(visible: false)
        }
    }
    
    func getMarkerImage(for location: SITLocation) -> UIImage? {
        if location.position.isOutdoor() {
            return userMarkerIcons["swf_location_outdoor_pointer"]
        } else if location.quality == .sitHigh && location.bearingQuality == .sitHigh {
            return userMarkerIcons["swf_location_pointer"]
        } else {
            return userMarkerIcons["swf_location"]
        }
    }
    
    func makeUserMarkerVisible(visible: Bool) {
        positionDrawer?.makeUserMarkerVisible(visible: visible)
    }
    
    func removeLastCustomMarkerIfOutsideRoute() {
        if (!self.isUserNavigating()) {
            self.removeLastCustomMarker()
        }
    }
    
    func removeLastCustomMarker() {
        if (self.lastCustomMarker != nil) {
            self.lastCustomMarker?.setMapView(mapView: nil)
            self.lastCustomMarker = nil
        }
    }
    
    func getCategoryFromMarker(marker: SitumMarker?) -> DestinationCategory? {
        guard let marker = marker else { return nil }
        
        if marker.isPoiMarker() {
            return .poi(marker.poi!)
        } else {
            let coordinate = CLLocationCoordinate2D(
                latitude: marker.gmsMarker.position.latitude,
                longitude: marker.gmsMarker.position.longitude
            )
            let floorId = getFloorIdFromMarker(marker: marker)
            let point = SITPoint(
                building: buildingInfo!.building,
                floorIdentifier: floorId,
                coordinate: coordinate
            )
            return .location(point)
        }
    }
    
    func createMarker(withPOI poi: SITPOI, selected: Bool = false) -> GMSMarker? {
        let coordinate = poi.position().coordinate()
        let poiMarker = GMSMarker(position: coordinate)
        poiMarker.title = poi.name
        poiMarker.userData = poi
        loadIcon(selected: false, poi: poi, map: true, marker: poiMarker)
        return poiMarker
    }
    
    func createMarker(withCoordinate coordinate: CLLocationCoordinate2D, floorId floor: String) -> GMSMarker {
        let marker: GMSMarker = GMSMarker(position: coordinate)
        marker.title = NSLocalizedString(
            "positioning.customDestination",
            bundle: SitumMapsLibrary.bundle,
            comment: "Shown to user when select a destination (destination is any free point that user selects on the map)"
        )
        marker.userData = floor
        marker.map = self.mapView
        
        return marker
    }
    
    func showPoiNames() -> Bool {
        if let settings = self.library?.settings, let showText = settings.showPoiNames {
            return showText
        }
        
        return false
    }
    
    func loadIcon(selected: Bool, poi: SITPOI, map: Bool, marker: GMSMarker) {
        iconsStore.obtainIconFor(category: poi.category) { items in
            if let icon = selected ? items?[1] : items?[0] {
                let color = UIColor(hex: "#5b5b5bff") ?? UIColor.gray
                let title = poi.name.uppercased()
                marker.icon = self.showPoiNames() ?
                icon.setTitle(title: title, size: 12.0, color: color, weight: .semibold) :
                icon
            }
            
            if map {
                marker.map = self.mapView
            }
        }
    }
}

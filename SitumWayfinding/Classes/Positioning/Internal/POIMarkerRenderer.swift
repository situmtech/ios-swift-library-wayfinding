//
// Created by Lapisoft on 28/4/22.
//

import Foundation
import GoogleMaps
import SitumSDK

protocol POIMarkerRendererDelegate: AnyObject {
    func selected(marker: SitumMarker, buildingInfo: SITBuildingInfo)
    func deselected(marker: SitumMarker, buildingInfo: SITBuildingInfo)
}

class POIMarkerRenderer {
    typealias PoiSelected = () -> Void
    
    private(set) var selectedMarker: SitumMarker?
    weak var delegate: POIMarkerRendererDelegate? = nil
    private var mapView: GMSMapView
    
    private var poiMarkers: Array<SitumMarker> = []
    private var buildingInfo: SITBuildingInfo
    private var iconsStore: IconsStore
    private var showPoiNames: Bool
    private var currentFloor: SITFloor?

    init(mapView: GMSMapView, buildingInfo: SITBuildingInfo, showPoiNames: Bool, iconsStore: IconsStore) {
        self.mapView = mapView
        self.buildingInfo = buildingInfo
        self.showPoiNames = showPoiNames
        self.iconsStore = iconsStore
    }
    
    // MARK: Display of POIs
    func displayPoiMarkers(onFloor floor: SITFloor, isUserNavigating: Bool) {
        currentFloor = floor
        cleanMarkers()
        if isUserNavigating {
            showOnlyDestinationMarker(floor: floor)
        } else {
            showAllPOIMarkersInFloor(floor: floor)
        }
    }
    
    private func cleanMarkers() {
        for poiMarker in poiMarkers {
            poiMarker.setMapView(mapView: nil)
        }
        poiMarkers.removeAll()
        if let selectedMarker = selectedMarker {
            selectedMarker.setMapView(mapView: nil)
            mapView.selectedMarker = nil
        }
    }
    
    private func showOnlyDestinationMarker(floor: SITFloor) {
        guard let marker = selectedMarker, marker.floorIdentifier == floor.identifier else { return }
        mapView.selectedMarker = marker.gmsMarker
        marker.setMapView(mapView: mapView)
    }
    
    private func showAllPOIMarkersInFloor(floor: SITFloor) {
        var poisInSelectedFloor: Array<SITPOI> = Array()
        for poi in buildingInfo.indoorPois {
            if poi.position().floorIdentifier == floor.identifier {
                poisInSelectedFloor.append(poi)
            }
        }
    
        for poi in poisInSelectedFloor {
            let isSelected = selectedMarker?.poi == poi
            if isSelected {
                if let oldSelectedMarker = selectedMarker {
                    // get rid of old selected marker
                    oldSelectedMarker.setMapView(mapView: nil)
                    selectedMarker = nil
                }
            }
            let marker = createMarker(withPOI: poi, isSelected: isSelected)
            poiMarkers.append(marker)
            loadIcon(marker: marker, poi: poi, isSelected: isSelected)
        }
    }
    
    private func createMarker(withPOI poi: SITPOI, isSelected: Bool) -> SitumMarker {
        let coordinate = poi.position().coordinate()
        let poiMarker = GMSMarker(position: coordinate)
        poiMarker.title = poi.name
        poiMarker.userData = poi
        let marker = SitumMarker(from: poiMarker)
        if isSelected {
            selectedMarker = marker
        }
        return marker
    }
    
    // MARK: Selection
    func userSelect(gmsMarker: GMSMarker) {
        let marker = poiMarkers.first { marker in marker.gmsMarker == gmsMarker }!
        select(marker: marker)
    }
    
    /**
     Select a POI if exists, otherwise raise and error (it's possible to create a POI programmatically
     and if doesn't exist in building this error will raise)
     - Parameters:
       - poi: POI to select
       - selectedHandler: success callback after animation of selection is finished
     - Throws: WayfindingError.invalidPOI
     */
    func select(poi: SITPOI, selectedHandler: PoiSelected? = nil) throws {
        let marker = try marker(from: poi)
        select(marker: marker, selectedHandler: selectedHandler)
    }
    
    private func marker(from poi: SITPOI) throws -> SitumMarker {
        guard let marker = poiMarkers.first(where: { marker in marker.poi?.id == poi.id }) else {
            throw WayfindingError.invalidPOI
        }
        return marker
    }
    
    func select(location: CLLocationCoordinate2D, floor: SITFloor, selectedHandler: PoiSelected? = nil) {
        let marker = createCustomDestinationMarker(location: location, floor: floor)
        select(marker: marker, selectedHandler: selectedHandler)
    }
    
    private func createCustomDestinationMarker(location: CLLocationCoordinate2D, floor: SITFloor) -> SitumMarker {
        let gmsMarker: GMSMarker = GMSMarker(position: location)
        gmsMarker.title = NSLocalizedString("positioning.customDestination",
            bundle: SitumMapsLibrary.bundle,
            comment: "Shown to user when select a destination (destination is any free point that user selects on the map)"
        )
        let marker = SitumMarker(from: gmsMarker, in: floor)
        marker.setMapView(mapView: mapView)
        return marker
    }
    
    private func select(marker: SitumMarker, selectedHandler: PoiSelected? = nil) {
        if let poi = marker.poi {
            loadIcon(marker: marker, poi: poi, isSelected: true)
        }
        CATransaction.begin()
        CATransaction.setValue(0.5, forKey: kCATransactionAnimationDuration)
        CATransaction.setCompletionBlock({
            self.selectMarkerInMap(marker: marker)
            selectedHandler?()
        })
        mapView.animate(toLocation: marker.gmsMarker.position)
        CATransaction.commit()
    }
    
    private func selectMarkerInMap(marker: SitumMarker) {
        // only select when the marker is different
        if selectedMarker != marker {
            deselect()  // deselect if any marker is selected before select new one
            selectedMarker = marker
            mapView.selectedMarker = marker.gmsMarker
            delegate?.selected(marker: marker, buildingInfo: buildingInfo)
        }
    }
    
    func deselect() {
        guard let marker = selectedMarker else { return }
        mapView.selectedMarker = nil
        selectedMarker = nil
        if poiMarkers.first(where: { $0 == marker }) == nil {
            // we are deselecting a marker that is no longer valid so we need to release it from map
            marker.setMapView(mapView: nil)
        } else if let floor = currentFloor, marker.floorIdentifier == floor.identifier, let poi = marker.poi {
            loadIcon(marker: marker, poi: poi, isSelected: false)
        }
        delegate?.deselected(marker: marker, buildingInfo: buildingInfo)
    }
    
    private func loadIcon(marker: SitumMarker, poi: SITPOI, isSelected: Bool) {
        iconsStore.obtainIconFor(category: poi.category) { [weak self] items in
            guard let renderer = self else { return }
            guard let items = items else { return }
            let icon = isSelected ? items[1] : items[0]
            
            let color = UIColor(hex: "#5b5b5bff") ?? UIColor.gray
            let title = poi.name.uppercased()
            if renderer.showPoiNames {
                marker.gmsMarker.icon = icon?.setTitle(title: title, size: 12.0, color: color, weight: .semibold)
            } else {
                marker.gmsMarker.icon = icon
            }
            marker.gmsMarker.map = renderer.mapView
            if isSelected {
                renderer.mapView.selectedMarker = marker.gmsMarker
            }
        }
    }
}

//
// Created by Lapisoft on 20/5/22.
//

import Foundation
import GoogleMaps
import SitumSDK

class MarkerRenderer {
    private(set) var markers: Array<SitumMarker> = []
    private var mapView: GMSMapView
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
    
    func displayPOIMarkers(forFloor floor: SITFloor) {
        cleanMarkers()
        let poisInFloor = buildingInfo.indoorPois.filter { poi in poi.position().floorIdentifier == floor.identifier }
    
        for poi in poisInFloor {
            let marker = SitumMarker(poi)
            markers.append(marker)
            loadUnselectedIcon(forMarker: marker)
        }
    }
    
    func displayCustomMarker(marker: SitumMarker, forFloor floor: SITFloor) {
        if floor.identifier == marker.floorIdentifier {
            markers.append(marker)
            marker.setMapView(mapView: mapView)
        }
    }
    
    func displayDestinationMarker(marker: SitumMarker, forFloor floor: SITFloor) {
        cleanMarkers()
        if floor.identifier == marker.floorIdentifier {
            markers.append(marker)
            loadSelectedIcon(forMarker: marker)
        }
    }
    
    private func cleanMarkers() {
        for marker in markers {
            // disassociate markers from map (otherwise we lost reference and they get stuck in map forever)
            marker.setMapView(mapView: nil)
        }
        markers.removeAll()
    }
    
    func loadSelectedIcon(forMarker marker: SitumMarker) {
        if marker.isPoiMarker {
            loadIcon(forMarker: marker, selected: true)
        }
        if marker.isCustomMarker {
            mapView.selectedMarker = marker.gmsMarker
            if marker.gmsMarker.map == nil {
                marker.setMapView(mapView: mapView)
            }
        }
    }
    
    func loadUnselectedIcon(forMarker marker: SitumMarker) {
        if marker.isPoiMarker {
            loadIcon(forMarker: marker, selected: false)
        }
        // when unselected a custom marker we remove it
        if marker.isCustomMarker {
            marker.setMapView(mapView: nil)
            markers = markers.filter { element in element != marker }
        }
        mapView.selectedMarker = nil
    }
    
    private func loadIcon(forMarker marker: SitumMarker, selected: Bool) {
        guard let poi = marker.poi else { return }
        // do not load images for markers that are not currently rendered (internal array)
        // also, ensure the marker is a reference to internal array of SitumMarker
        guard let marker = searchMarker(byPOI: poi) else { return }
        let showPoiNames = showPoiNames
        
        iconsStore.obtainIconFor(category: poi.category) { [weak self] items in
            if let icon = selected ? items?[1] : items?[0] {
                let color = UIColor(hex: "#5b5b5bff") ?? UIColor.gray
                let title = poi.name.uppercased()
                if showPoiNames {
                    marker.gmsMarker.icon = icon.setTitle(title: title, size: 12.0, color: color, weight: .semibold)
                } else {
                    marker.gmsMarker.icon = icon
                }
            }
            
            if marker.gmsMarker.map == nil {
                marker.setMapView(mapView: self?.mapView)
            }
            if selected {
                self?.mapView.selectedMarker = marker.gmsMarker
            }
        }
    }
    
    func searchMarker(byGMSMarker gmsMarker: GMSMarker) -> SitumMarker? {
        return markers.first(where: { poiMarker in poiMarker.gmsMarker == gmsMarker })
    }
    
    func searchMarker(byPOI searchedPoi: SITPOI) -> SitumMarker? {
        return markers.first { marker in
            guard let poi = marker.poi else { return false }
            return poi.id == searchedPoi.id
        }
    }
}
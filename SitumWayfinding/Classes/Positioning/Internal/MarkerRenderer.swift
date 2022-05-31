//
// Created by Lapisoft on 20/5/22.
//

import Foundation
import GoogleMaps
import SitumSDK
import GoogleMapsUtils

class MarkerRenderer {
    var isClusteringEnabled: Bool { return markerClustering != nil }
    
    private(set) var markers: Array<SitumMarker> = []
    private var mapView: GMSMapView
    private var buildingInfo: SITBuildingInfo
    private var iconsStore: IconsStore
    private var showPoiNames: Bool
    private var markerClustering: MarkerClustering? = nil
    private var currentFloor: SITFloor?
    
    init(
        mapView: GMSMapView,
        buildingInfo: SITBuildingInfo,
        iconsStore: IconsStore,
        showPoiNames: Bool,
        isClusteringEnabled: Bool
    ) {
        self.mapView = mapView
        self.buildingInfo = buildingInfo
        self.showPoiNames = showPoiNames
        self.iconsStore = iconsStore
        if isClusteringEnabled {
            markerClustering = MarkerClustering(mapView: mapView)
        }
    }
    
    func displayPOIMarkers(forFloor floor: SITFloor) {
        removeMarkers()
        let poisInFloor = buildingInfo.indoorPois.filter { poi in poi.position().floorIdentifier == floor.identifier }
        
        for poi in poisInFloor {
            let marker = SitumMarker(poi)
            markers.append(marker)
            loadIcon(forMarker: marker, selected: false) { [weak self] marker in
                if let markerClustering = self?.markerClustering  {
                    markerClustering.add(marker)
                    markerClustering.display()
                } else {
                    self?.insertMarkerInGoogleMaps(marker: marker)
                }
            }
        }
    }
    
    func displayLongPressMarker(_ marker: SitumMarker, forFloor floor: SITFloor) {
        if floor.identifier == marker.floorIdentifier {
            markers.append(marker)
            selectMarker(marker)
        }
    }
    
    func displayOnlyDestinationMarker(_ marker: SitumMarker, forFloor floor: SITFloor) {
        removeMarkers()
        if let markerCluster = markerClustering {
            markerCluster.add(marker)
            markerCluster.display()
        } else {
            if floor.identifier == marker.floorIdentifier {
                markers.append(marker)
                selectMarker(marker)
            }
        }
    }
    
    private func removeMarkers() {
        for marker in markers {
            // disassociate markers from map (otherwise we lost reference and they get stuck in map forever)
            removeMarkerFromGoogleMaps(marker: marker)
        }
        if isClusteringEnabled {
            markerClustering?.removeMarkers()
        }
        markers.removeAll()
    }
    
    func selectGMSMarker(_ marker: GMSMarker) {
        if isClusterGMSMarker(marker) {
            mapView.animate(toZoom: mapView.camera.zoom + 1)
        }
    }
    
    func selectMarker(_ marker: SitumMarker) {
        if isClusterGMSMarker(marker.gmsMarker) {
            mapView.animate(toZoom: mapView.camera.zoom + 1)
        } else if marker.isPoiMarker {
            loadIcon(forMarker: marker, selected: true) { [weak self] marker in
                self?.selectMarkerInGoogleMaps(marker: marker)
            }
        } else if marker.isCustomMarker {
            selectMarkerInGoogleMaps(marker: marker)
        }
    }
    
    func isClusterGMSMarker(_ marker: GMSMarker) -> Bool {
        return isClusteringEnabled && marker.userData is GMUCluster
    }
    
    func deselectMarker(_ marker: SitumMarker) {
        if marker.isPoiMarker {
            loadIcon(forMarker: marker, selected: false) { [weak self] marker in
                self?.deselectMarkerFromGoogleMaps(marker: marker)
            }
        }
        if marker.isCustomMarker {
            removeMarkerFromGoogleMaps(marker: marker)
            markers = markers.filter { element in element != marker }
        }
    }
    
    private func selectMarkerInGoogleMaps(marker: SitumMarker) {
        insertMarkerInGoogleMaps(marker: marker)
        mapView.selectedMarker = marker.gmsMarker
    }
    
    private func insertMarkerInGoogleMaps(marker: SitumMarker) {
        if marker.gmsMarker.map == nil {
            marker.setMapView(mapView: mapView)
        }
    }
    
    private func removeMarkerFromGoogleMaps(marker: SitumMarker) {
        if mapView.selectedMarker == marker.gmsMarker {
            deselectMarkerFromGoogleMaps(marker: marker)
        }
        marker.setMapView(mapView: nil)
    }
    
    private func deselectMarkerFromGoogleMaps(marker: SitumMarker) {
        mapView.selectedMarker = nil
    }
    
    /**
     Load the poi icon from the server for given marker
     - Parameters:
       - marker: marker to get icon for
       - selected: if the icon will be load with selected or deselected state
       - iconLoaded: Return the marker with the icon loaded inside
     */
    private func loadIcon(forMarker marker: SitumMarker, selected: Bool, iconLoaded: ((SitumMarker) -> ())? = nil) {
        guard let poi = marker.poi else { return }
        // do not load images for markers that are not currently rendered (internal array)
        // also, ensure the marker is a reference to internal array of SitumMarker
        guard let marker = searchMarker(byPOI: poi) else { return }
        let showPoiNames = showPoiNames
        
        iconsStore.obtainIconFor(category: poi.category) { items in
            guard let icon = selected ? items?[1] : items?[0] else {
                Logger.logDebugMessage("Icon from server could not be retrieved")
                return
            }
    
            let color = UIColor(hex: "#5b5b5bff") ?? UIColor.gray
            let title = poi.name.uppercased()
            if showPoiNames {
                marker.gmsMarker.icon = icon.setTitle(title: title, size: 12.0, color: color, weight: .semibold)
            } else {
                marker.gmsMarker.icon = icon
            }
            iconLoaded?(marker)
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
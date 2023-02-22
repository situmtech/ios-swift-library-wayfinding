//
// Created by Lapisoft on 20/5/22.
//

import Foundation
import GoogleMaps
import SitumSDK
import GoogleMapsUtils

class MarkerRenderer {
    var isClusteringEnabled: Bool { return markerClustering != nil }
    
    private(set) var markers: [SitumMarker] = []
    private var mapView: GMSMapView
    private var buildingManager: BuildingManager
    private var iconsStore: IconsStore
    private var showPoiNames: Bool
    private var markerClustering: GoogleMapsMarkerClustering? = nil

    private var currentFloor: SITFloor? = nil
    private var selectedPoi: SITPOI? = nil
    
    init(
        mapView: GMSMapView,
        buildingManager: BuildingManager,
        iconsStore: IconsStore,
        showPoiNames: Bool,
        isClusteringEnabled: Bool
    ) {
        self.mapView = mapView
        self.buildingManager = buildingManager
        self.showPoiNames = showPoiNames
        self.iconsStore = iconsStore
        if isClusteringEnabled {
            markerClustering = GoogleMapsMarkerClustering(mapView: mapView)
        }
        self.buildingManager.addDelegate(self)
    }
    
    func displayPoiMarkers(forFloor floor: SITFloor) {
        currentFloor = floor
        removeMarkers()
        var poisInFloor = buildingManager.filterPoisByCategories().filter(by: floor)
        poisInFloor = preserveSelectedPoi(pois: poisInFloor, floor: floor)

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
            selectMarkerIfIsSelectedPoi(marker: marker, poi: poi)
        }
    }

    private func preserveSelectedPoi(pois: [SITPOI], floor: SITFloor) -> [SITPOI] {
        guard let selectedPoi = selectedPoi else { return pois }
        var innerPois = pois
        if selectedPoi.belongs(to: floor) && !innerPois.contains(selectedPoi) {
            innerPois.append(selectedPoi)
        }
        return innerPois
    }

    private func selectMarkerIfIsSelectedPoi(marker: SitumMarker, poi: SITPOI) {
        if let selectedPoi = selectedPoi, selectedPoi.identifier == poi.identifier {
            selectMarker(marker)
        }
    }
    
    func displayLongPressMarker(_ marker: SitumMarker, forFloor floor: SITFloor) {
        if floor.identifier == marker.floorIdentifier {
            markers.append(marker)
            selectMarker(marker)
        }
    }
    
    func displayCustomMarker(_ marker: SitumMarker, forFloor floor: SITFloor) {
        if floor.identifier == marker.floorIdentifier {
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
    
    func displayOnlyDestinationMarker(_ marker: SitumMarker, forFloor floor: SITFloor) {
        removeMarkers()
        if let markerCluster = markerClustering {
            if floor.identifier == marker.floorIdentifier {
                markerCluster.add(marker)
                markerCluster.display()
            }
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
    
    func selectGMSClusterMarker(_ marker: GMSMarker) {
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
            selectedPoi = marker.poi
        } else if marker.isLongPressMarker {
            selectMarkerInGoogleMaps(marker: marker)
        } else if marker.isCustomMarker {
            loadIcon(forMarker: marker, selected: true) { [weak self] marker in
                self?.selectMarkerInGoogleMaps(marker: marker)
            }
        }
    }
    
    func isClusterGMSMarker(_ marker: GMSMarker) -> Bool {
        return isClusteringEnabled && marker.userData is GMUCluster
    }

    func deselectMarker(_ marker: SitumMarker) {
        if (marker.isPoiMarker || marker.isCustomMarker) {
            loadIcon(forMarker: marker, selected: false) { [weak self] marker in
                if let map = self?.mapView, marker.gmsMarker == map.selectedMarker {
                    // deselect poi if it is the one selected, otherwise since loadIcon is async
                    // we could be deselecting another poi that was selected during the load of the icon
                    self?.deselectMarkerFromGoogleMaps(marker: marker)
                }
            }
        } else if marker.isLongPressMarker {
            removeMarkerFromGoogleMaps(marker: marker)
            markers = markers.filter { element in element != marker }
        }
        selectedPoi = nil
        removeMarkerIfPoiIsFiltered(marker)
    }
    
    private func selectMarkerInGoogleMaps(marker: SitumMarker) {
        insertMarkerInGoogleMaps(marker: marker)
        mapView.selectedMarker = marker.gmsMarker
    }
    
    private func insertMarkerInGoogleMaps(marker: SitumMarker) {
        if marker.gmsMarker.map == nil {
            marker.setMapView(mapView: mapView)
            marker.gmsMarker.zIndex = ZIndices.poiMarker
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

    private func removeMarkerIfPoiIsFiltered(_ marker: SitumMarker) {
        guard let poi = marker.poi, let currentFloor = currentFloor else { return }
        if !buildingManager.hasCategoryIdInFilters(poi.categoryIdentifier) {
            displayPoiMarkers(forFloor: currentFloor)
        }
    }

    /**
     Load the poi icon from the server for given marker
     - Parameters:
       - marker: marker to get icon for
       - selected: if the icon will be load with selected or deselected state
       - iconLoaded: Return the marker with the icon loaded inside
     */
    private func loadIcon(forMarker marker: SitumMarker, selected: Bool, iconLoaded: ((SitumMarker) -> ())? = nil) {
        if (marker.isPoiMarker) {
            
            guard let poi = marker.poi else { return }
            // do not load images for markers that are not currently rendered (internal array)
            // also, ensure the marker is a reference to internal array of SitumMarker
            guard let marker = searchMarker(byPoi: poi) else { return }
            let showPoiNames = showPoiNames
            
            iconsStore.obtainIconFor(category: poi.category) { items in
                guard var icon = selected ? items?[1] : items?[0] else {
                    Logger.logDebugMessage("Icon from server could not be retrieved")
                    return
                }
                
                icon = ImageUtils.scaleImageToSize(image: icon, newSize: CGSize(width: 45, height: 45))
                
                let color = UIColor(hex: "#5b5b5bff") ?? UIColor.gray
                let title = poi.name
                if showPoiNames {
                    marker.gmsMarker.icon = icon.setTitle(title: title, size: 16.0, color: color, weight: .bold)
                } else {
                    marker.gmsMarker.icon = icon
                }
                iconLoaded?(marker)
            }
        } else if (marker.isCustomMarker) {
            guard let customPoi = marker.customPoi else { return }
            let markerImage = customPoi.getMarkerSelectedImage() == nil ? customPoi.getMarkerImage() : selected ? customPoi.getMarkerSelectedImage() : customPoi.getMarkerImage()
            let color = UIColor(hex: "#5b5b5bff") ?? UIColor.gray
            if (markerImage != nil) {
                let icon = ImageUtils.scaleImageToSize(image: markerImage!, newSize: CGSize(width: 45, height: 45))
                if (showPoiNames && customPoi.name != nil) {
                    marker.gmsMarker.icon = icon.setTitle(title: customPoi.name!, size: 16.0, color: color, weight: .bold)
                } else {
                    marker.gmsMarker.icon = icon
                }
                iconLoaded?(marker)
            } else {
                iconLoaded?(marker)
            }
        }
    }
    
    func searchMarker(byGMSMarker gmsMarker: GMSMarker) -> SitumMarker? {
        return markers.first(where: { poiMarker in poiMarker.gmsMarker == gmsMarker })
    }
    
    func searchMarker(byPoi searchedPoi: SITPOI) -> SitumMarker? {
        return markers.first { marker in
            guard let poi = marker.poi else { return false }
            return poi.id == searchedPoi.id
        }
    }
    
    func searchCustomMarker(customPoiId: Int) -> SitumMarker? {
        return markers.first(where: { marker in marker.isCustomMarker && marker.customPoi?.id == customPoiId})
    }
}

extension MarkerRenderer: BuildingManagerDelegate {
    func poiFiltersByCategoriesWereUpdated() {
        if let floor = currentFloor {
            displayPoiMarkers(forFloor: floor)
        }
    }
}

//
//  PoiMarker.swift
//  SitumWayfinding
//
//  Created by fsvilas on 4/1/22.
//

import Foundation
import GoogleMaps
import SitumSDK

struct SitumMarker: Equatable {
    
    // TODO JLAQ enum for marker type
    
    private(set) var gmsMarker: GMSMarker
    private(set) var poi: SITPOI?
    private(set) var custom = false
    var title: String { return gmsMarker.title ?? "" }
    private(set) var floorIdentifier: String
    var isPoiMarker: Bool { return poi != nil }
    var isLongPressMarker: Bool { return custom == false && poi == nil }
    var isCustomMarker: Bool { return custom }
    var isTopLevel: Bool {
        guard let poi = poi, let topLevelField = poi.customFields["top_level"] as? String else { return false }
        return topLevelField.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == "true"
    }
    
    init(_ poi: SITPOI) {
        let coordinate = poi.position().coordinate()
        floorIdentifier = poi.position().floorIdentifier
        let gmsMarker = GMSMarker(position: coordinate)
        //gmsMarker.title = poi.name // Hide title when selecting poi
        self.poi = poi
        self.gmsMarker = gmsMarker

        self.gmsMarker.markerData = SitumMarkerData(
            floorIdentifier: floorIdentifier,
            isPoiMarker: isPoiMarker,
            isLongPressMarker: isLongPressMarker,
            isTopLevel: isTopLevel
        )
    }
    
    // TODO JLAQ change arguments and default values
    init(coordinate: CLLocationCoordinate2D, floor: SITFloor, custom: Bool = false, title: String? = nil, id: String? = nil) {
        let marker: GMSMarker = GMSMarker(position: coordinate)
        // TODO JLAQ change title
        if (title != nil) {
            marker.title = title
        } else {
            marker.title = NSLocalizedString(
                "positioning.customDestination",
                bundle: SitumMapsLibrary.bundle,
                comment: "Shown to user when select a destination (destination is any free point that user selects on the map)"
            )
        }
        gmsMarker = marker
        floorIdentifier = floor.identifier
        self.custom = custom
        if (id != nil) {
            poi = SITPOI(identifier: id ?? "", createdAt: Date(), updatedAt: Date(), customFields: [:])
        }
    }
    
    func setMapView(mapView: GMSMapView?) {
        gmsMarker.map = mapView
    }
    
    static func ==(lhs: SitumMarker, rhs: SitumMarker) -> Bool {
        //Sometimes the pois are the same but the maker differ
        //TODO understand why
        return lhs.gmsMarker == rhs.gmsMarker ||
            (lhs.isPoiMarker && lhs.poi?.id == rhs.poi?.id)
    }
}

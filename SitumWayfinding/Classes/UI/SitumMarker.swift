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
    private(set) var gmsMarker: GMSMarker
    private(set) var poi: SITPOI?
    var title: String { return gmsMarker.title ?? "" }
    private(set) var floorIdentifier: String
    var isPoiMarker: Bool { return poi != nil }
    var isCustomMarker: Bool { return poi == nil }
    
    init(_ poi: SITPOI) {
        let coordinate = poi.position().coordinate()
        let gmsMarker = GMSMarker(position: coordinate)
        //gmsMarker.title = poi.name // Hide title when selecting poi
        self.poi = poi
        self.gmsMarker = gmsMarker
        floorIdentifier = poi.position().floorIdentifier
    }
    
    init(coordinate: CLLocationCoordinate2D, floor: SITFloor) {
        let marker: GMSMarker = GMSMarker(position: coordinate)
        marker.title = NSLocalizedString(
            "positioning.customDestination",
            bundle: SitumMapsLibrary.bundle,
            comment: "Shown to user when select a destination (destination is any free point that user selects on the map)"
        )
        gmsMarker = marker
        floorIdentifier = floor.identifier
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

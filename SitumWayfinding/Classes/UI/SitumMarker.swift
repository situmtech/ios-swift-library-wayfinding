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
    var floorIdentifier: String {
        if let poi = poi {
            return poi.position().floorIdentifier
        } else {
            return gmsMarker.userData as! String
        }
    }
    
    init(from marker: GMSMarker) {
        gmsMarker = marker
        if let poi = marker.userData as? SITPOI {
            self.poi = poi
        }
    }
    
    init(from marker: GMSMarker, in floor: SITFloor) {
        gmsMarker = marker
        gmsMarker.userData = floor.identifier
    }
    
    func setMapView(mapView: GMSMapView?) {
        gmsMarker.map = mapView
    }
    
    func isPoiMarker() -> Bool {
        return !(poi == nil)
    }
    
    static func ==(lhs: SitumMarker, rhs: SitumMarker) -> Bool {
        //Sometimes the pois are the same but the maker differ
        //TODO understand why
        return lhs.gmsMarker == rhs.gmsMarker ||
            (lhs.isPoiMarker() && lhs.poi?.id == rhs.poi?.id)
    }
}

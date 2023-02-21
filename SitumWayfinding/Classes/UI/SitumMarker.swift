//
//  PoiMarker.swift
//  SitumWayfinding
//
//  Created by fsvilas on 4/1/22.
//

import Foundation
import GoogleMaps
import SitumSDK

enum SitumMarkerType {
    case poiMarker
    case longPressMarker
    case customPoiMarker
}

struct SitumMarker: Equatable {
    private(set) var gmsMarker: GMSMarker
    private(set) var poi: SITPOI?
    private(set) var customPoi: CustomPoi?
    private(set) var markerType: SitumMarkerType = SitumMarkerType.poiMarker
    var title: String { return gmsMarker.title ?? "" }
    private(set) var floorIdentifier: String
    
    var isPoiMarker: Bool { return self.markerType == SitumMarkerType.poiMarker }
    var isLongPressMarker: Bool { return self.markerType == SitumMarkerType.longPressMarker }
    var isCustomMarker: Bool { return self.markerType == SitumMarkerType.customPoiMarker }

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
    
    init(customPoi: CustomPoi) {
        let marker: GMSMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: customPoi.latitude, longitude: customPoi.longitude))
        gmsMarker = marker
        floorIdentifier = customPoi.floorId
        self.customPoi = customPoi
        markerType = SitumMarkerType.customPoiMarker
    }
    
    init(coordinate: CLLocationCoordinate2D, floor: SITFloor, markerType: SitumMarkerType, title: String? = nil, id: String? = nil, image: UIImage? = nil) {
        let marker: GMSMarker = GMSMarker(position: coordinate)
        
        if (image != nil) {
            marker.icon = ImageUtils.scaleImageToSize(image: image!, newSize: CGSize(width: 45, height: 45))
        }
        
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
        self.markerType = markerType
        if (id != nil) {
            poi = SITPOI(identifier: id ?? "", createdAt: Date(), updatedAt: Date(), customFields: [:])
            poi!.name = title!
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

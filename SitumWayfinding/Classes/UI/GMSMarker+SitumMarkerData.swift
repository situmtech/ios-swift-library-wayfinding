//
// Created by Lapisoft MacPro on 21/10/22.
//

import Foundation
import GoogleMaps
import SitumSDK

extension GMSMarker {
    func getMarkerData() -> SitumMarkerData? {
        return userData as? SitumMarkerData
    }

    func setMarkerData(_ data: SitumMarkerData) {
        userData = data
    }
}

struct SitumMarkerData {
    var floorIdentifier: String
    var isPoiMarker: Bool
    var isCustomMarker: Bool
    var isTopLevel: Bool
}

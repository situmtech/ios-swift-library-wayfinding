//
// Created by Lapisoft MacPro on 21/10/22.
//

import Foundation
import GoogleMaps
import SitumSDK

extension GMSMarker {
    var markerData: SitumMarkerData? {
        get { return userData as? SitumMarkerData }
        set { userData = newValue }
    }
}

struct SitumMarkerData {
    var floorIdentifier: String
    var isPoiMarker: Bool
    var isLongPressMarker: Bool
    var isTopLevel: Bool
}

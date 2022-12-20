//
// Created by Lapisoft MacPro on 19/12/22.
//

import Foundation
import SitumSDK

extension SITFloor {
    var floorUILabel: String {
        if name != "" {
            return "\(NSLocalizedString("search.floor", bundle: SitumMapsLibrary.bundle, comment: "")) \(name)"
        } else {
            return "\(NSLocalizedString("search.floor", bundle: SitumMapsLibrary.bundle, comment: "")) \(floor)"
        }
    }
}
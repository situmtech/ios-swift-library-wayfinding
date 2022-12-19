//
// Created by Lapisoft MacPro on 19/12/22.
//

import Foundation
import SitumSDK

extension SITFloor {
    /**
     Description of floor, if the floor has a name show this name otherwise show the Numeric value representating
     the ground level.
    */
    open override var description: String {
        if name != "" {
            return "\(NSLocalizedString("search.floor", bundle: SitumMapsLibrary.bundle, comment: "")) \(name)"
        } else {
            return "\(NSLocalizedString("search.floor", bundle: SitumMapsLibrary.bundle, comment: "")) \(floor)"
        }
    }
}
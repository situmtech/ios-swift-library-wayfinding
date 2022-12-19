//
// Created by Lapisoft MacPro on 19/12/22.
//

import Foundation
import SitumSDK

extension SITBuildingInfo {
    func buildingFloorDescription(_ floor: SITFloor) -> String {
        return "\(building.name) / \(floor.description)"
    }
}
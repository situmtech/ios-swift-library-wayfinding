//
// Created by Lapisoft MacPro on 19/12/22.
//

import Foundation
import SitumSDK

extension SITBuildingInfo {
    func buildingFloorUILabel(_ floor: SITFloor) -> String {
        return "\(building.name) / \(floor.floorUILabel)"
    }

    func floorWith(floorIdentifier: String) -> SITFloor? {
        return floors.first(where: { $0.identifier == floorIdentifier })
    }
}
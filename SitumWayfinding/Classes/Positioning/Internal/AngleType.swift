//
//  AngleType.swift
//  SitumMappingTool
//
//  Created by Cristina Sánchez Barreiro on 11/04/2019.
//  Copyright © 2019 Situm Technologies S.L. All rights reserved.
//

import Foundation
import SitumSDK

enum AngleType: Int {
    case angleZero = 0
    case angleRight = 90
    case anglePlain = 180
    case angleConcave = 270
    
    func value() -> Int{
        return self.rawValue
    }
    
    func toSITAngle() -> SITAngle{
        return SITAngle(degrees: Float(self.value()))
    }
    
}

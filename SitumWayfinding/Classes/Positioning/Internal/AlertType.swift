//
//  AlertType.swift
//  SitumMappingTool
//
//  Created by Cristina Sánchez Barreiro on 09/04/2019.
//  Copyright © 2019 Situm Technologies S.L. All rights reserved.
//

import Foundation

enum AlertType: Int {
    case compassCalibrationNeeded = 0
    case outOfBuilding = 1
    case outsideRoute = 2
    
    func value() -> Int{
        return self.rawValue
    }
    
}

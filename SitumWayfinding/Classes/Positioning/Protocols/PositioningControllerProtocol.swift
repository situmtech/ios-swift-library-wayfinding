//
//  PositioningControllerProtocol.swift
//  SitumWayfinding
//
//  Created by Adrián Rodríguez on 18/06/2019.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//

import Foundation
import GoogleMaps

protocol PositioningController {
    
    var buildingId: String { get set }    
    func getGoogleMap() -> GMSMapView?
}

//
//  CustomMarkerPosition.swift
//  SitumWayfinding
//
//  Created by Jose Alvarez on 6/2/23.
//

import Foundation

struct CustomPoi: Codable {
    let key: String
    let buildingId: String
    let floorId: String
    let latitude: Double
    let longitude: Double
}

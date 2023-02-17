//
//  CustomMarkerPosition.swift
//  SitumWayfinding
//
//  Created by Jose Alvarez on 6/2/23.
//

import Foundation

public struct CustomPoi: Codable {
    let key: String
    public let name: String?
    public let description: String?
    public let buildingId: String
    public let floorId: String
    public let latitude: Double
    public let longitude: Double
}

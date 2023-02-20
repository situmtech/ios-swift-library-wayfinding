//
//  CustomPoi.swift
//  SitumWayfinding
//
//  Created by Jose Alvarez on 6/2/23.
//

import Foundation

/// Object that represents a custom POI saved by the user 
public struct CustomPoi: Codable {
    let key: String
    /// Name of the poi
    public let name: String?
    /// Description of the poi
    public let description: String?
    /// ID of the building where this POI is placed
    public let buildingId: String
    /// ID of the floor where this POI is placed
    public let floorId: String
    /// Latitude of the poi
    public let latitude: Double
    /// Longitude of the poi
    public let longitude: Double
}

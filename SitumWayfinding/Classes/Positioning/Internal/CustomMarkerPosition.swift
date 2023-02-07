//
//  CustomMarkerPosition.swift
//  SitumWayfinding
//
//  Created by Jose Alvarez on 6/2/23.
//

import Foundation

struct CustomMarkerPosition: Codable {
    let key: String
    let buildingId: String
    let floorId: String
    let latitude: Double
    let longitude: Double
//    let position: SITPoint
    
//    private enum CodingKeys: String, CodingKey {
//        case key
//        case position_lat
//        case position_lng
//        case position_floor_id
//        case position_building_id
//   }
//
//    init(key: String, position: SITPoint) {
//        self.key = key
//        self.position = position
//    }
//
//
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.key = try container.decode(String.self, forKey: .key)
//        let buildingId = try container.decode(String.self, forKey: .position_building_id)
//        let floorId = try container.decode(String.self, forKey: .position_floor_id)
//        let latitude = try container.decode(Double.self, forKey: .position_lat)
//        let longitude = try container.decode(Double.self, forKey: .position_lng)
//
//        self.position = SITPoint(building: buildingId, floorIdentifier: floorId, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
//    }
//
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(self.key, forKey: .key)
//        try container.encode("position_building_id", forKey: .position_building_id)
//        try container.encode("position_floor_id", forKey: .position_floor_id)
//        try container.encode("position_lat", forKey: .position_lat)
//        try container.encode("position_lng", forKey: .position_lng)
//    }
    
}

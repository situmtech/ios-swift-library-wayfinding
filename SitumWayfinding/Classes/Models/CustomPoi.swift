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
    let markerImageData: Data?
    let markerSelectedImageData: Data?
    
    public init(key: String, name: String?, description: String?, buildingId: String, floorId: String, latitude: Double, longitude: Double) {
        self.key = key
        self.name = name
        self.description = description
        self.buildingId = buildingId
        self.floorId = floorId
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(key: String, name: String?, description: String?, buildingId: String, floorId: String, latitude: Double, longitude: Double, markerImage: UIImage? = nil, markerSelectedImage: UIImage? = nil) {
        self.key = key
        self.name = name
        self.description = description
        self.buildingId = buildingId
        self.floorId = floorId
        self.latitude = latitude
        self.longitude = longitude
        self.markerImageData = markerImage?.pngData()
        self.markerSelectedImageData = markerSelectedImage?.pngData()
    }
    
    func getMarkerImage() -> UIImage? {
        if (self.markerImageData != nil) {
            return UIImage(data: self.markerImageData!)
        }
        return nil
    }
    
    func getMarkerSelectedImage() -> UIImage? {
        if (markerSelectedImageData != nil) {
            return UIImage(data: markerSelectedImageData!)
        }
        return nil
    }

}

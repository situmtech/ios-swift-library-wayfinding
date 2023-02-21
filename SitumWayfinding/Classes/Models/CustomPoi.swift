//
//  CustomPoi.swift
//  SitumWayfinding
//
//  Created by Jose Alvarez on 6/2/23.
//

import Foundation

/// Object that represents a custom POI saved by the user 
public struct CustomPoi: Codable {
    public private(set) var key: String
    /// Name of the poi
    public private(set) var name: String?
    /// Description of the poi
    public private(set) var description: String?
    /// ID of the building where this POI is placed
    public private(set) var buildingId: String
    /// ID of the floor where this POI is placed
    public private(set) var floorId: String
    /// Latitude of the poi
    public private(set) var latitude: Double
    /// Longitude of the poi
    public private(set) var longitude: Double
    public private(set) var markerImageData: Data?
    public private(set) var markerSelectedImageData: Data?
    
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

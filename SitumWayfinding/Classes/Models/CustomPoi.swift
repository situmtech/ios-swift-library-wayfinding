//
//  CustomPoi.swift
//  SitumWayfinding
//
//  Created by Jose Alvarez on 6/2/23.
//

import Foundation

/// Object that represents a custom POI saved by the user 
public struct CustomPoi: Codable {
    /// Unique key of the poi
    public private(set) var id: Int
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
    /// Image data of the marker when not selected
    public private(set) var markerImageData: Data?
    /// Image data of the marker when selected
    public private(set) var markerSelectedImageData: Data?
    
    init(key: Int, name: String?, description: String?, buildingId: String, floorId: String, latitude: Double, longitude: Double, markerImage: UIImage? = nil, markerSelectedImage: UIImage? = nil) {
        self.id = key
        self.name = name
        self.description = description
        self.buildingId = buildingId
        self.floorId = floorId
        self.latitude = latitude
        self.longitude = longitude
        self.markerImageData = markerImage?.pngData()
        self.markerSelectedImageData = markerSelectedImage?.pngData()
    }
    
    /// Get custom poi image as UIImage
    public func getMarkerImage() -> UIImage? {
        if (self.markerImageData != nil) {
            return UIImage(data: self.markerImageData!)
        }
        return nil
    }
    
    /// Get custom poi selected image as UIImage
    public func getMarkerSelectedImage() -> UIImage? {
        if (markerSelectedImageData != nil) {
            return UIImage(data: markerSelectedImageData!)
        }
        return nil
    }

}

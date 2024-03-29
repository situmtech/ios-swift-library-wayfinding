//
//  CustomPoi.swift
//  SitumWayfinding
//
//  Created by Jose Alvarez on 6/2/23.
//

import Foundation


struct CustomPoiImpl: CustomPoi, Codable {
    /// Unique key of the poi
    private(set) var id: Int
    /// Name of the poi
    private(set) var name: String?
    /// Description of the poi
    private(set) var description: String?
    /// ID of the building where this POI is placed
    private(set) var buildingId: String
    /// ID of the floor where this POI is placed
    private(set) var floorId: String
    /// Latitude of the poi
    private(set) var latitude: Double
    /// Longitude of the poi
    private(set) var longitude: Double
    /// Image data of the marker when not selected
    private(set) var markerImageData: Data?
    /// Image data of the marker when selected
    private(set) var markerSelectedImageData: Data?
    
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
    func getMarkerImage() -> UIImage? {
        if (self.markerImageData != nil) {
            return UIImage(data: self.markerImageData!)
        }
        return nil
    }
    
    /// Get custom poi selected image as UIImage
    func getMarkerSelectedImage() -> UIImage? {
        if (markerSelectedImageData != nil) {
            return UIImage(data: markerSelectedImageData!)
        }
        return nil
    }
    
    func getName() -> String? {
        return self.name
    }
    
    func getId() -> Int {
        return self.id
    }
    
    func getDescription() -> String? {
        return self.description
    }
    
    func getLevelId() -> Int {
        return Int(self.floorId) ?? -1
    }
    
    func getBuildingId() -> Int {
        return Int(self.buildingId) ?? -1
    }
    
    func toMap() -> [String : Any] {
        let customPoiDict: [String: Any] = [
            "id": self.getId(),
            "name": self.getName(),
            "description": self.getDescription(),
            "buildingId": self.getBuildingId(),
            "levelId": self.getLevelId(),
            "coordinates": [
                "latitude": self.latitude,
                "longitude": self.longitude,
                
            ]
        ]
        return customPoiDict
        
    }
    
    
    
}

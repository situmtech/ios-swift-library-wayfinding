//
//  CustomMarkerPosition.swift
//  SitumWayfinding
//
//  Created by Jose Alvarez on 6/2/23.
//

import Foundation


class CustomPoiManager {
    let customMarkerKeyPrefix = "custom_position_";
    
    private func getStorageCustomKey(poiKey: Int) -> String {
        return "\(self.customMarkerKeyPrefix)\(poiKey)"
    }
    
    func get(poiKey: Int) -> CustomPoi? {
        let customPoiStorageKey = self.getStorageCustomKey(poiKey: poiKey)
        if let data = UserDefaults.standard.data(forKey: customPoiStorageKey) {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(CustomPoi.self, from: data)

            } catch {
                print("Unable to Decode Position (\(error))")
            }
        }
        return nil
    }
    
    func remove(poiKey: Int) {
        let customPoiStorageKey = self.getStorageCustomKey(poiKey: poiKey)
        UserDefaults.standard.removeObject(forKey: customPoiStorageKey)
    }
    
    
    func store(customPoi: CustomPoi) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(customPoi)
            
            let customPoiStorageKey = self.getStorageCustomKey(poiKey: customPoi.id)
            UserDefaults.standard.set(data, forKey: customPoiStorageKey)
        } catch {
            print("Unable to Encode Position (\(error))")
        }
    }
    
}

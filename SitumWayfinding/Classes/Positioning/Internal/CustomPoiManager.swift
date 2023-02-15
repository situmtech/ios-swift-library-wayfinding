import Foundation


class CustomPoiManager {
    let customMarkerKeyPrefix = "custom_position_";
    
    private func getStorageCustomKey(poiKey: String) -> String {
        return "\(self.customMarkerKeyPrefix)\(poiKey)"
    }
    
    func get(poiKey: String) -> CustomPoi? {
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
    
    func remove(poiKey: String) {
        let customPoiStorageKey = self.getStorageCustomKey(poiKey: poiKey)
        UserDefaults.standard.removeObject(forKey: customPoiStorageKey)
    }
    
    
    func store(customPoi: CustomPoi) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(customPoi)
            
            let customPoiStorageKey = self.getStorageCustomKey(poiKey: customPoi.key)
            UserDefaults.standard.set(data, forKey: customPoiStorageKey)
        } catch {
            print("Unable to Encode Position (\(error))")
        }
    }
    
}

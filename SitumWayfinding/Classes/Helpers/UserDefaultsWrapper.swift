//
//  UserDefaultsWrapper.swift
//  SitumMappingTool
//
//  Created by Cristina Sánchez Barreiro on 11/04/2019.
//  Copyright © 2019 Situm Technologies S.L. All rights reserved.
//

import Foundation
import SitumSDK

class UserDefaultsWrapper {
    
    static func getAccessibilityMode() -> SITAccessibilityMode {
        let accessibilityInt = UserDefaults.standard.integer(forKey: "accessibility_mode")
        return {
            switch accessibilityInt {
            case 0:
                return .chooseShortest
            case 1:
                return .onlyAccessible
            case 2:
                return .onlyNotAccessibleFloorChanges
            default:
                return .chooseShortest
            }
            }()
    }
    
    static func getUseGps() -> Bool{
        return UserDefaults.standard.bool(forKey: "use_gps")
    }
    
    static func getUseBarometer() -> Bool {
        return UserDefaults.standard.bool(forKey: "use_barometer")
    }
    
    static func getSingleBuildingMode() -> Bool {
        return UserDefaults.standard.bool(forKey: "single_building_mode")
    }
    
    /** Return true if app should use fake locations, false if situm positioning is used */
    static func getUseFakeLocations() -> Bool {
        return UserDefaults.standard.bool(forKey: "fake_locations") // false by default if value is absent
    }
    
    static func setUseFakeLocations(useFakeLocation: Bool) {
        UserDefaults.standard.set(useFakeLocation, forKey: "fake_locations")
    }
    
    static func getInterval() -> Int {
        return Int (UserDefaults.standard.float(forKey: "interval") * 1000)
    }
    
    static func getSmallestDisplacement() -> Float {
        return UserDefaults.standard.float(forKey: "smallest_displacement")
    }
    
    static internal func getCredentialsFromPlist() -> Credentials {
        let user: String = getValueFromPlist(withKey: "es.situm.sdk.API_USER")
        let apiKey: String = getValueFromPlist(withKey: "es.situm.sdk.API_KEY")
        let googleMapsApiKey: String = getValueFromPlist(withKey: "com.google.android.geo.API_KEY")
        
        return Credentials(user: user, apiKey: apiKey, googleMapsApiKey: googleMapsApiKey)
    }
    
    static internal func getActiveBuildingFromPlist() -> String {
        return getValueFromPlist(withKey: "es.situm.sdk.ACTIVE_BUILDING_ID")
    }
    
    static internal func getValueFromPlist(withKey key: String) -> String {
        var value: String?
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            if let plistDictionary = NSDictionary(contentsOfFile: path) {
                value = plistDictionary.object(forKey: key) as? String
            }
        }
        return value ?? ""
    }
}

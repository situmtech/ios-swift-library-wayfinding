//
//  LibrarySettings.swift
//  SitumWayfinding
//
//  Created by Situm on 3/2/21.
//

import Foundation
import GoogleMaps

/**
 Situm Maps initialization settings
 
 Use this class to customize the preferences of WayfindingLibrary
 */
@objc public class LibrarySettings: NSObject {
    
    private(set) var credentials: Credentials?
    private(set) var buildingId: String? = ""
    private(set) var useDashboardTheme: Bool = true
    private(set) var googleMap: GMSMapView?
    
    
    // private(set) var orgDetails: OrganizationTheme?
    private override init() {
        
    }
    
    
    
    
    // MARK: - Builder
    /**
     Helper class to create instances on LibrarySettings object
     */
    @objc public class Builder: NSObject {
        
        private var instance: LibrarySettings = LibrarySettings()
        
        @discardableResult
        @objc public func setCredentials(credentials: Credentials) -> Builder {
            instance.credentials = credentials
            return self
        }
        
        @discardableResult
        @objc public func setBuildingId(buildingId: String) -> Builder {
            instance.buildingId = buildingId
            return self
        }
        
        @discardableResult
        @objc public func setUseDashboardTheme(useDashboardTheme: Bool) -> Builder {
            instance.useDashboardTheme = useDashboardTheme
            return self
        }
        
        @discardableResult
        @objc public func setGoogleMap(googleMap: GMSMapView) -> Builder {
            instance.googleMap = googleMap
            return self
        }
        
        @objc public func build() -> LibrarySettings {
            return instance
        }
        
        @objc internal func copy(settings: LibrarySettings ) -> Builder {
            let builderCopy = Builder()
            
            if settings.credentials != nil {
                builderCopy.setCredentials(credentials: settings.credentials!)
            }
            
            if settings.buildingId != nil {
                builderCopy.setBuildingId(buildingId: settings.buildingId!)
            }
            
            if settings.googleMap != nil {
                builderCopy.setGoogleMap(googleMap: settings.googleMap!)
            }

            builderCopy.setUseDashboardTheme(useDashboardTheme: settings.useDashboardTheme)

            return builderCopy
        }
    }
}



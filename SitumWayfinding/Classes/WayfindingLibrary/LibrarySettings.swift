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
    
    /// Credentials object
    private(set) var credentials: Credentials?
    /// String containing the identifier of the building to load
    private(set) var buildingId: String? = ""
    /// Boolean that indicates if the module should customize its appeareance based on user theme
    private(set) var useDashboardTheme: Bool = true
    /// Google map view if set by outside world
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
        
        /// Establish credentials. Following the builder pattern it returns an object to itself.
        @discardableResult
        @objc public func setCredentials(credentials: Credentials) -> Builder {
            instance.credentials = credentials
            return self
        }
        
        /// Establish building identifier. Following the builder pattern it returns an object to itself.
        @discardableResult
        @objc public func setBuildingId(buildingId: String) -> Builder {
            instance.buildingId = buildingId
            return self
        }

        /// Establish if customization is needed. Following the builder pattern it returns an object to itself.
        @discardableResult
        @objc public func setUseDashboardTheme(useDashboardTheme: Bool) -> Builder {
            instance.useDashboardTheme = useDashboardTheme
            return self
        }
        
        /// Establish google map object. Following the builder pattern it returns an object to itself.
        @discardableResult
        @objc public func setGoogleMap(googleMap: GMSMapView) -> Builder {
            instance.googleMap = googleMap
            return self
        }
        
        /// Returns an instance of LibrarySettings
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



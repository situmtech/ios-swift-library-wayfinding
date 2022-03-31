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
    /// Icon map position
    private(set) var userPositionIcon: String? = ""
    /// Icon for arrow position
    private(set) var userPositionArrowIcon: String? = ""
    /// Text that will be used as placeholder in the search view component.
    private(set) var searchViewPlaceholder: String? = ""
    /// Boolean to configure if location system should use the remote configuration (true) or not (false). See https://situm.com/docs/07-remote-configuration/ to learn more on how to use this functionality.
    private (set) var useRemoteConfig: Bool = false
    
    /// Boolean that configure if the name of the POIs is shown above its icons when painting them on the map
    private (set) var showPoiNames: Bool? = false
    
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

        /// Establish if user configure icon position
        @discardableResult
        @objc public func setUserPositionIcon(userPositionIcon: String) -> Builder {
            instance.userPositionIcon = userPositionIcon
            return self
        }

        /// Establish if user configure arrow icon position
        @discardableResult
        @objc public func setUserPositionArrowIcon(userPositionArrowIcon: String) -> Builder {
            instance.userPositionArrowIcon = userPositionArrowIcon
            return self
        }
        
        /// Set the text that will be used as placeholder in the search view component.
        @discardableResult
        @objc public func setSearchViewPlaceholder(searchViewPlaceholder: String) -> Builder {
            instance.searchViewPlaceholder = searchViewPlaceholder
            return self
        }
        
        /// Establish the usage of remote configuration to initialize the location system (customizable in dashboard)
        @discardableResult
        @objc public func setUseRemoteConfig(useRemoteConfig: Bool) -> Builder {
            instance.useRemoteConfig = useRemoteConfig
            return self
        }
        
        /// Boolean that configure if the name of the POIs is shown above its icons when painting them on the map
        @discardableResult
        @objc public func setShowPoiNames(showPoiNames: Bool) -> Builder {
            instance.showPoiNames = showPoiNames
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

            if settings.userPositionIcon != nil {
                builderCopy.setUserPositionIcon(userPositionIcon: settings.userPositionIcon!)
            }

            if settings.userPositionArrowIcon != nil {
                builderCopy.setUserPositionArrowIcon(userPositionArrowIcon: settings.userPositionArrowIcon!)
            }
            
            if settings.searchViewPlaceholder != nil {
                builderCopy.setSearchViewPlaceholder(searchViewPlaceholder: settings.searchViewPlaceholder!)
            }
            
            if settings.useRemoteConfig != nil {
                builderCopy.setUseRemoteConfig(useRemoteConfig: settings.useRemoteConfig)
            }

            builderCopy.setShowPoiNames(showPoiNames: settings.showPoiNames ?? false)

            return builderCopy
        }
    }
}

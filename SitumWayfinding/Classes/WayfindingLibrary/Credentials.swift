//
//  Credentials.swift
//  SitumWayfinding
//
//  Created by Adrián Rodríguez on 29/05/2019.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//

import Foundation

/**
 Container class used to provide credentials both for SitumSDK and Google Maps
 */
public class Credentials {
    
    /// Mail of the Situm dashboard user
    public private(set) var user: String
    /// APIKey or password associated with the provided mail
    public private(set) var password: String
    /// APIKey to use GoogleMaps services
    public private(set) var mapsApiKey: String
    /// Boolean indicating if auth for SitumSDK will be done with APIKey or password
    public private(set) var isApiKey: Bool
    
    /**
     Inits a Credentials object with user and APIKEY for SitumSDK and APIKEY for GoogleMaps
     
     - parameter user: Mail of the Situm dashboard user
     - parameter password: Apikey associated with the provided mail
     - parameter googleMapsApiKey: APIKey to use GoogleMaps services
     */
    public init(user: String, apiKey: String, googleMapsApiKey: String) {
        self.user = user
        self.password = apiKey
        self.mapsApiKey = googleMapsApiKey
        self.isApiKey = true
    }
    
    /**
     Inits a Credentials object with user and password for SitumSDK and APIKEY for GoogleMaps
     
     - parameter user: Mail of the Situm dashboard user
     - parameter password: Password associated with the provided mail
     - parameter googleMapsApiKey: APIKey to use GoogleMaps services
     */
    public init(user: String, password: String, googleMapsApiKey: String) {
        self.user = user
        self.password = password
        self.mapsApiKey = googleMapsApiKey
        self.isApiKey = false
    }   
    
}

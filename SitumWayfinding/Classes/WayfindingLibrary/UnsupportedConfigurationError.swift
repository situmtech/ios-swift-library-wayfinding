//
//  UnsupportedConfigurationError.swift
//  SitumWayfinding
//
//  Created by Adrián Rodríguez on 26/06/2019.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//

import Foundation

/**
 This object encapsulates all the possible Error cases that the Wayfinding Library may throw
 */
public enum UnsupportedConfigurationError: Error {
    
    /**
     Error thrown when no credentials are set before loading the wayfinding view
     
     - message: Brief text explaining the reason of the error
     */
    case missingCredentials(message: String)
    
    /**
    Error thrown when the credentials are invalid
    
    - message: Brief text explaining the reason of the error
    */
    case invalidCredentials(message: String)
    
    /**
     Error thrown when the provided ID for the active building is invalid
     
     - message: Brief text explaining the reason of the error
     */
    case invalidActiveBuilding(message: String)
}

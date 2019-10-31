//
//  CredentialsStrategy.swift
//  SitumWayfinding
//
//  Created by Adrián Rodríguez on 29/05/2019.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//

import Foundation
import SitumSDK
import GoogleMaps

protocol Strategy {
    func doCheckCredentials(credentials: Credentials)
}

/**
 Class used to validate credentials both for SitumSDK and Google Maps
 */
internal class CredentialsStrategy {
    
    /**
     Function used to authenticate the user
     
     - parameter credentials: Instance of the class Credentials initialized with the user's auth data
     */
    public static func checkCredentials(credentials: Credentials) {
        let strategy: Strategy = CredentialsStrategy.decideStrategy()
        strategy.doCheckCredentials(credentials: credentials)
    }
    
    private static func decideStrategy() -> Strategy {
        return DefaultStrategy()
    }
}

private class DefaultStrategy: Strategy {
    
    public func doCheckCredentials(credentials: Credentials) {
        SITServices.clearData()
        if(credentials.isApiKey) {
            SITServices.provideAPIKey(credentials.password, forEmail: credentials.user)
        } else {
            SITServices.provideUser(credentials.user, password: credentials.password)
        }
        GMSServices.provideAPIKey(credentials.mapsApiKey)
    }
    
}

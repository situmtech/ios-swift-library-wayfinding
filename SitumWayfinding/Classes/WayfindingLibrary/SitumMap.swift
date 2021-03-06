//
//  SitumMap.swift
//  SitumWayfinding
//
//  Created by Adrián Rodríguez on 18/06/2019.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import SitumSDK

/**
 Protocol implemented by SitumMapsLibrary
 */
public protocol SitumMap {
        
    /**
     Provides the GMSMapView instance used inside the Wayfinding view
     
     - returns: A GMSMapView instance which is the same being used by the Wayfinding controller
     */
    func getGoogleMap() -> GMSMapView?
    
    /**
     Allows setting a closure with a custom exit segue that will be executed when the "Go back" button is pressed.
     You may also include operations to be done before closing the wayfinding view.
     
     - parameter callback: Closure used to perform the exit segue from the wayfinding view
     */
    func setOnBackPressedCallback(_ callback: @escaping (_ sender: Any) -> Void)
    
    /**
     Sets an interceptor to read or modify the location request before is actually used to start positioning
     
     - parameter interceptor: Closure that will be executed with the location request as its parameter before starting the positioning
     */
    func addLocationRequestInterceptor(_ interceptor: @escaping (SITLocationRequest) -> Void)
    
    /**
     Sets an interceptor to read or modify the directions request before is actually used to start guiding
     
     - parameter interceptor: Closure that will be executed with the directions request as its parameter before starting the guidance
     */
    func addDirectionsRequestInterceptor(_ interceptor: @escaping (SITDirectionsRequest) -> Void)
    
    /**
     Sets an interceptor to read or modify the navigation request before is actually used to obtain a route
     
     - parameter interceptor: Closure that will be executed with the navigation request as its parameter before starting the navigation
     */
    func addNavigationRequestInterceptor(_ interceptor: @escaping (SITNavigationRequest) -> Void)
    
}

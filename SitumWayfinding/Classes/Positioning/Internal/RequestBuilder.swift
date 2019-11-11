//
//  RequestBuilder.swift
//  SitumMappingTool
//
//  Created by Cristina Sánchez Barreiro on 11/04/2019.
//  Copyright © 2019 Situm Technologies S.L. All rights reserved.
//

import Foundation
import SitumSDK

class RequestBuilder {
    
    class func buildLocationRequest(buildingId: String) -> SITLocationRequest {
        let request: SITLocationRequest = SITLocationRequest(buildingId: buildingId)
        request.useGps = UserDefaultsWrapper.getUseGps()
        request.useBarometer = UserDefaultsWrapper.getUseBarometer()
        request.useDeadReckoning = true
        #if DEBUG
        request.interval = Int32(UserDefaultsWrapper.getInterval())
        request.smallestDisplacement = UserDefaultsWrapper.getSmallestDisplacement()
        #endif
        return request
        
    }
    
    class func buildDirectionsRequest(userLocation: SITLocation, destination: SITPoint!) -> SITDirectionsRequest {
        Logger.logInfoMessage("Requesting routes to poi")
        let buildingIdentifierCopy = userLocation.position.buildingIdentifier
        let floorIdentifierCopy = userLocation.position.floorIdentifier
        let cartCoordCopy = SITCartesianCoordinate(x: userLocation.position.cartesianCoordinate!.x, y: userLocation.position.cartesianCoordinate!.y)
        let origin = SITPoint(coordinate: CLLocationCoordinate2DMake(userLocation.position.coordinate().latitude, userLocation.position.coordinate().longitude), buildingIdentifier: buildingIdentifierCopy, floorIdentifier: floorIdentifierCopy, cartesianCoordinate: cartCoordCopy)
        origin.name = "My Location"
        
        // We are making a copy so changes do not collide with route request
        let myLocation = SITLocation(timestamp: userLocation.timestamp, position: origin, bearing: userLocation.bearing.degrees(), cartesianBearing: userLocation.cartesianBearing.radians(), quality: userLocation.quality, accuracy: userLocation.accuracy, provider: userLocation.provider)        
        let request: SITDirectionsRequest = SITDirectionsRequest(location: myLocation, withDestination: destination)
        request.setAccessibility(UserDefaultsWrapper.getAccessibilityMode())
        
        return request        
    }
    
    class func buildNavigationRequest(route: SITRoute) -> SITNavigationRequest {
        let request: SITNavigationRequest = SITNavigationRequest(route: route)
        request.distanceToGoalThreshold = 5
        request.distanceToFloorChangeThreshold = 5
        request.distanceToChangeIndicationThreshold = 5
        request.timeToIgnoreUnexpectedFloorChanges = 100000
        return request
    }
}

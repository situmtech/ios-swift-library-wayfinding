//  OnNavigationListener.swift
//  ios-app-wayfindingExample
//
//  Created by Lapisoft on 09/02/2022.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//


import Foundation
import SitumSDK

/**
 Delegate that get notified about navigation events
 */
public protocol OnNavigationChangeListener {
    /**
     Called when a navigation request was made either by user or by the library. Status of navigation object will be
     requested
     - Parameter navigation: navigation object
     */
    func onNavigationRequested(navigation: Navigation)
    /**
     Called when navigation fails due an error. Status of navigation object will be error
     - Parameter error: error that makes navigation fail
     - Parameter navigation: navigation object
     */
    func onNavigationError(error: Error, navigation: Navigation)
    /**
     Called when navigation finishes either by user cancelation or user reaching the destination. Status of navigation
     object will be destinationReached or canceled
     - Parameter navigation: navigation object
     */
    func onNavigationFinished(navigation: Navigation)
}


/**
 Object that contains information about navigation events
 */
public protocol Navigation {
    /**
     Current status of the current navigation
     */
    var status: NavigationStatus { get set }
    /**
     Destination of the current navigation either a SITPOI or a SITPoint
     */
    var destination: Destination { get set }
    /**
     Point of the current destination
     */
    var point: SITPoint { get }
    /**
     If navigation goes towards a POI this holds the identifier of the POI
     */
    var identifier: String? { get }
    /**
     If navigation goes towards a POI this holds the name of the POI
     */
    var name: String? { get }
}

/**
 This represent the destination of a navigation towards a POI or a location
 */
public enum Destination {
    case poi(SITPOI)
    case location(SITPoint)
}

/**
 Current status of the navigation
 */
public enum NavigationStatus {
    case requested
    case error
    case destinationReached
    case canceled
}

internal struct WYFNavigation: Navigation {
    var status: NavigationStatus
    var destination: Destination
    var point: SITPoint {
        switch destination {
        case .poi(let poi):
            return poi.position()
        case .location(let point):
            return point
        }
    }
    var identifier: String?  {
        guard case .poi(let poi) = destination else { return nil }
        return poi.identifier
    }
    var name: String? {
        guard case .poi(let poi) = destination else { return nil }
        return poi.name
    }

    init(status: NavigationStatus, destination: Destination) {
        self.status = status
        self.destination = destination
    }
}

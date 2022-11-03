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
public protocol OnNavigationListener {
    /**
     Called when a navigation request was made either by user or by the library. Status of navigation object will be
     requested
     - Parameter navigation: navigation object
     */
    func onNavigationRequested(navigation: Navigation)
    
    
    /**
     Called when all the calculation to obtain the route are done and the navigation is started. Status of navigation object will be started
     - Parameter navigation: navigation object
     */
    func onNavigationStarted(navigation: Navigation)
    
    /**
     Called when navigation fails due an error. Status of navigation object will be error
     - Parameter navigation: navigation object
     - Parameter error: error that makes navigation fail
     */
    func onNavigationError(navigation: Navigation, error: Error)
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
     Current status of the ongoing navigation
     */
    var status: NavigationStatus { get set }
    /**
     Destination of the current navigation
     */
    var destination: Destination { get set }
    
    /**
     The calculated route.
     */
    var route: SITRoute? { get set }
    
}

/**
 This represent the destination of a navigation towards a POI or a location
 */
public protocol Destination {
    /**
     Either a POI or a location
     */
    var category: DestinationCategory { get set }
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
 Type of destination
 */
public enum DestinationCategory {
    /**
     Destination is a POI with a SITPOI inside
     */
    case poi(SITPOI)
    /**
     Destination is a location with a SITPoint inside
     */
    case location(SITPoint)
}

/**
 Current status of the navigation
 */
public enum NavigationStatus {
    /**
     Navigation was requested by user/developer
     */
    case requested
    /**
        Route was computed and navigation started
     */
    case started
    /**
     An error has occurred on the ongoing Navigation
     */
    case error(Error)
    /**
     The destination was reached by user
     */
    case destinationReached
    /**
     The ongoing navigation was cancelled by the user/developer
     */
    case canceled
}

/**
 Error that navigation could raise
 */
public enum NavigationError: Error {
    /**
     Error raised when actual position of user is unknown
     */
    case positionUnknown
    /**
     Error raised when actual location of user is outdoor, navigation is only available indoor
     */
    case outdoorOrigin
    /**
     Error raised when user request navigation without select a valid destination
     */
    case noDestinationSelected
    /**
     Error raised when SITUM could not calculate route to destination due an internal error
     */
    case unableToComputeRoute
    /**
     Error raised when there is no route available between user position and destination
     */
    case noAvailableRoute
    /**
     Error raised when a user goes outside the current route and is located out of building
     */
    case outsideBuilding
    /**
     Error raised when a problem with location service happened. Contains the inner location error
     */
    case locationError(Error?)
}

extension NavigationError: LocalizedError {
    /**
     Description of error
     */
    public var errorDescription: String? {
        switch self {
        case .positionUnknown:
            return NSLocalizedString("navigationError.positionUnknown", bundle: SitumMapsLibrary.bundle, comment: "")
        case .outdoorOrigin:
            return NSLocalizedString("navigationError.outdoorOrigin", bundle: SitumMapsLibrary.bundle, comment: "")
        case .noDestinationSelected:
            return NSLocalizedString("navigationError.noDestinationSelected", bundle: SitumMapsLibrary.bundle, comment: "")
        case .unableToComputeRoute:
            return NSLocalizedString("navigationError.unableToComputeRoute", bundle: SitumMapsLibrary.bundle, comment: "")
        case .noAvailableRoute:
            return NSLocalizedString("navigationError.noAvailableRoute", bundle: SitumMapsLibrary.bundle, comment: "")
        case .outsideBuilding:
            return NSLocalizedString("navigationError.outsideBuilding", bundle: SitumMapsLibrary.bundle, comment: "")
        case .locationError(let error):
            return error?.localizedDescription
        }
    }
    /**
     Code of error
     */
    public var _code: Int {
        switch self {
        case .positionUnknown:
            return 10_101
        case .outdoorOrigin:
            return 10_102
        case .noDestinationSelected:
            return 10_103
        case .unableToComputeRoute:
            return 10_104
        case .noAvailableRoute:
            return 10_105
        case .outsideBuilding:
            return 10_106
        case .locationError:
            return 10_107
        }
    }
}

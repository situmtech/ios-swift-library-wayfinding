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
}

/**
 This represent the destination of a navigation towards a POI or a location
 */
public protocol Destination {
    /**
     Either a POI or a location
     */
    var category: Category { get set }
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
public enum Category {
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
     An error has occurred on the ongoing Navigation
     */
    case error
    /**
     The destination was reached by user
     */
    case destinationReached
    /**
     The ongoing navigation was cancelled by the user/developer
     */
    case canceled
}

internal struct WYFNavigation: Navigation {
    var status: NavigationStatus
    var destination: Destination
}

internal struct WYFDestination: Destination {
    var category: Category
    var point: SITPoint {
        switch category {
        case .poi(let poi):
            return poi.position()
        case .location(let point):
            return point
        }
    }
    var identifier: String?  {
        guard case .poi(let poi) = category else { return nil }
        return poi.identifier
    }
    var name: String? {
        guard case .poi(let poi) = category else { return nil }
        return poi.name
    }

    init(category: Category) {
        self.category = category
    }
}

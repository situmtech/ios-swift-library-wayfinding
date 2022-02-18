//
//  WYFNavigation.swift
//  SitumWayfinding
//
//  Created by Lapisoft on 18/2/22.
//

import Foundation

internal struct WYFNavigation: Navigation {
    var status: NavigationStatus
    var destination: Destination
}

internal struct WYFDestination: Destination {
    var category: DestinationCategory
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
    
    init(category: DestinationCategory) {
        self.category = category
    }
}

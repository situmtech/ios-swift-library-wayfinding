//
//  PositioningUtils.swift
//  SitumWayfinding
//
//  Created by fsvilas on 26/04/2021.
//

import Foundation

extension CLLocationCoordinate2D {
    /// Returns distance from coordianate in meters.
    /// - Parameter from: coordinate which will be used as end point.
    /// - Returns: Returns distance in meters.
    func distance(from: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: self.latitude, longitude: self.longitude)
        return from.distance(from: to)
    }
}

struct PositioningUtils {
    static func hasBearingChangedEnoughToReloadUi(newBearing: Float, lastAnimatedBearing: Float) -> Bool {
        if((newBearing < (lastAnimatedBearing - 5.0)) || (newBearing > (lastAnimatedBearing + 5.0))) {
            return true;
        }
        return false;
    }
}

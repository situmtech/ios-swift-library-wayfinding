//
//  PositionDrawerProtocol.swift
//  SitumWayfinding
//
//  Created by fsvilas on 27/04/2021.
//

import Foundation

protocol PositionDrawerProtocol{
    
    func updateUserLocation(with location: SITLocation, with userMarkerImage: UIImage?, with radiusCircleColor: UIColor?)
    func updateUserBearing(with location: SITLocation)
    func makeUserMarkerVisible(visible: Bool)
    
}

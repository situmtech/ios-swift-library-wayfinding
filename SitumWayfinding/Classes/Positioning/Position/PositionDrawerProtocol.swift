//
//  PositionPainterProtocol.swift
//  SitumWayfinding
//
//  Created by fsvilas on 27/04/2021.
//

import Foundation

protocol PositionPainterProtocol{
    
    func updateUserLocation(with location: SITLocation, with userMarkerImage: UIImage?)
    func updateUserBearing(with location: SITLocation)
    func makeUserMarkerVisible(visible: Bool)
    
}

//
//  PositioningView.swift
//  SitumMappingTool
//
//  Created by Cristina Sánchez Barreiro on 09/04/2019.
//  Copyright © 2019 Situm Technologies S.L. All rights reserved.
//

import Foundation
import SitumSDK

protocol PositioningView {
    
    func change(_ state: SITLocationState, centerCamera: Bool)
    
    func stop()
    
    func showNumberOfBeaconsRanged(text: Int)
    
    func updateUI(with location: SITLocation)
    
    func showAlertMessage(title: String, message: String, alertType:AlertType)
    
    func showFakeLocationsAlert()
    
    func showRoute(route: SITRoute)
    
    func updateProgress(progress: SITNavigationProgress)
    
    func stopNavigation()
    
    func reloadTableViewData()
    
    func selectFloor(floorId: String)
    
    func createAndShowCustomMarkerIfOutsideRoute(atCoordinate coordinate: CLLocationCoordinate2D, atFloor floorId: String)
    
}

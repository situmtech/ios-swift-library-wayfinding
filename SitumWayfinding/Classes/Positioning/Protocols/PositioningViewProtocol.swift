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
    
    func reloadFloorPlansTableViewData()
    
    func select(floor floorId: String)
    
    func select(poi:SITPOI) throws
    
    func setCameraCentered()
    
    func createAndShowCustomMarkerIfOutsideRoute(atCoordinate coordinate: CLLocationCoordinate2D, atFloor floorId: String)

    func stopNavigation(with error: Error)

    func finishNavigation(status: NavigationStatus)
}

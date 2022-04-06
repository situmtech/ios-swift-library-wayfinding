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
    
    func cleanLocationUI()
    
    func showNumberOfBeaconsRanged(text: Int)
    
    func updateUI(with location: SITLocation)
    
    func showAlertMessage(title: String, message: String, alertType:AlertType)
    
    func present(viewController: UIViewController)
    
    func showRoute(route: SITRoute)
    
    func updateProgress(progress: SITNavigationProgress)
    
    func stopNavigation(status: NavigationStatus)
    
    func reloadFloorPlansTableViewData()
    
    func select(floor floorId: String)
    
    func select(poi:SITPOI) throws
    
    func setCameraCentered()
    
    func createAndShowCustomMarkerIfOutsideRoute(atCoordinate coordinate: CLLocationCoordinate2D, atFloor floorId: String)
    
}

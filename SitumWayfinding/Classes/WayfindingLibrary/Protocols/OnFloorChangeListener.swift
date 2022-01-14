//
//  OnFloorChangeListener.swift
//  SitumWayfinding
//
//  Created by fsvilas on 11/1/22.
//

import Foundation

/**
 Delegate that get notified about changes in the selected floor
 */
public protocol OnFloorChangeListener{
    /**
     Method that notifies that the selected floor has changed. The selected floor is the one which plan is shown on the screen. It may differ to the one where the user is positioned.
     */
    func onFloorChanged(from:SITFloor, to:SITFloor, building:SITBuilding)
   

}

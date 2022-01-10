//
//  WayfindingDelegate.swift
//
//  Created by fsvilas on 3/1/22.
//

import Foundation
import SitumSDK

 /**
  Delegate that provide access to internal events that happens inside the module
  */
public protocol WayfindingDelegate{

     /**
      Method that notifies when a POI has been selected.
      */
     func onPoiSelected(poi: SITPOI, level: SITFloor, building: SITBuilding)
     
     /**
      Method that notifies when a POI has been deselected.
      */
     func onPoiDeselected(building: SITBuilding)

     /**
      Method that notifies that the selected floor has changed. The selected floor is the one which plan is shown on the screen. It may differ to the one where the user is positioned. 
      */
     func onFloorChanged(from:SITFloor, to:SITFloor, building:SITBuilding)
    
}

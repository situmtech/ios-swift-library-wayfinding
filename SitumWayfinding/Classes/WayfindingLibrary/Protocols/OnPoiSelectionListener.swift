//
//  WayfindingDelegate.swift
//
//  Created by fsvilas on 3/1/22.
//

import Foundation
import SitumSDK

 /**
  Delegate that get notified about changes in selection/deselection of Pois
  */
public protocol OnPoiSelectionListener{

     /**
      Method that notifies when a POI has been selected.
      */
     func onPoiSelected(poi: SITPOI, level: SITFloor, building: SITBuilding)
     
     /**
      Method that notifies when a POI has been deselected.
      */
     func onPoiDeselected(building: SITBuilding)
    
}

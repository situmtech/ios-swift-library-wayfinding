//
//  OnCustomPoiChangeListener.swift
//  SitumWayfinding
//
//  Created by Alba Martínez on 15/2/23.
//

import Foundation
import SitumSDK

 /**
  Delegate that is notified about events related to custom poi creation and selection.
  */
public protocol OnCustomPoiChangeListener {
    
    /**
     Method that notifies when a Custom POI has been set.
     */
    func onCustomPoiCreated(customPoi: CustomPoi)
    
    /**
     Method that notifies when a Custom POI has been removed.
     */
    func onCustomPoiRemoved(customPoi: CustomPoi)

     /**
      Method that notifies when a Custom POI has been selected.
      */
    func onCustomPoiSelected(customPoi: CustomPoi)
     
     /**
      Method that notifies when a Custom POI has been deselected.
      */
    func onCustomPoiDeselected(customPoi: CustomPoi)
    
}

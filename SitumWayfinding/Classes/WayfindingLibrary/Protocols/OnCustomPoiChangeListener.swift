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

/// Object that represents a custom POI saved by the user
public protocol CustomPoi {
    /// Name of the custom poi.
    func getName() -> String?;
    
    /// Unique identifier of the custom poi.
    func getId() -> Int;
    
    /// Optional description of the custom poi.
    func getDescription() -> String?;

    /// Level identifier of the custom poi.
    func getLevelId() -> Int;
    
    /// Building identifier of the custom poi.
    func getBuildingId() -> Int;
    
    /// Method that creates a map of an instance of CustomPoi with all its attributes.
    func toMap() -> [String: Any];
}

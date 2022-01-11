//
//  WayfindingDelegateNotifier.swift
//  SitumWayfinding
//
//  Created by fsvilas on 10/1/22.
//

import Foundation
class WayfindingDelegatesNotifier{
    var poiSelectionDelegate: OnPoiSelectionListener?
    var floorChangeDelegate: OnFloorChangeListener?
    
    /**
     Method that notifies when a POI has been selected. There are several actions that can result on a POI being selected.
       1) When the user touch a POI in the screen
       2) When the user search for POIs and select one of the available results
     */
    func notifyOnPOISelected(poi:SITPOI, buildingInfo:SITBuildingInfo){
        // Find the floor
        var poiFloor = SITFloor()
        if let foundFloor = buildingInfo.floors.first(where: {$0.identifier == poi.position().floorIdentifier}) {
            poiFloor = foundFloor
        } else {
            poiFloor.identifier = poi.position().floorIdentifier
        }
        poiSelectionDelegate?.onPoiSelected(poi: poi, level: poiFloor, building: buildingInfo.building)
    }

    /**
     Method that notifies when a POI has been deselected. There are several actions that can result on a POI being deselected.
       1) When the user touchs elsewhere in the map
       2) When a different POI was seleted
       3) When the user performs a long click on the map
     */
    func notifyOnPOIDeselected(poi:SITPOI, buildingInfo:SITBuildingInfo){
        poiSelectionDelegate?.onPoiDeselected(building: buildingInfo.building)
    }
    
    /**
    Method that notifies delegate that the selected floor has changed. The selected floor is the one which plan is shown on the screen. It may differ to the one where the user is positioned. There are several actions than can result on a floor change:
      1) The user selects a different floor level on the floor selector
      2) The user search and select a POI thats is in a different floor than the current selected floor
      3) When the selected floor and the floor where the user is being positioned match if the user position floor changes the selected floor changes accordingly
     */
    func notifyOnFloorChanged(from:SITFloor, to:SITFloor, buildingInfo:SITBuildingInfo){
        floorChangeDelegate?.onFloorChanged(from:from, to:to, building: buildingInfo.building)
        
    }
}

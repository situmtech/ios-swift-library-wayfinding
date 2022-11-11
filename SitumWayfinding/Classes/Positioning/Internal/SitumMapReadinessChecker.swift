//
//  SitumMapReadinessChecker.swift
//  SitumWayfinding
//
//  Created by Lapisoft on 18/1/22.
//

import Foundation

class SitumMapReadinessChecker {
    private var isBuildingInfoLoaded = false
    private var isCurrentFloorMapLoaded = false
    private var isOrganizationLoaded = false
    private var isMapReady = false
    // only notify the first time after maps is ready
    private var delegateWasNotify = false
    private var mapDidLoadHandler: (() -> Void)? = nil

    init(mapDidLoadHandler: @escaping () -> Void) {
        self.mapDidLoadHandler = mapDidLoadHandler
    }

    func buildingInfoLoaded() {
        isBuildingInfoLoaded = true
        checkIsMapIsLoadedAndReady()
    }

    func setMapAsReady() {
        isMapReady = true
        checkIsMapIsLoadedAndReady()
    }

    func currentFloorMapLoaded() {
        isCurrentFloorMapLoaded = true
        checkIsMapIsLoadedAndReady()
    }
    
    func setOrganizationLoaded() {
        isOrganizationLoaded = true
        checkIsMapIsLoadedAndReady()
    }

    func checkIsMapIsLoadedAndReady() {
        if (isBuildingInfoLoaded && isCurrentFloorMapLoaded && isMapReady && isOrganizationLoaded && !delegateWasNotify) {
            mapDidLoadHandler?()
            delegateWasNotify = true
        }
    }
}

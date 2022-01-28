//
//  OnMapReadyListener.swift
//  SitumWayfinding
//
//  Created by Lapisoft on 18/1/22.
//

import Foundation

/**
 Delegate that get notified when the map is ready to interact and fully loaded.
 */
public protocol OnMapReadyListener {
    /**
     Method that notifies that it is safe to perform operations over the map. After the SitumMapsLibrary load() method
     is called, the module has to load the map on screen and obtain cartographic information. During this time the
     module is not properly initialized and operations over the map are not guaranteed to end as expected.

     - parameter map: instance of the SitumMapsLibrary prepared to perform operations
     */
    func onMapReady(map: SitumMap)
}
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
     Method that notifies when the map is fully loaded. This will be called after call load() on library when all
     the resources are loaded, and the user can start to interact with the map.
     */
    func onMapReady(map: SitumMap)
}
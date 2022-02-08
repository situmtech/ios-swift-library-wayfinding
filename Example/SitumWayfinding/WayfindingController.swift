//
//  WayfindingController.swift
//  ios-app-wayfindingExample
//
//  Created by Adrián Rodríguez on 17/06/2019.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//

import Foundation
import UIKit
import SitumWayfinding
import SitumSDK
import GoogleMaps

class WayfindingController: UIViewController, OnPoiSelectionListener, OnFloorChangeListener, OnMapReadyListener {
    
    @IBOutlet var containerView: UIView!
    
    var library: SitumMapsLibrary?
    var selectFirstPOIAutomatically: Bool = false
    var buildingId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {

        let credentials: Credentials = Credentials(user: "YOUR_USER", apiKey: "YOUR_SITUM_APIKEY", googleMapsApiKey: "YOUR_GOOGLEMAPS_APIKEY")

        buildingId = "YOUR_BUILDING_ID"
        let settings = LibrarySettings.Builder()
                .setCredentials(credentials: credentials)
                .setBuildingId(buildingId: buildingId)
                .setUseRemoteConfig(useRemoteConfig: true)
                .build()
        self.library = SitumMapsLibrary(containedBy: self.containerView, controlledBy: self, withSettings: settings)
            
        self.library?.addLocationRequestInterceptor { (locationRequest: SITLocationRequest) in
            locationRequest.useGlobalLocation = true;
            let options: SITOutdoorLocationOptions = SITOutdoorLocationOptions()
            options.buildingDetector = .SITBLE
            locationRequest.outdoorLocationOptions = options
        }
        self.library?.setOnPoiSelectionListener(listener: self)
        self.library?.setOnFloorChangeListener(listener: self)
        self.library?.setOnMapReadyListener(listener: self)

        do {
            try self.library!.load()
        } catch {
            print("An error has ocurred. Your SitumView could not be loaded.")
        }

        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Wayfinding Delegate
    func onPoiDeselected(building: SITBuilding) {
        print("onPoiDeselected app")
    }
    
    func onPoiSelected(poi: SITPOI, level: SITFloor, building: SITBuilding) {
        print("onPoiSelected")
    }
    func onFloorChanged(from: SITFloor, to: SITFloor, building: SITBuilding) {
        print("onFloorChanged from \(from.floor) to \(to.floor)")
    }

    func onMapReady(map: SitumMap) {
        print("map ready to interact \(map)")

        if (selectFirstPOIAutomatically) {
            // get pois of the same building loaded in viewWillAppear
            SITCommunicationManager.shared().fetchBuildingInfo(buildingId, withOptions: nil, success: { mapping in
                guard mapping != nil, let buildingInfo = mapping!["results"] as? SITBuildingInfo else {return}

                // select the first poi of the building
                let point = buildingInfo.indoorPois[0]
                self.library!.selectPoi(poi: point) { result in
                    switch result {
                    case .success:
                        print("POI: selection succeeded")
                    case .failure(let reason):
                        if let error = reason as? WayfindingError {
                            switch error {
                            case .invalidPOI:
                                print("POI: selection error, invalid POI \(reason))")
                            case .unknown:
                                print("POI: unknown error \(reason))")
                            }
                        } else {
                            print("POI: generic error \(reason))")
                        }
                    }
                }
            }, failure: { error in
                print("fetchBuildingInfoError \(error)")
            })
        }
    }
}



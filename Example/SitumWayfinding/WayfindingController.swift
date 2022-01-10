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

class WayfindingController: UIViewController, WayfindingDelegate {
    
    @IBOutlet var containerView: UIView!
    
    var library: SitumMapsLibrary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        
        let credentials: Credentials = Credentials(user: "YOUR_USER", apiKey: "YOUR_SITUM_APIKEY", googleMapsApiKey: "YOUR_GOOGLEMAPS_APIKEY")

        let buildingId = "YOUR_BUILDING_ID"
        let settings = LibrarySettings.Builder()
                .setCredentials(credentials: credentials)
                .setBuildingId(buildingId: buildingId)
                .build()
        self.library = SitumMapsLibrary(containedBy: self.containerView, controlledBy: self, withSettings: settings)
            
        self.library?.addLocationRequestInterceptor { (locationRequest: SITLocationRequest) in
            locationRequest.useGlobalLocation = true;
            let options: SITOutdoorLocationOptions = SITOutdoorLocationOptions()
            options.buildingDetector = .SITBLE
            locationRequest.outdoorLocationOptions = options
        }
        self.library?.setWayfindingDelegate(delegate: self)
            
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
}



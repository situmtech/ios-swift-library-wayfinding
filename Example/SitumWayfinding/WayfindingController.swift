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

class WayfindingController: UIViewController {
    
    @IBOutlet var containerView: UIView!
    
    var library: SitumMapsLibrary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        
        let credentials: Credentials = Credentials(user: "YOUR_EMAIL", apiKey: "YOUR_API_KEY", googleMapsApiKey: "AIzaSyAAjP-7eUkRTU5cBMAVC8ASgo1z5aBeEdQ")

        let buildingId = "YOUR_BUILDING_ID"
        
        let loadWithNew = true
        
        if loadWithNew {
            let settings = LibrarySettings.Builder()
                .setCredentials(credentials: credentials)
                .setBuildingId(buildingId: buildingId)
                .build()
            self.library = SitumMapsLibrary(containedBy: self.containerView, controlledBy: self, withSettings: settings)
            
            do {
                try self.library!.load()
                
            } catch {
                print("An error has ocurred. Your SitumView could not be loaded.")
            }
        } else {
        
            self.library = SitumMapsLibrary(containedBy: self.containerView, controlledBy: self)
            self.library?.setOnBackPressedCallback(
                {(_ sender: Any) in
                    self.performSegue(withIdentifier: "unloadWayfinding", sender: self)
                }
            )

            self.library?.addLocationRequestInterceptor { (locationRequest: SITLocationRequest) in
                locationRequest.useGlobalLocation = true;
                let options: SITOutdoorLocationOptions = SITOutdoorLocationOptions()
                options.buildingDetector = .SITBLE
                locationRequest.outdoorLocationOptions = options
            }

            library?.setCredentials(credentials)
            do {
                try library?.load(buildingWithId: buildingId)
            } catch {
                print("An error has ocurred. Your SitumView couldn't be loaded.")
            }
        )
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}



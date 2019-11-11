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
        
        let credentials: Credentials = Credentials(user: "YOUR_USER", apiKey: "YOUR_SITUM_APIKEY", googleMapsApiKey: "YOUR_GOOGLEMAPS_APIKEY")
        self.library = SitumMapsLibrary(containedBy: self.containerView, controlledBy: self)
        self.library?.setOnBackPressedCallback(
            {(_ sender: Any) in
                self.performSegue(withIdentifier: "unloadWayfinding", sender: self)
            }
        )
        library?.setCredentials(credentials)
        do {
            try library?.load(buildingWithId: "YOUR_BUILDING_ID")
        } catch {
            print("An error has ocurred. Your SitumView couldn't be loaded.")
        }
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}



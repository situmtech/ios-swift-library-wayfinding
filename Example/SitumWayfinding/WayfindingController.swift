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

    var action: WYFAction?
    var credentials: Credentials!
    var buildingId: String!

    var library: SitumMapsLibrary?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        let settings = LibrarySettings.Builder()
                .setCredentials(credentials: credentials)
                .setBuildingId(buildingId: buildingId)
                .build()
        self.library = SitumMapsLibrary(containedBy: self.containerView, controlledBy: self, withSettings: settings)

        self.library?.addLocationRequestInterceptor { (locationRequest: SITLocationRequest) in
            let options: SITOutdoorLocationOptions = SITOutdoorLocationOptions()
            options.buildingDetector = .SITBLE
            locationRequest.outdoorLocationOptions = options
            // setting building ID disable indoor-outdoor positioning
            locationRequest.buildingID = self.buildingId
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

        if let action = action {
            switch action {
            case .selectPoi(let poi):
                selectPoi(poi: poi)
            case .navigateToPoi(let poi):
                self.navigateToPoi(poi: poi)
            }
        }
    }

    private func selectPoi(poi: SITPOI) {
        self.library?.selectPoi(poi: poi) { [weak self] result in
            switch result {
            case .success:
                print("POI: selection succeeded")
            case .failure(let reason):
                self?.processSelectionError(error: reason)
            }
        }
    }

    private func navigateToPoi(poi: SITPOI) {
        self.library?.navigateToPoi(poi: poi) { [weak self] result in
            switch result {
            case .success:
                print("POI: navigation started")
            case .failure(let reason):
                self?.processSelectionError(error: reason)
            }
        }
    }

    private func processSelectionError(error: Error) {
        if let error = error as? WayfindingError {
            switch error {
            case .invalidPOI:
                print("POI: selection error, invalid POI \(error))")
            case .unknown:
                print("POI: unknown error \(error))")
            }
        } else {
            print("POI: generic error \(error))")
        }
    }
}



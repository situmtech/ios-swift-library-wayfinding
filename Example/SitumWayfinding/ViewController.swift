//
//  ViewController.swift
//  ios-app-wayfindingExample
//
//  Created by Adrián Rodríguez on 16/05/2019.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//

import UIKit
import SitumWayfinding
import SitumSDK

class ViewController: UIViewController {

    @IBOutlet var loadButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    private var credentials: Credentials!
    private var buildingId: String = ""
    private var currentFloor: SITFloor? = nil
    private var location: (lat: String, lng: String)!
    private var pois: [SITPOI]? = nil
    private var selectedPoi: SITPOI? = nil
    private var action: WYFAction?
    private let cellId = "cell"
    
    @IBOutlet weak var remoteConfigSwitch: UISwitch!
    @IBOutlet weak var fakeLocationSwitch: UISwitch!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellId)

        credentials = Credentials(
            user: "YOUR_USER",
            apiKey: "YOUR_SITUM_APIKEY",
            googleMapsApiKey: "YOUR_GOOGLEMAPS_APIKEY"
        )
        buildingId = "YOUR_BUILDING_ID"
        location = (lat: "YOUR_LATITUDE", lng: "YOUR_LONGITUDE")

        fakeLocationSwitch.isOn = UserDefaults.standard.bool(forKey: "fake_locations")
        loadPois()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func loadTapped(_ sender: Any) {
        action = nil
        self.performSegue(withIdentifier: "loadWayfindingSegue", sender: self)
    }
    
    @IBAction func loadAndSelectTapped(_ sender: Any) {
        guard let selectedPoi = selectedPoi else {
            showUnselectedPoiError()
            return
        }
        action = .selectPoi(selectedPoi)
        self.performSegue(withIdentifier: "loadWayfindingSegue", sender: self)
    }
    
    @IBAction func loadAndNavigateTapped(_ sender: Any) {
        guard let selectedPoi = selectedPoi else {
            showUnselectedPoiError()
            return
        }
        action = .navigateToPoi(selectedPoi)
        self.performSegue(withIdentifier: "loadWayfindingSegue", sender: self)
    }

    @IBAction func loadAndNavigateToLocation(_ sender: Any) {
        guard let floor = currentFloor else {
            self.showError(title: "Navigate to Location", message: "You must wait until building is downloaded")
            return
        }
        guard let lat = Double(location.lat), let lng = Double(location.lng) else {
            self.showError(title: "Latitude or longitude incorrect",
                message: "You set latitude and longitude in code (ViewController.location) to a correct value")
            return
        }

        action = .navigateToLocation(floor: floor, lat: lat, lng: lng)
        self.performSegue(withIdentifier: "loadWayfindingSegue", sender: self)
    }
    
    @IBAction func clearCacheTapped(_ sender: Any) {
        SITCommunicationManager.shared().clearCache()
    }
    
    @IBAction func changeFakeLocation(_ sender: Any) {
        UserDefaults.standard.set(fakeLocationSwitch.isOn, forKey: "fake_locations")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loadWayfindingSegue" {
            if let vc = segue.destination as? WayfindingController {
                vc.credentials = credentials
                vc.buildingId = buildingId
                vc.action = action
                vc.useRemoteConfig = remoteConfigSwitch.isOn
            }
        }
    }

    private func showUnselectedPoiError() {
        self.showError(title: "Select POI",
            message: "You must select a POI in the list of available POIs to perform the action")
    }

    private func showError(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true)
    }

    private func loadPois() {
        SITServices.provideAPIKey(credentials.password, forEmail: credentials.user)
        SITCommunicationManager.shared().fetchBuildingInfo(buildingId, withOptions: nil, success: { [weak self] mapping in
            guard mapping != nil, let buildingInfo = mapping!["results"] as? SITBuildingInfo else {return}
            self?.pois = buildingInfo.indoorPois
            if buildingInfo.floors.count > 0 {
                self?.currentFloor = buildingInfo.floors[0]
            }
            self?.tableView.reloadData()
        }, failure: { error in
            print("fetchBuildingInfo \(error)")
        })
    }
}


extension ViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let pois = pois else { return 1 }
        return pois.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellId) else {
            fatalError("There is no cell registered for identifier \(cellId)")
        }
        if let pois = pois {
            let poi = pois[indexPath.row]
            cell.textLabel?.text = poi.name
            if let selectedPoi = selectedPoi, selectedPoi.identifier == poi.identifier {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else {
            cell.textLabel?.text = "Loading..."
        }
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let pois = pois else { return }
        selectedPoi = pois[indexPath.row]
        tableView.reloadData()
    }
}

enum WYFAction {
    case selectPoi(SITPOI), navigateToPoi(SITPOI), navigateToLocation(floor: SITFloor, lat: Double, lng: Double)
}

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
    private var pois: [SITPOI]? = nil
    private var selectedPoi: SITPOI? = nil
    private var action: WYFAction?
    private let cellId = "cell"

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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "loadWayfindingSegue" {
            if let vc = segue.destination as? WayfindingController {
                vc.credentials = credentials
                vc.buildingId = buildingId
                vc.action = action
            }
        }
    }

    private func showUnselectedPoiError() {
        let alert = UIAlertController(
            title: "Select POI",
            message: "You must select a POI in the list of available POIs to do given action",
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
    case selectPoi(SITPOI), navigateToPoi(SITPOI)
}

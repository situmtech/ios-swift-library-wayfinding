//
//  SearchResultsTableViewController.swift
//  SitumWayfinding
//
//  Created by fsvilas on 25/10/21.
//

import Foundation

protocol SearcheableItem {
    var id: String { get }
    var name: String { get }
    var floorlevel: Int { get }
}

extension SITPOI: SearcheableItem {
    var id: String {
        return self.identifier
    }

    var floorlevel: Int {
        return 0
    }
}

class SearchResultsTableViewController: UITableViewController {

    var filteredPois: [SearcheableItem] = []
    private var myTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return filteredPois.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as! SearchTableViewCell

        let searchableItem = filteredPois[indexPath.row]
        cell.name = searchableItem.name
        cell.distance = ""
        cell.floor = ""
        cell.icon = nil

        let currentPOI = (parent as! PositioningViewController).buildingInfo?.indoorPois.first(where: { $0.id == searchableItem.id })
        if currentPOI != nil {
            cell.floor = getFloor(floorIdentifier: currentPOI!.position().floorIdentifier)
            if (parent as! PositioningViewController).poiCategoryIcons[currentPOI!.category.code] != nil {
                cell.icon = (parent as! PositioningViewController).poiCategoryIcons[currentPOI!.category.code]
            } else {
                SITCommunicationManager.shared().fetchSelected(false, iconFor: currentPOI!.category, withCompletion: { iconData, error in
                    if error != nil {
                        Logger.logErrorMessage("error retrieving icon data")
                    } else {
                        DispatchQueue.main.async(execute: {
                            if let iconData = iconData {
                                cell.icon = UIImage(data: iconData)
                            }
                        })
                    }
                })
            }
        }

        return cell
    }
}

extension SearchResultsTableViewController: UISearchResultsUpdating {

    // MARK: - UISearchResultsUpdating delegate methods
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }

    private func filterContentForSearchText(_ searchText: String) {
        if let parentController = (parent as? PositioningViewController) {
            let filteredPois = searchText.isEmpty ? parentController.buildingInfo?.indoorPois ?? []
                    : (parentController.buildingInfo?.indoorPois ?? []).filter { (poi: SearcheableItem) -> Bool in
                return poi.name.lowercased().contains(searchText.lowercased())
            }
            //filteredPois.sort() TODO: cuando se calcule la distancia ordenar por ese valor
            self.filteredPois = filteredPois
            tableView.reloadData()
        }
    }

    func dismissSearchResultsController(constraints: [NSLayoutConstraint]?){
        willMove(toParent: nil)
        NSLayoutConstraint.deactivate(constraints!)
        view.removeFromSuperview()
        removeFromParent()
    }

    private func getFloor(floorIdentifier: String) -> String {
        let floor = (self.parent as! PositioningViewController).buildingInfo?.floors.first(where: { $0.identifier ==  floorIdentifier })
        return floor?.floor != nil ? "Floor \(floor!.floor)" : ""
    }
}

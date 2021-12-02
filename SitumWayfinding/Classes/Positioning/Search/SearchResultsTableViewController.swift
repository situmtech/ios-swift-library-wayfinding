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

    func floor(controller: PositioningViewController) -> String
    func icon(controller: PositioningViewController, cell: SearchTableViewCell)
}

extension SITPOI: SearcheableItem {
    var id: String {
        return self.identifier
    }

    func floor(controller: PositioningViewController) -> String {
        let floor = controller.buildingInfo?.floors.first(where: { $0.identifier ==  self.position().floorIdentifier })
        return floor?.floor != nil ? "Floor \(floor!.floor)" : ""
    }

    func icon(controller: PositioningViewController, cell: SearchTableViewCell) {
        if controller.poiCategoryIcons[self.category.code] != nil {
            cell.icon = controller.poiCategoryIcons[self.category.code]!
        } else {
            SITCommunicationManager.shared().fetchSelected(false, iconFor: self.category, withCompletion: { iconData, error in
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
}

class SearchResultsTableViewController: UITableViewController {
    var buildingPOIs: [SITPOI] = []
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
        cell.distance = "" //TODO en proxima tarea se debe calcular este valor
        cell.floor = searchableItem.floor(controller: (parent as! PositioningViewController))
        searchableItem.icon(controller: (parent as! PositioningViewController), cell: cell)

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
        let filteredPois = searchText.isEmpty ? buildingPOIs
                : buildingPOIs.filter { (poi: SearcheableItem) -> Bool in
            return poi.name.lowercased().contains(searchText.lowercased())
        }
        //filteredPois.sort()  TODO: cuando se calcule la distancia ordenar por ese valor
        self.filteredPois = filteredPois
        tableView.reloadData()
    }

    // MARK: - Dismiss this view from parent
    func dismissSearchResultsController(constraints: [NSLayoutConstraint]?){
        willMove(toParent: nil)
        NSLayoutConstraint.deactivate(constraints!)
        view.removeFromSuperview()
        removeFromParent()
    }

    // MARK: - Search floor of POI
    private func getFloor(floorIdentifier: String) -> String {
        let floor = (self.parent as! PositioningViewController).buildingInfo?.floors.first(where: { $0.identifier ==  floorIdentifier })
        return floor?.floor != nil ? "Floor \(floor!.floor)" : ""
    }
}

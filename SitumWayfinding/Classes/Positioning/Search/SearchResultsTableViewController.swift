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

class SearchResultsTableViewController: UITableViewController, UISearchResultsUpdating {
    
    public var searchController : UISearchController?
    var filteredPois: [SearcheableItem] = []
    private var myTableView: UITableView!
    
    var isSearchBarEmpty: Bool {
      return searchController!.searchBar.text?.isEmpty ?? true
    }
    
    var isFiltering: Bool {
        return searchController?.isActive ?? false && !isSearchBarEmpty
    }
    
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

        let currentPOI = (self.parent as! PositioningViewController).buildingInfo?.indoorPois.first(where: { $0.id == searchableItem.id })
        if (currentPOI != nil) {
            cell.floor = "\(currentPOI!.position().floorIdentifier)"
            if (self.parent as! PositioningViewController).poiCategoryIcons[currentPOI!.category.code] != nil {
                cell.icon = (self.parent as! PositioningViewController).poiCategoryIcons[currentPOI!.category.code]
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
    
    func updateSearchResults(for searchController: UISearchController) {
        view.isHidden = false //Make results table visible even when search bar is selected
        guard searchController.isActive else {return}
        tableView.reloadData()
    }
}

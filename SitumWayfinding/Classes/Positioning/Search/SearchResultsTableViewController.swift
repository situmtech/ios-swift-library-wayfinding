//
//  SearchResultsTableViewController.swift
//  SitumWayfinding
//
//  Created by fsvilas on 25/10/21.
//

import Foundation

class SearchResultsTableViewController: UITableViewController, UISearchResultsUpdating {
    
    public var searchController : UISearchController?
    var filteredPois: [String] = []
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
        
        let name = filteredPois[indexPath.row]
        cell.name = name
        cell.distance = "200 m"
        cell.floor = "1st Floor"
        cell.icon = UIImage(named: "swf_info")
        return cell
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        view.isHidden = false //Make results table visible even when search bar is selected
        guard searchController.isActive else {return}
        tableView.reloadData()
    }
}

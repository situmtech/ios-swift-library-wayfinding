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
    func obtainIconImage( controller:PositioningViewController, completion:@escaping(UIImage?) -> Void)
}

extension SITPOI: SearcheableItem {
    
    var id: String {
        return self.identifier
    }

    func floor(controller: PositioningViewController) -> String {
        let floor = controller.buildingInfo?.floors.first(where: { $0.identifier ==  self.position().floorIdentifier })
        return floor?.floor != nil ? "Floor \(floor!.floor)" : ""
    }

    //TODO migrate to await-async
    func obtainIconImage(controller: PositioningViewController, completion: @escaping(UIImage?) -> Void) {
        controller.iconsStore.obtainIconFor(category: self.category) { icon in
            completion(icon)
        }
    }
}

class SearchResultsTableViewController: UITableViewController {
    var buildingPOIs: [SearcheableItem] = []
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
        searchableItem.obtainIconImage(controller: (parent as! PositioningViewController)) { image in
            cell.icon=image
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
        let filteredPois = searchText.isEmpty ? buildingPOIs
                : buildingPOIs.filter { (poi: SearcheableItem) -> Bool in
            return poi.name.lowercased().contains(searchText.lowercased())
        }
        //TODO: cuando se calcule la distancia ordenar por ese valor
        self.filteredPois = filteredPois.sorted(by: { $0.name < $1.name })
        tableView.reloadData()
    }

    // MARK: - Dismiss this view from parent
    func dismissSearchResultsController(constraints: [NSLayoutConstraint]?){
        willMove(toParent: nil)
        NSLayoutConstraint.deactivate(constraints!)
        view.removeFromSuperview()
        removeFromParent()
    }
}

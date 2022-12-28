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
    //TODO make it more generic
    func floor(activeBuildingInfo: SITBuildingInfo?) -> String
    func distance() -> String
    func obtainIconImage(iconsStore:IconsStore?, completion:@escaping(UIImage?) -> Void)
}

extension SITPOI: SearcheableItem {
    
    var id: String {
        return self.identifier
    }

    func floor(activeBuildingInfo: SITBuildingInfo?) -> String {
        guard let floor = activeBuildingInfo?.floors.first(where: { $0.identifier ==  self.position().floorIdentifier }) else {
            return ""
        }
        return "\(NSLocalizedString("search.floor", bundle: SitumMapsLibrary.bundle, comment: "")) \(floor.floor)"
    }
    
    func distance() -> String {
        // TODO en proxima tarea se debe calcular este valor
        // localized string to use in the future for distance
        let _ = NSLocalizedString("search.distance", bundle: SitumMapsLibrary.bundle, comment: "")
        return ""
    }

    //TODO migrate to await-async
    func obtainIconImage(iconsStore:IconsStore?, completion: @escaping(UIImage?) -> Void) {
        if let uIconsStore = iconsStore{
            uIconsStore.obtainIconFor(category: self.category) { icons in
                completion(icons?[0])
            }
        } else{
            completion(nil)
        }
    }
}

class SearchResultsTableViewController: UITableViewController {
    var delegate:PositioningView?
    var searchController:UISearchController?
    var activeBuildingInfo : SITBuildingInfo?
    var filteredPois: [SearcheableItem] = []
    var iconsStore : IconsStore?
    
    private var myTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: UITableViewController delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        if (self.filteredPois.count == 0)
        {
            arrangeForNoResultsFound(the: tableView)
        }else{
            arrangeForResultsFound(the: tableView)
        }
        return 1
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
        cell.distance = searchableItem.distance()
        cell.floor = searchableItem.floor(activeBuildingInfo: activeBuildingInfo)
        searchableItem.obtainIconImage(iconsStore: iconsStore) { image in
            cell.icon=image
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = filteredPois[indexPath.row]
        if selectedItem is SITPOI{
            do {
                try delegate?.select(poi: selectedItem as! SITPOI)
            }catch{
            }
        }
        hideSearchController()
    }
    
    func hideSearchController(){
        searchController?.isActive = false
    }
    
    //MARK : UI customization methods
    func arrangeForNoResultsFound(the tableView: UITableView){
        let noDataLabel = UITextField(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.width))
        noDataLabel.text          = NSLocalizedString("search.noResultFound", bundle: SitumMapsLibrary.bundle, comment: "")
        noDataLabel.textAlignment = .center
        tableView.backgroundView  = noDataLabel
        tableView.separatorStyle  = .none
    }
    
    func arrangeForResultsFound(the tableView: UITableView){
        tableView.backgroundView  = nil
        tableView.separatorStyle  = .singleLine
    }
}

extension SearchResultsTableViewController: UISearchResultsUpdating {

    // MARK: - UISearchResultsUpdating delegate methods
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }

    private func filterContentForSearchText(_ searchText: String) {
        let buildingPois = activeBuildingInfo?.indoorPois ?? []
        let filteredPois = searchText.isEmpty ? buildingPois
                : buildingPois.filter { (poi: SearcheableItem) -> Bool in
            return poi.name.lowercased().contains(searchText.lowercased())
        }
        //TODO: cuando se calcule la distancia ordenar por ese valor
        self.filteredPois = filteredPois.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
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

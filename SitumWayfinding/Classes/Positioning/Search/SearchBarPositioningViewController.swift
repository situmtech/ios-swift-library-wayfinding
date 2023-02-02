extension PositioningViewController: UISearchControllerDelegate, UISearchBarDelegate {
    // MARK : Init Search Controller
    func initSearchController() {
        let storyboard = UIStoryboard(name: "SitumWayfinding", bundle: nil)
        searchResultsController = storyboard.instantiateViewController(withIdentifier: "searchResultsVC") as? SearchResultsTableViewController
        searchController = UISearchController()
        searchController?.searchResultsUpdater = searchResultsController
        searchController?.delegate = self
        searchController?.searchBar.delegate = self
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.searchBar.placeholder = searchTextPlaceholder()
        searchController?.hidesNavigationBarDuringPresentation = false
        navbar.topItem?.titleView = searchController!.searchBar
    }
    
    func searchTextPlaceholder() -> String {
        if let searchViewPlaceholder = library?.settings?.searchViewPlaceholder, searchViewPlaceholder.count > 0 {
            return searchViewPlaceholder
        } else {
            return NSLocalizedString("positioning.searchPois",
                bundle: SitumMapsLibrary.bundle,
                comment: "Placeholder for searching pois")
        }
    }
    
    func createSearchResultsContraints() {
        //We need to use navbar.topItem?.titleView in constraints instead of navbar because navigation bar dont update properly its height after adding search bar to its titleView: navbar.topItem?.titleView =  searchController!.searchBar
        let views = ["searchResultView": searchResultsController!.view, "navigationBar": navbar.topItem?.titleView]
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[searchResultView]-0-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views as [String: Any])
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[navigationBar]-0-[searchResultView]-0-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views as [String: Any])
        searchResultViewConstraints = horizontalConstraints + verticalConstraints
    }
    
    //MARK: UISearchControllerDelegate methods
    func presentSearchController(_ searchController: UISearchController) {
        customizeSearchBarTintColor()
        // Inititialize searchResultsController variables
        searchResultsController?.activeBuildingInfo = self.buildingInfo
        searchResultsController?.iconsStore = iconsStore
        searchResultsController?.delegate = self
        searchResultsController?.searchController = searchController
        // Add the results view controller to the container.
        addChild(searchResultsController!)
        view.addSubview(searchResultsController!.view)
        
        // Create and activate the constraints for the child’s view.
        searchResultsController!.view.translatesAutoresizingMaskIntoConstraints = false
        createSearchResultsContraints()
        NSLayoutConstraint.activate(searchResultViewConstraints!)
        
        // Notify the child view controller that the move is complete.
        searchResultsController!.didMove(toParent: self)
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        searchResultsController?.willMove(toParent: self)
        searchResultsController?.view.removeFromSuperview()
        searchResultsController?.removeFromParent()
    }
    
    //MARK: UISearchBarDelegate methods
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchResultsController?.dismissSearchResultsController(constraints: searchResultViewConstraints)
    }
    
    func customizeSearchBarTintColor(){
        searchController?.searchBar.tintColor = uiColorsTheme.primaryColor
    }
}

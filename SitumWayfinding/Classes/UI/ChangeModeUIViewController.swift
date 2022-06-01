//MARK: Change between ui of different modes (default, navigation)
extension PositioningViewController {
    func showPositioningUI() {
        mapContainerViewTopConstraint.constant = 44
        infoBarMap.isHidden = false
        infoBarNavigation.isHidden = true
        indicationsView.isHidden = true
        navbar.isHidden = false
    }
    
    func showNavigationUI() {
        mapContainerViewTopConstraint.constant = 0
        infoBarMap.isHidden = true
        infoBarNavigation.isHidden = false
        indicationsView.isHidden = false
        navbar.isHidden = true
        containerInfoBarNavigation?.setLoadingState()
        indicationsViewController?.showNavigationLoading()
    }
    
    func hiddenNavBar() {
        mapContainerViewTopConstraint.constant = 0
        infoBarMap.isHidden = false
        navbar.isHidden = true
    }
}

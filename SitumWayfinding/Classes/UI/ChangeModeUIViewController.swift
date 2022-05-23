//MARK: Change between ui of different modes (default, navigation)
extension PositioningViewController {
    func showPositioningUI() {
        self.mapContainerViewTopConstraint.constant = 44
        self.infoBarMap.isHidden = false
        self.infoBarNavigation.isHidden = true
        self.indicationsView.isHidden = true
        self.navbar.isHidden = false
    }
    
    func showNavigationUI() {
        self.mapContainerViewTopConstraint.constant = 0
        self.infoBarMap.isHidden = true
        self.infoBarNavigation.isHidden = false
        self.indicationsView.isHidden = false
        self.navbar.isHidden = true
        containerInfoBarNavigation?.initializeProgress()
    }
    
    func hiddenNavBar() {
        self.mapContainerViewTopConstraint.constant = 0
        self.infoBarMap.isHidden = false
        self.navbar.isHidden = true
    }
}

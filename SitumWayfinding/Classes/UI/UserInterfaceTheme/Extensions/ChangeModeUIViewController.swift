//MARK: Change between ui of different modes (default, navigation)
extension PositioningViewController {
    func showPositioningUI() {
        mapContainerViewTopConstraint.constant = 44
        infoBarMap.isHidden = false
        infoBarNavigation.isHidden = true
        indicationsView.isHidden = true
        navbar.isHidden = false
        containerInfoBarMap?.isBeingPresented()
        hideFindMyCarUIElements()
    }
        
    func showNavigationUI() {
        mapContainerViewTopConstraint.constant = 0
        infoBarMap.isHidden = true
        infoBarNavigation.isHidden = false
        
        var isHidden = !(self.library?.getSettings()?.showNavigationIndications ?? false)
        indicationsView.isHidden = isHidden
        
        navbar.isHidden = true
        containerInfoBarNavigation?.setLoadingState()
        //It seing that ViewWillAppear is not being called to viewController when isHidden is change so we have to notify viewController
        indicationsViewController?.isBeingPresented()
        containerInfoBarNavigation?.isBeingPresented()
        indicationsViewController?.showNavigationLoading()
        hideFindMyCarUIElements()
    }
    
    private func displayFindMyCarUIElements() {
//        findMyCarView.isHidden = false
//        findMyCarButton.isHidden = true
//        navigateToCarButton.isHidden = true
        positionPickerImage.isHidden = false
        findMyCarModeActive = true
        findMyCarAcceptButton.isHidden = false
        findMyCarCancelButton.isHidden = false
    }

    private func hideFindMyCarUIElements() {
//        findMyCarView?.isHidden = true
//        findMyCarButton.isHidden = false
//        navigateToCarButton.isHidden = false
        positionPickerImage?.isHidden = true
        findMyCarModeActive = false
        findMyCarAcceptButton.isHidden = true
        findMyCarCancelButton.isHidden = true
    }

    func findMyCarMode() {
        findMyCarModeActive = true
        mapContainerViewTopConstraint.constant = 44
        infoBarMap.isHidden = true
        infoBarNavigation.isHidden = true
        indicationsView.isHidden = true
        navbar.isHidden = true
        displayFindMyCarUIElements()
    }
    
    func hiddenNavBar() {
        mapContainerViewTopConstraint.constant = 0
        infoBarMap.isHidden = false
        navbar.isHidden = true
        hideFindMyCarUIElements()
    }
}

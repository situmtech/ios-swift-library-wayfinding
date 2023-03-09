//MARK: Change between ui of different modes (default, navigation)
extension PositioningViewController {
    func showPositioningUI() {
        mapContainerViewTopConstraint.constant = 44
        infoBarMap.isHidden = false
        infoBarNavigation.isHidden = true
        indicationsView.isHidden = true
        navbar.isHidden = false
        containerInfoBarMap?.isBeingPresented()
        hideCustomPoiCreationUIElements()
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
        hideCustomPoiCreationUIElements()
    }
    
    private func displayCustomPoiCreationUIElements() {
        positionPickerImage.isHidden = false
        customPoiCreationModeActive = true
        customPoiAcceptButton.isHidden = false
        customPoiCancelButton.isHidden = false
    }

    private func hideCustomPoiCreationUIElements() {
        positionPickerImage?.isHidden = true
        customPoiCreationModeActive = false
        customPoiAcceptButton.isHidden = true
        customPoiCancelButton.isHidden = true
    }

    func customPoiCreationUI() {
        customPoiCreationModeActive = true
        mapContainerViewTopConstraint.constant = 44
        infoBarMap.isHidden = true
        infoBarNavigation.isHidden = true
        indicationsView.isHidden = true
        navbar.isHidden = true
        displayCustomPoiCreationUIElements()
    }
    
    func hiddenNavBar() {
        mapContainerViewTopConstraint.constant = 0
        infoBarMap.isHidden = false
        navbar.isHidden = true
        hideCustomPoiCreationUIElements()
    }
}

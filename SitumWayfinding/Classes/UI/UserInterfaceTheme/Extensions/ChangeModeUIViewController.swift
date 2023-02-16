//MARK: Change between ui of different modes (default, navigation)
extension PositioningViewController {
    func showPositioningUI() {
        mapContainerViewTopConstraint.constant = 44
        infoBarMap.isHidden = false
        infoBarNavigation.isHidden = true
        indicationsView.isHidden = true
        navbar.isHidden = false
        containerInfoBarMap?.isBeingPresented()
        hideCustomPoiSelectionUIElements()
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
        hideCustomPoiSelectionUIElements()
    }
    
    private func displayCustomPoiSelectionUIElements() {
        positionPickerImage.isHidden = false
        customPoiSelectionModeActive = true
        customPoiAcceptButton.isHidden = false
        customPoiCancelButton.isHidden = false
    }

    private func hideCustomPoiSelectionUIElements() {
        positionPickerImage?.isHidden = true
        customPoiSelectionModeActive = false
        customPoiAcceptButton.isHidden = true
        customPoiCancelButton.isHidden = true
    }

    func customPoiSelectionMode() {
        deselect(marker: lastSelectedMarker)
        customPoiSelectionModeActive = true
        mapContainerViewTopConstraint.constant = 44
        infoBarMap.isHidden = true
        infoBarNavigation.isHidden = true
        indicationsView.isHidden = true
        navbar.isHidden = true
        displayCustomPoiSelectionUIElements()
    }
    
    func hiddenNavBar() {
        mapContainerViewTopConstraint.constant = 0
        infoBarMap.isHidden = false
        navbar.isHidden = true
        hideCustomPoiSelectionUIElements()
    }
}

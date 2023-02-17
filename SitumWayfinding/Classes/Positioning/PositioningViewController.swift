//
//  PositioningViewController.swift
//  SitumMappingTool
//
//  Created by Cristina Sánchez Barreiro on 05/04/2019.
//  Copyright © 2019 Situm Technologies S.L. All rights reserved.
//

import UIKit
import GoogleMaps
import os
import SitumSDK

let SecondsBetweenAlerts = 30.0
let SitumURL = "https://dashboard.situm.com"

class PositioningViewController: SitumViewController, GMSMapViewDelegate, UITableViewDataSource, UITableViewDelegate, PositioningView, PositioningController {
    //MARK PositioningController protocol variables
    var buildingId: String = ""
    var library: SitumMapsLibrary? {
        willSet(newLibrary) {
            UIColorsTheme.useDashboardTheme = newLibrary?.settings?.useDashboardTheme ?? false
        }
    }
    var delegateNotifier: WayfindingDelegatesNotifier? {
        return library?.delegatesNotifier
    }
    var useRemoteConfig: Bool = false
    //Positioning
    @IBOutlet weak var navbar: UINavigationBar!
    @IBOutlet weak var mapContainerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var positioningButton: UIButton!
    @IBOutlet weak var levelsTableView: UITableView!
    @IBOutlet weak var levelsTableHeightConstaint: NSLayoutConstraint!
    @IBOutlet weak var centerButton: UIButton!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var numberBeaconsRangedView: UIView!
    @IBOutlet weak var numberBeaconsRangedLabel: UILabel!
    @IBOutlet weak var positioningButtonLoadingIndicator: UIActivityIndicatorView!
    //Navigation
    @IBOutlet weak var indicationsView: UIView!
    weak var indicationsViewController: IndicationsViewController?
    @IBOutlet weak var navigationButton: UIButton!
    @IBOutlet weak var deletePoiButton: UIButton!
    
    //Find my car
    @IBOutlet weak var positionPickerImage: UIImageView!
    @IBOutlet weak var customPoiAcceptButton: UIButton!
    @IBOutlet weak var customPoiCancelButton: UIButton!
    
    @IBOutlet weak var infoBarMap: UIView!
    weak var containerInfoBarMap: InfoBarMapViewController?
    @IBOutlet weak var infoBarNavigation: UIView!
    weak var containerInfoBarNavigation: InfoBarNavigationViewController?
    
    //Map added from outside. We have to use containment view to allow
    //the map and the other layers appear in same screen
    var mapViewVC: UIViewController!
    var mapView: GMSMapView!
    //Loading
    var loadingError: Bool = false
    //Positioning
    var markerRenderer: MarkerRenderer?
    var buildingManager: BuildingManager?
    var mapOverlay: GMSGroundOverlay = GMSGroundOverlay()
    var floorplans: Dictionary<String, UIImage> = [:]
    let iconsStore: IconsStore = IconsStore()
    var userMarkerIcons: Dictionary<String, UIImage> = [:]
    var lastBearing: Float = 0.0
    var lastAnimatedBearing: Float = 0.0
    var isCameraCentered: Bool = false
    let locManager: CLLocationManager = CLLocationManager()
    var buildingInfo: SITBuildingInfo? = nil
    var buildingName: String { return self.buildingInfo?.building.name ?? DEFAULT_BUILDING_NAME }
    var isFirstLoadingOfFloors: Bool = true
    var actualZoom: Float = 0.0
    var selectedLevelIndex: Int = 0
    let floorSelectorCornerRadius = RoundCornerRadius.big
    var presenter: PositioningPresenter? = nil
    var positionDrawer: PositionDrawerProtocol? = nil
    //Navigation
    var lastSelectedMarker: SitumMarker?
    var lastCustomMarker: SitumMarker?
    var destinationMarker: SitumMarker?
    var destinationString: String { return self.destinationMarker?.gmsMarker.title ?? DEFAULT_POI_NAME }
    var polyline: Array<GMSPolyline> = []
    var routePath: Array<GMSMutablePath> = []
    var loadFinished: Bool = false
    // Custom markerses
    var customPoi: CustomPoi?
    // TODO abstract the name and description logic to a new controller
    var customPoiName: String?
    var customPoiDescription: String?
    let customMarker = GMSMarker()
    // Customization
    var organizationTheme: SITOrganizationTheme?
    //Search
    @IBOutlet weak var searchBar: UISearchBar!
    var searchResultsController: SearchResultsTableViewController?
    var searchController: UISearchController?
    var searchResultViewConstraints: [NSLayoutConstraint]?
    // readiness of map
    private var mapReadinessChecker: SitumMapReadinessChecker!
    // hold reference of fake ui builder to avoid premature release
    private var fakeUI: FakeLocationUIBuilder?
    // Constants
    let DEFAULT_SITUM_COLOR = "#283380"
    let DEFAULT_POI_NAME: String = "POI"
    let DEFAULT_BUILDING_NAME: String = "Current Building"
    var lock = false
    var changeOfFloorMarker = GMSMarker()
    var tileProvider: TileProvider!
    var preserveStateInNewViewAppeareance = false
    // Find my car mode variables
    var customPoiSelectionModeActive = false
    var carPositionKey = "car_parking_position"
    var customPoiManager = CustomPoiManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        mapContainerViewTopConstraint.constant = 44
        backButton.title = NSLocalizedString("positioning.back",
            bundle: SitumMapsLibrary.bundle,
            comment: "Button to go back when the user is in the positioning controller (where the map is shown)")
        customizeBackButtonColor()
        self.displayElementsNavBar()
        definesPresentationContext = true
        mapReadinessChecker = SitumMapReadinessChecker { [weak self] in
            guard let instance = self else { return }
            if let library = instance.library {
                instance.delegateNotifier?.notifyOnMapReady(map: library)
            }
        }

        self.initializeChangeOfFloorMarker()
        self.retrieveCustomPoi(poiKey: self.carPositionKey)

        do {
            let fonts = ["Roboto-Black", "Roboto-Bold", "Roboto-Medium", "Roboto-Regular"]
            try FontLoader.registerFonts(fonts: fonts)
        } catch {
            print("Error: Can't load fonts")
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (!preserveStateInNewViewAppeareance || positionDrawer == nil){
            self.initializeViewBeforeAppearing()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeLocationListener()
    }

    override func viewDidLayoutSubviews() {
        //In viewWillAppear layout hasnt finished yet
        addMap()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if CLLocationManager.locationServicesEnabled() {
            let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
            if status == CLAuthorizationStatus.notDetermined {
                self.locManager.requestAlwaysAuthorization()
            }
        }
    }

    func initializeViewBeforeAppearing(){
        positionDrawer = GoogleMapsPositionDrawer(mapView: mapView)
        let loading = NSLocalizedString("alert.loading.title",
            bundle: SitumMapsLibrary.bundle,
            comment: "Alert title when loading library")
        let message = NSLocalizedString("alert.loading.message",
            bundle: SitumMapsLibrary.bundle,
            comment: "Alert message when loading library")
        let loadingAlert = UIAlertController(title: loading, message: message, preferredStyle: .actionSheet)
        self.present(loadingAlert, animated: true, completion: {
            if (self.loadFinished) {
                self.situmLoadFinished(loadingAlert: loadingAlert)
            }
        })
        
        SITCommunicationManager.shared().fetchBuildingInfo(self.buildingId, withOptions: nil, success: { (mapping: [AnyHashable : Any]?) in
            if (mapping != nil) {
                self.buildingInfo = mapping!["results"] as? SITBuildingInfo
                self.buildingManager = BuildingManager(buildingInfo: self.buildingInfo!)
                self.mapReadinessChecker.buildingInfoLoaded()
                if self.buildingManager == nil {
                    self.loadingError = true
                    self.situmLoadFinished(loadingAlert: loadingAlert)
                } else {
                    SITCommunicationManager.shared().fetchOrganizationTheme(options: nil, success: { (mapping: [AnyHashable : Any]?) in
                        print("Success retrieving details of organization")
                        if mapping != nil {
                            let organizationDetails = mapping!["results"] as? SITOrganizationTheme
                            print("Organization Details: \(organizationDetails)")
                            
                            // Now we have the organization details and we can work with their values (if any)
                            UIColorsTheme.organizationTheme = organizationDetails!

                            self.situmLoadFinished(loadingAlert: loadingAlert)
                            self.presenter = PositioningPresenter(view: self, buildingInfo: self.buildingInfo!, interceptorsManager: self.library?.interceptorsManager ?? InterceptorsManager())
                            if let lib = self.library {
                                if let set = lib.settings {
                                    self.presenter?.useRemoteConfig = set.useRemoteConfig
                                }
                            }
                            self.addLocationListener()
                            self.initializeUIElements()
                        }
                    }, failure: { (error: Error?) in
                        print("Failed retrieving details of org")
                        // Use default values instead of an error
                        self.loadingError = true
                        self.situmLoadFinished(loadingAlert: loadingAlert)
                    })
                }
            }
        }, failure: { (error: Error?) in
            Logger.logErrorMessage(error.debugDescription)
            self.loadingError = true;
            self.situmLoadFinished(loadingAlert: loadingAlert)
        })

    }
    
    func displayElementsNavBar() {
        navbar.topItem?.title = ""
        
        if (self.showSearchBar()) {
            initSearchController()
        }
        
        if (!self.showBackButton()) {
            navbar.topItem?.leftBarButtonItem = nil
        }
    }

    func situmLoadFinished(loadingAlert: UIAlertController) {
        loadingAlert.dismiss(animated: true) {
            if (self.loadingError) {
                let title = NSLocalizedString("alert.error.building.title",
                    bundle: SitumMapsLibrary.bundle,
                    comment: "Alert title after an error retrieving a building happens")
                let message = NSLocalizedString("alert.error.building.message",
                    bundle: SitumMapsLibrary.bundle,
                    comment: "Alert message after an error retrieving a building happens")
                self.showAlertMessage(title: title, message: message, alertType: .otherAlert)
            }
        }
        loadFinished = true
    }
    
    //MARK: Initializers
    func addLocationListener() {
        if let presenter = presenter {
            presenter.addLocationListener()
        }
    }

    func removeLocationListener() {
        if let presenter = presenter {
            presenter.removeLocationListener()
        }
    }

    func initializeUIElements() {
        initializeMapView()
        initializeMarkerMapRenderer()
        initializePositioningUIElements()
        initializeIcons()
        customizeBackButtonColor()
    }

    func customizeBackButtonColor(){
        backButton?.tintColor = uiColorsTheme.primaryColor
    }
    
    func addMap() {
        self.mapViewVC.view = mapView
        tileProvider = TileProvider(mapView: mapView)
    }
    
    func initializeMapView() {
        floorplans = Dictionary()
        mapView.isIndoorEnabled = false
        mapView.delegate = self
        lastBearing = 0.0
        lastAnimatedBearing = 0.0
        
        let zoom: Float = actualZoom > 0.0 ? actualZoom : 18.0
        
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees
        
        if let coordinate = presenter?.userLocation?.position.coordinate() {
            latitude = coordinate.latitude
            longitude = coordinate.longitude
        } else {
            latitude = (buildingInfo?.building.center().latitude)!
            longitude = (buildingInfo?.building.center().longitude)!
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: zoom)
        // Check if values are correct (!= -1). Otherwise it could break the app.
        var zoomValues = minMaxZoomValues()
        mapView.setMinZoom(zoomValues.minZoom, maxZoom: zoomValues.maxZoom)
        mapView.camera = camera
    }

    func minMaxZoomValues() -> (minZoom: Float, maxZoom: Float) {
        var minZoom = self.library!.settings!.minZoom
        if minZoom <= 0 || minZoom < kGMSMinZoomLevel {
            minZoom = kGMSMinZoomLevel
        }
        
        var maxZoom = self.library!.settings!.maxZoom
        if (maxZoom <= 0 || maxZoom <= minZoom || maxZoom > kGMSMaxZoomLevel) {
            maxZoom = kGMSMaxZoomLevel
        }

        return (minZoom, maxZoom)
    }
    
    func initializePositioningUIElements() {
        initializePositioningButton()
        hideCenterButton()
        initializeLevelIndicator()
        initializeNavigationButton()
        initializeDeletePoiButton()
        initializeInfoBar()
        prepareCenterButton()
        initializeCustomPoiSelectionButtons()
        numberBeaconsRangedView.isHidden = true
    }

    func initializeIcons() {
        let bundle = Bundle(for: type(of: self))
        let userLocIconName = getIconNameOrDefault(iconName: library?.settings?.userPositionIcon, defaultIconName: "swf_location")
        let userLocArrowIconName = getIconNameOrDefault(iconName: library?.settings?.userPositionArrowIcon, defaultIconName: "swf_location_pointer")

        if let locationPointer = UIImage(named: userLocArrowIconName, in: bundle, compatibleWith: nil),
           let locationOutdoorPointer = UIImage(named: "swf_location_outdoor_pointer", in: bundle, compatibleWith: nil),
           let location = UIImage(named: userLocIconName, in: bundle, compatibleWith: nil),
           let radius = UIImage(named: "swf_radius", in: bundle, compatibleWith: nil) {

            userMarkerIcons = [
                "swf_location_pointer" : locationPointer,
                "swf_location_outdoor_pointer" : locationOutdoorPointer,
                "swf_location" : location,
                "swf_radius" : radius
            ]
        }
    }
    
    func initializeMarkerMapRenderer() {
        guard let mapView = mapView, let buildingManager = buildingManager else {
            Logger.logDebugMessage("Marker renderer could not be created because mapView and building info is not set or is incorrect")
            return
        }
        let isClusteringEnabled = library?.settings?.enablePoisClustering ?? false
        markerRenderer = MarkerRenderer(mapView: mapView, buildingManager: buildingManager, iconsStore: iconsStore, showPoiNames:
            showPoiNames(), isClusteringEnabled: isClusteringEnabled)
    }

    private func getIconNameOrDefault(iconName: String?, defaultIconName: String) -> String {
        (iconName ?? "").isEmpty ? defaultIconName : iconName!
    }
    
    func initializePositioningButton() {
        positioningButton.layer.cornerRadius = 0.5 * positioningButton.bounds.size.width
        positioningButton.layer.masksToBounds = false
        positioningButton.isHidden = !(self.library?.settings?.positioningFabVisible ?? true)
        updatePositioningButtonImage(name: "swf_ic_action_no_positioning",state:.normal)
        customizePositioningButtonColor()

        positioningButtonLoadingIndicator.hidesWhenStopped = true
        if let presenter = presenter {
            initializePositioningButtonWithLocationState(presenter.locationManager.state())
        } else {
            initializePositioningButtonWithLocationState(.stopped)
        }
    }

    func updatePositioningButtonImage(name: String?, state:UIControl.State){
        let positioningButtonColors = colorsForPositioningButton()
        positioningButton.configure(imageName: name, buttonColors: positioningButtonColors, for: state)
    }

    func customizePositioningButtonColor() {
        let positioningButtonColors = colorsForPositioningButton()
        positioningButton.adjustColors(positioningButtonColors)
        positioningButton.setSitumShadow(colorTheme: uiColorsTheme)
    }

    func colorsForPositioningButton() -> ButtonColors{
        var buttonsColors: ButtonColors
        if positioningButton.isSelected{
            buttonsColors = ButtonColors(iconTintColor: uiColorsTheme.backgroundedButtonsIconstTintColor, backgroundColor: uiColorsTheme.primaryColor)
        }else{
            buttonsColors = ButtonColors(iconTintColor: uiColorsTheme.iconsTintColor, backgroundColor: uiColorsTheme.backgroundColor)
        }
        return buttonsColors
    }

    private func initializePositioningButtonWithLocationState(_ currentState: SITLocationState) {
        // if current state is started we do not know location yet so we set the calculating state
        // When the first location arrives in delegate interface will be updated accordingly
        if currentState == SITLocationState.started {
            changeLocationState(.calculating, centerCamera: true)
        } else {
            changeLocationState(currentState, centerCamera: true)
        }
    }

    func initializeLoadingIndicator() {
        positioningButtonLoadingIndicator.isHidden = true
        positioningButtonLoadingIndicator.hidesWhenStopped = true
        customizeLoadingIndicatorColor()
    }

    func customizeLoadingIndicatorColor(){
        positioningButtonLoadingIndicator.color = uiColorsTheme.iconsTintColor
    }
    
    func initializeLevelIndicator() {
        selectedLevelIndex = 0
        levelsTableView.alwaysBounceVertical = false
        levelsTableView.dataSource = self
        levelsTableView.delegate = self
        levelsTableView.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: floorSelectorCornerRadius)

        initializeLevelSelector()
        
        let indexPath = getDefaultFloorFirstLoad()
        levelsTableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
        tableView(levelsTableView, didSelectRowAt: indexPath)
        levelsTableView.isHidden = !(self.library?.settings?.floorsListVisible ?? true)
    }
    
    private func getDefaultFloorFirstLoad() -> IndexPath {
        var indexPath = IndexPath(row: 0, section: 0)
        
        if (buildingInfo?.floors.count ?? 0 > 1) {
            indexPath.row = buildingInfo!.floors.count - 1
        }
        
        return indexPath
    }
    
    func customPoiSelectionMode(name: String, description: String?) {
        if (self.customPoiSelectionModeActive) {
            print("Custom poi selection mode is already active")
        } else {
            if(SITNavigationManager.shared().isRunning()) {
                print("Cannot edit custom pois while navigating")
            } else {
                self.customPoiName = name
                self.customPoiDescription = description
                self.deselect(marker: lastSelectedMarker)
                self.customPoiSelectionUI()
            }
        }
    }
    
    private func retrieveCustomPoi(poiKey: String) {
        self.customPoi =  customPoiManager.get(poiKey: poiKey)
    }
    
    private func deleteCustomPoi(poiKey: String) {
        self.customPoi = nil
        customPoiManager.remove(poiKey: poiKey)
        
        deselect(marker: lastSelectedMarker, notifyDelegate: false)
        delegateNotifier?.notifyOnCustomPoiRemoved(poiId: poiKey)
        
        if let floor = orderedFloors(buildingInfo: buildingInfo)?[self.selectedLevelIndex] {
            displayMarkers(forFloor: floor, isUserNavigating: self.isUserNavigating())
        }
    }
    
    func removeCustomPoi() {
        self.deleteCustomPoi(poiKey: carPositionKey)
    }
    
    func storeCustomPoi(poiKey: String, name: String, description: String, buildingId: String, floorId: String, lat: Double, lng: Double) {
        customPoi = CustomPoi(key: poiKey, name: name, description: description, buildingId: buildingId, floorId: floorId, latitude: lat, longitude: lng)
        
        customPoiManager.store(customPoi: customPoi!)
        delegateNotifier?.notifyOnCustomPoiSet(customPoi: customPoi!)
        
        if let floor = orderedFloors(buildingInfo: buildingInfo)?[self.selectedLevelIndex] {
            displayMarkers(forFloor: floor, isUserNavigating: self.isUserNavigating())
        }
    }
    
    private func initializeCustomPoiSelectionButtons() {
        // Find my car menu
        customPoiAcceptButton.layer.cornerRadius = 0.5 * customPoiAcceptButton.bounds.size.width
        customPoiAcceptButton.layer.masksToBounds = false
        customPoiAcceptButton.setSitumShadow(colorTheme: uiColorsTheme)
        let acceptButtonColors =  ButtonColors(iconTintColor: uiColorsTheme.backgroundedButtonsIconstTintColor, backgroundColor: uiColorsTheme.primaryColor)
        customPoiAcceptButton.adjustColors(acceptButtonColors)
        customPoiAcceptButton.isHidden = true

        // Navigate to car button
        customPoiCancelButton.layer.cornerRadius = 0.5 * customPoiCancelButton.bounds.size.width
        customPoiCancelButton.layer.masksToBounds = false
        customPoiCancelButton.setSitumShadow(colorTheme: uiColorsTheme)
        let cancelButtonColors =  ButtonColors(iconTintColor: uiColorsTheme.backgroundedButtonsIconstTintColor, backgroundColor: uiColorsTheme.dangerColor)
        customPoiCancelButton.adjustColors(cancelButtonColors)
        customPoiCancelButton.isHidden = true

    }
    
    func initializeNavigationButton() {
        navigationButton.layer.cornerRadius = 0.5 * navigationButton.bounds.size.width
        navigationButton.layer.masksToBounds = false
        navigationButton.setIcon(imageName: "situm_navigate_action", for: .normal)
        customizeNavigationButtonColor()
        navigationButton.isHidden = true
    }
    
    private func initializeDeletePoiButton() {
        deletePoiButton.layer.cornerRadius = 0.5 * deletePoiButton.bounds.size.width
        deletePoiButton.layer.masksToBounds = false
        deletePoiButton.setSitumShadow(colorTheme: uiColorsTheme)
        let buttonColors =  ButtonColors(iconTintColor: uiColorsTheme.backgroundedButtonsIconstTintColor, backgroundColor: uiColorsTheme.dangerColor)
        deletePoiButton.adjustColors(buttonColors)
        deletePoiButton.isHidden = true
    }

    func customizeNavigationButtonColor(){
        navigationButton.setSitumShadow(colorTheme: uiColorsTheme)
        let buttonColors =  ButtonColors(iconTintColor: uiColorsTheme.backgroundedButtonsIconstTintColor, backgroundColor: uiColorsTheme.primaryColor)
        navigationButton.adjustColors(buttonColors)
    }
    
    func initializeInfoBar() {
        if (self.showBackButton() || self.showSearchBar()) {
            self.showPositioningUI()
        }
        
        if (!self.showSearchBar() && !self.showBackButton()) {
            self.hiddenNavBar()
        }
        
        self.containerInfoBarMap?.setLabels(primary: self.buildingName)
        if UIColorsTheme.organizationTheme?.logo != nil {
            // Bring the image and save it on cache
            if (library?.settings?.useDashboardTheme == false) {
                return
            }
            
            let logoUrl = SitumURL + UIColorsTheme.organizationTheme!.logo.direction
            let data = NSData(contentsOf: URL(string: logoUrl)!) as Data?
            if let data = data {
                let image = UIImage.init(data: data)
                containerInfoBarMap?.setLogo(image: image)
                containerInfoBarNavigation?.setLogo(image: image)
            }
        }
    }
    
    //MARK: Floorplans
    func displayMap(forLevel selectedLevelIndex: Int) {
        guard let buildingInfo = buildingInfo else {
            Logger.logDebugMessage("Building info not set in PositioningViewController")
            return
        }
        guard let floor = orderedFloors(buildingInfo: buildingInfo)?[selectedLevelIndex] else {
            Logger.logDebugMessage("Floor not found on building: \(buildingInfo)")
            return
        }
        if floorplans[floor.identifier] != nil {
            displayFloorPlan(forFloor: floor)
            self.mapReadinessChecker.currentFloorMapLoaded()
        } else {
            fetchMap(floor: floor)
        }
    }
    
    private func fetchMap(floor: SITFloor) {
        let title = NSLocalizedString("positioning.error.emptyFloor.alert.title",
                bundle: SitumMapsLibrary.bundle,
                comment: "Alert title error when download the floor plan fails")
        let message = NSLocalizedString("positioning.error.emptyFloor.alert.message",
                bundle: SitumMapsLibrary.bundle,
                comment: "Alert title error when download the floor plan fails")

        SITCommunicationManager.shared().fetchMap(
            from: orderedFloors(buildingInfo: buildingInfo)![selectedLevelIndex],
            withCompletion: { imageData in
                if let imageData = imageData {
                    let image =  UIImage.init(data: imageData, scale: UIScreen.main.scale)
                    let scaledImage = ImageUtils.scaleImage(image: image!)
                    self.floorplans[floor.identifier] = scaledImage
                    self.displayFloorPlan(forFloor: floor)
                    self.mapReadinessChecker.currentFloorMapLoaded()
                } else {
                    self.showAlertMessage(title: title, message: message, alertType: .otherAlert)
                }
            })
    }

    func filterPois(by categoryIds: [String]) {
        buildingManager?.setPoiFilters(by: categoryIds)
    }

    func displayFloorPlan(forFloor floor: SITFloor) {
        self.mapOverlay.map = nil
        let bounds: SITBounds = buildingInfo!.building.bounds()
        let coordinateBounds = GMSCoordinateBounds(coordinate: bounds.southWest, coordinate: bounds.northEast)
        let mapOverlay = GMSGroundOverlay(bounds: coordinateBounds, icon: floorplans[floor.identifier])
        
        self.mapOverlay = mapOverlay
        self.mapOverlay.bearing = CLLocationDirection(buildingInfo!.building.rotation.degrees())
        self.mapOverlay.zIndex = ZIndices.floorPlan
        self.mapOverlay.map = mapView
        displayMarkers(forFloor: floor, isUserNavigating: SITNavigationManager.shared().isRunning())
        tileProvider.addTileFor(floor: floor)
    }
    
    func orderedFloors(buildingInfo: SITBuildingInfo?) -> [SITFloor]? {
        if let bInfo = buildingInfo {
            return bInfo.floors.reversed()
        }
        
        return []
    }
    
    //PositioningView protocol method
    func setCameraCentered() {
        isCameraCentered = true
        hideCenterButton()
    }
    
    func reloadFloorPlansTableViewData() {
        levelsTableView.reloadData()
    }
    
    //PositioningView protocol method
    func select(floor floorId: String) {
        if let indexPath = getIndexPath(floorId: floorId) {
            tableView(levelsTableView, didSelectRowAt: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select(floor: indexPath)
    }
    
    func select(floor floorIndex: IndexPath) {
        resetChangeOfFloorMarker()

        let isSameLevel = floorIndex.row == self.selectedLevelIndex
        // When it is the first loading of floors, whe always load the floor. This is to avoid a bug when only one floor
        // exists and floor is no loading because of previous condition. We should decouple tableview/load floors in the
        // future to avoid using global flags in class
        if isSameLevel && !isFirstLoadingOfFloors {
            return
        }
        isFirstLoadingOfFloors = false
        if let uBuildingInfo = buildingInfo,
           let from = orderedFloors(buildingInfo: buildingInfo)?[selectedLevelIndex],
           let to = orderedFloors(buildingInfo: buildingInfo)?[floorIndex.row] {
            delegateNotifier?.notifyOnFloorChanged(from: from, to: to, buildingInfo: uBuildingInfo)
        }
        self.removeLastCustomMarkerIfOutsideRoute()
        self.selectedLevelIndex = floorIndex.row
        self.reloadFloorPlansTableViewData()
        self.displayMap(forLevel: self.selectedLevelIndex)
        if (presenter?.userLocation != nil && !isSameLevel) {
            self.isCameraCentered = false
            self.showCenterButton()
            self.updateUI(with: self.presenter!.userLocation!)
        }
        levelsTableView.scrollToRow(at: floorIndex, at: .middle, animated: true)
    }
    
    //MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buildingInfo!.floors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "LevelCellIdentifier")
        cell?.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: floorSelectorCornerRadius)

        if let level: SITFloor = orderedFloors(buildingInfo: buildingInfo)?[indexPath.row] {
            // [06/08/19] This check is here because older buildings without the name field give unexpected nulls casted to string
            let shouldDisplayLevelName = !(level.name.isEmpty || (level.name == "<null>"))
            let textToDisplay: String = shouldDisplayLevelName ? level.name : String(level.floor)
            cell?.textLabel?.text = String(format: "%@", textToDisplay)
            let cellCollors  = getCellColors(forFloor: level, atRow: indexPath.row)
            cell?.textLabel?.textColor = cellCollors.textColor
            cell?.backgroundColor = cellCollors.backgroundColor
        }
        return cell!
    }
    
    func initializeLevelSelector() {
        if self.buildingInfo!.floors.count < 5 {
            self.levelsTableHeightConstaint.constant = CGFloat(Double(self.buildingInfo!.floors.count) * 43.5)
        } else {
            self.levelsTableHeightConstaint.constant = CGFloat(5 * 43.5)
        }
        self.levelsTableView.layoutIfNeeded()
        self.levelsTableView.reloadData()
    }
    
    //MARK: Markers
    
    func updateUserBearing(with location: SITLocation) {
        if PositioningUtils.hasBearingChangedEnoughToReloadUi(newBearing: location.bearing.degrees(), lastAnimatedBearing: lastAnimatedBearing) {
            positionDrawer?.updateUserBearing(with: location)
            //Relocate camera
            if isCameraCentered {
                mapView.animate(toBearing: CLLocationDirection(location.bearing.degrees()))
            }
            lastAnimatedBearing = location.bearing.degrees()
        }
    }
    
    //MARK: Handle camera
    func showCenterButton() {
        positioningButton.isHidden = true
        centerButton.isHidden = false
    }
    
    func hideCenterButton() {
        centerButton.isHidden = true
        if (!(SITNavigationManager.shared().isRunning())) {
            positioningButton.isHidden = !(self.library?.settings?.positioningFabVisible ?? true)
        }
    }
    
    func updateCamera(with location: SITLocation) {
        if isCameraCentered {
            let position = location.position
            let cameraUpdate = GMSCameraUpdate.setTarget(position.coordinate())
            mapView.animate(with: cameraUpdate)
        }
    }
    
    func changeLocationState(_ state: SITLocationState, centerCamera: Bool) {
        changePositioningButton(toState: state)
        isCameraCentered = centerCamera
    }
    
    private func changePositioningButton(toState state: SITLocationState) {
        let bundle = Bundle(for: type(of: self))

        switch state {
        case .stopped:
            positioningButton.isSelected = false
            updatePositioningButtonImage(name: "swf_ic_action_no_positioning", state: .normal)
            positioningButtonLoadingIndicator.isHidden = true
            positioningButtonLoadingIndicator.stopAnimating()
        case .calculating:
            positioningButton.isSelected = false
            updatePositioningButtonImage(name: nil, state: .normal)
            positioningButtonLoadingIndicator.isHidden = false
            positioningButtonLoadingIndicator.startAnimating()
        case .started:
            positioningButton.isSelected = true
            updatePositioningButtonImage(name: "swf_ic_action_localize", state: .selected)
            positioningButtonLoadingIndicator.isHidden = true
            positioningButtonLoadingIndicator.stopAnimating()
        default:
            // Button shouldn't react to outOfBuilding, compassNeedsCalibration and other states
            break
        }
    }
    
    func changeNavigationButtonVisibility(isVisible visible: Bool) {
        if (visible) {
            navigationButton.isHidden = false
        } else {
            navigationButton.isHidden = true
            changeDeletePoiButtonVisibility(isVisible: false)
        }
    }
    
    func changeDeletePoiButtonVisibility(isVisible visible: Bool) {
        if (visible) {
            deletePoiButton.isHidden = false
        } else {
            deletePoiButton.isHidden = true
        }
    }
    
    
    //MARK: MapViewDelegate
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        Logger.logDebugMessage("Map will move with gesture: \(gesture)")
        if isCameraCentered && gesture {
            isCameraCentered = false
            showCenterButton()
        }
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        if position.zoom < 15 {
            positioningButton.isHidden = true
            centerButton.isHidden = true
            levelsTableView.isHidden = true
        } else {
            if isCameraCentered || presenter?.userLocation == nil {
                hideCenterButton()
            } else {
                showCenterButton()
            }
            levelsTableView.isHidden = !(self.library?.settings?.floorsListVisible ?? true)
        }
        
        if (presenter?.shouldCameraPositionBeDraggedInsideBuildingBounds(position: position.target) ?? false) {
            if let cameraInsideBounds = presenter?.modifyCameraToBeInsideBuildingBounds(camera: position) {
                mapView.animate(to: cameraInsideBounds)
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        select(gmsMarker: marker)
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        // at this point google maps selectedMarker should be nil (library is in charge of this right now)
        deselect(marker: lastSelectedMarker)
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        guard let buildingInfo = buildingInfo else {
            Logger.logDebugMessage("Building info not set in PositioningViewController")
            return
        }
        guard let floor = orderedFloors(buildingInfo: buildingInfo)?[selectedLevelIndex] else {
            Logger.logDebugMessage("Floor not found on building: \(buildingInfo)")
            return
        }
        guard let manager = presenter?.locationManager else {
            Logger.logErrorMessage("At this moment a manager should exist attached to the presenter instance")
            return
        }
        
        deselect(marker: lastSelectedMarker)
        if !LocationManagerFactory.isFake(object: manager) {
            longPressAction(at: coordinate, forFloor: floor)
        } else {
            fakeLongPressAction(in: buildingInfo, with: manager, at: coordinate, forFloor: floor)
        }
    }
    
    private func fakeLongPressAction(
        in buildingInfo: SITBuildingInfo,
        with locationManager: SITLocationInterface,
        at coordinate: CLLocationCoordinate2D,
        forFloor floor: SITFloor
    ) {
        fakeUI = FakeLocationUIBuilder(buildingInfo: buildingInfo, locationManager: locationManager)
        let alert = fakeUI!.createFakeActionsAlert(
            coordinate: coordinate,
            floorId: floor.identifier,
            defaultAction: { [weak self] point in
                self?.longPressAction(at: coordinate, forFloor: floor)
            })
        present(alert, animated: true, completion: nil)
    }
    
    private func longPressAction(at coordinate: CLLocationCoordinate2D, forFloor floor: SITFloor) {
        createAndShowCustomMarkerIfOutsideRoute(atCoordinate: coordinate, forFloor: floor)
    }
    
    func mapViewSnapshotReady(_ mapView: GMSMapView) {
        mapReadinessChecker.setMapAsReady()
    }
    
    //MARK: IBActions
    @IBAction
    func positioningButtonrPressed(_ sender: Any) {
        Logger.logInfoMessage("Positioning Button Has Been pressed")
        self.presenter?.positioningButtonPressed()
    }
    
    @IBAction
    func navigationButtonPressed(_ sender: Any) {
        Logger.logInfoMessage("Navigation Button Has Been pressed")
        startNavigationByUser()
    }
    
    @IBAction func deletePoiButtonPressed(_ sender: Any) {
        deleteCustomPoi(poiKey: self.carPositionKey)
    }
    
    @IBAction func customPoiAcceptButtonTapped(_ sender: Any) {
        self.showPositioningUI()
        
        let markerPosition = self.mapView.projection.coordinate(for: CGPoint(x: self.mapView.center.x, y: self.mapView.center.y))
        if let floor = self.orderedFloors(buildingInfo: self.buildingInfo)?[self.selectedLevelIndex] {
            if let buildingInfo = self.buildingInfo {
                self.storeCustomPoi(
                    poiKey: self.carPositionKey,
                    name: self.customPoiName ?? "",
                    description: self.customPoiDescription ?? "",
                    buildingId: buildingInfo.building.identifier,
                    floorId: floor.identifier,
                    lat: markerPosition.latitude,
                    lng: markerPosition.longitude
                )
            }
        }
    }
    
    
    @IBAction func customPoiCancelButtonTapped(_ sender: Any) {
        self.showPositioningUI()
    }
    
    func startNavigationByUser() {
        self.startNavigation()
        if let category = getCategoryFromMarker(marker: self.lastSelectedMarker) {
            let navigation = WYFNavigation(status: .requested, destination: WYFDestination(category: category))
            self.delegateNotifier?.navigationDelegate?.onNavigationRequested(navigation: navigation)
        }
    }
    
    func startNavigation(to poi: SITPOI) {
        do {
            try self.select(poi: poi) { [weak self] in
                self?.startNavigation()
                let navigation = WYFNavigation(status: .requested, destination: WYFDestination(category: .poi(poi)))
                self?.delegateNotifier?.navigationDelegate?.onNavigationRequested(navigation: navigation)
            }
        } catch {
            Logger.logErrorMessage("poi \(poi) is not a valid poi in this building")
        }
    }
    
    func startNavigation(to location: CLLocationCoordinate2D, in floor: SITFloor) {
        guard let indexPath = getIndexPath(floorId: floor.identifier) else {
            return
        }
        select(floor: indexPath)
        createAndShowCustomMarkerIfOutsideRoute(atCoordinate: location, forFloor: floor)
        select(marker: lastCustomMarker!) { [weak self] in
            guard let positioningVC = self else { return }
            self?.startNavigation()
            let point = SITPoint(building: positioningVC.buildingInfo!.building, floorIdentifier: floor.identifier,
                coordinate: location)
            let navigation = WYFNavigation(status: .requested, destination: WYFDestination(category: .location(point)))
            self?.delegateNotifier?.navigationDelegate?.onNavigationRequested(navigation: navigation)
        }
    }
    
    /**
     Start navigation to selected marker. If no marker is selected this method will do nothing
     */
    private func startNavigation() {
        var destination = kCLLocationCoordinate2DInvalid
        if let marker = self.lastSelectedMarker {
            self.destinationMarker = marker
            destination = marker.gmsMarker.position
        }
        self.positioningButton.isHidden = true
        self.presenter?.startPositioningAndNavigate(withDestination: destination,
            inFloor: orderedFloors(buildingInfo: buildingInfo)![self.selectedLevelIndex].identifier)
        self.presenter?.centerViewInUserLocation()
        self.indicationsViewController?.setDestination(destination: destinationString)
        self.showNavigationUI()
    }
    
    @IBAction
    func goBackButtonPressed(_ sender: Any) {
        self.presenter?.view = nil
        if let callback: (Any) -> Void = self.library?.onBackPressedCallback {
            callback(sender)
        } else {
            if let navigationController = self.navigationController {
                navigationController.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
    }
    
    @IBAction
    func stopNavigatingButtonPressed(_ sender: UIButton) {
        stopNavigationByUser()
    }
    
    @IBAction
    func centerButtonPressed(_ sender: UIButton) {
        //        self.changeNavigationButtonVisibility(isVisible: false)
        presenter?.centerViewInUserLocation()
    }

    //MARK: PositioningView protocol methods
    func showNumberOfBeaconsRanged(text: Int) {
        if (self.numberBeaconsRangedView.isHidden) {
            self.numberBeaconsRangedView.isHidden = false
        }
        let format = NSLocalizedString("positioning.numBeacons",
            bundle: SitumMapsLibrary.bundle,
            comment: "Used to show the user the number of beacons that library detects nearby")
        self.numberBeaconsRangedLabel.text = String.localizedStringWithFormat(format, text)
    }
    
    func updateUI(with location: SITLocation) {
        updateUserMarker(with: location)
        updateCamera(with: location)
        updateUserBearing(with: location)
        presenter?.updateLevelSelector(location: location, isCameraCentered: self.isCameraCentered, selectedLevel: orderedFloors(buildingInfo: buildingInfo)![self.selectedLevelIndex].identifier)
    }
    
    func updateInfoBarLabelsIfNotInsideRoute(mainLabel title: String, secondaryLabel subtitle: String = "") {
        if (self.destinationMarker == nil) {
            self.containerInfoBarMap?.setLabels(primary: title, secondary: subtitle)
        }
    }
    
    func showAlertMessage(title: String, message: String, alertType: AlertType) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let title = NSLocalizedString("generic.ok", bundle: SitumMapsLibrary.bundle, comment: "Generic ok action")
        alert.addAction(UIAlertAction(title: title, style: .default, handler: { _ in
            self.presenter?.alertViewClosed(alertType)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showRoute(route: SITRoute) {
        changeNavigationButtonVisibility(isVisible: false)
       
        if let floor = orderedFloors(buildingInfo: buildingInfo)?[self.selectedLevelIndex] {
            displayMarkers(forFloor: floor, isUserNavigating: true)
        }
        notifyStartOfNavigation(marker: self.destinationMarker, route: route)
    }
    
    func updateProgress(progress: SITNavigationProgress) {
        self.containerInfoBarNavigation?.updateProgress(progress: progress)
        self.indicationsViewController?.setInstructions(progress: progress, destination: destinationString)
        
        // Update route based on this information
        for line in self.polyline {
            line.map = nil;
        }
        
        // Filter route steps for floors
        let selectedFloor = orderedFloors(buildingInfo: buildingInfo)?[self.selectedLevelIndex]
        self.generateAndPrintRoutePathWithRouteSegments(segments: progress.segments(), selectedFloor: selectedFloor!)
        let location: SITLocation = progress.closestLocationInRoute
        self.updateUI(with: location)
    }
    
    func createAndShowCustomMarkerIfOutsideRoute(
        atCoordinate coordinate: CLLocationCoordinate2D,
        forFloor floor: SITFloor
    ) {
        if (!isUserNavigating()) {
            if inside(coordinate: coordinate) {
                removeLastCustomMarkerIfOutsideRoute()
                lastCustomMarker = SitumMarker(coordinate: coordinate, floor: floor)
                lastSelectedMarker = lastCustomMarker
                containerInfoBarMap?.setLabels(primary: lastCustomMarker!.title, secondary: floorUILabel(with: lastCustomMarker!))
                changeNavigationButtonVisibility(isVisible: true)
                displayMarkers(forFloor: floor, isUserNavigating: false)
            } else {
                let title = NSLocalizedString("positioning.error.outsideBuilding.title",
                    bundle: SitumMapsLibrary.bundle,
                    comment: "Alert title error when the user try to set a custom location outside building")
                let message = NSLocalizedString("positioning.error.outsideBuilding.message",
                    bundle: SitumMapsLibrary.bundle,
                    comment: "Alert title message when the user try to set a custom location outside building")
                showAlertMessage(title: title, message: message, alertType: .otherAlert)
            }
        }
    }
    
    // MARK: SitumMapsLibrary methods
    func getGoogleMap() -> GMSMapView? {
        return self.mapView
    }
    
    func routeWillRecalculate() {
        containerInfoBarNavigation?.setLoadingState()
        indicationsViewController?.showNavigationLoading()
    }
    
    //MARK: Helper methods
    
    
    func showSearchBar() -> Bool {
        if let settings = self.library?.settings, let showSearchBar = settings.showSearchBar {
            return showSearchBar
        }
        
        return false
    }
    
    func showBackButton() -> Bool {
        if let settings = self.library?.settings, let showBackButton = settings.showBackButton {
            return showBackButton
        }
        
        return false
    }
    
    func inside(coordinate: CLLocationCoordinate2D) -> Bool {
        if let dimensions = buildingInfo?.building.dimensions(),
            let center = buildingInfo?.building.center(),
            let rotation = buildingInfo?.building.rotation {
            
            let converter = SITCoordinateConverter(
                dimensions: dimensions,
                center: center,
                rotation: rotation
            )
            
            let cartesianCoordinate = converter.toCartesianCoordinate(coordinate)
            
            return !(
                cartesianCoordinate.x > dimensions.width ||
                cartesianCoordinate.y > dimensions.height ||
                cartesianCoordinate.x < 0 ||
                cartesianCoordinate.y < 0
            )
            
        } else {
            return false
        }
    }
    
    func isUserNavigating() -> Bool {
        return self.destinationMarker != nil
    }
    
    func getCellColors(forFloor floor: SITFloor, atRow row: Int) -> ButtonColors {
        var cellCollors: ButtonColors
        
        if row == selectedLevelIndex {
            cellCollors = ButtonColors(iconTintColor: uiColorsTheme.textColor, backgroundColor: UIColor.lightGray)
        } else {
            cellCollors = ButtonColors(iconTintColor: uiColorsTheme.textColor, backgroundColor: uiColorsTheme.backgroundColor)
        }
        
        if let presenter = presenter {
            if presenter.isSameFloor(floorIdentifier: floor.identifier) {
                cellCollors = ButtonColors(iconTintColor: uiColorsTheme.backgroundedButtonsIconstTintColor, backgroundColor: uiColorsTheme.primaryColor)
            }
        }
        
        return cellCollors
    }
    
    func getIndexPath(floorId: String) -> IndexPath? {
        var indexPath: IndexPath? = nil
        for i in 0..<self.buildingInfo!.floors.count {
            if floorId == orderedFloors(buildingInfo: buildingInfo)![i].identifier {
                indexPath = IndexPath(item: i, section: 0);
                break;
            }
        }
        return indexPath;
    }
    
    func generateAndPrintRoutePathWithRouteSegments(segments: Array<SITRouteSegment>, selectedFloor: SITFloor) {
        let styles: [GMSStrokeStyle] = [.solidColor(
            uiColorsTheme.primaryColor), .solidColor(.clear)]
        let scale = 1.0 / mapView.projection.points(forMeters: 1, at: mapView.camera.target)
        let solidLine = NSNumber(value: 5.0 * Float(scale))
        let gap = NSNumber(value: 5.0 * Float(scale))
        
        resetChangeOfFloorMarker()

        for (index, segment) in segments.enumerated() {
            if segment.floorIdentifier == selectedFloor.identifier {
                self.updateChangeOfFloorMarker(forSelectedFloor: selectedFloor, withFloorSegment: segment)

                let path: GMSMutablePath = GMSMutablePath()
                for point in segment.points {
                    path.add(point.coordinate())
                }
                if (index == segments.endIndex - 1) {
                    if let lastPoint = self.destinationMarker?.gmsMarker.position {
                        path.add(lastPoint)
                    }
                }
                self.routePath.append(path)
                let polyline: GMSPolyline = GMSPolyline(path: path)
                polyline.strokeWidth = 6
                polyline.geodesic = true
                /*
                    To make the effect of the dotted line we pass as parameters 2 colours (blue and transparent - styles),
                    the size that the blue and transparent dots must have - solidLine and gap - and the type of logitude value, in this
                    case rhumb (rumbo).
                 */
                polyline.spans = GMSStyleSpans(polyline.path!, styles, [solidLine, gap], GMSLengthKind.rhumb)
                self.polyline.append(polyline)
                polyline.zIndex = ZIndices.route
                polyline.map = self.mapView
            }
        }
    }
    
    
    
    //MARK: Stop methods
    func stopNavigationByUser() {
        resetChangeOfFloorMarker()
        self.changeOfFloorMarker.position = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        stopNavigation(status: .canceled)
    }
    
    func cleanLocationUI() {
        self.makeUserMarkerVisible(visible: false)
        self.numberBeaconsRangedView.isHidden = true
        self.reloadFloorPlansTableViewData()
        self.hideCenterButton()
        self.changeLocationState(.stopped, centerCamera: false)
    }
    
    func stopNavigation(status: NavigationStatus) {
        presenter?.resetLastOutsideRouteAlert()
        SITNavigationManager.shared().removeUpdates()
        self.changeNavigationButtonVisibility(isVisible: false)
        self.showPositioningUI()
        if (!self.showSearchBar() && !self.showBackButton()) {
            self.hiddenNavBar()
        }
        self.containerInfoBarMap?.setLabels(primary: self.buildingName)
        for polyline in self.polyline {
            polyline.map = nil
        }
        self.removeLastCustomMarker()
        self.destinationMarker?.setMapView(mapView: nil)
        self.notifyEndOfNavigation(status: status, marker: self.destinationMarker)
        self.destinationMarker = nil
        self.lastSelectedMarker = nil
        if let floor = orderedFloors(buildingInfo: buildingInfo)?[self.selectedLevelIndex] {
            displayMarkers(forFloor: floor, isUserNavigating: false)
        }
    }
    
    private func notifyStartOfNavigation(marker: SitumMarker?, route: SITRoute?) {
        guard let navigation = buildNavigationObject(status: .started, marker: marker, route: route) else { return }
        self.delegateNotifier?.navigationDelegate?.onNavigationStarted(navigation: navigation)
    }

    private func notifyEndOfNavigation(status: NavigationStatus, marker: SitumMarker?) {
        guard let navigation = buildNavigationObject(status: status, marker: marker, route:nil) else { return }
        if case .error(let error) = status {
            self.delegateNotifier?.navigationDelegate?.onNavigationError(navigation: navigation, error: error)
            if let error = error as? NavigationError {
                switch error {
                case .positionUnknown:
                    let title = NSLocalizedString("positioning.error.positionUnknown.alert.title",
                        bundle: SitumMapsLibrary.bundle,
                        comment: "Alert title error when the user position is unknown")
                    self.showAlertMessage(title: title, message: error.localizedDescription, alertType: .otherAlert)
                case .outdoorOrigin:
                    let title = NSLocalizedString("positioning.error.positionOutdoor.alert.title",
                        bundle: SitumMapsLibrary.bundle,
                        comment: "Alert title error when the user is outdoor")
                    self.showAlertMessage(title: title, message: error.localizedDescription, alertType: .otherAlert)
                case .noDestinationSelected:
                    let title = NSLocalizedString("positioning.error.noDestinationSelected.alert.title",
                        bundle: SitumMapsLibrary.bundle,
                        comment: "Alert title error when the user does not select a destination")
                    self.showAlertMessage(title: title, message: error.localizedDescription, alertType: .otherAlert)
                case .unableToComputeRoute, .noAvailableRoute, .outsideBuilding:
                    let title = NSLocalizedString("positioning.error.unableToComputeRoute.alert.title",
                        bundle: SitumMapsLibrary.bundle,
                        comment: "Alert title error when WayFinding cannot compute route to destination")
                    self.showAlertMessage(title: title, message: error.localizedDescription, alertType: .otherAlert)
                case .locationError(let error):
                    let errorMessage = error?.localizedDescription ?? WayfindingError.unknown.localizedDescription
                    let title = NSLocalizedString("alert.error.title",
                        bundle: SitumMapsLibrary.bundle,
                        comment: "Alert title for generic errors ")
                    self.showAlertMessage(title: title, message: errorMessage, alertType: .otherAlert)
                }
            }
        } else {
            if case .destinationReached = status {
                let title = NSLocalizedString("positioning.destinationReached.alert.title",
                    bundle: SitumMapsLibrary.bundle,
                    comment: "Alert title to show to the user when destination was reached")
                let message = NSLocalizedString("positioning.destinationReached.alert.message",
                    bundle: SitumMapsLibrary.bundle,
                    comment: "Alert message to show to the user when destination was reached")
                self.showAlertMessage(title: title, message: message, alertType: .otherAlert)
            }
            self.delegateNotifier?.navigationDelegate?.onNavigationFinished(navigation: navigation)
        }
    }
    
    private func buildNavigationObject(status: NavigationStatus, marker: SitumMarker?, route:SITRoute?) -> Navigation? {
        guard let category = self.getCategoryFromMarker(marker: self.destinationMarker) else { return nil }
        let navigation = WYFNavigation(status: status, destination: WYFDestination(category: category),route: route)
        return navigation
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "mapContainerSegueID" {
                self.mapViewVC = segue.destination
            }
            if identifier == "infoBarMapSegue" {
                containerInfoBarMap = segue.destination as? InfoBarMapViewController
            }
            if identifier == "infoBarNavigationSegue" {
                containerInfoBarNavigation = segue.destination as? InfoBarNavigationViewController
            }
            if identifier == "topIndicationsSegue" {
                indicationsViewController = segue.destination as? IndicationsViewController
            }
        }
    }

    func getBuilding(buildingId: String, completion: @escaping (Result<SITBuilding, WayfindingError>) -> Void) {
        SITCommunicationManager.shared().fetchBuildingInfo(buildingId, withOptions: nil, success: { (mapping: [AnyHashable : Any]?) in
            if (mapping != nil) {
                guard let buildingInfoFilter = mapping!["results"] as? SITBuildingInfo else {
                    completion(.failure(.unknown))
                    return
                }
                completion(.success(buildingInfoFilter.building))
            }
        }, failure: { _ in
            completion(.failure(.unknown))
        })
    }
    
    func prepareCamera(building: SITBuilding) -> SITCameraOptions {
        return SITCameraOptions(minZoom: self.library!.settings!.minZoom, maxZoom: self.library!.settings!.maxZoom, southWestCoordinate: building.bounds().southWest, northEastCooordinate: building.bounds().northEast)
    }
    
    func lockCamera(options: SITCameraOptions) {
        self.lock = true
        let bounds = GMSCoordinateBounds(coordinate: options.southWestCoordinate, coordinate: options.northEastCooordinate)
        self.mapView.cameraTargetBounds = bounds
        let update = GMSCameraUpdate.fit(bounds, withPadding: 0.0)
        self.mapView.moveCamera(update)

        // Determine if values are outside min/max range. Cap zooms to min/max values
        var lockedMinZoom = self.mapView.camera.zoom - 0.1
        var lockedMaxZoom = self.mapView.maxZoom

        let zoomValues = minMaxZoomValues()
        
        if (lockedMinZoom < zoomValues.minZoom) {
            lockedMinZoom = zoomValues.minZoom
        }
        
        if (lockedMaxZoom > zoomValues.maxZoom) {
            lockedMaxZoom = zoomValues.maxZoom
        }

        self.mapView.setMinZoom(lockedMinZoom, maxZoom: lockedMaxZoom)
    }
    
    func unlockCamera() {
        self.lock = false
        self.mapView.cameraTargetBounds = nil
    }
}


extension PositioningViewController {
    //MARK: POI Selection
    //Programatic POI selection, a POI can also be selected by the user tapping on it in the  phone screen
    func select(poi: SITPOI) throws {
        try select(poi: poi, success: {})
    }
    
    func select(poi: SITPOI, success: @escaping () -> Void) throws {
        guard let indexPath = getIndexPath(floorId: poi.position().floorIdentifier),
            let renderer = markerRenderer else { return }
        
        select(floor: indexPath)
        if let markerPoi = renderer.searchMarker(byPoi: poi) {
            select(marker: markerPoi, success: success)
        } else {
            throw WayfindingError.invalidPOI
        }
    }
    
    func select(gmsMarker: GMSMarker) {
        guard let renderer = markerRenderer else { return }
        if renderer.isClusteringEnabled && renderer.isClusterGMSMarker(gmsMarker) {
            renderer.selectGMSClusterMarker(gmsMarker)
        } else {
            guard  let marker = renderer.searchMarker(byGMSMarker: gmsMarker) else {
                Logger.logDebugMessage("Marker should be in renderer, otherwise user selects a marker that the app is not handling correctly")
                return
            }
            select(marker: marker, success: {})
        }
    }
    
    func select(marker: SitumMarker) {
        select(marker: marker, success: {})
    }
    
    func selectCustomPoi(success: @escaping () -> Void) throws {
        if (customPoi != nil) {
            guard let indexPath = getIndexPath(floorId: customPoi!.floorId),
                let renderer = markerRenderer else { return }
            
            select(floor: indexPath)
            if let customMarker = renderer.searchCustomMarker() {
                select(marker: customMarker, success: success)
            } else {
                // TODO throw custom error
                print("No custom POI stored")
            }
        }
    }
    
    //Imitates actions done by google maps when a user select a marker
    func select(marker: SitumMarker, success: @escaping () -> Void) {
        //TODO Extender para que sexa valido tamen para os custom markers
        if marker != lastSelectedMarker {
            deselect(marker: lastSelectedMarker)
        }
    
        markerRenderer?.selectMarker(marker)
        
        CATransaction.begin()
        CATransaction.setValue(0.5, forKey: kCATransactionAnimationDuration)
        CATransaction.setCompletionBlock({
            // self.mapView.selectedMarker = marker.gmsMarker // tooltip sobre POI
//            if marker.isPoiMarker {
                self.poiMarkerWasSelected(poiMarker: marker)
//            }
            self.lastSelectedMarker = marker
            success()
        })
        self.mapView.animate(toLocation: marker.gmsMarker.position)
        CATransaction.commit()
    }
    
    func deselect(marker: SitumMarker?, notifyDelegate: Bool = true) {
        self.removeLastCustomMarkerIfOutsideRoute()
        self.changeNavigationButtonVisibility(isVisible: false)
        self.updateInfoBarLabelsIfNotInsideRoute(mainLabel: self.buildingName)
        self.lastSelectedMarker = nil
        if let marker = marker {
            if marker.isPoiMarker {
                poiMarkerWasDeselected(poiMarker: marker, notifyDelegate: notifyDelegate)
            }
            markerRenderer?.deselectMarker(marker)
        }
    }
    
    func poiMarkerWasSelected(poiMarker: SitumMarker) {
        if (!isUserNavigating()) {
            changeNavigationButtonVisibility(isVisible: true)
            if (poiMarker.isCustomMarker) {
                changeDeletePoiButtonVisibility(isVisible: true)
            }
        }
        updateInfoBarLabelsIfNotInsideRoute(mainLabel: poiMarker.poi?.name ?? DEFAULT_POI_NAME,
            secondaryLabel: floorUILabel(with: poiMarker))
        if (positioningButton.isSelected) {
            showCenterButton()
        }
        isCameraCentered = false
        //Call only if this marker wasnt already the selected one
        if poiMarker != lastSelectedMarker, let uPoi = poiMarker.poi, let uBuildingInfo = buildingInfo {
            if (!poiMarker.isCustomMarker) {
                poiWasSelected(poi: uPoi, buildingInfo: uBuildingInfo)
            } else {
                customPoiWasSelected(poiId: uPoi.identifier)
            }
        }
    }

    private func floorUILabel(with marker: SitumMarker) -> String {
        guard let buildingInfo = buildingInfo else { return " "}

        if let floor = buildingInfo.floorWith(floorIdentifier: marker.floorIdentifier) {
            return buildingInfo.buildingFloorUILabel(floor)
        } else {
            return buildingName
        }
    }
    
    func poiMarkerWasDeselected(poiMarker: SitumMarker, notifyDelegate: Bool = true) {
        if let uPoi = poiMarker.poi, let uBuildingInfo = buildingInfo {
            if !poiMarker.isCustomMarker && notifyDelegate {
                poiWasDeselected(poi: uPoi, buildingInfo: uBuildingInfo)
            } else if notifyDelegate {
                customPoiWasDeselected(poiId: uPoi.identifier)
            }
        }
    }
    
    func poiWasSelected(poi: SITPOI, buildingInfo: SITBuildingInfo) {
        delegateNotifier?.notifyOnPOISelected(poi: poi, buildingInfo: buildingInfo)
    }
    
    func poiWasDeselected(poi: SITPOI, buildingInfo: SITBuildingInfo) {
        delegateNotifier?.notifyOnPOIDeselected(poi: poi, buildingInfo: buildingInfo)
    }
    
    func customPoiWasSelected(poiId: String) {
        delegateNotifier?.notifyOnCustomPoiSelected(poiId: poiId)
    }
    
    func customPoiWasDeselected(poiId: String) {
        delegateNotifier?.notifyOnCustomPoiDeselected(poiId: poiId)
    }
    
    func displayMarkers(forFloor floor: SITFloor, isUserNavigating: Bool) {
        guard let renderer = markerRenderer else { return }
        if !isUserNavigating {
            renderer.displayPoiMarkers(forFloor: floor)
            if let customMarker = lastCustomMarker {
                renderer.displayLongPressMarker(customMarker, forFloor: floor)
            }
            
            if let storedCustomPoi = customPoi {
                if let indexPath = self.getIndexPath(floorId: storedCustomPoi.floorId)?.row {
                    if let markerFloor = orderedFloors(buildingInfo: buildingInfo)?[indexPath] {
                        // TODO JLAQ do not create a new instance of situm marker on each render
                        let markerPosition = CLLocationCoordinate2D(latitude: storedCustomPoi.latitude, longitude: storedCustomPoi.longitude)
                        let markerIcon = UIImage(
                            named: "situm_find_my_car_marker",
                            in: SitumMapsLibrary.bundle,
                            compatibleWith: nil)
                        let situmMarker = SitumMarker(
                            coordinate: markerPosition,
                            floor: markerFloor,
                            custom: true,
                            title: storedCustomPoi.name,
                            id: String(storedCustomPoi.key),
                            image: markerIcon
                        )
                        renderer.displayCustomMarker(situmMarker, forFloor: floor)
                    }
                }
            }
            
            // in the future selection should be encapsulated in some other class to abstract Google maps
            for marker in renderer.markers {
                if marker == lastSelectedMarker {
                    select(marker: marker)
                }
            }
        } else {
            if let marker = destinationMarker {
               renderer.displayOnlyDestinationMarker(marker, forFloor: floor)
            } else {
                Logger.logDebugMessage("Destination will not be shown because there is no destinationMarker selected")
            }
        }
    }
    
    func updateUserMarker(with location: SITLocation) {
        let selectedLevel: SITFloor? = orderedFloors(buildingInfo: buildingInfo)![selectedLevelIndex]
        if isCameraCentered || location.position.isOutdoor() || selectedLevel?.identifier == location.position
            .floorIdentifier {
            let userMarkerImage = getMarkerImage(for: location)
            positionDrawer?.updateUserLocation(
                with: location,
                with: userMarkerImage,
                with: uiColorsTheme.primaryColorDimished
            )
            self.makeUserMarkerVisible(visible: true)
        } else {
            makeUserMarkerVisible(visible: false)
        }
    }
    
    func getMarkerImage(for location: SITLocation) -> UIImage? {
        if location.position.isOutdoor() {
            return userMarkerIcons["swf_location_outdoor_pointer"]
        } else if location.quality == .sitHigh && location.bearingQuality == .sitHigh {
            return userMarkerIcons["swf_location_pointer"]
        } else {
            return userMarkerIcons["swf_location"]
        }
    }
    
    func makeUserMarkerVisible(visible: Bool) {
        positionDrawer?.makeUserMarkerVisible(visible: visible)
    }
    
    func removeLastCustomMarkerIfOutsideRoute() {
        if (!self.isUserNavigating()) {
            self.removeLastCustomMarker()
        }
    }
    
    func removeLastCustomMarker() {
        if (self.lastCustomMarker != nil) {
            self.lastCustomMarker?.setMapView(mapView: nil)
            self.lastCustomMarker = nil
        }
    }
    
    func getCategoryFromMarker(marker: SitumMarker?) -> DestinationCategory? {
        guard let marker = marker else { return nil }
        
        if let poi = marker.poi {
            return .poi(poi)
        } else {
            let coordinate = CLLocationCoordinate2D(
                latitude: marker.gmsMarker.position.latitude,
                longitude: marker.gmsMarker.position.longitude
            )
            let point = SITPoint(
                building: buildingInfo!.building,
                floorIdentifier: marker.floorIdentifier,
                coordinate: coordinate
            )
            return .location(point)
        }
    }
    
    func showPoiNames() -> Bool {
        if let settings = self.library?.settings, let showText = settings.showPoiNames {
            return showText
        }
        
        return false
    }
}

extension PositioningViewController {
    func initializeChangeOfFloorMarker() {
        let icon = self.scaledImage(
            image: UIImage(named: "change_floor")!,
            scaledToSize: CGSize(width: 40.0, height: 40.0)
        )
        let markerView = UIImageView(image: icon)
        self.changeOfFloorMarker.iconView = markerView
        self.changeOfFloorMarker.position = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        resetChangeOfFloorMarker()
    }

    func showChangeOfFloorMarker(position: CLLocationCoordinate2D) {
        self.changeOfFloorMarker.position = position
        self.changeOfFloorMarker.map = self.mapView
    }

    func scaledImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    func updateChangeOfFloorMarker(forSelectedFloor: SITFloor, withFloorSegment: SITRouteSegment) {
        if shouldDrawChangeOfFloorMarker(segment: withFloorSegment, selectedFloor: forSelectedFloor) {
            self.drawChangeOfFloorMarker(segment: withFloorSegment)
        }
    }

    func drawChangeOfFloorMarker(segment: SITRouteSegment) {
        let last = segment.points.last
        if let coordinates = last?.coordinate() {
            let position = CLLocationCoordinate2D(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            self.showChangeOfFloorMarker(position: position)
        }
    }

    func isSegment(_ segment: SITRouteSegment, inFloor: SITFloor) -> Bool {
        return segment.floorIdentifier == inFloor.identifier
    }

    func isDestinationFloor(selectedFloor: SITFloor) -> Bool {
        return self.destinationMarker?.floorIdentifier == selectedFloor.identifier
    }

    func shouldDrawChangeOfFloorMarker(segment: SITRouteSegment, selectedFloor: SITFloor) -> Bool {
        return isSegment(segment, inFloor: selectedFloor) && !isDestinationFloor(selectedFloor: selectedFloor)
    }

    func resetChangeOfFloorMarker() {
        self.changeOfFloorMarker.map = nil
    }

    func prepareCenterButton() {
        centerButton.layer.cornerRadius = 30
        centerButton.layer.masksToBounds = false
        customizeCenterButtonColorAndText()
    }

    func customizeCenterButtonColorAndText() {
        centerButton.backgroundColor = uiColorsTheme.primaryColor
        centerButton.setSitumShadow(colorTheme: uiColorsTheme)
        let textColor = uiColorsTheme.backgroundedButtonsIconstTintColor

        let title = NSLocalizedString(
            "positioning.center",
            bundle: SitumMapsLibrary.bundle,
            comment: "Button to center map in current location of user"
        )
        let font = UIFont(name: "Roboto-Black", size: 18) ?? UIFont.systemFont(ofSize: 18)

        let textAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: textColor
        ]

        let textTitle = NSMutableAttributedString(
            string: title.uppercased(),
            attributes: textAttributes
        )

        centerButton.setAttributedTitle(textTitle, for: .normal)

    }

}

extension PositioningViewController {
    override func reloadScreenColors(){
        mapView.applySitumSytle()
        levelsTableView.reloadData()
        customizeCenterButtonColorAndText()
        customizePositioningButtonColor()
        customizeLoadingIndicatorColor()
        customizeNavigationButtonColor()
        customizeBackButtonColor()
        customizeSearchBarTintColor()
    }
}

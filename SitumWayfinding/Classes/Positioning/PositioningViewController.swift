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

class PositioningViewController: UIViewController, GMSMapViewDelegate, UITableViewDataSource, UITableViewDelegate, PositioningView, PositioningController {
    //MARK PositioningController protocol variables
    var buildingId: String = ""
    var library: SitumMapsLibrary?
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
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    //Navigation
    @IBOutlet weak var indicationsView: UIView!
    weak var indicationsViewController: IndicationsViewController?
    @IBOutlet weak var navigationButton: UIButton!
    
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
    var actualZoom: Float = 0.0
    var selectedLevelIndex: Int = 0
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
    // Customization
    var organizationTheme: SITOrganizationTheme?
    //Search
    @IBOutlet weak var searchBar: UISearchBar!
    var searchResultsController: SearchResultsTableViewController?
    var searchController: UISearchController?
    var searchResultViewConstraints: [NSLayoutConstraint]?
    // readiness of map
    private var mapReadinessChecker: SitumMapReadinessChecker!
    // Constants
    let DEFAULT_SITUM_COLOR = "#283380"
    let DEFAULT_POI_NAME: String = "POI"
    let DEFAULT_BUILDING_NAME: String = "Current Building"
    let fakeLocationsOptions = [
        "0º",
        "90º",
        "180º",
        "270º",
        NSLocalizedString("positioning.createMarker", bundle: SitumMapsLibrary.bundle, comment: "")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapContainerViewTopConstraint.constant = 44
        backButton.title = NSLocalizedString("positioning.back",
            bundle: SitumMapsLibrary.bundle,
            comment: "Button to go back when the user is in the positioning controller (where the map is shown)")
        centerButton.setTitle(NSLocalizedString("positioning.center",
            bundle: SitumMapsLibrary.bundle,
            comment: "Button to center map in current location of user"), for: .normal)
        self.displayElementsNavBar()
        definesPresentationContext = true
        mapReadinessChecker = SitumMapReadinessChecker { [weak self] in
            guard let instance = self else { return }
            if let library = instance.library {
                instance.delegateNotifier?.notifyOnMapReady(map: library)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
                self.mapReadinessChecker.buildingInfoLoaded()
                if self.buildingInfo!.floors.count <= 0 {
                    self.loadingError = true;
                    self.situmLoadFinished(loadingAlert: loadingAlert)
                } else {
                    SITCommunicationManager.shared().fetchOrganizationTheme(options: nil, success: { (mapping: [AnyHashable : Any]?) in
                        print("Success retrieving details of organization")
                        if mapping != nil {
                            let organizationDetails = mapping!["results"] as? SITOrganizationTheme
                            print("Organization Details: \(organizationDetails)")
                            
                            // Now we have the organization details and we can work with their values (if any)
                            self.organizationTheme = organizationDetails!
                            
                            self.situmLoadFinished(loadingAlert: loadingAlert)
                            self.presenter = PositioningPresenter(view: self, buildingInfo: self.buildingInfo!, interceptorsManager: self.library?.interceptorsManager ?? InterceptorsManager())
                            if let lib = self.library {
                                if let set = lib.settings {
                                    self.presenter?.useRemoteConfig = set.useRemoteConfig
                                }
                            }
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
    func initializeUIElements() {
        initializeMapView()
        initializeMarkerMapRenderer()
        initializePositioningUIElements()
        initializeIcons()
    }
    
    func addMap() {
        self.mapViewVC.view = mapView
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
        mapView.camera = camera
    }
    
    func initializePositioningUIElements() {
        initializeNavigationBar()
        initializeIcons()
        initializePositioningButton()
        initializeLoadingIndicator()
        hideCenterButton()
        initializeLevelIndicator()
        initializeNavigationButton()
        initializeInfoBar()
        numberBeaconsRangedView.isHidden = true
    }
    
    func initializeNavigationBar() {
        //navbar.topItem?.title = buildingInfo!.building.name
    }
    
    func initializeIcons() {
        let bundle = Bundle(for: type(of: self))
        var userLocIconName = getIconNameOrDefault(iconName: library?.settings?.userPositionIcon, defaultIconName: "swf_location")
        var userLocArrowIconName = getIconNameOrDefault(iconName: library?.settings?.userPositionArrowIcon, defaultIconName: "swf_location_pointer")

        if var locationPointer = UIImage(named: userLocArrowIconName, in: bundle, compatibleWith: nil),
           let locationOutdoorPointer = UIImage(named: "swf_location_outdoor_pointer", in: bundle, compatibleWith: nil),
           var location = UIImage(named: userLocIconName, in: bundle, compatibleWith: nil),
           var radius = UIImage(named: "swf_radius", in: bundle, compatibleWith: nil) {

            userMarkerIcons = [
                "swf_location_pointer" : locationPointer,
                "swf_location_outdoor_pointer" : locationOutdoorPointer,
                "swf_location" : location,
                "swf_radius" : radius
            ]
        }
    }
    
    func initializeMarkerMapRenderer() {
        guard let mapView = mapView, let info = buildingInfo else {
            Logger.logDebugMessage("Marker renderer could not be created because mapView and building info are not set")
            return
        }
        markerRenderer = MarkerRenderer(mapView: mapView, buildingInfo: info,
            showPoiNames: showPoiNames(), iconsStore: iconsStore)
    }

    private func getIconNameOrDefault(iconName: String?, defaultIconName: String) -> String {
        (iconName ?? "").isEmpty ? defaultIconName : iconName!
    }
    
    func initializePositioningButton() {
        positioningButton.layer.cornerRadius = 0.5 * positioningButton.bounds.size.width
        positioningButton.layer.masksToBounds = false
        positioningButton.layer.shadowColor = UIColor.darkGray.cgColor
        positioningButton.layer.shadowOpacity = 0.8
        positioningButton.layer.shadowRadius = 8.0
        positioningButton.layer.shadowOffset = CGSize(width: 7.0, height: 7.0)
        positioningButton.isHidden = false
    }
    
    func initializeLoadingIndicator() {
        loadingIndicator.isHidden = true
        loadingIndicator.hidesWhenStopped = true
    }
    
    func initializeLevelIndicator() {
        selectedLevelIndex = 0
        levelsTableView.dataSource = self
        levelsTableView.delegate = self
        initializeLevelSelector()
        
        let indexPath = getDefaultFloorFirstLoad()
        levelsTableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
        tableView(levelsTableView, didSelectRowAt: indexPath)
        levelsTableView.isHidden = false
    }
    
    private func getDefaultFloorFirstLoad() -> IndexPath {
        var indexPath = IndexPath(row: 0, section: 0)
        
        if (buildingInfo?.floors.count ?? 0 > 1) {
            indexPath.row = buildingInfo!.floors.count - 1
        }
        
        return indexPath
    }
    
    func initializeNavigationButton() {
        navigationButton.layer.cornerRadius = 0.5 * navigationButton.bounds.size.width
        navigationButton.layer.masksToBounds = false
        navigationButton.layer.shadowColor = UIColor.darkGray.cgColor
        navigationButton.layer.shadowOpacity = 0.8
        navigationButton.layer.shadowRadius = 8.0
        navigationButton.layer.shadowOffset = CGSize(width: 7.0, height: 7.0)
        navigationButton.isHidden = true
    }
    
    func initializeInfoBar() {
        if (self.showBackButton() || self.showSearchBar()) {
            self.showPositioningUI()
        }
        
        if (!self.showSearchBar() && !self.showBackButton()) {
            self.hiddenNavBar()
        }
        
        self.containerInfoBarMap?.setLabels(primary: self.buildingName)
        if organizationTheme?.logo != nil {
            // Bring the image and save it on cache
            let logoUrl = "https://dashboard.situm.es" + organizationTheme!.logo.direction
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
            let title = NSLocalizedString("positioning.error.emptyFloor.alert.title",
                bundle: SitumMapsLibrary.bundle,
                comment: "Alert title error when download the floor plan fails")
            let message = NSLocalizedString("positioning.error.emptyFloor.alert.message",
                bundle: SitumMapsLibrary.bundle,
                comment: "Alert title error when download the floor plan fails")
            let wasMapFetched = SITCommunicationManager.shared().fetchMap(
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
            if !wasMapFetched {
                self.showAlertMessage(title: title, message: message, alertType: .otherAlert)
            }
        }
    }
    
    func displayFloorPlan(forFloor floor: SITFloor) {
        self.mapOverlay.map = nil
        let bounds: SITBounds = buildingInfo!.building.bounds()
        let coordinateBounds = GMSCoordinateBounds(coordinate: bounds.southWest, coordinate: bounds.northEast)
        let mapOverlay = GMSGroundOverlay(bounds: coordinateBounds, icon: floorplans[floor.identifier])
        
        self.mapOverlay = mapOverlay
        self.mapOverlay.bearing = CLLocationDirection(buildingInfo!.building.rotation.degrees())
        self.mapOverlay.map = mapView
        displayMarkers(forFloor: floor, isUserNavigating: SITNavigationManager.shared().isRunning())
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
        let isSameLevel = floorIndex.row == self.selectedLevelIndex
        if isSameLevel {
            return
        }
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
        
        if let level: SITFloor = orderedFloors(buildingInfo: buildingInfo)?[indexPath.row] {
            // [06/08/19] This check is here because older buildings without the name field give unexpected nulls casted to string
            let shouldDisplayLevelName = !(level.name.isEmpty || (level.name == "<null>"))
            let textToDisplay: String = shouldDisplayLevelName ? level.name : String(level.floor)
            cell?.textLabel?.text = String(format: "%@", textToDisplay)
            cell?.backgroundColor = getBackgroundColor(forFloor: level, atRow: indexPath.row)
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
        if isCameraCentered && PositioningUtils.hasBearingChangedEnoughToReloadUi(newBearing: location.bearing.degrees(), lastAnimatedBearing: lastAnimatedBearing) {
            positionDrawer?.updateUserBearing(with: location)
            //Relocate camera
            mapView.animate(toBearing: CLLocationDirection(location.bearing.degrees()))
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
            positioningButton.isHidden = false
        }
    }
    
    func updateCamera(with location: SITLocation) {
        if isCameraCentered {
            let position = location.position
            let cameraUpdate = GMSCameraUpdate.setTarget(position.coordinate())
            mapView.animate(with: cameraUpdate)
        }
    }
    
    func change(_ state: SITLocationState, centerCamera: Bool) {
        changePositioningButton(toState: state)
        isCameraCentered = centerCamera
    }
    
    func changePositioningButton(toState state: SITLocationState) {
        let bundle = Bundle(for: type(of: self))
        switch state {
        case .stopped:
            positioningButton.backgroundColor = UIColor(red: 0xff / 255.0, green: 0xff / 255.0, blue: 0xff / 255.0, alpha: 1)
            positioningButton.setImage(UIImage(named: "swf_ic_action_no_positioning", in: bundle, compatibleWith: nil), for: .normal)
            loadingIndicator.stopAnimating()
            positioningButton.isSelected = false
        case .calculating:
            positioningButton.setImage(nil, for: .normal)
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
            positioningButton.isSelected = false
        case .started:
            let color = UIColor(red: 0x00 / 255.0, green: 0x75 / 255.0, blue: 0xc9 / 255.0, alpha: 1)
            positioningButton.backgroundColor = primaryColor(defaultColor: color)
            
            positioningButton.setImage(UIImage(named: "swf_ic_action_localize", in: bundle, compatibleWith: nil), for: .selected)
            loadingIndicator.stopAnimating()
            positioningButton.isSelected = true
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
            levelsTableView.isHidden = false
        }
        
        if (presenter?.shouldCameraPositionBeDraggedInsideBuildingBounds(position: position.target) ?? false) {
            if let cameraInsideBounds = presenter?.modifyCameraToBeInsideBuildingBounds(camera: position) {
                mapView.animate(to: cameraInsideBounds)
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let renderer = markerRenderer else { return true }
        guard  let marker = renderer.searchMarker(byGMSMarker: marker) else {
            Logger.logDebugMessage("Marker should be in renderer, otherwise user selects a marker that the app is not handling correctly")
            return true
        }
        select(marker: marker)
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
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
        deselect(marker: lastSelectedMarker)
        if (self.presenter?.shouldShowFakeLocSelector() ?? false) {
            presenter?.fakeLocationPressed(coordinate: coordinate, floorId: orderedFloors(buildingInfo: buildingInfo)![selectedLevelIndex].identifier)
        } else {
            createAndShowCustomMarkerIfOutsideRoute(atCoordinate: coordinate, forFloor: floor)
        }
    }
    
    func showFakeLocationsAlert() {
        let title = NSLocalizedString("positioning.longPressAction.alert.title",
            bundle: SitumMapsLibrary.bundle,
            comment: "Alert title to show for a long press action")
        let message = NSLocalizedString("positioning.longPressAction.alert.message",
            bundle: SitumMapsLibrary.bundle,
            comment: "Alert message to show for a long press action")
        let cancel = NSLocalizedString("generic.cancel",
            bundle: SitumMapsLibrary.bundle,
            comment: "Generic cancel action ")
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancel, style: .default, handler: { _ in
            self.presenter?.alertViewClosed(.otherAlert)
        }))
        for (buttonIndex, text) in fakeLocationsOptions.enumerated() {
            alert.addAction(UIAlertAction(title: text, style: .default, handler: { _ in
                self.presenter?.fakeLocOptionSelected(atIndex: buttonIndex)
            }))
        }
        
        self.present(alert, animated: true, completion: nil)
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
        self.presenter?.stopPositioning()
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
        self.numberBeaconsRangedLabel.text = String(format: format, text)
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
    }
    
    func updateProgress(progress: SITNavigationProgress) {
        self.containerInfoBarNavigation?.setProgress(progress: progress)
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
                containerInfoBarMap?.setLabels(primary: lastCustomMarker!.title, secondary: buildingName)
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
    
    func getBackgroundColor(forFloor floor: SITFloor, atRow row: Int) -> UIColor {
        var color: UIColor
        
        if row == selectedLevelIndex {
            color = UIColor.lightGray
        } else {
            color = UIColor.white
        }
        
        if let presenter = presenter {
            if presenter.isSameFloor(floorIdentifier: floor.identifier) {
                color = UIColor(red: 0x00 / 255.0, green: 0xa1 / 255.0, blue: 0xdf / 255.0, alpha: 1)
                
                // Only affected if customization is declared
                color = primaryColor(defaultColor: color)
            }
        }
        
        return color
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
        let color = UIColor(red: 0x00 / 255.0, green: 0x75 / 255.0, blue: 0xc9 / 255.0, alpha: 1)
        let styles: [GMSStrokeStyle] = [.solidColor(
            primaryColor(defaultColor: color)), .solidColor(.clear)]
        let scale = 1.0 / mapView.projection.points(forMeters: 1, at: mapView.camera.target)
        let solidLine = NSNumber(value: 5.0 * Float(scale))
        let gap = NSNumber(value: 5.0 * Float(scale))
        
        for (index, segment) in segments.enumerated() {
            if segment.floorIdentifier == selectedFloor.identifier {
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
                polyline.map = self.mapView
            }
        }
    }
    
    //MARK: Stop methods
    func stopNavigationByUser() {
        stopNavigation(status: .canceled)
    }
    
    func cleanLocationUI() {
        self.makeUserMarkerVisible(visible: false)
        self.numberBeaconsRangedView.isHidden = true
        self.reloadFloorPlansTableViewData()
        self.hideCenterButton()
        self.change(.stopped, centerCamera: false)
    }
    
    func stopNavigation(status: NavigationStatus) {
        presenter?.resetLastOutsideRouteAlert()
        SITNavigationManager.shared().removeUpdates()
        self.changeNavigationButtonVisibility(isVisible: false)
        self.showPositioningUI()
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
    
    private func notifyEndOfNavigation(status: NavigationStatus, marker: SitumMarker?) {
        guard let category = self.getCategoryFromMarker(marker: self.destinationMarker) else { return }
        let navigation = WYFNavigation(status: status, destination: WYFDestination(category: category))
        
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
    
    func primaryColor(defaultColor: UIColor) -> UIColor {
        var color = defaultColor
        
        // Override color based on customization
        if let settings = library?.settings {
            if settings.useDashboardTheme == true {
                if let organizationTheme = organizationTheme { // Check if string is a valid string
                    let generalColor = UIColor(hex: organizationTheme.themeColors.primary) ?? UIColor.gray
                    color = organizationTheme.themeColors.primary.isEmpty ? defaultColor : generalColor
                }
            }
        }
        return color
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
        if let markerPoi = renderer.searchMarker(byPOI: poi) {
            select(marker: markerPoi, success: success)
        } else {
            throw WayfindingError.invalidPOI
        }
    }
    
    func select(marker: SitumMarker) {
        select(marker: marker, success: {})
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
            if marker.isPoiMarker {
                self.poiMarkerWasSelected(poiMarker: marker)
            }
            self.lastSelectedMarker = marker
            success()
        })
        self.mapView.animate(toLocation: marker.gmsMarker.position)
        CATransaction.commit()
    }
    
    func deselect(marker: SitumMarker?) {
        self.removeLastCustomMarkerIfOutsideRoute()
        self.changeNavigationButtonVisibility(isVisible: false)
        self.updateInfoBarLabelsIfNotInsideRoute(mainLabel: self.buildingName)
        self.lastSelectedMarker = nil
        if let marker = marker {
            if marker.isPoiMarker {
                poiMarkerWasDeselected(poiMarker: marker)
            }
            markerRenderer?.deselectMarker(marker)
        }
    }
    
    func poiMarkerWasSelected(poiMarker: SitumMarker) {
        if (!self.isUserNavigating()) {
            self.changeNavigationButtonVisibility(isVisible: true)
        }
        self.updateInfoBarLabelsIfNotInsideRoute(
            mainLabel: poiMarker.poi?.name ?? DEFAULT_POI_NAME,
            secondaryLabel: self.buildingName
        )
        if (self.positioningButton.isSelected) {
            showCenterButton()
        }
        isCameraCentered = false
        //Call only if this marker wasnt already the selected one
        if poiMarker != lastSelectedMarker, let uPoi = poiMarker.poi, let uBuildingInfo = buildingInfo {
            poiWasSelected(poi: uPoi, buildingInfo: uBuildingInfo)
        }
    }
    
    func poiMarkerWasDeselected(poiMarker: SitumMarker) {
        if let uPoi = poiMarker.poi, let uBuildingInfo = buildingInfo {
            poiWasDeselected(poi: uPoi, buildingInfo: uBuildingInfo)
        }
    }
    
    func poiWasSelected(poi: SITPOI, buildingInfo: SITBuildingInfo) {
        delegateNotifier?.notifyOnPOISelected(poi: poi, buildingInfo: buildingInfo)
    }
    
    func poiWasDeselected(poi: SITPOI, buildingInfo: SITBuildingInfo) {
        delegateNotifier?.notifyOnPOIDeselected(poi: poi, buildingInfo: buildingInfo)
    }
    
    func displayMarkers(forFloor floor: SITFloor, isUserNavigating: Bool) {
        guard let renderer = markerRenderer else { return }
        if !isUserNavigating {
            renderer.displayPOIMarkers(forFloor: floor)
            if let customMarker = lastCustomMarker {
                renderer.displayLongPressMarker(customMarker, forFloor: floor)
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
                Logger.logDebugMessage("Destination will not be shown becuase there is no destinationMarker selected")
            }
        }
    }
    
    func updateUserMarker(with location: SITLocation) {
        let selectedLevel: SITFloor? = orderedFloors(buildingInfo: buildingInfo)![selectedLevelIndex]
        if isCameraCentered || location.position.isOutdoor() || selectedLevel?.identifier == location.position
            .floorIdentifier {
            let userMarkerImage = getMarkerImage(for: location)
            let color = UIColor(
                red: 0x00 / 255.0,
                green: 0x75 / 255.0,
                blue: 0xc9 / 255.0,
                alpha: 1
            )
            positionDrawer?.updateUserLocation(
                with: location,
                with: userMarkerImage,
                with: primaryColor(defaultColor: color).withAlphaComponent(0.4)
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



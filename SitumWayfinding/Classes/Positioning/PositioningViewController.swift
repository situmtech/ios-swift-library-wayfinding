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
    @IBOutlet weak var currentIndicationLabel: UILabel!
    @IBOutlet weak var nextIndicationLabel: UILabel!
    @IBOutlet weak var infoBarView: UIView!
    @IBOutlet weak var singleInfoLabel: UILabel!
    @IBOutlet weak var titleInfoLabel: UILabel!
    @IBOutlet weak var subtitleInfoLabel: UILabel!
    @IBOutlet weak var cancelNavigationButton: UIButton!
    @IBOutlet weak var infoIconImage: UIImageView!
    @IBOutlet weak var navigationButton: UIButton!
    
    //Map added from outside. We have to use containment view to allow
    //the map and the other layers appear in same screen
    var mapViewVC: UIViewController!
    var mapView: GMSMapView!
    
    //Loading
    var loadingError:Bool = false
    
    //Positioning
    var mapOverlay: GMSGroundOverlay = GMSGroundOverlay()
    var poiMarkers: Array<GMSMarker> = []
    var floorplans: Dictionary<String, UIImage> = [:]
    let iconsStore:IconsStore = IconsStore()
    var userMarkerIcons: Dictionary<String, UIImage> = [:]
    var lastBearing: Float = 0.0
    var lastAnimatedBearing: Float = 0.0
    var isCameraCentered: Bool = false
    let locManager: CLLocationManager = CLLocationManager()
    var buildingInfo: SITBuildingInfo? = nil
    var actualZoom: Float = 0.0
    var selectedLevelIndex: Int = 0
    var presenter: PositioningPresenter? = nil
    var positionDrawer: PositionDrawerProtocol? = nil
    
    //Navigation
    var lastSelectedMarker: SitumMarker?
    var lastCustomMarker: SitumMarker?
    var destinationMarker: SitumMarker?
    var progress: SITNavigationProgress? = nil
    var polyline: Array<GMSPolyline> = []
    var routePath: Array<GMSMutablePath> = []
    var loadFinished:Bool = false
    
    // Customization
    var organizationTheme: SITOrganizationTheme?
    @IBOutlet weak var logoIV: UIImageView!
    
    //Search
    @IBOutlet weak var searchBar: UISearchBar!
    var searchResultsController : SearchResultsTableViewController?
    var searchController:UISearchController?
    var searchResultViewConstraints : [NSLayoutConstraint]?

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
        backButton.title = NSLocalizedString("positioning.back",
            bundle: SitumMapsLibrary.bundle,
            comment: "Button to go back when the user is in the positioning controller (where the map is shown)")
        centerButton.setTitle(NSLocalizedString("positioning.center",
            bundle: SitumMapsLibrary.bundle,
            comment: "Button to center map in current location of user"), for: .normal)
        initSearchController()
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
            if (self.loadFinished){
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

    func situmLoadFinished(loadingAlert : UIAlertController){
        loadingAlert.dismiss(animated: true) {
            if (self.loadingError){
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
        initializePositioningUIElements()
        initializeIcons()
    }
    
    func addMap(){
        self.mapViewVC.view = mapView
    }
    
    func initializeMapView() {
        poiMarkers = Array()
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
        self.infoBarView.isHidden = false
        
        self.updateInfoBarLabels(mainLabel: self.buildingInfo?.building.name ?? DEFAULT_BUILDING_NAME)
        self.initializeCancelNavigationButton()
        
        if organizationTheme?.logo != nil {
            // Bring the image and save it on cache
            
            let logoUrl = "https://dashboard.situm.es" +  organizationTheme!.logo.direction
            let data = NSData(contentsOf: URL(string: logoUrl)!) as Data?
            if let data = data {
                logoIV.image = UIImage.init(data: data)
            }
        }
    }
    
    func initializeCancelNavigationButton() {
        self.changeCancelNavigationButtonVisibility(isVisible: false)
        self.cancelNavigationButton.layer.cornerRadius = 0.5 * self.cancelNavigationButton.bounds.size.width
        self.cancelNavigationButton.layer.borderWidth = 2.0
        self.cancelNavigationButton.layer.borderColor = UIColor.red.cgColor
    }
    
    //MARK: POI Selection
    
    //Programatic POI selection, a POI can also be selected by the user tapping on it in the  phone screen
    func select(poi: SITPOI) throws {
        try select(poi: poi, success: {})
    }

    func select(poi: SITPOI, success: @escaping () -> Void) throws {
        if let indexpath = getIndexPath(floorId: poi.position().floorIdentifier){
            select(floor: indexpath)
        }
        if let markerPoi = poiMarkers.first(where: {($0.userData as! SITPOI).id == poi.id}){
            select(marker: SitumMarker(from: markerPoi), success: success)
        }else{
            throw WayfindingError.invalidPOI
        }
    }

    func select(marker: SitumMarker) {
        select(marker: marker, success: {})
    }

    //Imitates actions done by google maps when a user select a marker
    func select(marker:SitumMarker, success: @escaping () -> Void){
        //TODO Extender para que sexa valido tamen para os custom markers
        if marker != lastSelectedMarker{
            deselect(marker: lastSelectedMarker)
        }
        CATransaction.begin()
        CATransaction.setValue(0.5, forKey: kCATransactionAnimationDuration)
        CATransaction.setCompletionBlock({
            self.mapView.selectedMarker = marker.gmsMarker
            if marker.isPoiMarker(){
                self.poiMarkerWasSelected(poiMarker:marker)
            }
            self.lastSelectedMarker = marker
            success()
        })
        self.mapView.animate(toLocation: marker.gmsMarker.position)
        CATransaction.commit()
    }
    
    func deselect(marker:SitumMarker?){
        mapView.selectedMarker = nil
        self.removeLastCustomMarkerIfOutsideRoute()
        self.changeNavigationButtonVisibility(isVisible: false)
        self.updateInfoBarLabelsIfNotInsideRoute(mainLabel: self.buildingInfo?.building.name ?? DEFAULT_BUILDING_NAME)
        self.lastSelectedMarker = nil
        if let umarker = marker, umarker.isPoiMarker(){
            poiMarkerWasDeselected(poiMarker:umarker)
        }
    }
    
    
    func poiMarkerWasSelected(poiMarker:SitumMarker){
        if(!self.isUserNavigating()) {
            self.changeNavigationButtonVisibility(isVisible: true)
        }
        self.updateInfoBarLabelsIfNotInsideRoute(mainLabel: poiMarker.poi?.name ?? DEFAULT_POI_NAME, secondaryLabel: self.buildingInfo?.building.name ?? DEFAULT_BUILDING_NAME)
        if(self.positioningButton.isSelected) {
            showCenterButton()
        }
        isCameraCentered = false
        //Call only if this marker wasnt already the selected one
        if poiMarker != lastSelectedMarker, let uPoi = poiMarker.poi, let uBuildingInfo=buildingInfo{
            poiWasSelected(poi: uPoi, buildingInfo: uBuildingInfo)
        }
    }
    
    func poiMarkerWasDeselected(poiMarker:SitumMarker){
        if let uPoi=poiMarker.poi ,let uBuildingInfo=buildingInfo{
            poiWasDeselected(poi:uPoi, buildingInfo: uBuildingInfo)
        }
    }
    
    func poiWasSelected(poi:SITPOI, buildingInfo:SITBuildingInfo){
        delegateNotifier?.notifyOnPOISelected(poi: poi, buildingInfo:buildingInfo)
    }
    
    func poiWasDeselected(poi:SITPOI, buildingInfo:SITBuildingInfo){
        delegateNotifier?.notifyOnPOIDeselected(poi:poi, buildingInfo:buildingInfo)
    }
    
    //MARK: Floorplans

    func displayMap(forLevel selectedLevelIndex: Int) {
        let levelIdentifier = orderedFloors(buildingInfo: buildingInfo)![selectedLevelIndex].identifier
        if floorplans[levelIdentifier] != nil {
            displayFloorplan(forLevel: levelIdentifier)
            self.mapReadinessChecker.currentFloorMapLoaded()
        } else {
            let title = NSLocalizedString("positioning.error.emptyFloor.alert.title",
                bundle: SitumMapsLibrary.bundle,
                comment: "Alert title error when download the floor plan fails")
            let message = NSLocalizedString("positioning.error.emptyFloor.alert.message",
                bundle: SitumMapsLibrary.bundle,
                comment: "Alert title error when download the floor plan fails")
            let wasMapFetched = SITCommunicationManager.shared().fetchMap(from: orderedFloors(buildingInfo: buildingInfo)![selectedLevelIndex], withCompletion: { imageData in
                
                if let imageData = imageData {
                    let image =  UIImage.init(data: imageData, scale: UIScreen.main.scale)
                    let scaledImage = ImageUtils.scaleImage(image: image!)
                    self.floorplans[levelIdentifier] = scaledImage
                    self.displayFloorplan(forLevel: levelIdentifier)
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
    
    fileprivate func cleanPois() {
        for poiMarker in poiMarkers {
            poiMarker.map = nil
        }
        poiMarkers.removeAll()
    }
    
    func displayFloorplan(forLevel levelIdentifier: String?) {
        self.mapOverlay.map = nil
        let bounds: SITBounds = buildingInfo!.building.bounds()
        let coordinateBounds = GMSCoordinateBounds(coordinate: bounds.southWest, coordinate: bounds.northEast)
        let mapOverlay = GMSGroundOverlay(bounds: coordinateBounds, icon: floorplans[levelIdentifier!])
        
        self.mapOverlay = mapOverlay
        self.mapOverlay.bearing = CLLocationDirection(buildingInfo!.building.rotation.degrees())
        self.mapOverlay.map = mapView
        if (!(SITNavigationManager.shared().isRunning())) {
            displayPois(onFloor: levelIdentifier)
        } else {
            self.cleanPois()
            displayDestinationMarker(floor: levelIdentifier)
        }
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
    
    func select(floor floorIndex: IndexPath){
        let isSameLevel = floorIndex.row == self.selectedLevelIndex
        if isSameLevel{
            return
        }
        if let uBuildingInfo = buildingInfo, let from = orderedFloors(buildingInfo: buildingInfo)?[selectedLevelIndex], let to = orderedFloors(buildingInfo: buildingInfo)?[floorIndex.row]{
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
            cell?.backgroundColor = self.getBackgroundColor(row: indexPath.row, floorIdentifier: level.identifier)
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
    
    func displayDestinationMarker(floor: String?) {
        let floorIdentifier: String = self.getFloorIdFromMarker(marker: self.destinationMarker!)
        let mapView = (floor == floorIdentifier) ? self.mapView : nil
        self.destinationMarker?.setMapView(mapView: mapView)
    }
    
    func displayPois(onFloor floorIdentifier: String?) {
        self.cleanPois()
        var poisInSelectedFloor: Array<SITPOI> = Array()
        for poi in buildingInfo!.indoorPois {
            if poi.position().floorIdentifier == floorIdentifier {
                poisInSelectedFloor.append(poi)
            }
        }

        for poi in poisInSelectedFloor {
            if let marker = self.createMarker(withPOI: poi) {
                self.poiMarkers.append(marker)
                if poi == lastSelectedMarker?.poi && self.mapView.selectedMarker == nil
                {
                    self.mapView.selectedMarker = marker
                }
            }
        }
        poisInSelectedFloor.removeAll()
    }
    
    func updateUserMarker(with location: SITLocation) {
        let selectedLevel: SITFloor? = orderedFloors(buildingInfo: buildingInfo)![selectedLevelIndex]
        if isCameraCentered || location.position.isOutdoor() || selectedLevel?.identifier == location.position.floorIdentifier {
            let userMarkerImage = getMarkerImage(for: location)
            let color = UIColor(red: 0x00 / 255.0, green: 0x75 / 255.0, blue: 0xc9 / 255.0, alpha: 1)
            positionDrawer?.updateUserLocation( with: location, with: userMarkerImage, with: primaryColor(defaultColor: color).withAlphaComponent(0.4))
            self.makeUserMarkerVisible(visible: true) 
        } else {
            makeUserMarkerVisible(visible: false)
        }
    }
    
    func updateUserBearing(with location: SITLocation) {
        if isCameraCentered && PositioningUtils.hasBearingChangedEnoughToReloadUi(newBearing: location.bearing.degrees(),  lastAnimatedBearing: lastAnimatedBearing){
            positionDrawer?.updateUserBearing(with: location)
            //Relocate camera
            mapView.animate(toBearing: CLLocationDirection(location.bearing.degrees()))
            lastAnimatedBearing = location.bearing.degrees()
        }
    }
    
    func getMarkerImage(for location: SITLocation) -> UIImage? {
        if location.position.isOutdoor() {
           return  userMarkerIcons["swf_location_outdoor_pointer"]
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
        if(!self.isUserNavigating()) {
            self.removeLastCustomMarker()
        }
    }
    
    func removeLastCustomMarker() {
        if(self.lastCustomMarker != nil) {
            self.lastCustomMarker?.setMapView(mapView:nil)
            self.lastCustomMarker = nil
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
        if(visible) {
            // We only show the button if user is positioning
//            if(self.positioningButton.isSelected) {
                self.navigationButton.isHidden = false
//            }
        } else {
            self.navigationButton.isHidden = true
        }
    }
    
    func changeCancelNavigationButtonVisibility(isVisible visible: Bool) {
        if(visible) {
            self.cancelNavigationButton.isHidden = false
            self.infoIconImage.isHidden = true
        } else {
            self.cancelNavigationButton.isHidden = true
            self.infoIconImage.isHidden = false
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
        
        if(presenter?.shouldCameraPositionBeDraggedInsideBuildingBounds(position: position.target) ?? false) {
            if let cameraInsideBounds = presenter?.modifyCameraToBeInsideBuildingBounds(camera: position) {
                mapView.animate(to: cameraInsideBounds)
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        select(marker: SitumMarker(from: marker))
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        deselect(marker: lastSelectedMarker)
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        if(self.presenter?.shouldShowFakeLocSelector() ?? false) {
            presenter?.fakeLocationPressed(coordinate: coordinate, floorId: orderedFloors(buildingInfo: buildingInfo)![selectedLevelIndex].identifier)
        } else {
            deselect(marker: lastSelectedMarker)
            self.createAndShowCustomMarkerIfOutsideRoute(atCoordinate: coordinate, atFloor: orderedFloors(buildingInfo: buildingInfo)![selectedLevelIndex].identifier)
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
        let gsmMarker = self.createMarker(withCoordinate: location, floorId: floor.identifier)
        let marker = SitumMarker(from: gsmMarker)
        select(marker: marker) { [weak self] in
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
        self.changeCancelNavigationButtonVisibility(isVisible: true)
        self.presenter?.startPositioningAndNavigate(withDestination: destination,
            inFloor: orderedFloors(buildingInfo: buildingInfo)![self.selectedLevelIndex].identifier)
        self.presenter?.centerViewInUserLocation()
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
        if(self.destinationMarker == nil) {
            self.updateInfoBarLabels(mainLabel: title, secondaryLabel: subtitle)
        }
    }
    
    func updateInfoBarLabels(mainLabel title: String, secondaryLabel subtitle: String = "") {
        
        if(subtitle.isEmpty) {
            self.titleInfoLabel.isHidden = true
            self.subtitleInfoLabel.isHidden = true
            self.singleInfoLabel.isHidden = false
            self.singleInfoLabel.text = title
        } else {
            self.titleInfoLabel.isHidden = false
            self.subtitleInfoLabel.isHidden = false
            self.singleInfoLabel.isHidden = true
            self.titleInfoLabel.text = title
            self.subtitleInfoLabel.text = subtitle
        }
    }
    
    func showAlertMessage(title: String, message: String, alertType:AlertType) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
        let title = NSLocalizedString("generic.ok", bundle: SitumMapsLibrary.bundle, comment: "Generic ok action")
        alert.addAction(UIAlertAction(title: title, style: .default, handler: { _ in
            self.presenter?.alertViewClosed(alertType)
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    
    func showRoute(route: SITRoute) {
        self.changeNavigationButtonVisibility(isVisible: false)
        let floorIdentifier: String = self.getFloorIdFromMarker(marker: self.destinationMarker!)
        self.showPois(visible: false)
        if floorIdentifier == orderedFloors(buildingInfo: buildingInfo)?[self.selectedLevelIndex].identifier {
            self.destinationMarker?.setMapView(mapView: self.mapView)
        }
    }
    
    func updateProgress(progress: SITNavigationProgress) {
        self.progress = progress;
        self.indicationsView.isHidden = false
        let localizedFormat = NSLocalizedString("positioning.navigationProgress",
            bundle: SitumMapsLibrary.bundle,
            comment: "Show to the user distance to next point")
        let secondaryLabel = String(format: localizedFormat, progress.distanceToGoal)
        self.updateInfoBarLabels(mainLabel: self.destinationMarker?.gmsMarker.title ?? DEFAULT_POI_NAME,
            secondaryLabel: secondaryLabel)
        
        // Update route based on this information
        for line in self.polyline {
            line.map = nil;
        }
        
        // Filter route steps for floors
        let selectedFloor = orderedFloors(buildingInfo: buildingInfo)?[self.selectedLevelIndex]
        
        self.generateAndPrintRoutePathWithRouteSegments(segments: progress.segments(), selectedFloor: selectedFloor!)
        
        if(self.indicationsView.isHidden) {
            self.indicationsView.isHidden = false
        }
        // Update information on the instruction
        self.currentIndicationLabel.text = progress.currentIndication.humanReadableMessage()
        // Update distance and time
        self.nextIndicationLabel.text = progress.nextIndication.humanReadableMessage()
        
        let location: SITLocation = progress.closestLocationInRoute
        self.updateUI(with: location)
    }
    
    func showPois(visible: Bool) {
        for marker in poiMarkers {
            marker.map = visible ? self.mapView : nil;
        }
    }
    
    func createAndShowCustomMarkerIfOutsideRoute(atCoordinate coordinate: CLLocationCoordinate2D, atFloor floorId: String) {
        if(!self.isUserNavigating()) {
            self.removeLastCustomMarkerIfOutsideRoute()
            self.lastCustomMarker = SitumMarker(from:  self.createMarker(withCoordinate: coordinate, floorId: floorId))
            let mainLabel = NSLocalizedString("positioning.customDestination",
                bundle: SitumMapsLibrary.bundle,
                comment: "Shown to user when select a destination (destination is any free point that user selects on the map)")
            self.updateInfoBarLabels(mainLabel: mainLabel, secondaryLabel: self.buildingInfo?.building.name ?? DEFAULT_BUILDING_NAME)
            self.changeNavigationButtonVisibility(isVisible: true)
            self.lastSelectedMarker = self.lastCustomMarker
        }
    }
    
    // MARK: SitumMapsLibrary methods
    
    func getGoogleMap() -> GMSMapView? {
        return self.mapView
    }
    
    //MARK: Helper methods
    
    func createMarker(withPOI poi: SITPOI) -> GMSMarker? {
        let coordinate = poi.position().coordinate()
        let poiMarker = GMSMarker(position: coordinate)
        poiMarker.title = poi.name
        poiMarker.userData = poi
        iconsStore.obtainIconFor(category: poi.category) { item in
            if let icon = item {
                let color = UIColor(hex: "#5b5b5bff") ?? UIColor.gray
                let title = poi.name.uppercased()
                poiMarker.icon = self.showPoiNames() ?
                icon.setTitle(title: title, size: 12.0, color: color, weight: .semibold) :
                    icon
            }
            poiMarker.map = self.mapView
        }
        return poiMarker
    }
    
    func showPoiNames() -> Bool {
        if let settings = self.library?.settings, let showText = settings.showPoiNames {
            return showText
        }
        
        return false
    }
    
    func createMarker(withCoordinate coordinate: CLLocationCoordinate2D, floorId floor: String) -> GMSMarker {
        let marker: GMSMarker = GMSMarker(position: coordinate)
        marker.title = NSLocalizedString("positioning.customDestination",
            bundle: SitumMapsLibrary.bundle,
            comment: "Shown to user when select a destination (destination is any free point that user selects on the map)")
        marker.userData = floor
        marker.map = self.mapView
        
        return marker
    }
    
    func isUserNavigating() -> Bool {
        return self.destinationMarker != nil
    }
    
    func getBackgroundColor(row: Int, floorIdentifier: String?) -> UIColor {
        var color: UIColor
        
        if row == self.selectedLevelIndex {
            color = UIColor.lightGray
        } else {
            color = UIColor.white
        }
        
        if let presenter = presenter {
            if presenter.isSameFloor(floorIdentifier: floorIdentifier) {
                color = UIColor(red: 0x00 / 255.0, green: 0xa1 / 255.0, blue: 0xdf / 255.0, alpha: 1)
                
                // Only affected if customization is declared
                color = primaryColor(defaultColor: color)
                
            }
        }
        
        return color
    }
    
    func getIndexPath(floorId: String) -> IndexPath? {
        var indexPath: IndexPath? = nil
        for i in 0 ..< self.buildingInfo!.floors.count {
            if floorId == orderedFloors(buildingInfo: buildingInfo)![i].identifier {
                indexPath = IndexPath(item: i, section: 0);
                break;
            }
        }
        return indexPath;
    }
    
    func getFloorIdFromMarker(marker: SitumMarker?) -> String {
        var floorIdentifier: String = ""
        if let floorId = marker?.gmsMarker.userData as? String {
            floorIdentifier = floorId
        } else if let selectedPOI = marker?.poi{
            floorIdentifier = selectedPOI.position().floorIdentifier
        }
        return floorIdentifier
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
                if (index == segments.endIndex-1) {
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
        self.indicationsView.isHidden = true
        self.changeCancelNavigationButtonVisibility(isVisible: false)
        self.changeNavigationButtonVisibility(isVisible: false)
        self.updateInfoBarLabels(mainLabel: self.buildingInfo?.building.name ?? DEFAULT_BUILDING_NAME)
        for polyline in self.polyline {
            polyline.map = nil
        }
        self.displayPois(onFloor: orderedFloors(buildingInfo:  buildingInfo)?[self.selectedLevelIndex].identifier)
        self.removeLastCustomMarker()
        self.destinationMarker?.setMapView(mapView: nil)
        self.notifyEndOfNavigation(status: status, marker: self.destinationMarker)
        self.destinationMarker = nil

        // hide selected point
        self.mapView.selectedMarker = nil
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
    
    private func getCategoryFromMarker(marker: SitumMarker?) -> DestinationCategory? {
        guard let marker = marker else { return nil }
        
        if marker.isPoiMarker() {
            return .poi(marker.poi!)
        } else {
            let coordinate = CLLocationCoordinate2D(
                latitude: marker.gmsMarker.position.latitude,
                longitude: marker.gmsMarker.position.longitude
            )
            let floorId = getFloorIdFromMarker(marker: marker)
            let point = SITPoint(building: buildingInfo!.building, floorIdentifier: floorId,
                coordinate: coordinate)
            return .location(point)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "mapContainerSegueID"{
                self.mapViewVC = segue.destination
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

extension PositioningViewController: UISearchControllerDelegate, UISearchBarDelegate{

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
    
    func searchTextPlaceholder()->String{
        if let searchViewPlaceholder = library?.settings?.searchViewPlaceholder, searchViewPlaceholder.count > 0{
            return searchViewPlaceholder
        }else{
            return NSLocalizedString("positioning.searchPois",
                bundle: SitumMapsLibrary.bundle,
                comment: "Placeholder for searching pois")
        }
    }
    
    func createSearchResultsContraints(){
        //We need to use navbar.topItem?.titleView in constraints instead of navbar because navigation bar dont update properly its height after adding search bar to its titleView: navbar.topItem?.titleView =  searchController!.searchBar
        let views = ["searchResultView": searchResultsController!.view, "navigationBar": navbar.topItem?.titleView]
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[searchResultView]-0-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views as [String : Any])
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[navigationBar]-0-[searchResultView]-0-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views as [String : Any])
        searchResultViewConstraints = horizontalConstraints + verticalConstraints
    }
    
//MARK: UISearchControllerDelegate methods
    func presentSearchController(_ searchController: UISearchController) {
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
}


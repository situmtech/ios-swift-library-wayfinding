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

class PositioningViewController: UIViewController ,GMSMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, PositioningView, PositioningController {
    
    //MARK PositioningController protocol variables
    var buildingId: String = ""
    var library: SitumMapsLibrary?

    //Positioning
    @IBOutlet weak var navbar: UINavigationBar!
    @IBOutlet weak var positioningButton: UIButton!
    @IBOutlet weak var levelsTableView: UITableView!
    @IBOutlet weak var levelsTableHeightConstaint: NSLayoutConstraint!
    @IBOutlet weak var centerButton: UIButton!
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
    
    //Positioning
    var mapOverlay: GMSGroundOverlay = GMSGroundOverlay()
    var userLocationMarker: GMSMarker? = nil
    var userLocationRadiusMarker: GMSMarker? = nil
    var poiMarkers: Array<GMSMarker> = []
    var floorplans: Dictionary<String, UIImage> = [:]
    var poiCategoryIcons: Dictionary<String, UIImage> = [:]
    var userMarkerIcons: Dictionary<String, UIImage> = [:]
    var lastBearing: Float = 0.0
    var lastAnimatedBearing: Float = 0.0
    var isCameraCentered: Bool = false
    let locManager: CLLocationManager = CLLocationManager()
    public var buildingInfo: SITBuildingInfo? = nil
    var actualZoom: Float = 0.0
    var selectedLevelIndex: Int = 0
    var presenter: PositioningPresenter? = nil
    
    //Navigation
    var lastSelectedMarker: GMSMarker?
    var lastCustomMarker: GMSMarker?
    var destinationMarker: GMSMarker?
    var progress: SITNavigationProgress? = nil
    var polyline: Array<GMSPolyline> = []
    var routePath: Array<GMSMutablePath> = []
    
    // Constants
    let DEFAULT_POI_NAME: String = "POI"
    let DEFAULT_BUILDING_NAME: String = "Current Building"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let alert: UIAlertView = UIAlertView.init(title: "Loading", message: "Hold on for a moment", delegate: nil, cancelButtonTitle: nil)
        alert.show()
        
        SITCommunicationManager.shared().fetchBuildingInfo(self.buildingId, withOptions: nil, success: { (mapping: [AnyHashable : Any]?) in
            if (mapping != nil) {
                self.buildingInfo = mapping!["results"] as? SITBuildingInfo
                if self.buildingInfo!.floors.count <= 0 {
                    self.showAlertMessage(title: "Error obtaining building info at 1", message: "An unexpected error ocurred while downloading the building's information. Please try again.")
                } else {
                    alert.dismiss(withClickedButtonIndex: 0, animated: true)
                    self.presenter = PositioningPresenter(view: self, buildingInfo: self.buildingInfo!, interceptorsManager: self.library?.interceptorsManager ?? InterceptorsManager())
                    self.initializeUIElements()
                }
            }
        }, failure: { (error: Error?) in
            Logger.logErrorMessage(error.debugDescription)
            alert.dismiss(withClickedButtonIndex: 0, animated: true)
            self.showAlertMessage(title: "Error obtaining building info at 2", message: "An unexpected error ocurred while downloading the building's information. Please try again.")
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
        navbar.topItem?.title = buildingInfo!.building.name
    }
    
    func initializeIcons() {
        poiCategoryIcons = Dictionary()
        let bundle = Bundle(for: type(of: self))
        if let locationPointer = UIImage(named: "swf_location_pointer", in: bundle, compatibleWith: nil), let locationOutdoorPointer = UIImage(named: "swf_location_outdoor_pointer", in: bundle, compatibleWith: nil), let location = UIImage(named: "swf_location", in: bundle, compatibleWith: nil), let radius = UIImage(named: "swf_radius", in: bundle, compatibleWith: nil) {
            userMarkerIcons = [
                "swf_location_pointer" : locationPointer,
                "swf_location_outdoor_pointer" : locationOutdoorPointer,
                "swf_location" : location,
                "swf_radius" : radius
            ]
        }
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
        
        let indexPath = IndexPath(row: 0, section: 0)
        levelsTableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        tableView(levelsTableView, didSelectRowAt: indexPath)
        levelsTableView.isHidden = false
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
    }
    
    func initializeCancelNavigationButton() {
        self.changeCancelNavigationButtonVisibility(isVisible: false)
        self.cancelNavigationButton.layer.cornerRadius = 0.5 * self.cancelNavigationButton.bounds.size.width
        self.cancelNavigationButton.layer.borderWidth = 2.0
        self.cancelNavigationButton.layer.borderColor = UIColor.red.cgColor
    }

    //MARK: Floorplans
    
    func displayMap(forLevel selectedLevelIndex: Int) {
        let levelIdentifier = buildingInfo!.floors[selectedLevelIndex].identifier
        if floorplans[levelIdentifier] != nil {
            displayFloorplan(forLevel: levelIdentifier)
        } else {
            SITCommunicationManager.shared().fetchMap(from: buildingInfo!.floors[selectedLevelIndex], withCompletion: { imageData in
                
                if let imageData = imageData {
                    let image =  UIImage.init(data: imageData, scale: UIScreen.main.scale)
                    let scaledImage = ImageUtils.scaleImage(image: image!)
                    self.floorplans[levelIdentifier] = scaledImage
                    self.displayFloorplan(forLevel: levelIdentifier)
                } else {
                    self.showAlertMessage(title: "Empty floorplan", message: "An unexpected error ocurred while downloading the floorplan. Please try again.")
                }
            })
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
    
    func selectFloor(floorId: String) {
        if let indexPath = getIndexPath(floorId: floorId) {
            tableView(levelsTableView, didSelectRowAt: indexPath)
        }
        isCameraCentered = true
        hideCenterButton()
    }
    
    func reloadTableViewData() {
        levelsTableView.reloadData()
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
        
        if let level: SITFloor = buildingInfo?.floors[indexPath.row] {
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
        let floorIdentifier: String = self.getFloorIdFromMarker(selectedMarker: self.destinationMarker!)
        self.destinationMarker?.map = (floor == floorIdentifier) ? self.mapView : nil
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
            }
        }
        poisInSelectedFloor.removeAll()
    }
    
    func updateUserMarker(with location: SITLocation) {
        let userLocationMarker = self.userLocationMarkerInMapView(mapView: self.mapView)
        let userLocationRadiusMarker = self.userLocationRadiusMarkerInMapView(mapView: self.mapView)
        let selectedLevel: SITFloor? = buildingInfo!.floors[selectedLevelIndex]
        if isCameraCentered || location.position.isOutdoor() || selectedLevel?.identifier == location.position.floorIdentifier {
            userLocationMarker.position = location.position.coordinate()
            userLocationRadiusMarker.position = location.position.coordinate()
            if self.isBearingChangedEnoughToReloadUi(bearing: location.bearing.degrees()) {
                userLocationMarker.rotation = CLLocationDegrees(location.bearing.degrees())
            }
            if location.position.isOutdoor() {
                userLocationMarker.icon = userMarkerIcons["swf_location_outdoor_pointer"]
            } else if location.quality == .sitHigh && location.bearingQuality == .sitHigh {
                userLocationMarker.icon = userMarkerIcons["swf_location_pointer"]
            } else {
                userLocationMarker.icon = userMarkerIcons["swf_location"]
            }
            self.makeUserMarkerVisible(visible: true) 
        } else {
            makeUserMarkerVisible(visible: false)
        }
    }
    
    func makeUserMarkerVisible(visible: Bool) {
        if (visible && self.userLocationMarkerInMapView(mapView: self.mapView).map == nil) {
            self.userLocationMarkerInMapView(mapView: self.mapView).map = self.mapView
            self.userLocationRadiusMarkerInMapView(mapView: self.mapView).map = self.mapView
        } else if (!visible && self.userLocationMarkerInMapView(mapView: self.mapView).map != nil) {
            self.userLocationMarkerInMapView(mapView: self.mapView).map = nil
            self.userLocationRadiusMarkerInMapView(mapView: self.mapView).map = nil
        }
    }
    
    func removeLastCustomMarkerIfOutsideRoute() {
        if(!self.isUserNavigating()) {
            self.removeLastCustomMarker()
        }
    }
    
    func removeLastCustomMarker() {
        if(self.lastCustomMarker != nil) {
            self.lastCustomMarker?.map = nil
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
        lastBearing = location.bearing.degrees()
        if isCameraCentered {
            let position = location.position
            let cameraUpdate = GMSCameraUpdate.setTarget(position.coordinate())
            mapView.animate(with: cameraUpdate)
            if isBearingChangedEnoughToReloadUi(bearing: location.bearing.degrees()) {
                mapView.animate(toBearing: CLLocationDirection(location.bearing.degrees()))
                lastAnimatedBearing = location.bearing.degrees()
            }
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
            positioningButton.backgroundColor = UIColor(red: 0x00 / 255.0, green: 0x75 / 255.0, blue: 0xc9 / 255.0, alpha: 1)
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
        if(!self.isUserNavigating()) {
            self.changeNavigationButtonVisibility(isVisible: true)
        }
        if(self.positioningButton.isSelected) {
            showCenterButton()
        }
        self.removeLastCustomMarkerIfOutsideRoute()
        self.updateInfoBarLabelsIfNotInsideRoute(mainLabel: marker.title ?? DEFAULT_POI_NAME, secondaryLabel: self.buildingInfo?.building.name ?? DEFAULT_BUILDING_NAME)
        self.lastSelectedMarker = marker
        isCameraCentered = false
        
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        self.removeLastCustomMarkerIfOutsideRoute()
        self.changeNavigationButtonVisibility(isVisible: false)
        self.updateInfoBarLabelsIfNotInsideRoute(mainLabel: self.buildingInfo?.building.name ?? DEFAULT_BUILDING_NAME)
    }
    
    func mapView(_ mapView: GMSMapView, didLongPressAt coordinate: CLLocationCoordinate2D) {
        if(self.presenter?.shouldShowFakeLocSelector() ?? false) {
            presenter?.fakeLocationPressed(coordinate: coordinate, floorId: buildingInfo!.floors[selectedLevelIndex].identifier)
        } else {
            self.createAndShowCustomMarkerIfOutsideRoute(atCoordinate: coordinate, atFloor: buildingInfo!.floors[selectedLevelIndex].identifier)
        }
    }
    
    func showFakeLocationsAlert() {
        let alert = UIAlertView(title: "Long press actions", message: "Select an action:", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "0º", "90º", "180º", "270º", "Create marker")
        
        alert.show()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.removeLastCustomMarkerIfOutsideRoute()
        self.changeNavigationButtonVisibility(isVisible: false)
        let isSameLevel = indexPath.row == self.selectedLevelIndex
        self.selectedLevelIndex = indexPath.row
        self.reloadTableViewData()
        self.displayMap(forLevel: self.selectedLevelIndex)
        if (presenter?.userLocation != nil && !isSameLevel) {
            self.isCameraCentered = false
            self.showCenterButton()
            self.updateUI(with: self.presenter!.userLocation!)
        }
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
        if (self.lastSelectedMarker != nil) {
            self.destinationMarker = self.lastSelectedMarker
        } else {
            self.showAlertMessage(title: "No destination selected", message: "There is no destination currently selected, the navigation cannot be started. Please select a POI (or longpress to create a custom one) and try again.")
        }
        self.positioningButton.isHidden = true
        self.changeCancelNavigationButtonVisibility(isVisible: true)
        self.presenter?.navigationButtonPressed(withDestination: self.destinationMarker!.position, inFloor: self.buildingInfo!.floors[self.selectedLevelIndex].identifier)
    }
    
    @IBAction
    func goBackButtonPressed(_ sender: Any) {
        self.presenter?.stopPositioning()
        self.presenter?.view = nil
        if let callback: (Any) -> Void = self.library?.onBackPressedCallback {
            callback(sender)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction
    func stopNavigatingButtonPressed(_ sender: UIButton) {
        presenter?.stopNavigation()
    }
    
    @IBAction
    func centerButtonPressed(_ sender: UIButton) {
//        self.changeNavigationButtonVisibility(isVisible: false)
        presenter?.centerButtonPressed()
    }
    
    //MARK: PositioningView protocol methods
    
    func showNumberOfBeaconsRanged(text: Int) {
        if (self.numberBeaconsRangedView.isHidden) {
            self.numberBeaconsRangedView.isHidden = false
        }
        self.numberBeaconsRangedLabel.text = String(format: "%d beacons", text)
    }
    
    func updateUI(with location: SITLocation) {
        updateUserMarker(with: location)
        presenter?.updateLevelSelector(location: location, isCameraCentered: self.isCameraCentered)
        updateCamera(with: location)
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
    
    func showAlertMessage(title: String, message: String) {
        let alertView = UIAlertView.init(title: title, message: message, delegate: self, cancelButtonTitle: "Ok");
        alertView.show()
    }

    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        #if DEBUG
        presenter?.fakeLocOptionSelected(atIndex: buttonIndex)
        #endif
    }
    
    func alertViewCancel(_ alertView: UIAlertView) {
        self.presenter?.alertViewClosed(alertView)
    }
    
    func showRoute(route: SITRoute) {
        self.changeNavigationButtonVisibility(isVisible: false)
        let floorIdentifier: String = self.getFloorIdFromMarker(selectedMarker: self.destinationMarker!)
        self.showPois(visible: false)
        if floorIdentifier == buildingInfo?.floors[self.selectedLevelIndex].identifier {
            self.destinationMarker?.map = self.mapView
        }
    }
    
    func updateProgress(progress: SITNavigationProgress) {
        self.progress = progress;
        self.indicationsView.isHidden = false
        self.updateInfoBarLabels(mainLabel: self.destinationMarker?.title ?? DEFAULT_POI_NAME, secondaryLabel: String(format: "%.1fm remaining", progress.distanceToGoal))
        
        // Update route based on this information
        for line in self.polyline {
            line.map = nil;
        }
        
        // Filter route steps for floors
        let selectedFloor = self.buildingInfo?.floors[self.selectedLevelIndex]
        
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
            self.lastCustomMarker = self.createMarker(withCoordinate: coordinate, floorId: floorId)
            self.updateInfoBarLabels(mainLabel: "Custom destination", secondaryLabel: self.buildingInfo?.building.name ?? DEFAULT_BUILDING_NAME)
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
        if poiCategoryIcons[poi.category.code] != nil {
            poiMarker.icon = poiCategoryIcons[poi.category.code]
            poiMarker.map = mapView
        } else {
            SITCommunicationManager.shared().fetchSelected(false, iconFor: poi.category, withCompletion: { iconData, error in
                if error != nil {
                    Logger.logErrorMessage("error retrieving icon data")
                } else {
                    
                    DispatchQueue.main.async(execute: {
                        var iconImg: UIImage? = nil
                        if let iconData = iconData {
                            let newSize = CGFloat(self.mapView.camera.zoom * 3.0)
                            iconImg = ImageUtils.scaleImageToSize(image: UIImage(data: iconData)!, newSize: CGSize(width: newSize, height: newSize))
                        }
                        self.poiCategoryIcons[poi.category.code] = iconImg
                        poiMarker.icon = iconImg
                        poiMarker.map = self.mapView
                    })
                }
            })
        }
        return poiMarker
    }
    
    func createMarker(withCoordinate coordinate: CLLocationCoordinate2D, floorId floor: String) -> GMSMarker {
        let marker: GMSMarker = GMSMarker(position: coordinate)
        marker.title = "Custom destination"
        marker.userData = floor
        marker.map = self.mapView
        
        return marker
    }
    
    func isBearingChangedEnoughToReloadUi(bearing: Float) -> Bool {
        if((bearing < (self.lastAnimatedBearing - 5.0)) || (bearing > (self.lastAnimatedBearing + 5.0))) {
            return true;
        }
        return false;
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
            }
        }
        
        return color
    }
    
    func getIndexPath(floorId: String) -> IndexPath? {
        var indexPath: IndexPath? = nil
        for i in 0 ..< self.buildingInfo!.floors.count {
            if floorId == self.buildingInfo!.floors[i].identifier {
                indexPath = IndexPath(item: i, section: 0);
                break;
            }
        }
        return indexPath;
    }
    
    func getFloorIdFromMarker(selectedMarker marker: GMSMarker) -> String {
        var floorIdentifier: String = ""
        if let floorId: String = self.destinationMarker?.userData as? String {
            floorIdentifier = floorId
        } else if let selectedPOI: SITPOI = self.destinationMarker?.userData as? SITPOI {
            floorIdentifier = selectedPOI.position().floorIdentifier
        }
        
        return floorIdentifier
    }
    
    func userLocationMarkerInMapView(mapView: GMSMapView) -> GMSMarker {
        if (self.userLocationMarker == nil) {
            let marker: GMSMarker = GMSMarker.init()
            marker.icon = self.userMarkerIcons["swf_location_pointer"]
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.isTappable = false;
            marker.zIndex = 2;
            marker.isFlat = true;
            self.userLocationMarker = marker;
        }
        return self.userLocationMarker!;
    }
    
    func userLocationRadiusMarkerInMapView (mapView: GMSMapView) -> GMSMarker {
        if (self.userLocationRadiusMarker == nil) {
            let marker: GMSMarker = GMSMarker.init()
            marker.icon = self.userMarkerIcons["swf_radius"]
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.isTappable = false;
            marker.zIndex = 1
            self.userLocationRadiusMarker = marker
        }
        return self.userLocationRadiusMarker!
    }
    
    func generateAndPrintRoutePathWithRouteSegments(segments: Array<SITRouteSegment>, selectedFloor: SITFloor) {
        for (index, segment) in segments.enumerated() {
            if segment.floorIdentifier == selectedFloor.identifier {
                let path: GMSMutablePath = GMSMutablePath()
                for point in segment.points {
                    path.add(point.coordinate())
                }
                if (index == segments.endIndex-1) {
                    if let lastPoint = self.destinationMarker?.position {
                        path.add(lastPoint)
                    }
                }
                self.routePath.append(path)
                let polyline: GMSPolyline = GMSPolyline(path: path)
                polyline.strokeWidth = 3
                self.polyline.append(polyline)
                polyline.map = self.mapView
            }
        }
    }
    
    //MARK: Stop methods
    func stop() {
        self.makeUserMarkerVisible(visible: false)
        self.numberBeaconsRangedView.isHidden = true
        self.reloadTableViewData()
        self.hideCenterButton()
        self.change(.stopped, centerCamera: false)
        self.stopNavigation()
    }
    
    func stopNavigation() {
        SITNavigationManager.shared().removeUpdates()
        self.indicationsView.isHidden = true
        self.changeCancelNavigationButtonVisibility(isVisible: false)
        self.changeNavigationButtonVisibility(isVisible: false)
        self.updateInfoBarLabels(mainLabel: self.buildingInfo?.building.name ?? DEFAULT_BUILDING_NAME)
        for polyline in self.polyline {
            polyline.map = nil
        }
        self.displayPois(onFloor: self.buildingInfo?.floors[self.selectedLevelIndex].identifier)
        self.removeLastCustomMarker()
        self.destinationMarker?.map = nil
        self.destinationMarker = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            if identifier == "mapContainerSegueID"{
                self.mapViewVC = segue.destination
            }
        }
    }

    @IBAction func clearCacheButtonPressed(_ sender: Any) {
        SITCommunicationManager.shared().clearCache()
    }
}


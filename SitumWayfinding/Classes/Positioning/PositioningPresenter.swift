//
//  PositioningPresenter.swift
//  SitumMappingTool
//
//  Created by Cristina Sánchez Barreiro on 09/04/2019.
//  Copyright © 2019 Situm Technologies S.L. All rights reserved.
//

import Foundation
import SitumSDK
import GoogleMaps

class PositioningPresenter: NSObject, SITLocationDelegate, SITDirectionsDelegate, SITNavigationDelegate {
    
    var view: PositioningView?
    var buildingInfo: SITBuildingInfo
    var interceptorsManager: InterceptorsManager
    
    var useFakeLocations: Bool = false
    var isSystemWaitingToStartRoute: Bool = false
    /* User location would be:
    1. When not in navigation -> Location updated by SITLocationManager in delegate call
    2. When in navigation -> SITNavigationProgress.closestLocationInRoute
    */
    var userLocation: SITLocation? = nil
    var locationManagerUserLocation: SITLocation? = nil
    var lastCalibrationAlert: TimeInterval = 0.0
    var lastOOBAlert: TimeInterval = 0.0
    var lastOutsideRouteAlert: TimeInterval = 0.0
    var point: SITPoint? = nil
    var directionsRequest: SITDirectionsRequest? = nil
    var route: SITRoute? = nil
    var locationManager: SITLocationManager = SITLocationManager.sharedInstance()
    
    var useRemoteConfig: Bool = false
    
    let compassCalibrationAlertTitle = "Compass calibration needed"
    let oobAlertTitle = "User outside building"
    let outsideRouteAlertTitle = "User ouside route"

    init(view: PositioningView, buildingInfo: SITBuildingInfo, interceptorsManager: InterceptorsManager) {
        self.view = view
        self.buildingInfo = buildingInfo
        self.interceptorsManager = interceptorsManager
    }
    
    func startPositioning() {
        initializeLocationManagers()
        requestLocationUpdates()
    }
    
    func initializeLocationManagers() {
        #if DEBUG
        self.useFakeLocations = UserDefaultsWrapper.getUseFakeLocations()
        if (self.useFakeLocations) {
//            self.locationManager = SITFakeLocationManager.sharedInstance()
        } else {
            self.locationManager = SITLocationManager.sharedInstance()
        }
        #else
        self.locationManager = SITLocationManager.sharedInstance()
        #endif
        self.locationManager.delegate = self
    }
    
    func requestLocationUpdates() {
        var request: SITLocationRequest = RequestBuilder.buildLocationRequest(buildingId: buildingInfo.building.identifier)
        request = self.interceptorsManager.onLocationRequest(request)
        self.locationManager.requestLocationUpdates(SITServices.isUsingRemoteConfig() && useRemoteConfig ? nil: request)
        view?.change(.calculating, centerCamera: true)
    }
    
    func stopPositioning() {
        self.locationManager.removeUpdates()
        self.userLocation = nil
        self.locationManagerUserLocation = nil
        self.lastOOBAlert = 0.0
        self.lastCalibrationAlert = 0.0
        view?.cleanLocationUI()
        view?.stopNavigation(status: .canceled)
    }

    func resetLastOutsideRouteAlert() {
        self.lastOutsideRouteAlert = 0.0
    }
    
    public func shouldShowFakeLocSelector() -> Bool {
        #if DEBUG
        return self.useFakeLocations
        #else
        return false
        #endif
    }
    
    func hasAlertPresentationDateExpired(type: AlertType) -> Bool {
        let now = Date().timeIntervalSince1970
        var lastDate: TimeInterval = 0.0
        
        if (type == .otherAlert){
            print("Got a non valid alert type checking hasAlertPresentationDateExpired")
            return false
        }
        
        lastDate = {
            switch type {
            case .compassCalibrationNeeded:
                return self.lastCalibrationAlert
            case.outOfBuilding:
                return self.lastOOBAlert
            case .outsideRoute:
                return self.lastOutsideRouteAlert
            case .otherAlert:
                return now
            }
        }()
        
        return now - lastDate > SecondsBetweenAlerts
    }
    
    private func updateLastAlertVisibleDate(type: AlertType){
        switch type {
        case .compassCalibrationNeeded:
            self.lastCalibrationAlert = NSDate().timeIntervalSince1970
        case.outOfBuilding:
            self.lastOOBAlert = NSDate().timeIntervalSince1970
        case .outsideRoute:
            self.lastOutsideRouteAlert = NSDate().timeIntervalSince1970
        default:
            print("Got a non valid alert type updating last AlertVisibleDate")
        }
    }
    
    //MARK: Handle user interactions
    
    public func positioningButtonPressed() {
        if (self.locationManager.state() == .stopped) {
            self.startPositioning()
        } else {
            self.stopPositioning()
        }
    }

    public func startPositioningAndNavigate(withDestination destination: CLLocationCoordinate2D, inFloor floorId: String) {
        point = nil
        if (CLLocationCoordinate2DIsValid(destination)){
            point = SITPoint(building: buildingInfo.building, floorIdentifier: floorId, coordinate: destination)
        }
        if (self.locationManager.state() == .stopped) {
            self.startPositioning()
            self.isSystemWaitingToStartRoute = true
        } else {
            self.requestDirections(to: point)
        }
    }

    public func alertViewClosed(_ alertType:AlertType = .otherAlert) {
        self.updateLastAlertVisibleDate(type: alertType)
    }
    
    public func fakeLocationPressed(coordinate: CLLocationCoordinate2D, floorId: String) {
        if (!useFakeLocations) {
            return
        }
        let building = buildingInfo.building
        let converter: SITCoordinateConverter = SITCoordinateConverter(dimensions: building.dimensions(), center: building.center(), rotation: building.rotation)
        
        let cartesianCoordinate: SITCartesianCoordinate? = converter.toCartesianCoordinate(coordinate)
        
        point = SITPoint(coordinate: coordinate, buildingIdentifier: building.identifier, floorIdentifier: floorId, cartesianCoordinate: cartesianCoordinate!)
        
        view?.showFakeLocationsAlert()
        
        if let x = cartesianCoordinate?.x, let y = cartesianCoordinate?.y {
            Logger.logInfoMessage("Fake location pressed at \(x), \(y)")
        }
    }
    
    public func fakeLocOptionSelected(atIndex index: Int) {
        // Entering this if means we are creating a custom marker instead of a fake location
        if(index == 5) {
            if let point = self.point{
                self.view?.createAndShowCustomMarkerIfOutsideRoute(atCoordinate: point.coordinate(), atFloor: point.floorIdentifier)
            }
        } else {
            self.createFakeLocation(index: index)
        }
    }
    
    public func createFakeLocation(index: Int) {
        if (!self.useFakeLocations) {
            return
        }
        if let point = self.point {
            let angle: SITAngle = {
                switch(index) {
                case 2:
                    return AngleType.angleRight.toSITAngle()
                case 3:
                    return AngleType.anglePlain.toSITAngle()
                case 4:
                    return AngleType.angleConcave.toSITAngle()
                default:
                    return AngleType.angleZero.toSITAngle()
                }
            }()
            
            
            
            let building = buildingInfo.building
            let converter = SITCoordinateConverter(dimensions: building.dimensions(), center: building.center(), rotation: building.rotation)
            let location = SITLocation(timestamp: Date().timeIntervalSince1970, position: point, bearing: angle.degrees() + 90, cartesianBearing: (converter.toCartesianAngle(angle).radians()), quality: .sitHigh, accuracy: 5, provider: "Fake")
            
//            SITFakeLocationManager.sharedInstance().update(with: location)
            
        }
    }
    
    func centerViewInUserLocation() {
        if let userLocation = userLocation {
            view?.select(floor: userLocation.position.floorIdentifier)
            view?.setCameraCentered()
            view?.updateUI(with: userLocation)
        }
    }
    
    func shouldCameraPositionBeDraggedInsideBuildingBounds(position: CLLocationCoordinate2D) -> Bool {
        
        // [26/04/19] Since this functionality is expected to suffer changes in the short term, it is only available in debug for now
        #if DEBUG
        if(!UserDefaultsWrapper.getSingleBuildingMode()) {
            return false
        }
        
        let bounds: SITBounds = self.buildingInfo.building.bounds()
        let isOutsideLatitude: Bool = position.latitude < bounds.southWest.latitude || position.latitude > bounds.northEast.latitude
        let isOutsideLongitude: Bool = position.longitude < bounds.southWest.longitude || position.longitude > bounds.northEast.longitude
        if (isOutsideLatitude || isOutsideLongitude) {
            return true
        }
        #endif
        return false
    }
    
    func modifyCameraToBeInsideBuildingBounds(camera: GMSCameraPosition) -> GMSCameraPosition {

        var destinationLatitude  = camera.target.latitude
        var destinationLongitude = camera.target.longitude
        let bounds: SITBounds = self.buildingInfo.building.bounds()
        
        if (camera.target.latitude > bounds.northEast.latitude) {
            destinationLatitude = bounds.northEast.latitude
        }
        if (camera.target.latitude < bounds.southWest.latitude) {
            destinationLatitude = bounds.southWest.latitude
        }
        if (camera.target.longitude > bounds.northEast.longitude) {
            destinationLongitude = bounds.northEast.longitude
        }
        if (camera.target.longitude < bounds.southWest.longitude) {
            destinationLongitude = bounds.southWest.longitude;
        }
        
        // [26/04/19] TODO: 17 is not always a good value for zoom, depending on building size
        let zoom: Float = camera.zoom < 17.0 ? 17.0 : camera.zoom
        let destinationCamera = GMSCameraPosition.camera(withLatitude: destinationLatitude, longitude: destinationLongitude, zoom: zoom)
        
        return destinationCamera
    }
    
    public func requestDirections(to position: SITPoint!) {
        if let navigationError = checkDirectionsRequestValidity(origin: userLocation?.position ?? nil, destination: position) {
            view?.stopNavigation(status: .error(navigationError))
            return
        }
    
        var request: SITDirectionsRequest = RequestBuilder.buildDirectionsRequest(userLocation: userLocation!, destination: position)
        request = self.interceptorsManager.onDirectionsRequest(request)
        SITDirectionsManager.sharedInstance().delegate = self
        SITDirectionsManager.sharedInstance().requestDirections(request)
    }
    
    func isUserIndoor() -> Bool{
        if let userIndoor = locationManagerUserLocation?.position.isIndoor(){
            return userIndoor
        }
        return false
    }
    
    func isUserNavigating() -> Bool{
        return SITNavigationManager.shared().isRunning()
    }
    
    func checkDirectionsRequestValidity(origin: SITPoint!, destination: SITPoint!) -> NavigationError? {
        let originError = checkIfOriginIsValid(origin: origin)
        if (originError != nil){
            return originError
        }
        
        let destinationError = self.checkIfDestinationIsValid(destination: destination)
        return destinationError
    }
    
    func checkIfOriginIsValid(origin:SITPoint!) -> NavigationError? {
        if (origin == nil){
            //Theoretically this shouldnt happen as positioning is started when a route is requested if it was stopped
            return .positionUnknown
        }
        if (origin.isOutdoor()) {
            return .outdoorOrigin
        }
        return nil
    }
    
    func checkIfDestinationIsValid(destination: SITPoint!) -> NavigationError? {
        if (destination == nil){
            return .noDestinationSelected
        }
        return nil
    }
    
    func requestNavigation(route: SITRoute) {
        var request = RequestBuilder.buildNavigationRequest(route: route)
        request = self.interceptorsManager.onNavigationRequest(request)
        SITNavigationManager.shared().delegate = self
        SITNavigationManager.shared().requestNavigationUpdates(request)
        SITNavigationManager.shared().update(with: userLocation!)
    }
    
    func updateLevelSelector(location: SITLocation, isCameraCentered: Bool, selectedLevel: String) {
        if userLocation?.position.floorIdentifier != selectedLevel {
            view?.reloadFloorPlansTableViewData()
            if isCameraCentered {
                view?.select(floor: location.position.floorIdentifier)
            }
        } else {
            view?.reloadFloorPlansTableViewData()
        }
    }
    
    //Mark LocationDelegate methods
    
    func locationManager(_ locationManager: SITLocationInterface, didUpdateRangedBeacons numberOfRangedBeacons: Int) {
        view?.showNumberOfBeaconsRanged(text: numberOfRangedBeacons)
    }
    
    func locationManager(_ locationManager: SITLocationInterface, didUpdate location: SITLocation) {

        Logger.logDebugMessage("location manager updates location: \(location), provider: \(location.provider)")
        locationManagerUserLocation = location

        if (userLocation == nil) {
            view?.change(.started, centerCamera: true)
        }
        
        if isUserNavigating() {
            SITNavigationManager.shared().update(with: location)
            //UI and self.userLocation are updated in SITNavigationManager callback with the user position adjusted to the route
        } else {
            userLocation = location
            view?.updateUI(with: location)
        }
        
        if(isSystemWaitingToStartRoute) {
            self.isSystemWaitingToStartRoute = false
            self.requestDirections(to: self.point)
        }
    }
    
    
    func locationManager(_ locationManager: SITLocationInterface, didFailWithError error: Error?) {
        Logger.logErrorMessage("Location error problem: \(error.debugDescription)")
        view?.cleanLocationUI()
        view?.stopNavigation(status: .error(NavigationError.locationError(error)))
    }
    
    func locationManager(_ locationManager: SITLocationInterface, didUpdate state: SITLocationState) {
        var stateName: String
        switch  state {
        case .started:
            stateName = "Started"
            break;
        case .stopped:
            stateName = "Stopped"
            break;
        case .calculating:
            stateName = "Calculating"
            break;
        case .compassNeedsCalibration:
            stateName = "Compass needs calibration"
            showAlertIfNeeded(type: .compassCalibrationNeeded, title: self.compassCalibrationAlertTitle, message: "Your device's compass isn't calibrated right now. Please recalibrate it to obtain the best navigation experience.")
            break;
        case .userNotInBuilding:
            stateName = "User not in building"
            if isUserNavigating(){
                view?.stopNavigation(status: .error(NavigationError.outsideBuilding))
            }
            showAlertIfNeeded(type: .outOfBuilding, title: self.oobAlertTitle, message: "The user is currently outside of the building. Positioning will resume when the user returns.")
            break;
        }
        Logger.logDebugMessage("Location manager updates state: \(stateName)")
    }

    //MARK: DirectionsDelegate methods
    
    func directionsManager(_ manager: SITDirectionsInterface, didFailProcessingRequest request: SITDirectionsRequest, withError error: Error?) {
        Logger.logErrorMessage("directions request failed with error: \(error.debugDescription)");
        self.view?.stopNavigation(status: .error(NavigationError.unableToComputeRoute))
    }
    
    func directionsManager(_ manager: SITDirectionsInterface, didProcessRequest request: SITDirectionsRequest, withResponse route: SITRoute) {
        if (route.routeSteps.count == 0) {
            Logger.logDebugMessage("Unable to find a path for request: \(request.debugDescription)")
            self.view?.stopNavigation(status: .error(NavigationError.noAvailableRoute))
        } else {
            view?.showRoute(route: route)
            self.directionsRequest = request
            self.route = route
            self.requestNavigation(route: route)
            Logger.logDebugMessage("Directions request completed. To Display routes and : \(route.debugDescription)")
        }
    }
    
    //MARK: NavigationDelegate methods
    
    func navigationManager(_ navigationManager: SITNavigationInterface, didFailWithError error: Error) {
        Logger.logErrorMessage("Navigation error: \(error)")
        self.view?.stopNavigation(status: .error(error))
    }
    
    func navigationManager(_ navigationManager: SITNavigationInterface, didUpdate progress: SITNavigationProgress, on route: SITRoute) {
        Logger.logDebugMessage("Update Progress: \(progress.debugDescription)")
        view?.updateProgress(progress: progress)
        self.userLocation = progress.closestLocationInRoute
    }
    
    func navigationManager(_ navigationManager: SITNavigationInterface, destinationReachedOn route: SITRoute) {
        Logger.logDebugMessage("Destination reached")
        self.view?.stopNavigation(status: .destinationReached)
    }
    
    func navigationManager(_ navigationManager: SITNavigationInterface, userOutsideRoute route: SITRoute) {
        Logger.logDebugMessage("user outside route detected: \(route.debugDescription)");
        
        if isUserIndoor(){
            showAlertIfNeeded(type: .outsideRoute, title: self.outsideRouteAlertTitle, message: "The user is not currently detected on the route. Please go back to resume navigation.")
        }else{
            view?.stopNavigation(status: .error(NavigationError.outsideBuilding))
        }
    }
    
    func showAlertIfNeeded(type: AlertType, title: String, message: String){
        if self.hasAlertPresentationDateExpired(type: type) {
            view?.showAlertMessage(title: title, message: message, alertType: type)
            self.updateLastAlertVisibleDate(type: type)
        }
    }
    
    func isSameFloor(floorIdentifier: String?) -> Bool {

        if let userFloor = userLocation?.position.floorIdentifier {
            if let floorIdentifier = floorIdentifier {
                return floorIdentifier == userFloor
            }
        }
        return false
    }
}

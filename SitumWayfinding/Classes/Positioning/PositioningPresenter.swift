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
    
    var isSystemWaitingToStartRoute: Bool = false
    /* User location would be:
    1. When not in navigation -> Location updated by SITLocationManager in delegate call
    2. When in navigation -> SITNavigationProgress.closestLocationInRoute
    */
    var userLocation: SITLocation? = nil
    var lastPositioningLocation: SITLocation? = nil
    var locationManagerUserLocation: SITLocation? = nil
    var lastCalibrationAlert: TimeInterval = 0.0
    var lastOOBAlert: TimeInterval = 0.0
    var lastOutsideRouteAlert: TimeInterval = 0.0
    var point: SITPoint? = nil
    var directionsRequest: SITDirectionsRequest? = nil
    var route: SITRoute? = nil
    var locationManager: SITLocationInterface = SITLocationManager.sharedInstance()
    var now = Date()
    let timeRecalculate = 6
    
    var useRemoteConfig: Bool = false

    init(view: PositioningView, buildingInfo: SITBuildingInfo, interceptorsManager: InterceptorsManager) {
        self.view = view
        self.buildingInfo = buildingInfo
        self.interceptorsManager = interceptorsManager
    }
    
    func startPositioning() {
        requestLocationUpdates()
    }
    
    func addLocationListener() {
        // In a normal use case, SITLocationManager will be the provider of user positions,
        // however in WYF with debug purposes we allow the user to "fake" its location
        // Here we use factory pattern to abstract the construction of this location provider. SITLocationManager
        // or FakeLocationManager will be instantiated depending if the user want actual or fake positions
        #if DEBUG
        locationManager = LocationManagerFactory.createLocationManager()
        #endif
        
        LocationManagerFactory.addDelegate(object: locationManager, delegate: self)
    }

    func removeLocationListener() {
        LocationManagerFactory.removeDelegate(object: locationManager, delegate: self)
    }
    
    func requestLocationUpdates() {
        var request: SITLocationRequest = RequestBuilder.buildLocationRequest(buildingId: buildingInfo.building.identifier)
        request = self.interceptorsManager.onLocationRequest(request)
        self.locationManager.requestLocationUpdates(SITServices.isUsingRemoteConfig() && useRemoteConfig ? nil: request)
        view?.changeLocationState(.calculating, centerCamera: true)
    }

    func resetLastOutsideRouteAlert() {
        self.lastOutsideRouteAlert = 0.0
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
            case .permissionsError:
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

    func stopPositioning() {
        self.locationManager.removeUpdates()
        self.userLocation = nil
        self.locationManagerUserLocation = nil
        self.lastOOBAlert = 0.0
        self.lastCalibrationAlert = 0.0
        view?.cleanLocationUI()
        view?.stopNavigation(status: .canceled)
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
    
    // MARK: LocationDelegate methods SITLocationDelegate
    
    func locationManager(_ locationManager: SITLocationInterface, didUpdateRangedBeacons numberOfRangedBeacons: Int) {
        view?.showNumberOfBeaconsRanged(text: numberOfRangedBeacons)
    }
    
    func locationManager(_ locationManager: SITLocationInterface, didUpdate location: SITLocation) {

        Logger.logDebugMessage("location manager updates location: \(location), provider: \(location.provider)")
        locationManagerUserLocation = location

        if (userLocation == nil) {
            view?.changeLocationState(.started, centerCamera: true)
        }
        
        if isUserNavigating() {
            // UI and self.userLocation are updated in SITNavigationManager callback with the user position adjusted
            // to the route
            SITNavigationManager.shared().update(with: location)
            // this positions will be used if some error in navigation occur and navigation manager do not return
            // the user current position
            lastPositioningLocation = location
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
        
        // TODO: Update SDK Error visibility to access
        switch error {
        case .some(let error as NSError) where error.code == 7 || error.code == 8:
            
            view?.showAlertMessage(title: NSLocalizedString("wayfinding.permissionsErrorTitle", bundle: SitumMapsLibrary.bundle, comment: "Unable to provide location"), message: NSLocalizedString("wayfinding.permissionsErrorDescription", bundle: SitumMapsLibrary.bundle, comment: "Please go to settings and enable location and bluetooth permissions to provide locations") , alertType: .permissionsError)
            
        default:
            print("detected error: \(error)")
            
        }
    }
    
    func locationManager(_ locationManager: SITLocationInterface, didUpdate state: SITLocationState) {
        var stateName: String
        switch  state {
        case .started:
            stateName = "Started"
            break;
        case .stopped:
            stateName = "Stopped"
            stopPositioning()
            break;
        case .calculating:
            stateName = "Calculating"
            break;
        case .compassNeedsCalibration:
            stateName = "Compass needs calibration"
            let compassCalibrationAlertTitle = NSLocalizedString("positioning.calibrationNeeded.alert.title",
                bundle: SitumMapsLibrary.bundle,
                comment: "The user needs to calibrate the compass")
            showAlertIfNeeded(type: .compassCalibrationNeeded, title: compassCalibrationAlertTitle,
                message: NSLocalizedString("positioning.calibrationNeeded.alert.message",
                    bundle: SitumMapsLibrary.bundle,
                    comment: ""))
            break;
        case .userNotInBuilding:
            stateName = "User not in building"
            if isUserNavigating(){
                view?.stopNavigation(status: .error(NavigationError.outsideBuilding))
            }
            let oobAlertTitle = NSLocalizedString("positioning.outsideBuilding.alert.title",
                bundle: SitumMapsLibrary.bundle,
                comment: "Alert title to show user is outside of building")
            showAlertIfNeeded(type: .outOfBuilding, title: oobAlertTitle,
                message: NSLocalizedString("positioning.outsideBuilding.alert.message",
                    bundle: SitumMapsLibrary.bundle,
                    comment: "") )
            break;
        }
        Logger.logDebugMessage("Location manager updates state: \(stateName)")
    }

    // MARK: DirectionsDelegate methods
    
    func directionsManager(_ manager: SITDirectionsInterface, didFailProcessingRequest request: SITDirectionsRequest, withError error: Error?) {
        Logger.logErrorMessage("Directions request failed with error: \(error.debugDescription)");
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
    
    //MARK: SITNavigationDelegate methods
    
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
        Logger.logDebugMessage("User outside route detected: \(route.debugDescription)");
        
        if isUserIndoor() {
            if checkRecalculate() {
                if let lastLocation = lastPositioningLocation {
                    view?.updateUI(with: lastLocation)
                }
                recalculateRoute()
            }
        } else {
            view?.stopNavigation(status: .error(NavigationError.outsideBuilding))
        }
    }
    
    private func checkRecalculate() -> Bool {
        let endDate = Date()
        let difference = Calendar.current.dateComponents([.second], from: now, to: endDate)
        return difference.second! > timeRecalculate
    }
    
    private func recalculateRoute() {
        self.now = Date()
        view?.routeWillRecalculate()
        SITNavigationManager.shared().removeUpdates()
        userLocation = lastPositioningLocation
        requestDirections(to: point)
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


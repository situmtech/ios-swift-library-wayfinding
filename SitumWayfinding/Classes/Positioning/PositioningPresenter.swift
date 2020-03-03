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
    var userLocation: SITLocation? = nil
    var lastCalibrationAlert: TimeInterval = 0.0
    var lastOOBAlert: TimeInterval = 0.0
    var lastOutsideRouteAlert: TimeInterval = 0.0
    var point: SITPoint? = nil
    var directionsRequest: SITDirectionsRequest? = nil
    var route: SITRoute? = nil
    var locationManager: SITLocationManager = SITLocationManager.sharedInstance()
    
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
        self.locationManager.requestLocationUpdates(request)
        view?.change(.calculating, centerCamera: true)
    }
    
    func stopPositioning() {
        if self.locationManager.state() != .stopped {
            self.locationManager.removeUpdates()
        }
        self.userLocation = nil
        self.lastOOBAlert = 0.0
        self.lastCalibrationAlert = 0.0
        view?.stop()
    }
    
    func stopNavigation() {
        self.lastOutsideRouteAlert = 0.0
        view?.stopNavigation()
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
    
    public func navigationButtonPressed(withDestination destination: CLLocationCoordinate2D, inFloor floorId: String) {
        point = SITPoint(building: buildingInfo.building, floorIdentifier: floorId, coordinate: destination)
        if (self.locationManager.state() == .stopped) {
            self.startPositioning()
            self.isSystemWaitingToStartRoute = true
        } else {
            self.requestDirections(to: point)
        }
    }
    
    public func alertViewClosed(_ alertView: UIAlertView) {
        var alertType:AlertType = .otherAlert;
        if(alertView.title == self.compassCalibrationAlertTitle) {
            alertType = .compassCalibrationNeeded
        } else if(alertView.title == self.oobAlertTitle) {
            alertType = .outOfBuilding
        } else if(alertView.title == self.outsideRouteAlertTitle) {
            alertType = .outsideRoute
        }
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
    
    func centerButtonPressed() {
        if let userLocation = userLocation {
            
            view?.selectFloor(floorId: userLocation.position.floorIdentifier)
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
        if let userLocation = userLocation {
            var request: SITDirectionsRequest = RequestBuilder.buildDirectionsRequest(userLocation: userLocation, destination: position)
            request = self.interceptorsManager.onDirectionsRequest(request)
            SITDirectionsManager.sharedInstance().delegate = self
            SITDirectionsManager.sharedInstance().requestDirections(request)
        } else {
            view?.showAlertMessage(title: "Position unknown", message: "User actual location is unknown, please activate the positioning before computing a route and try again.")
            view?.stopNavigation()
            return
        }
    }
    
    func requestNavigation(route: SITRoute) {
        var request = RequestBuilder.buildNavigationRequest(route: route)
        request = self.interceptorsManager.onNavigationRequest(request)
        SITNavigationManager.shared().delegate = self
        SITNavigationManager.shared().requestNavigationUpdates(request)
        SITNavigationManager.shared().update(with: userLocation!)
    }
    
    func updateLevelSelector(location: SITLocation, isCameraCentered: Bool) {
        if userLocation?.position.floorIdentifier != location.position.floorIdentifier {
            view?.reloadTableViewData()
            if isCameraCentered {
                view?.selectFloor(floorId: location.position.floorIdentifier)
            }
        } else {
            view?.reloadTableViewData()
        }
    }
    
    //Mark LocationDelegate methods
    
    func locationManager(_ locationManager: SITLocationInterface, didUpdateRangedBeacons numberOfRangedBeacons: Int) {
        view?.showNumberOfBeaconsRanged(text: numberOfRangedBeacons)
    }
    
    func locationManager(_ locationManager: SITLocationInterface, didUpdate location: SITLocation) {
        
        Logger.logDebugMessage("location manager updates location: \(location), provider: \(location.provider)")
        
        if (userLocation == nil) {
            view?.change(.started, centerCamera: true)
        }
        
        if (SITNavigationManager.shared().isRunning()) {
            SITNavigationManager.shared().update(with: location)
        } else {
            view?.updateUI(with: location)
            self.userLocation = location
        }
        
        if(isSystemWaitingToStartRoute) {
            self.isSystemWaitingToStartRoute = false
            self.requestDirections(to: self.point)
        }
    }
    
    
    func locationManager(_ locationManager: SITLocationInterface, didFailWithError error: Error?) {
        Logger.logErrorMessage("Location error problem: \(error.debugDescription)")
        if error != nil {
            let fullError = error! as NSError
            if ((fullError.userInfo["kindof"] != nil) && ((fullError.userInfo["kindof"] as! String) == "critical")) {
                view?.stop()
            }
        }
        view?.showAlertMessage(title: "Error", message: error!.localizedDescription)
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
            showAlertIfNeeded(type: .outOfBuilding, title: self.oobAlertTitle, message: "The user is currently outside of the building. Positioning will resume when the user returns.")
            break;
        }
        Logger.logDebugMessage("Location manager updates state: \(stateName)")
    }
    
    //MARK: DirectionsDelegate methods
    
    func directionsManager(_ manager: SITDirectionsInterface, didFailProcessingRequest request: SITDirectionsRequest, withError error: Error?) {
        view?.showAlertMessage(title: "Unable to compute route", message: "An unexpected error was found while computing the route. Please try again.")
        Logger.logErrorMessage("directions request failed with error: \(error.debugDescription)");
    }
    
    func directionsManager(_ manager: SITDirectionsInterface, didProcessRequest request: SITDirectionsRequest, withResponse route: SITRoute) {
        if (route.routeSteps.count == 0) {  
            view?.showAlertMessage(title: "Unable to compute route", message: "There is no route between the selected locations. Try to compute a different route or to switch accessibility mode")
            Logger.logDebugMessage("Unable to find a path for request: \(request.debugDescription)")
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
        self.stopNavigation()
    }
    
    func navigationManager(_ navigationManager: SITNavigationInterface, didUpdate progress: SITNavigationProgress, on route: SITRoute) {
        Logger.logDebugMessage("Update Progress: \(progress.debugDescription)")
        view?.updateProgress(progress: progress)
        self.userLocation = progress.closestLocationInRoute
    }
    
    func navigationManager(_ navigationManager: SITNavigationInterface, destinationReachedOn route: SITRoute) {
        Logger.logDebugMessage("Destination reached")
        let alert = UIAlertView(title: "Destination Reached", message: "You've arrived to your destination", delegate: self, cancelButtonTitle: "Ok")
        alert.tag = 1
        alert.show()
        view?.stopNavigation()
    }
    
    func navigationManager(_ navigationManager: SITNavigationInterface, userOutsideRoute route: SITRoute) {
        Logger.logDebugMessage("user outside route detected: \(route.debugDescription)");
        showAlertIfNeeded(type: .outsideRoute, title: self.outsideRouteAlertTitle, message: "The user is not currently detected on the route. Please go back to resume navigation.")
    }
    
    func showAlertIfNeeded(type: AlertType, title: String, message: String){
        if self.hasAlertPresentationDateExpired(type: type) {
            view?.showAlertMessage(title: title, message: message)
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

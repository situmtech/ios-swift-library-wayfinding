//
//  SitumMapsLibrary.swift
//  SitumWayfinding
//
//  Created by Adrián Rodríguez on 23/05/2019.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//

import UIKit
import SitumSDK
import GoogleMaps

/**
 Class used to load the wayfinding module on a given view
 */
@objc public class SitumMapsLibrary: NSObject, SitumMap {
    
    private var parentViewControler: UIViewController
    private var containerView: UIView
    private var toPresentViewController: PositioningViewController?
    internal let interceptorsManager: InterceptorsManager = InterceptorsManager()
    internal var onBackPressedCallback: ((Any) -> Void)?
    
    /// Credentials object used to authenticate the user before loading the wayfinding module
    public private(set) var credentials: Credentials?
    
    /**
     Initializes the library and checks the user's credentials.
     
     - parameter view: View object that will contain the wayfinding UI
     - parameter viewController: View controller associated with the containing view
     */
    @objc public init(containedBy view: UIView, controlledBy viewController: UIViewController) {
        self.parentViewControler = viewController
        self.containerView = view
    }

    /**
     Sets the credentials that will be used to authenticate when "load(buildingWithId:, logWith:)" is called
     
     - parameter: credentials: Credentials object used to authenticate against Situm SDK and Google Maps
     */
    @objc public func setCredentials(_ credentials: Credentials) {
        self.credentials = credentials
    }
    
    /**
     Loads the Wayfinding UI in the assigned view and shows the selected building.
     If no Credentials have been set, this method will throw an exception.
     
     - parameter buildingId: Id of the building to be load
     */
    @objc public func load(buildingWithId buildingId: String?) throws {
        try validationsPreLoading(buildingWithId: buildingId)
        let mapView = obtainGMSMapView()
        prepareForLoading(buildingWithId: buildingId, withMap: mapView)
        UIUtils().present(the: self.toPresentViewController!, over: self.parentViewControler, in: self.containerView)
    }
    
    /**
     Loads the Wayfinding UI in the assigned view using the provided map and shows the selected building.
     If no Credentials have been set, this method will throw an exception.
     
     - parameter buildingId: Id of the building to be load
     - parameter googleMapsMap: Map to be used to present info
     */
    @objc public func load(buildingWithId buildingId: String?, googleMapsMap gMap:GMSMapView?) throws {
        try validationsPreLoading(buildingWithId: buildingId)
        prepareForLoading(buildingWithId: buildingId, withMap: gMap)
        UIUtils().present(the: self.toPresentViewController!, over: self.parentViewControler, in: self.containerView)
    }
    
    /**
     Provides the GMSMapView instance used inside the Wayfinding view
     
     - returns: A GMSMapView instance which is the same being used by the Wayfinding controller
     */
    public func getGoogleMap() -> GMSMapView? {
        return self.toPresentViewController?.getGoogleMap()
    }
    
    /**
     Allows setting a closure with a custom exit segue that will be executed when the "Go back" button is pressed.
     You may also include operations to be done before closing the wayfinding view. If no callback is set, the
     wayfinding view will try to exit using NavigationController method: popViewController(animated: Bool)
     
     - parameter callback: Closure used to perform the exit segue from the wayfinding view
     */
    public func setOnBackPressedCallback(_ callback: @escaping (_ sender: Any) -> Void) {
        self.onBackPressedCallback = callback
    }
    
    /**
     Sets an interceptor to read or modify the location request before is actually used to start positioning.
     Multiple interceptors can be add and they will be executed in the same order as they were set.
     
     - parameter interceptor: Closure that will be executed with the location request as its parameter before starting the positioning
     */
    public func addLocationRequestInterceptor(_ interceptor: @escaping (SITLocationRequest) -> Void) {
        self.interceptorsManager.addLocationRequestInterceptor(interceptor)
    }
    
    /**
     Sets an interceptor to read or modify the directions request before is actually used to start guiding
     Multiple interceptors can be add and they will be executed in the same order as they were set.
     
     - parameter interceptor: Closure that will be executed with the directions request as its parameter before starting the guidance
     */
    public func addDirectionsRequestInterceptor(_ interceptor: @escaping (SITDirectionsRequest) -> Void) {
        self.interceptorsManager.addDirectionsRequestInterceptor(interceptor)
    }
    
    /**
     Sets an interceptor to read or modify the navigation request before is actually used to obtain a route
     Multiple interceptors can be add and they will be executed in the same order as they were set.
     
     - parameter interceptor: Closure that will be executed with the navigation request as its parameter before starting the navigation
     */
    public func addNavigationRequestInterceptor(_ interceptor: @escaping (SITNavigationRequest) -> Void) {
        self.interceptorsManager.addNavigationRequestInterceptor(interceptor)
    }
}

extension SitumMapsLibrary {
    
    internal func obtainGMSMapView()->GMSMapView?{
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        return mapView
    }
    
    internal func loadFromView(buildingWithId buildingId: String?) throws {
        let mapView = obtainGMSMapView()
        try prepareForLoading(buildingWithId: buildingId, withMap: mapView)
        UIUtils().presentFromView(the: self.toPresentViewController!, in: self.containerView)
    }
    
    internal func validationsPreLoading(buildingWithId buildingId: String?) throws {
        try validateUserCredentials(self.credentials)
        try validateActiveBuilding(buildingId)
        
    }
    
    internal func prepareForLoading(buildingWithId buildingId: String?, withMap googleMapView: GMSMapView?) {
        if self.toPresentViewController == nil {
            self.toPresentViewController = self.prepareControllerToPresent(buildingWithId: buildingId!, withMap: googleMapView!)
        }
    }
    
    internal func validateUserCredentials(_ credentials: Credentials?) throws {
        // TODO: This checks if credentials exist, it should also check if they are valid
        if let credentials = credentials {
            CredentialsStrategy.checkCredentials(credentials: credentials)
        } else {
            throw UnsupportedConfigurationError.missingCredentials(message: "You must set your auth info with setCredentials() before calling load(buildingWithId:)")
        }
    }
    
    internal func validateActiveBuilding(_ buildingId: String?) throws {
        if(buildingId == nil || buildingId!.isEmpty) {
            throw UnsupportedConfigurationError.invalidActiveBuilding(message: "The building ID in plist file is not correct. Please add a valid ID with key: es.situm.sdk.ACTIVE_BUILDING_ID")
        }
    }
    
    internal func prepareControllerToPresent(buildingWithId buildingId: String,withMap googleMapView: GMSMapView) -> PositioningViewController? {
        let vc = UIUtils().viewControllerFromStoryboard(with:"SCTPositioningController")
        let toPresentViewController = vc as? PositioningViewController
        toPresentViewController?.buildingId = buildingId
        toPresentViewController?.library = self
        toPresentViewController?.mapView = googleMapView
        
        return toPresentViewController
    }
}

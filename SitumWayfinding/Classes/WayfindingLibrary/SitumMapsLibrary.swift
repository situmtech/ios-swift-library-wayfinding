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
    internal var delegatesNotifier = WayfindingDelegatesNotifier()
    static internal var bundle: Bundle = {
        let libraryBundle = Bundle(for: SitumMapsLibrary.self)
        guard let resourceBundleURL = libraryBundle.url(forResource: "SitumWayfinding", withExtension: "bundle") else {
            fatalError("SitumWayfinding.bundle not found!")
        }
        guard let resourceBundle = Bundle(url: resourceBundleURL) else {
            fatalError("Cannot access MySDK.bundle!")
        }
        return resourceBundle
    }()
    
    /// Credentials object used to authenticate the user before loading the wayfinding module
    // public private(set) var credentials: Credentials?
    
    /// Settings variable used to configure the module with all needed parameters.
    public private(set) var settings: LibrarySettings?
    
    /**
     Initializes the library and checks the user's credentials.
     
     - parameter view: View object that will contain the wayfinding UI
     - parameter viewController: View controller associated with the containing view
     */
    @available(*, deprecated, message: "Please use ", renamed:"init")
    @objc public convenience init(containedBy view: UIView, controlledBy viewController: UIViewController) {
        // self.parentViewControler = viewController
        // self.containerView = view

        // Point to the other init method with
        self.init(containedBy: view, controlledBy: viewController, withSettings: LibrarySettings.Builder().build()) // Empty or default settings
    }
    
    
    /**
     Designated initializer
     
    Use this to create an instance of the SitumMapsLibrary.
     
    After that, load it into memory with the load() method.
     */
    @objc public init(containedBy view: UIView, controlledBy viewController: UIViewController, withSettings settings: LibrarySettings) {
        self.parentViewControler = viewController
        self.containerView = view
        self.settings = settings
    }
    
    /// try to load the module. This method can throw an exception if needed parameters are not set. See init method to know how to properly configure an instance.
    @objc public func load() throws {
        // Validate credentials, buildingId and so on..
        
        try validateSettings()
        if let settings = getSettings() {
            let mapView = settings.googleMap != nil ? settings.googleMap : obtainGMSMapView()
            prepareForLoading(buildingWithId: settings.buildingId, withMap: mapView)
            SITServices.setUseRemoteConfig(settings.useRemoteConfig)
            self.toPresentViewController?.preserveStateInNewViewAppeareance = false;
            UIUtils().present(the: self.toPresentViewController!, over: self.parentViewControler, in: self.containerView)
        } // NOTE: else unnecessary: validateSettings already checks settings not nil
    }

    /**
     Sets the credentials that will be used to authenticate when "load(buildingWithId:, logWith:)" is called
     
     - parameter: credentials: Credentials object used to authenticate against Situm SDK and Google Maps
     */
    @available(*, deprecated, message: "Use property on LibrarySettings instance instead")
    @objc public func setCredentials(_ credentials: Credentials) {
        // self.credentials = credentials
        let settingsBuilder = LibrarySettings.Builder().copy(settings: settings!) // Keep values previosuly specified
        settingsBuilder.setCredentials(credentials: credentials)
        settings = settingsBuilder.build()
    }
    
    /**
     Loads the Wayfinding UI in the assigned view and shows the selected building.
     If no Credentials have been set, this method will throw an exception.
     
     - parameter buildingId: Id of the building to be load
     */
    @available(*, deprecated, message: "Use load instead")
    @objc public func load(buildingWithId buildingId: String?) throws {
        // Previous implementation
        // Validate before using buildingId?
        try validateActiveBuilding(buildingId)
        if let buildingId = buildingId {
            // Override settings configuration with new information
            let settingsBuilder = LibrarySettings.Builder().copy(settings: settings!) // Keep values previosuly specified
            settingsBuilder.setBuildingId(buildingId: buildingId)
            settings = settingsBuilder.build()
            
            try load()
        }
    }
    
    /**
     Loads the Wayfinding UI in the assigned view using the provided map and shows the selected building.
     If no Credentials have been set, this method will throw an exception.
     
     - parameter buildingId: Id of the building to be load
     - parameter googleMapsMap: Map to be used to present info
     */
    @available(*, deprecated, message: "Use load instead")
    @objc public func load(buildingWithId buildingId: String?, googleMapsMap gMap:GMSMapView?) throws {
        try validationsPreLoading(buildingWithId: buildingId)
        prepareForLoading(buildingWithId: buildingId, withMap: gMap)
        UIUtils().present(the: self.toPresentViewController!, over: self.parentViewControler, in: self.containerView)
    }
    
    /**
     Changes the container view that currently contains the WYF UI and present it in this new view whitout the need to reset the module.
     - parameter view new view that will contain the wayfinding UI
     - parameter viewController: view controller associated with the containing view
     */
    @objc public func presentInNewView(_ view: UIView, controlledBy viewController: UIViewController){
        self.parentViewControler = viewController
        self.containerView = view
        self.toPresentViewController?.preserveStateInNewViewAppeareance = true;
        UIUtils().present(the: self.toPresentViewController!, over: self.parentViewControler, in: self.containerView)
    }

    
    /**
       Stops Situm Navigation
     */
    @objc public func stopNavigation(){
        self.toPresentViewController?.stopNavigation(status: .canceled)
    }
    
    /**
        Stops Situm Positioning
     */
    @objc public func stopPositioning(){
        self.toPresentViewController?.presenter?.stopPositioning()
    }
    
    /**
     Provides the GMSMapView instance used inside the Wayfinding view
     
     - returns: A GMSMapView instance which is the same being used by the Wayfinding controller
     */
    @available(*, deprecated, message: "Use LibrarySettings.getGoogleMap instead")
    public func getGoogleMap() -> GMSMapView? {
        return self.toPresentViewController?.getGoogleMap()
    }
    
    /// Retrieve the properties the module has been loaded with.
    @objc public func getSettings() -> LibrarySettings? {
        return self.settings
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
    
    /**
     Sets a delegate that get notified about changes in selection/deselection of Pois
     
     - parameter delegate: OnPoiSelectedListener protocol
     */
    public func setOnPoiSelectionListener(listener: OnPoiSelectionListener?) {
        delegatesNotifier.poiSelectionDelegate = listener
    }
    
    /**
     Sets a delegate  that get notified about changes in the selected floor. 
     
     - parameter delegate: OnPoiSelectedListener protocol
     */
    public func setOnFloorChangeListener(listener: OnFloorChangeListener?) {
        delegatesNotifier.floorChangeDelegate=listener
    }

    /**
     Sets a delegate that get notified when the map is ready to interact with and fully loaded.
     
     - parameter listener: OnMapReadyListener
     */
    public func setOnMapReadyListener(listener: OnMapReadyListener?) {
        delegatesNotifier.mapReadyDelegate = listener
    }

    /**
     Sets a delegate that get notified with events related to Navigation

     - parameter listener: OnNavigationChangeListener
     */
    public func setOnNavigationListener(listener: OnNavigationListener?) {
        delegatesNotifier.navigationDelegate = listener
    }

    /**
     Start the navigation to a poi in the current building. This will:
        * Start the positioning if needed
        * Calculate and draw the route from the current user location to the poi.
        * Provide the step-by-step instructions to reach the poi.
     WARNING: this method only works during or after OnMapReadyListener.onMapReady callback is executed
     - parameters:
       - poi: navigation goes toward this SITPOI
     */
    public func navigateToPoi(poi: SITPOI) {
        guard let positioningController = toPresentViewController else { return }
        positioningController.startNavigation(to: poi)
    }

    /**
     Select a given poi. This method will perform the proper actions over the User Interface to make that Poi the
     selected one
     WARNING: this method only works during or after OnMapReadyListener.onMapReady callback is executed
     - parameters:
       - poi: the SITPOI you want to select
       - completion: callback called when operation complete either successfully or with an error
     */
    public func selectPoi(poi: SITPOI, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try self.toPresentViewController?.select(poi: poi) {
                completion(.success(()))
            }
        } catch {
            completion(.failure(error))
        }
    }

    /**
     Start the navigation to a given a location in the current building. The location will be determined by its floor,
     its latitude and its longitude. This will:
        * Start the positioning if needed
        * Calculate and draw the route from the current user location to the location.
        * Provide the step-by-step instructions to reach the location.
     WARNING: this method only works during or after OnMapReadyListener.onMapReady callback is executed
     - parameters:
       - floor: floor of the location
       - lat: latitude of the location
       - lng: longitude of the location

     */
    public func navigateToLocation(floor: SITFloor, lat: Double, lng: Double) {
        guard let positioningController = toPresentViewController else { return }
        let location = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        positioningController.startNavigation(to: location, in: floor)
    }
    
    /**
     This method centers the map on a given building and limits the map zoom and pan to that building bounds.
     - parameters
        - building: The building on where the camera will be locked
    */
    public func lockCameraToBuilding(building: SITBuilding) {
        guard let positioningController = toPresentViewController else { return }
        let cameraOption = positioningController.prepareCamera(building: building)
        positioningController.lockCamera(options: cameraOption)
    }
    
    /**
     This method centers the map on a given building and limits the map zoom and pan to that building bounds.
     - parameters
        - buildingId: The id of building on where the camera will be locked
    */
    public func lockCameraToBuilding(buildingId: String, completion: @escaping (Result<SITBuilding, WayfindingError>) -> Void) {
        guard let positioningController = toPresentViewController else { return }
        positioningController.getBuilding(buildingId: buildingId) { result in
            switch result {
                case .success(let building):
                    let cameraOption = positioningController.prepareCamera(building: building)
                    positioningController.lockCamera(options: cameraOption)
                    completion(.success(building))
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    /**
     This method unlock the camera and allows the user to pan outside building bounds.
    */
    public func unlockCamera() {
        guard let positioningController = toPresentViewController else { return }
        positioningController.unlockCamera()
    }

    /**
     This method filter POIs by given category Ids. This will hide the icon of every POI in the map that not
     matches these category Ids. If an empty array is supplied all POIs will be shown.
     WARNING: this method only works during or after OnMapReadyListener.onMapReady callback is executed
     - parameters
        - categoryIds: these are the ids of the categories to filter
     */
    public func filterPois(by categoryIds: [String]) {
        guard let positioningController = toPresentViewController else { return }
        positioningController.filterPois(by: categoryIds)
    }

    /**
     Start positioning of the user in the map in loaded building
     */
    public func startPositioning() {
        guard let presenter = toPresentViewController?.presenter else { return }
        presenter.startPositioning()
    }

    /**
     Download the building tiles. Not all the buildings have tiles available to be downloaded.
     If the tiles are available, a zip file is downloaded and unzipped in the user Library path for application
     - Parameter completion:
     */
    public func fetchTilesOffline(completion: @escaping (Result<Void, WayfindingError>) -> Void) {
        guard let positioningController = toPresentViewController else { return }
        positioningController.fetchTiles(completion: completion)
    }

    /**
     Invalidate all downloaded tiles to use in offline and delete from user Library path
     */
    public func clearTiles() {
        SITCommunicationManager.shared().clearTiles()
    }
}

extension SitumMapsLibrary {
    
    internal func obtainGMSMapView()->GMSMapView?{
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        
        do {
            if let styleURL = SitumMapsLibrary.bundle.url(forResource: "situm_google_maps_style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find situm_google_maps_style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        return mapView
    }
    
    internal func loadFromView(buildingWithId buildingId: String?) throws {
        let mapView = obtainGMSMapView()
        try prepareForLoading(buildingWithId: buildingId, withMap: mapView)
        UIUtils().presentFromView(the: self.toPresentViewController!, in: self.containerView)
    }
    
    internal func validationsPreLoading(buildingWithId buildingId: String?) throws {
        try validateUserCredentials(self.settings?.credentials)
        try validateActiveBuilding(buildingId)
        
    }
    
    internal func validateSettings() throws {
        // Validate credentials
        if let settings = getSettings() {
            try validateUserCredentials(settings.credentials)
            try validateActiveBuilding(settings.buildingId)
            
            
        } else {
            // throw an exception if necessary
            print("Unable to access configuration LibrarySettings. ")
        }
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
            let message = NSLocalizedString("situmMapsLibrary.error.credentials",
                bundle: SitumMapsLibrary.bundle,
                comment: "Error when user does not set credentials")
            throw UnsupportedConfigurationError.missingCredentials(message: message)
        }
    }
    
    internal func validateActiveBuilding(_ buildingId: String?) throws {
        if(buildingId == nil || buildingId!.isEmpty) {
            let message = NSLocalizedString("situmMapsLibrary.error.invalidBuilding",
                bundle: SitumMapsLibrary.bundle,
                comment: "Error when user does not set correctly building id")
            throw UnsupportedConfigurationError.invalidActiveBuilding(message: message)
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

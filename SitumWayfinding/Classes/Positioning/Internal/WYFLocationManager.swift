//
// Created by Lapisoft on 30/3/22.
//

import Foundation
import SitumSDK

protocol WYFLocationManager: SITLocationInterface {
    var delegate: SITLocationDelegate? { get set }
    func longPress(presenter: PositioningPresenter, coordinate: CLLocationCoordinate2D, buildingInfo: SITBuildingInfo,
                   floorId: String)
}

class LocationManagerCreator {
    static func locationManager() -> WYFLocationManager {
        #if DEBUG
        if (UserDefaultsWrapper.getUseFakeLocations()) {
            return FakeLocationManager()
        } else {
            return WYFSITLocationManager()
        }
        #else
        return WYFSITLocationManager()
        #endif
    }
}

fileprivate class WYFSITLocationManager: SITLocationManager, WYFLocationManager {
    weak override var delegate: SITLocationDelegate? {
        get { return SITLocationManager.sharedInstance().delegate }
        set(value) { SITLocationManager.sharedInstance().delegate = value}
    }
    private var instance: SITLocationManager { return SITLocationManager.sharedInstance() }
    
    func longPress(
        presenter: PositioningPresenter,
        coordinate: CLLocationCoordinate2D,
        buildingInfo: SITBuildingInfo,
        floorId: String)
    {
        presenter.view?.createAndShowCustomMarkerIfOutsideRoute(atCoordinate: coordinate, atFloor: floorId)
    }
    
    override func requestLocationUpdates(_ request: SITLocationRequest?) {
        instance.requestLocationUpdates(request)
    }
    
    override func state() -> SITLocationState {
        instance.state()
    }
    
    override func removeUpdates() {
        instance.removeUpdates()
    }
    
    override func updateLocationParameters(_ update: SITLocationParametersUpdate) {
        instance.updateLocationParameters(update)
    }
}

fileprivate class FakeLocationManager: NSObject, WYFLocationManager {
    weak var delegate: SITLocationDelegate? = nil
    
    private var location: SITLocation?
    private var timer: Timer?
    
    func longPress(
        presenter: PositioningPresenter,
        coordinate: CLLocationCoordinate2D,
        buildingInfo: SITBuildingInfo,
        floorId: String)
    {
        let building = buildingInfo.building
        let converter: SITCoordinateConverter = SITCoordinateConverter(
            dimensions: building.dimensions(), center: building.center(), rotation: building.rotation)
        let cartesianCoordinate: SITCartesianCoordinate? = converter.toCartesianCoordinate(coordinate)
        let point = SITPoint(
            coordinate: coordinate,
            buildingIdentifier: building.identifier,
            floorIdentifier: floorId,
            cartesianCoordinate: cartesianCoordinate!
        )
        
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
        alert.addAction(UIAlertAction(title: cancel, style: .default))
    
        let fakeLocationsOptions: [AngleType] = [.angleZero, .angleRight, .anglePlain, .angleConcave]
        for option in fakeLocationsOptions {
            alert.addAction(UIAlertAction(title: "\(option.rawValue)º", style: .default, handler: { [weak self] _ in
                let angle = option.toSITAngle()
                let location = SITLocation(
                    timestamp: Date().timeIntervalSince1970,
                    position: point,
                    bearing: angle.degrees() + 90,
                    cartesianBearing: (converter.toCartesianAngle(angle).radians()),
                    quality: .sitHigh,
                    accuracy: 5,
                    provider: "Fake"
                )
                self?.update(with: location)
            }))
        }
    
        let markerTitle = NSLocalizedString("positioning.createMarker", bundle: SitumMapsLibrary.bundle, comment: "")
        alert.addAction(UIAlertAction(title: markerTitle, style: .default) { _ in
            presenter.view?.createAndShowCustomMarkerIfOutsideRoute(
                atCoordinate: point.coordinate(), atFloor: point.floorIdentifier)
        })
        
        presenter.view?.present(viewController: alert)
    
        if let x = cartesianCoordinate?.x, let y = cartesianCoordinate?.y {
            Logger.logInfoMessage("Fake location pressed at \(x), \(y)")
        }
    }
    
    private func update(with location: SITLocation) {
        self.location = location
        
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                if let instance = self, let location = instance.location {
                    instance.delegate?.locationManager(instance, didUpdate: location)
                }
            }
        }
    }

    func removeUpdates() {
        removeTimer()
    }
    
    func requestLocationUpdates(_ request: SITLocationRequest?) {}
    
    func state() -> SITLocationState {
        if timer == nil {
            return .stopped
        } else {
            return .started
        }
    }
    
    func updateLocationParameters(_ update: SITLocationParametersUpdate) {}
    
    deinit {
        removeTimer()
    }
    
    private func removeTimer() {
        timer?.invalidate()
        timer = nil
    }
}

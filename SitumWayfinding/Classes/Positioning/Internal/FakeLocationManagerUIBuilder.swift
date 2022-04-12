//
// Created by Lapisoft on 11/4/22.
//

import Foundation
import SitumSDK

class FakeLocationManagerUIBuilder {
    private var buildingInfo: SITBuildingInfo
    private var locationManager: SITLocationInterface
    
    init(buildingInfo: SITBuildingInfo, locationManager: SITLocationInterface) {
        self.buildingInfo = buildingInfo
        self.locationManager = locationManager
    }
    
    func createFakeActionsAlert(
        coordinate: CLLocationCoordinate2D,
        floorId: String,
        defaultAction: @escaping (SITPoint) -> ()
    ) -> UIAlertController {
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
        
        let alert = createAlertForFakeActions()
        
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
        
        alert.addAction(UIAlertAction(title: "Outside building", style: .default) { [weak self] _ in
            let point = SITPoint(wihtCoordinate: coordinate)
            let angle = SITAngle(degrees: 90)!
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
        })
        
        let markerTitle = NSLocalizedString("positioning.createMarker", bundle: SitumMapsLibrary.bundle, comment: "")
        alert.addAction(UIAlertAction(title: markerTitle, style: .default) { _ in
            defaultAction(point)
        })
        
        if let x = cartesianCoordinate?.x, let y = cartesianCoordinate?.y {
            Logger.logInfoMessage("Fake location pressed at \(x), \(y)")
        }
        
        return alert
    }
    
    private func createAlertForFakeActions() -> UIAlertController {
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
        return alert
    }
    
    private func update(with location: SITLocation) {
        LocationManagerFactory.update(object: locationManager, with: location)
    }
}
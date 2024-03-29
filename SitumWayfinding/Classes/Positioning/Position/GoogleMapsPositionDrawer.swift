//
//  PositionAnimator.swift
//  SitumWayfinding
//
//  Created by fsvilas on 26/04/2021.
//

import Foundation
import GoogleMaps

class GoogleMapsPositionDrawer:PositionDrawerProtocol {
    var mapView: GMSMapView!
    var userLocationMarker: GMSMarker? = nil
    var userLocationRadiusCircle: GMSCircle? = nil
    var userPositionAnimationTimer: Timer?
    
    let numberOfInterpolationPoints = 15
    let interpolationTime = 0.5 //In seconds
    let minimunPositionChangeToAnimate = 0.2 //In meters
    
    init(mapView: GMSMapView!) {
        self.mapView = mapView
    }
    
    
    func updateUserLocation(with location: SITLocation, with userMarkerImage: UIImage?, with radiusCircleColor: UIColor?){
        configureUserLocationMarkerInMapView(location:location, userMarkerImage: userMarkerImage, mapView: mapView)
        configureUserLocationRadiusCircleInMapView(location: location, mapView: mapView, radiusCircleColor: radiusCircleColor)
        animateUserLocationChangesInMapView(to: location)
    }
    
    func updateUserBearing(with location: SITLocation){
        userLocationMarker?.rotation = CLLocationDegrees(location.bearing.degrees())
    }
    
    func makeUserMarkerVisible(visible: Bool) {
        if (visible && userLocationMarker?.map == nil) {
            userLocationMarker?.map = mapView
            userLocationRadiusCircle?.map = mapView
        } else if (!visible && userLocationMarker?.map != nil) {
            userLocationMarker?.map  = nil
            userLocationRadiusCircle?.map = nil
        }
    }
    
    private func configureUserLocationMarkerInMapView(location: SITLocation, userMarkerImage:UIImage?, mapView: GMSMapView) {
        if (userLocationMarker == nil) {
            let marker: GMSMarker = GMSMarker.init()
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.isTappable = false;
            marker.zIndex = ZIndices.locationMarker;
            marker.isFlat = true;
            marker.position = location.position.coordinate()
            userLocationMarker = marker;
        }
        userLocationMarker?.icon = userMarkerImage
        userLocationMarker?.iconView?.tintColor = UIColor.red
    }
    
    private func configureUserLocationRadiusCircleInMapView (location: SITLocation, mapView: GMSMapView, radiusCircleColor: UIColor?) {

        if (userLocationRadiusCircle == nil){
            userLocationRadiusCircle = GMSCircle(position: location.position.coordinate(), radius: CLLocationDistance(location.accuracy))
            //TODO: color radius accurace
            let color = radiusCircleColor
            
            userLocationRadiusCircle?.strokeColor = color
            userLocationRadiusCircle?.fillColor = color
            userLocationRadiusCircle?.isTappable = false
            userLocationRadiusCircle?.zIndex = ZIndices.locationRadiusCircle
        }
    }
   /**
     Animates changes in user location and location accuracy. Unfortunately only marker objects (GMSMarker) have fluid animations when its position is changed in Google Maps. To improve the visual appeal, we have to interpolate intermediate positions between origin and destination ans the accuracy circle radius.
     - Parameter location: New user location
    */
    private func animateUserLocationChangesInMapView(to location: SITLocation){
        userPositionAnimationTimer?.invalidate()
        let origin:CLLocationCoordinate2D = userLocationMarker!.position
        let destination: CLLocationCoordinate2D = location.position.coordinate()
        let initialRadius = userLocationRadiusCircle!.radius
        let endRadius = location.accuracy
        
        var runCount = 0
        let interpolationInterval =  Double(interpolationTime)/Double(numberOfInterpolationPoints)
        userPositionAnimationTimer = Timer.scheduledTimer(withTimeInterval: interpolationInterval, repeats: true) { timer in
            // To make user position marker and accuracy position circle to move synced we have to animate the changes in same block, instead of separate blocks for each of them
            
            let fraction = Double(runCount+1)/Double (self.numberOfInterpolationPoints)
            let interpolatedLocation = self.interpolatePosition(fraction: fraction, origin: origin, destination: destination)
            let interpolatedRadius = self.interpolateAccuracyRadius(fraction: fraction, initialRadius: initialRadius, endRadius: Double(endRadius))
            runCount += 1
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.0)
            if origin.distance(from: destination)>self.minimunPositionChangeToAnimate {
                self.userLocationMarker?.position = interpolatedLocation
                self.userLocationRadiusCircle?.position = interpolatedLocation
            }
            self.userLocationRadiusCircle?.radius = interpolatedRadius
            CATransaction.commit()
            
            if runCount == self.numberOfInterpolationPoints {
                timer.invalidate()
            }
        }
    }

    private func interpolatePosition(fraction: Double, origin:CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> CLLocationCoordinate2D{
        let lat: Double = (destination.latitude - origin.latitude) * fraction + origin.latitude;
        let lng: Double = (destination.longitude - origin.longitude) * fraction + origin.longitude;
        return CLLocationCoordinate2DMake(lat, lng)
    }
    
    private func interpolateAccuracyRadius(fraction: Double, initialRadius: Double, endRadius: Double) ->Double{
        return (initialRadius + (endRadius-initialRadius) * fraction)
    }
    
}

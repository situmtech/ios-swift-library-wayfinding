import GoogleMaps

struct SITCameraOption {
    var minZoom: Float?
    var maxZoom: Float?
    var coordinateBounds: GMSCoordinateBounds?
    
    init(minZoom: Float, maxZoom: Float, bounds: SITBounds) {
        self.minZoom = minZoom
        self.minZoom = maxZoom
        self.coordinateBounds = GMSCoordinateBounds(
            coordinate: bounds.southWest,
            coordinate: bounds.northEast
        )
    }
    
    func moveCamera(mapView: GMSMapView) {
        mapView.cameraTargetBounds = self.coordinateBounds
    }
    
}

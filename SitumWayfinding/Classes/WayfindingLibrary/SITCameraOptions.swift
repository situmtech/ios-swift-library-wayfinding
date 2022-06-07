import CoreLocation

struct SITCameraOptions {
    var minZoom: Float
    var maxZoom: Float
    var southWestCoordinate: CLLocationCoordinate2D
    var northEastCooordinate: CLLocationCoordinate2D
    
    init(minZoom: Float, maxZoom: Float, southWestCoordinate: CLLocationCoordinate2D, northEastCooordinate: CLLocationCoordinate2D) {
        self.minZoom = minZoom
        self.maxZoom = maxZoom
        self.southWestCoordinate = southWestCoordinate
        self.northEastCooordinate = northEastCooordinate
    }
}

//
// Created by Lapisoft on 25/5/22.
//

import Foundation
import SitumSDK
import GoogleMapsUtils
import GoogleMaps

class GoogleMapsMarkerClustering {
    private var mapView: GMSMapView
    private var clusterManager: GMUClusterManager
    
    init(mapView: GMSMapView) {
        self.mapView = mapView
        let iconGenerator = GMUDefaultClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = WYFClusterRenderer(mapView: mapView,  clusterIconGenerator: iconGenerator)
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
    }
    
    func add(_ marker: SitumMarker) {
        clusterManager.add(marker.gmsMarker)
    }
    
    func add(_ marker: Array<SitumMarker>) {
        clusterManager.add(marker.map { marker in marker.gmsMarker })
    }
    
    func display() {
        clusterManager.cluster()
    }
    
    func removeMarkers() {
        clusterManager.clearItems()
    }
}


fileprivate class WYFClusterRenderer: GMUDefaultClusterRenderer {
    private static let zoomLevelThreshold: Float = 19.5

    override func shouldRender(as cluster: GMUCluster, atZoom zoom: Float) -> Bool {
        if (zoom > WYFClusterRenderer.zoomLevelThreshold) {
            return false
        }
        return super.shouldRender(as: cluster, atZoom: zoom)
    }
}

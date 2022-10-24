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
        let algorithm = SITNonHierarchicalDistanceBasedAlgorithm()
        let renderer = WYFClusterRenderer(mapView: mapView,  clusterIconGenerator: iconGenerator)
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
    }
    
    func add(_ marker: SitumMarker) {
        clusterManager.add(marker.gmsMarker)
    }
    
    func display() {
        clusterManager.cluster()
    }
    
    func removeMarkers() {
        clusterManager.clearItems()
    }
}

fileprivate class SITNonHierarchicalDistanceBasedAlgorithm: GMUNonHierarchicalDistanceBasedAlgorithm {
    private var nonClusteredItems: [GMSMarker] = []

    override func add(_ items: [GMUClusterItem]) {
        for item in items {
            let marker = item as! GMSMarker // GoogleMapsMarkerClustering set only gmsMarkers
            if let markerData = marker.markerData, markerData.isTopLevel {
                nonClusteredItems.append(marker)
            } else {
                return super.add([item])
            }
        }
    }

    override func remove(_ item: GMUClusterItem) {
        super.remove(item)
        let marker = item as! GMSMarker
        nonClusteredItems.removeAll(where: { $0 == marker })
    }

    override func clearItems() {
        super.clearItems()
        nonClusteredItems.removeAll()
    }

    override func clusters(atZoom zoom: Float) -> [GMUCluster] {
        var clusters = super.clusters(atZoom: zoom)
        // Add one cluster per item in nonClusteredItems. This allows to show the POI marker as is, because
        // when a cluster only has one elements is shown as a normal marker instead of the clustering icon
        for nonClusteredItem in nonClusteredItems {
            let singleItemCluster = createClusterWithOneElement(nonClusteredItem)
            clusters.append(singleItemCluster)
        }
        return clusters
    }

    private func createClusterWithOneElement(_ item: GMSMarker) -> GMUCluster {
        let singleItemCluster: GMUStaticCluster = GMUStaticCluster(position: item.position)
        singleItemCluster.addItem(item)
        return singleItemCluster
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

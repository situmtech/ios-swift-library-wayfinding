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
        let iconGenerator = SITClusterIconGenerator()
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

fileprivate class SITClusterIconGenerator: NSObject, GMUClusterIconGenerator {
    private var iconCache = NSCache<NSString, UIImage>()
    private var buckets: [Int] = [10, 20, 50, 100, 200, 1000]
    private var sitBackgroundColors: [UIColor]  = [
        UIColor(red: 0, green: 73, blue: 152),
        UIColor(red: 0, green: 153, blue: 204),
        UIColor(red: 102, green: 152, blue: 0),
        UIColor(red: 255, green: 136, blue: 0),
        UIColor(red: 204, green: 0, blue: 0),
        UIColor(red: 153, green: 51, blue: 204),
    ]

    func icon(forSize size: UInt) -> UIImage! {
        // copied from  GMUDefaultClusterIconGenerator.m:107
        // https://github.com/googlemaps/google-maps-ios-utils/blob/main/src/Clustering/View/GMUDefaultClusterIconGenerator.m#L107
        let intSize = Int(size)
        let bucketIndex = bucketIndexForSize(intSize)
        var text = ""

        // If size is smaller to first bucket size, use the size as is otherwise round it down to the
        // nearest bucket to limit the number of cluster icons we need to generate.
        if size < buckets[0] {
            text = String(format: "%d", intSize)
        } else {
            text = String(format: "%d+", buckets[bucketIndex])
        }
        return icon(forText: text, withBucketIndex: bucketIndex)
    }

    private func bucketIndexForSize(_ size: Int) -> Int {
        // copied from: GMUDefaultClusterIconGenerator.m:129
        // https://github.com/googlemaps/google-maps-ios-utils/blob/main/src/Clustering/View/GMUDefaultClusterIconGenerator.m#L129
        // Finds the smallest bucket which is greater than |size|. If none exists return the last bucket
        // index (i.e |_buckets.count - 1|).
        var index = 0
        while (index + 1 < buckets.count && buckets[index + 1] <= size) {
           index += 1
        }
        return index
    }

    private func icon(forText text: String, withBucketIndex bucketIndex: Int) -> UIImage! {
        // copied from: GMUDefaultClusterIconGenerator.m:168
        // https://github.com/googlemaps/google-maps-ios-utils/blob/main/src/Clustering/View/GMUDefaultClusterIconGenerator.m#L168
        let text = NSString(string: text)
        if let icon = iconCache.object(forKey: text) { return icon }

        let font = UIFont.boldSystemFont(ofSize: 20)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        let textSize = text.size(withAttributes: attributes)

        let padding: CGFloat = 12
        let maximumSize: CGFloat = 43
        let rectDimension = max(maximumSize, max(textSize.width, textSize.height)) + 3 * CGFloat(bucketIndex) + padding;
        let rect = CGRect(x: 0, y: 0, width: rectDimension, height: rectDimension)

        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return UIImage() }
        
        // draw halo of circle
        context.saveGState()
        context.setFillColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        context.fillEllipse(in: rect)
        context.restoreGState()

        // draw circle with color of bucket
        context.saveGState()
        let backgroundColorIndex = min(Int(bucketIndex), sitBackgroundColors.count - 1)
        let backgroundColor = sitBackgroundColors[backgroundColorIndex]
        context.setFillColor(backgroundColor.cgColor)

        let innerPadding: CGFloat = 3.5
        let innerRectDimension = rectDimension - innerPadding * 2
        let innerCircleRect = CGRect(x: innerPadding, y: innerPadding, width: innerRectDimension, height: innerRectDimension)
        context.fillEllipse(in: innerCircleRect)
        context.restoreGState()

        // draw text
        UIColor.white.set()
        let textRect = rect.insetBy(dx: (rect.size.width - textSize.width) / 2, dy: (rect.size.height - textSize.height) / 2)
        text.draw(in: textRect, withAttributes: attributes)
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return UIImage() }
        UIGraphicsEndImageContext()

        iconCache.setObject(newImage, forKey: text)
        return newImage
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
}

//
//  SitumTileLayer.swift
//  SitumWayfinding
//
//  Created by fsvilas on 7/9/22.
//

import Foundation
import GoogleMaps

class TileProvider {

    let tileSize = 256
    var mapView: GMSMapView!
    private var tileLayer: SitumTileLayer?
    private var useCustomTiles: Bool
    private var isDebugging: Bool

    init(mapView: GMSMapView, useCustomTiles: Bool? = nil, isDebugging: Bool? = nil) {
        self.useCustomTiles = useCustomTiles ?? false
        self.isDebugging = isDebugging ?? false
        if self.useCustomTiles {
            self.mapView = mapView
        }
    }

    func addTileFor(floor: SITFloor) {
        guard useCustomTiles else { return }

        removeTileLayer()

        tileLayer = SitumTileLayer(floor: floor, isDebugging: isDebugging)
        tileLayer?.clearTileCache()
        tileLayer?.tileSize = tileSize
        // Display on the map at a specific zIndex
        tileLayer?.zIndex = ZIndices.tile
        tileLayer?.map = mapView
    }

    func removeTileLayer() {
        guard useCustomTiles else { return }

        tileLayer?.map = nil
        tileLayer = nil
    }
}

fileprivate class SitumTileLayer: GMSTileLayer {
    var floor: SITFloor
    private var gmsUrlTileLayer: GMSURLTileLayer
    private var isDebugging: Bool

    init(floor: SITFloor, isDebugging: Bool? = nil) {
        self.floor = floor
        self.isDebugging = isDebugging ?? false
        gmsUrlTileLayer = GMSURLTileLayer(urlConstructor: { (x, y, zoom) in
            let tile = SITCommunicationManager.shared().getTileForBuilding(floor.buildingIdentifier, floorIdentifier: floor.identifier, x: Int(x), y: Int(y), z: Int(zoom))
            if tile.resourceType == .url {
                return tile.url
            }
            return nil
        })
    }

    override func requestTileFor(x: UInt, y: UInt, zoom: UInt, receiver: GMSTileReceiver) {
        let tile = SITCommunicationManager.shared().getTileForBuilding(floor.buildingIdentifier, floorIdentifier: floor.identifier, x: Int(x), y: Int(y), z: Int(zoom))
        if tile.resourceType == .url {
            gmsUrlTileLayer.requestTileFor(x: x, y: y, zoom: zoom, receiver: receiver)
        } else if tile.resourceType == .file {
            if var image = UIImage(contentsOfFile: tile.path!) {
                if isDebugging {
                    image = createMarkedTileForDebugging(image: image)
                }
                receiver.receiveTileWith(x: x, y: y, zoom: zoom, image: image)
            } else {
                receiver.receiveTileWith(x: x, y: y, zoom: zoom, image: nil)
            }
        } else {
            receiver.receiveTileWith(x: x, y: y, zoom: zoom, image: nil)
        }
    }

    override func clearTileCache() {
        gmsUrlTileLayer.clearTileCache()
    }

    private func createMarkedTileForDebugging(image: UIImage) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { rendererContext in
            rendererContext.cgContext.setStrokeColor(UIColor.red.cgColor)
            rendererContext.cgContext.setLineWidth(5)

            let padding: CGFloat = 30
            let rectangle = CGRect(x: padding, y: padding, width: rect.width - padding * 2, height: rect.height - padding * 2)
            rendererContext.cgContext.addEllipse(in: rectangle)
            rendererContext.cgContext.drawPath(using: .stroke)


            let font = UIFont.boldSystemFont(ofSize: 60)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.red,
                .paragraphStyle: paragraphStyle
            ]
            let text = "DEBUG\nTILE FROM\nLOCAL CACHE"
            let textSize = text.size(withAttributes: attributes)
            let textRect = rect.insetBy(dx: (rect.size.width - textSize.width) / 2, dy: (rect.size.height - textSize.height) / 2)
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}

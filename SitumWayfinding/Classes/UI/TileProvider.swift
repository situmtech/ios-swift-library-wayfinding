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

    init(mapView: GMSMapView) {
        self.mapView = mapView
    }

    func addTileFor(floor: SITFloor) {
        removeTileLayer()

        tileLayer = SitumTileLayer(floor: floor)
        tileLayer?.tileSize = tileSize
        // Display on the map at a specific zIndex
        tileLayer?.zIndex = ZIndices.tile
        tileLayer?.map = mapView
    }

    func removeTileLayer() {
        tileLayer?.map = nil
        tileLayer = nil
    }
}

fileprivate class SitumTileLayer: GMSTileLayer {
    var floor: SITFloor
    private var gmsUrlTileLayer: GMSURLTileLayer?

    init(floor: SITFloor) {
        self.floor = floor
        super.init()
        gmsUrlTileLayer = GMSURLTileLayer(urlConstructor: { [weak self] (x, y, zoom) in
            guard let tile = self?.getTile(x: x, y: y, zoom: zoom), tile.resourceType == .url else { return nil }
            return tile.url
        })
    }

    override func requestTileFor(x: UInt, y: UInt, zoom: UInt, receiver: GMSTileReceiver) {
        let tile = getTile(x: x, y: y, zoom: zoom)
        if tile.resourceType == .url {
            gmsUrlTileLayer?.requestTileFor(x: x, y: y, zoom: zoom, receiver: receiver)
        } else if tile.resourceType == .file, let image = UIImage(contentsOfFile: tile.path!) {
            receiver.receiveTileWith(x: x, y: y, zoom: zoom, image: image)
        }
    }

    private func getTile(x: UInt, y: UInt, zoom: UInt) -> SITTile {
        return SITCommunicationManager.shared().getTileForBuilding(
            floor.buildingIdentifier,
            floorIdentifier: floor.identifier,
            x: Int(x),
            y: Int(y),
            z: Int(zoom)
        )
    }

    override func clearTileCache() {
        gmsUrlTileLayer?.clearTileCache()
    }
}

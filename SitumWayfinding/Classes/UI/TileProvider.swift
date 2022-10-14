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
    private var gmsUrlTileLayer: GMSURLTileLayer

    init(floor: SITFloor) {
        self.floor = floor
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
            receiver.receiveTileWith(x: x, y: y, zoom: zoom, image: UIImage(contentsOfFile: tile.path!))
        } else {
            receiver.receiveTileWith(x: x, y: y, zoom: zoom, image: nil)
        }
    }

    override func clearTileCache() {
        gmsUrlTileLayer.clearTileCache()
    }
}

//
//  SitumTileLayer.swift
//  SitumWayfinding
//
//  Created by fsvilas on 7/9/22.
//

import Foundation
import GoogleMaps

class TileProvider{
    
    let baseUrl = "https://dashboard.situm.com/api/v1/tiles/"
    let tileSize = 256
    var mapView: GMSMapView!
    var tileLayer:GMSURLTileLayer?
    
    init(mapView:GMSMapView){
        self.mapView = mapView
    }
    
    func addTileFor(floorIdentifier:String){
        removeTileLayer()
        let urls: GMSTileURLConstructor = { (x, y, zoom) in
            let url = self.baseUrl + "\(floorIdentifier)/\(zoom)/\(x)/\(y).png"
            return URL(string: url)
        }
        tileLayer = GMSURLTileLayer(urlConstructor: urls)
        tileLayer?.tileSize = tileSize

        // Display on the map at a specific zIndex
        tileLayer?.zIndex = zIndices.tile
        tileLayer?.map = mapView
    }
    
    func removeTileLayer(){
        tileLayer?.map=nil
        tileLayer=nil
    }
}

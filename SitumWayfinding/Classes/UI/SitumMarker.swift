//
//  PoiMarker.swift
//  SitumWayfinding
//
//  Created by fsvilas on 4/1/22.
//

import Foundation
import GoogleMaps

struct SitumMarker:Equatable{
    private(set) var gmsMarker:GMSMarker
    private(set) var poi:SITPOI?
    
    init(from marker:GMSMarker){
        self.gmsMarker=marker
        if let poi=marker.userData as? SITPOI{
            self.poi=poi
        }
    }
    
    func setMapView(mapView:GMSMapView?){
        gmsMarker.map=mapView
    }
    
    func isPoiMarker()->Bool{
        return !(poi==nil)
    }
    
    static func == (lhs: SitumMarker, rhs: SitumMarker) -> Bool {
        //Sometimes the pois are the same but the maker differ
        //TODO understand why
           return lhs.gmsMarker == rhs.gmsMarker ||
        (lhs.isPoiMarker() && lhs.poi?.id == rhs.poi?.id)
       }
    
}

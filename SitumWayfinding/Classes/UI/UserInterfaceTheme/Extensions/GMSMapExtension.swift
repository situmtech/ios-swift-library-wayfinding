//
//  GMSMapExtension.swift
//  SitumWayfinding
//
//  Created by fsvilas on 13/1/23.
//

import Foundation
import GoogleMaps

extension GMSMapView{
    func applySitumSytle() {
        do {
            var styleMap = "situm_google_maps_style"
            
            if #available(iOS 12.0, *) {
                if traitCollection.userInterfaceStyle == .dark {
                    styleMap = "\(styleMap)_dark"
                }
            }
            
            if let styleURL = SitumMapsLibrary.bundle.url(forResource: styleMap, withExtension: "json") {
                mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find \(styleMap).json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
    }
}

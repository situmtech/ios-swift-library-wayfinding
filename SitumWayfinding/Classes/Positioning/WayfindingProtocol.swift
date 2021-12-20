//
//  WayfindingProtocol.swift
//  SitumWayfinding
//
//  Created by fsvilas on 16/12/21.
//

import Foundation

enum WayfindingError: Error {
    case invalidPOI
}

protocol WayfindingProtocol {
    func select(poi:SITPOI) throws
}



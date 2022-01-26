//
// Created by Lapisoft on 26/1/22.
//

import Foundation

/**
 Errors WayfindinLibrary could raise
 */
public enum WayfindingError: Error {
    /**
     Select a POI on selectPoi() inside SitumMapsLibrary could return and invalid POI error
     when this poi do no belong to the current building
     */
    case invalidPOI
    /**
     Generic error that represent an unexpected error
     */
    case unknown
}
